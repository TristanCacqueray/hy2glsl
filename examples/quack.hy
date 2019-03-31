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

(import hy2glsl.library)
(import [hy2glsl.library [*]])

(setv formula `(do
                 (setv z.y (abs z.y))
                 (setv z (cLog (+ z c))))
      vertex (vertex-dumb)
      attributes vertex-dumb-attributes
      fragment (fragment-plane (color-ifs formula
                                          :color-type 'mean-mix-distance
                                          :julia True
                                          :color-factor 1.
                                          :color-ratio 0.01
                                          :pre-iter 0
                                          :max-iter 84)
                               :post-process (contrast-saturation-brightness
                                               :brightness 0.9
                                               ;; :gamma 1.8
                                               :contrast 1.)
                               :super-sampling 3)
      uniforms {"range" 10000.0
                "center" [0.4 0.0]
                "seed" [-0.3964285714285715 -2.18454190476190493]})