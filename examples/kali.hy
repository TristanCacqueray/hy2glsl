;; Copyright 2019 tristanC
;; This file is part of hy2glsl.
;;
;; Hy2glsl is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Hy2glsl is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Hy2glsl.  If not, see <https://www.gnu.org/licenses/>.

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
