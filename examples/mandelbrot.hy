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

(setv mandelbrot `(setv z (+ (vec2 (- (* z.x z.x) (* z.y z.y))
                                   (* 2.0 z.x z.y))
                             c))
      vertex (vertex-dumb)
      attributes vertex-dumb-attributes
      fragment (fragment-plane (color-ifs mandelbrot))
      uniforms {"range" 1.6
                "center" [-0.7 0.0]})
