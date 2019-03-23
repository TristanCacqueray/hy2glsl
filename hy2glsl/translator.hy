;; hy2glsl -- Hy to GLSL Language Translator
;;
;; This library is free software: you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.
;;
;; This library is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with this program. If not, see <http://www.gnu.org/licenses/>.

;; Missing core procedures discussed in: https://github.com/hylang/hy/pull/1762
(defn expression? [e]
  (instance? HyExpression e))
(defn list? [l]
  (instance? HyList l))

(setv gl-types '[int float vec2 vec3 vec4 mat2 mat3 mat4])

(defn hy2glsl [code]
  (setv shader [])
  (defn translate [expr env &optional [indent 0] [term True]]
    (defn append [&rest code &kwargs kwargs]
      (.append shader (+ (* " " (* 2 (if (in "indent" kwargs)
                                         (get kwargs "indent")
                                         indent)))
                         (.join "" (map str code)))))

    ;; Environment procedures to manage variables scope
    (defn mangle-var [var-name]
      ;; GLSL '.' are valid
      (.join "." (map mangle (.split var-name '.))))
    (defn lookup [var-name &optional [env env]]
      ;; Look in environment for variable type
      (setv var-name (mangle (get (.split var-name '.) 0)))
      (if (in var-name env)
          (get env var-name)
          None))
    (defn define [var-name var-type &optional [env env]]
      ;; Set variable type
      (setv var-name (mangle (get (.split var-name '.) 0)))
      (when (lookup var-name env)
        (print "warning: var" var-name "shadow the environment!"))
      (assoc env var-name (name var-type)))
    (defn copy-env []
      ;; Copy the environment
      (setv result {})
      (for [k env]
        (assoc result k (get env k)))
      result)

    (defn infer-type [expr]
      ;; Very primitive type inference...
      (defn infer [expr &optional [no-symbol False]]
        (cond [(and (expression? expr) (in (get expr 0) gl-types))
               (get expr 0)]
              [(expression? expr)
               ;; First look for any known variables type
               (for [e expr]
                 (setv expr-type (infer e :no-symbol True))
                 (when expr-type
                   (return expr-type)))
               ;; Then look for symbols
               (for [e expr]
                 (setv expr-type (infer e))
                 (when expr-type
                   (return expr-type)))
               ]
              [(and (not no-symbol) (float? expr))
               'float]
              [(and (not no-symbol) (integer? expr))
               'int]
              [(and (symbol? expr) (lookup expr))
               (lookup expr)]
              [True None]))
      (setv inferred-type (infer expr))
      (when (not inferred-type)
        (print "Error: couldn't infer type of" expr))
      inferred-type)

    (cond [(expression? expr)
           (setv operator (get expr 0))
           (cond
             ;; Hy Functions/variables to glsl
             [(= operator 'defn)
              #_(comment
                  Syntax: (defn name [[arg1 :type] ...] :return-type code)
                  Argument are list of name and keyword type, empty list is void
                  Return type is optional, default to void
                  )
              (setv code-pos 3) ; assume no return type
              (if (keyword? (get expr code-pos))
                  (do
                    (setv return-type (name (get expr code-pos)))
                    (setv code-pos (inc code-pos)))
                  (setv return-type "void"))
              (append "\n" :indent 0)
              (setv new-env (copy-env))
              (append return-type " " (mangle (get expr 1)) "("
                      (if (len (get expr 2))
                          (.join ", " (map (fn [arg]
                                             (if (lookup (get arg 0))
                                                 (print "warning: shadow var:"
                                                        (get arg 0))
                                                 (assoc new-env
                                                        (get arg 0)
                                                        (name (get arg 1))))
                                             (+ (name (get arg 1))
                                                " " (get arg 0)))
                                           (get expr 2)))
                          "void")
                      ") {\n")
              ;; Ensure last expression is a return statement
              (when (and (not (= return-type "void"))
                         (expression? (last expr))
                         (not (= (get (last expr) 0) 'return)))
                (setv (get expr -1) (quasiquote
                                      (return (unquote (last expr))))))
              (translate (cut expr code-pos) new-env (inc indent))
              (append "}\n")]
             [(= operator 'setv)
              (if (lookup (get expr 1))
                  (setv type-str "")
                  (do
                    (define
                      (get expr 1)
                      (infer-type (get expr 2)))
                    (setv type-str (+ (lookup (get expr 1)) " "))))
              (append type-str (mangle-var (get expr 1)) " = ")
              (translate (get expr 2) env :term False)
              (append ";\n" :indent 0)]

             ;; GLSL specific procedure
             [(= operator 'version)
              #_(comment
                  Syntax: (version number)
                  )
              (append "#version " (get expr 1) "\n")]
             [(= operator 'extension)
              #_(comment
                  Syntax: (extension name)
                  )
              ;; TODO: support different extension keyword like 'enable
              (append "#extension " (get expr 1) " : require\n")]
             [(= operator 'output)
              #_(comment
                  Syntax: (output type name)
                  )
              (define (mangle (get expr 2)) (get expr 1))
              (append "out " (get expr 1)
                      " " (mangle (get expr 2)) ";\n")]
             [(= operator 'uniform)
              #_(comment
                  Syntax: (uniform type name)
                  )
              (define (mangle (get expr 2)) (get expr 1))
              (append "uniform " (get expr 1)
                      " " (mangle (get expr 2)) ";\n")]

             ;; Control flow
             [(= operator 'if)
              (append "if (")
              (translate (get expr 1) env :term False)
              (append ") {\n" :indent 0)
              (setv new-env (copy-env))
              (translate (cut expr 2) new-env (inc indent))
              (append "}\n")]
             [(= operator 'while)
              (append "while (")
              (translate (get expr 1) env :term False)
              (append ") {\n" :indent 0)
              (setv new-env (copy-env))
              (translate (cut expr 2) new-env (inc indent))
              (append "}\n")]
             [(= operator 'do)
              (append "{\n")
              (setv new-env (copy-env))
              (translate (cut expr 1) new-env (inc indent))
              (append "}\n")]
             [(= operator 'return)
              (append "return ")
              (translate (get expr 1) env :term False)
              (append ";\n" :indent 0)]
             [(= operator 'break)
              (append "break;\n")]

             ;; Boolean logic
             [(= operator 'or)
              (translate (get expr 1) env :term False)
              (for [operand (cut expr 2)]
                (append " || ")
                (translate operand env :term False))]

             ;; Logic
             [(= operator '<)
              (translate (get expr 1) env :term False)
              (append " < ")
              (translate (get expr 2) env :term False)]
             [(= operator '>)
              (translate (get expr 1) env :term False)
              (append " > ")
              (translate (get expr 2) env :term False)]

             ;; Arithmetic
             [(= operator '+)
              (translate (get expr 1) env :term False)
              (for [operand (cut expr 2)]
                (append " + ")
                (translate operand env :term False))]
             [(= operator '-)
              (when (= (len expr) 2)
                (append "-"))
              (translate (get expr 1) env :term False)
              (for [operand (cut expr 2)]
                (append " - ")
                (translate operand env :term False))]
             [(= operator '*)
              (translate (get expr 1) env :term False)
              (for [operand (cut expr 2)]
                (append " * ")
                (translate operand env :term False))]
             [(= operator '/)
              (translate (get expr 1) env :term False)
              (for [operand (cut expr 2)]
                (append " / ")
                (translate operand env :term False))]

             ;; Function call
             [(symbol? operator)
              (append (mangle operator) "(")
              (when (> (len expr) 1)
                (translate (get expr 1) env :term False))
              (for [operand (cut expr 2)]
                (append ", ")
                (translate operand env :term False))
              (append ")" :indent 0)
              (when term (append ";\n" :indent 0))]

             [(expression? operator)
              ;; This is an expression list, like a procedure body
              (for [e expr]
                (translate e env indent))]

             [True (print "error: unknown expresion:" expr)])]

          [(or (symbol? expr) (numeric? expr))
           (append expr)]

          [True (print "error: unknown symbol:" expr)]))
  (translate code {"gl_FragCoord" "vec2" "gl_FragColor" "vec4"} 0)
  (.join "" shader))
