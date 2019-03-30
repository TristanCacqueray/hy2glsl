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
       '(shader
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
            (if True
                (do
                  (setv local-var 44)
                  (setv nested-var color))))
          (setv local-var 43))
        #[[
vec4 color = vec4(0.0);
color = (color + 0.5);

void proc(void) {
  int local_var = 42;
  if (true) {
    local_var = 44;
    vec4 nested_var = color;
  }
}
int local_var = 43;
]]]
       ["Function signature inference"
       '(shader
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
       '(shader
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
]]]
       ["Library: fragment-plane"
       (library.fragment-plane `(defn color [uv] (vec3 0.)))
       #[[
uniform vec2 iResolution;
uniform vec2 center;
uniform float range;

vec3 color(vec2 uv) {
  return vec3(0.0);
}

void main(void) {
  vec2 uv = (((gl_FragCoord.xy / iResolution.xy) * 2.0) - 1.0);
  uv.y = (uv.y * -(iResolution.y / iResolution.x));
  vec2 pos = (center + (uv * range));
  vec3 col = color(pos);
  gl_FragColor = vec4(col, 1.0);
}
]]]
       ["Library: fragment-plane super-sampling"
       (library.fragment-plane `(defn color [uv] (vec3 0.)) :super-sampling 4)
       #[[
uniform vec2 iResolution;
uniform vec2 center;
uniform float range;

vec3 color(vec2 uv) {
  return vec3(0.0);
}

void main(void) {
  vec3 col = vec3(0.0);
  int m = 0;
  while (m < 4) {
    int n = 0;
    while (n < 4) {
      vec2 uv = ((((gl_FragCoord.xy + ((vec2(float(m), float(n)) / float(4)) - 0.5)) / iResolution.xy) * 2.0) - 1.0);
      uv.y = (uv.y * -(iResolution.y / iResolution.x));
      vec2 pos = (center + (uv * range));
      col = (col + color(pos));
      n = (n + 1);
    }
    m = (m + 1);
  }
  col = (col / float((4 * 4)));
  gl_FragColor = vec4(col, 1.0);
}
]]]
       ["Library: color-ifs"
        `(
           ~@(library.color-ifs `(setv z (+ (* z z) c)))
           (defn main [] (color (vec2 0.0))))
       #[[

vec3 color(vec2 coord) {
  float idx = 0.0;
  vec2 z = vec2(0.0);
  vec2 c = coord;
  while (idx < 42.0) {
    z = ((z * z) + c);
    if (dot(z, z) > 1000.0) {
      break;
    }
    idx = (idx + 1.0);
  }
  return vec3((1.0 * (idx / 42.0)));
}

vec3 main(void) {
  return color(vec2(0.0));
}
]]]]]
        (setv result (hy2glsl hy-input))
        (if (= result expected-glsl-output)
            (print "== OK:" test "==")
            (do
              (print "== KO:" test "==")
              (print result))))
