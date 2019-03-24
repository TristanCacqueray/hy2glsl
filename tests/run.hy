#!/bin/env hy

(import [hy2glsl [hy2glsl library]])

(for [[test hy-input expected-glsl-output]
      [["Pragma, extension and globals"
        '(
          (version 450)
          (extension GL_NV_gpu_shader_fp64)
          (uniform float iTime))
        #[[
#version 450
#extension GL_NV_gpu_shader_fp64 : require
uniform float iTime;
]]
        ]
       ["Function definition"
       '(
         (defn empty-vector [] (vec4 0.0))
         (defn test [] (empty-vector)))
       #[[

vec4 empty_vector(void) {
  return vec4(0.0);
}

vec4 test(void) {
  return empty_vector();
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
          (setv local-var 43))
        #[[
vec4 color = vec4(0.0);
color = (color + 0.5);

void proc(void) {
  int local_var = 42;
  {
    local_var = 44;
    vec4 nested_var = color;
  }
}
int local_var = 43;
]]]
       ["Function signature inference"
       '(
         (defn double-vec [uv]
           (+ uv uv))
         (setv var (double-vec (vec2 1.0))))
       #[[

vec2 double_vec(vec2 uv) {
  return (uv + uv);
}
vec2 var = double_vec(vec2(1.0));
]]]
       ["Function return type inference"
       '(
         (defn colorize [uv]
           (* uv 1))
         (defn post-process [color factor]
           (pow color factor))
         (defn main []
           (setv uv (vec2 0.0))
           (setv color (colorize uv))
           (setv color (post-process (+ uv color) 4.0))))
       #[[

vec2 colorize(vec2 uv) {
  return (uv * 1);
}

vec2 post_process(vec2 color, float factor) {
  return pow(color, factor);
}

void main(void) {
  vec2 uv = vec2(0.0);
  vec2 color = colorize(uv);
  color = post_process((uv + color), 4.0);
}
]]]
       ["Library: vertex-fullscreen"
       (library.vertex-fullscreen)
       #[[
attribute vec2 position;

void main(void) {
  gl_Position = vec4(position, 0.0, 1.0);
}
]]]]]
  (setv result (hy2glsl hy-input))
  (if (= result expected-glsl-output)
      (print "== OK:" test "==")
      (do
        (print "== KO:" test "==")
        (print result))))
