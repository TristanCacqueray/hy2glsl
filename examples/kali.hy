;; Fractal by Kali
;; (Implementation by Syntopia)
;; http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/msg31800/#msg31800

(import hy2glsl.library)
(import [hy2glsl.library [*]])


(setv kali `(do
              (setv z (* (/ (abs z) (dot z z)) -1.9231))
              (setv z (+ z c)))
      vertex (vertex-dumb)
      attributes vertex-dumb-attributes
      fragment (fragment-plane (color-ifs kali
                                          :color [0 0.4 0.7]
                                          :julia True
                                          :color-type 'mean-mix-distance
                                          :color-factor 0.5
                                          :escape 5
                                          :pre-iter 35
                                          :max-iter 40) :super-sampling 2)
      uniforms {"range" 100
                "seed" [0.5663564 0.0732411]})
