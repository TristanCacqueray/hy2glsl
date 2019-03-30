;; hy2glsl.library -- Collection of shader
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

(defn vertex-fullscreen [&optional [attribute-name 'position]]
  `(shader
     (attribute vec2 ~attribute-name)
     (defn main []
       (setv gl_Position (vec4 ~attribute-name 0. 1.)))))

(defn fragment-plane [color-code &optional
                      [res-name 'iResolution]
                      [center-name 'center]
                      [range-name 'range]
                      [super-sampling 1]]
  (when (not (instance? HyExpression (get color-code 0)))
    (setv color-code (HyExpression [color-code])))
  ;; Get last function name
  (if (in (get (get color-code 0) 0) ['shader 'do])
      (setv color-code (cut (get color-code 0) 1)))
  (setv color-func-name
        (get (get (list (filter (fn [x] (= (get x 0) 'defn)) color-code)) 0) 1))

  `(shader
     (uniform vec2 ~res-name)
     (uniform vec2 ~center-name)
     (uniform float ~range-name)
     ~@color-code
     (defn main []
       ~@(if (= super-sampling 1)
            `(do
              (setv uv (- (* (/ gl_FragCoord.xy (.xy ~res-name)) 2.) 1.0))
              (setv uv.y (* uv.y (- (/ (.y ~res-name) (.x ~res-name)))))
              (setv pos (+ ~center-name (* uv ~range-name)))
              (setv col (~color-func-name pos)))
             `(do
               (setv col (vec3 0.0))
               (setv m 0)
               (while (< m ~super-sampling)
                 (setv n 0)
                 (while (< n ~super-sampling)
                   (setv uv
                         (- (* (/ (+ gl_FragCoord.xy
                                     (- (/ (vec2 (float m) (float n))
                                           (float ~super-sampling))
                                        0.5))
                                  (.xy ~res-name)) 2.) 1.0))
                   (setv uv.y (* uv.y (- (/ (.y ~res-name) (.x ~res-name)))))
                   (setv pos (+ ~center-name (* uv ~range-name)))
                   (setv col (+ col (~color-func-name pos)))
                   (setv n (+ n 1)))
                 (setv m (+ m 1)))
               (setv col (/ col (float (* ~super-sampling ~super-sampling))))))
       (setv gl_FragColor (vec4 col 1.0)))))

(defn color-ifs [ifs-code &optional
                 [max-iter 42]
                 [escape 1e3]]
  (when (not (instance? HyExpression (get ifs-code 0)))
    (setv ifs-code (HyExpression [ifs-code])))
  (setv max-iter (float max-iter))
  `(shader
     (defn color [coord]
       (setv idx 0.0)
       (setv z (vec2 0.0))
       (setv c coord)
       (while (< idx ~max-iter)
         ~@ifs-code
         (if (> (dot z z) ~escape)
             (break))
         (setv idx (+ idx 1.0)))
       (vec3 (* 1.0 (/ idx ~max-iter))))))
