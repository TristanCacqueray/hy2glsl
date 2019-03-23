#!/bin/env hy

(import [hy2glsl [hy2glsl]])

(for [[test hy-input expected-glsl-output]
      [["Pragma, extension and globals"
        '(
          (version 450)
          (extension GL_NV_gpu_shader_fp64)
          (uniform float iTime)
          )
        #[[
#version 450
#extension GL_NV_gpu_shader_fp64 : require
uniform float iTime;
]]
        ]
       ["Function definition"
       '(
         (defn empty-vector [] :vec4 (vec4 0.0))
         (defn main [] (empty-vector))
         )
       #[[

vec4 empty_vector(void) {
  return vec4(0.0);
}

void main(void) {
  empty_vector();
}
]]
        ]
       ["Variable type inference"
        '(
          (setv color (vec4 0.))
          (setv color (+ color 0.5))
          (defn proc []
            (setv local-var 42)
            (do
              (setv local-var 44)
              (setv nested-var color)))
          (setv local-var 43)
          )
        #[[
vec4 color = vec4(0.0);
color = color + 0.5;

void proc(void) {
  int local_var = 42;
  {
    local_var = 44;
    vec4 nested_var = color;
  }
}
int local_var = 43;
]]]]]
  (setv result (hy2glsl hy-input))
  (if (= result expected-glsl-output)
      (print "== OK:" test "==")
      (do
        (print "== KO:" test "==")
        (print result))))
