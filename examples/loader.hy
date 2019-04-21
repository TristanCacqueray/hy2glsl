#!/bin/env hy
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

(import hy importlib os sys glumpy [glumpy [gl]] [hy2glsl [*]])

;; This fixes https://github.com/hylang/hy/issues/1753
(setv sys.executable hy.sys_executable)

(defn load [module-path]
  "Load a module"
  (setv
    module-name (get (.split (os.path.basename module-path) '.) 0)
    spec (importlib.util.spec_from_file_location module-name module-path)
    module (importlib.util.module_from_spec spec))
  (spec.loader.exec_module module)
  module)

(defn updated? []
  "Check if module or library has been updated"
  (global last-mtime)
  (setv mtime 0)
  (for [path [demo library.__file__]]
    (setv fmtime (getattr (os.stat path) 'st_mtime))
    (when (> fmtime mtime)
      (setv mtime fmtime)))
  (when (> mtime last-mtime)
    (setv last-mtime mtime)
    (return True)))

(try
  (setv demo (get sys.argv 1)
        module (load demo)
        program None
        last-mtime 0)
  (except [e Exception]
    (print e)
    (print "usage: loader.hy [module]")
    (.exit sys 0)))

(defn compile []
  "Compile the module"
  (global program)
  (if program
      (.delete program))
  (setv fragment (hy2glsl module.fragment)
        program (glumpy.gloo.Program
                  (hy2glsl module.vertex)
                  (hy2glsl module.fragment)
                  :count (getattr module 'count 4)))
  (print fragment)
  (for [attribute module.attributes]
    (assoc program attribute (get module.attributes attribute)))
  (for [uniform module.uniforms]
    (assoc program uniform (get module.uniforms uniform)))
  (assoc program "iResolution" [window.width window.height])
  (gl.glEnable gl.GL_BLEND)
  (gl.glBlendFunc gl.GL_SRC_ALPHA gl.GL_ONE_MINUS_SRC_ALPHA))

(setv window (glumpy.app.Window :width 800 :height 600))

(with-decorator window.event
  (defn on-draw [dt]
    (when (updated?)
      (global module)
      (importlib.reload module.hy2glsl.library)
      (setv module (load demo))
      (compile)
      (.clear window)
      (.draw program gl.GL_TRIANGLE_STRIP))))
(with-decorator window.event
  (defn on-resize [width height]
    (when program
      (assoc program "iResolution" [width height])
      (.clear window)
      (.draw program gl.GL_TRIANGLE_STRIP))))

(glumpy.app.run :framerate 30)
