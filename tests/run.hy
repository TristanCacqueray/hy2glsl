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

(import sys [hy2glsl [hy2glsl library]])

(for [[test hy-input expected-glsl-output]
      [["Pragma, extension and globals"
        '(shader
          (version 450)
          (extension GL_NV_gpu_shader_fp64)
          (uniform float iTime))
        #[[
#version 450
#extension GL_NV_gpu_shader_fp64 : require
uniform float iTime;
]]]
       ["Uniform metadata"
        '(shader
           (uniform float mod :default 1.0))
        #[[
uniform float mod; // 1.0;
]]]
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
        '(shader
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
       ["Variable type accessor"
        '(shader
           (setv color (vec4 0))
           (setv r color.x)
           (setv color.x 42.0))
        #[[
vec4 color = vec4(0);
float r = color.x;
color.x = 42.0;
]]]
       ["if else form"
        '(do
          (setv color (vec4 0.))
          (defn test-if []
            (if True
                (do
                  (setv color (vec4 1.0))
                  (setv inner-var 42.0))
                (do
                  (setv color (vec4 0.0))
                  (setv inner-var 42)))))
        #[[
vec4 color = vec4(0.0);

void test_if(void) {
  if (true) {
    color = vec4(1.0);
    float inner_var = 42.0;
  } else {
    color = vec4(0.0);
    int inner_var = 42;
  }
}
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
       ["Built-in: cSquare"
        '(shader
           (version 200)
           (setv z (cSquare (vec2 1.0))))
        #[[
#version 200

vec2 cSquare(vec2 c) {
  return vec2(((c.x * c.x) - (c.y * c.y)), (2.0 * c.x * c.y));
}
vec2 z = cSquare(vec2(1.0));
]]]
       ["Built-in: crDiv"
        `(shader
           (setv complex (crDiv 42.0 (vec2 1.0))))
        #[[
vec2 crDiv(float r, vec2 c) {
  if (abs(c.x) <= abs(c.y)) {
    float ratio = (c.x / c.y);
    float denom = (c.y * (1 + (ratio * ratio)));
    return vec2(((r * ratio) / denom), -(r / denom));
  } else {
    float ratio = (c.y / c.x);
    float denom = (c.x * (1 + (ratio * ratio)));
    return vec2((r / denom), (-(r * ratio) / denom));
  }
}
vec2 complex = crDiv(42.0, vec2(1.0));
]]]
       ["Built-in: hypot"
        `(shader
           (setv hp (hypot (vec2 1.0))))
        #[[
float hypot(vec2 c) {
  float x = abs(c.x);
  float y = abs(c.y);
  float t = min(x, y);
  x = max(x, y);
  t = (t / x);
  if (c.x == 0.0 && c.y == 0.0) {
    return 0.0;
  } else {
    return (x * sqrt((1.0 + (t * t))));
  }
}
float hp = hypot(vec2(1.0));
]]]
       ["Built-in: cPowr"
        `(shader
           (setv z (cPowr (vec2 1.0) 42.)))
        #[[
float hypot(vec2 c) {
  float x = abs(c.x);
  float y = abs(c.y);
  float t = min(x, y);
  x = max(x, y);
  t = (t / x);
  if (c.x == 0.0 && c.y == 0.0) {
    return 0.0;
  } else {
    return (x * sqrt((1.0 + (t * t))));
  }
}

vec2 cPowr(vec2 c, float r) {
  float x = exp((log(hypot(c)) * r));
  float y = (atan(c.y, c.x) * r);
  return vec2((x * cos(y)), (x * sin(y)));
}
vec2 z = cPowr(vec2(1.0), 42.0);
]]]
       ["Built-in: cLog"
        `(shader
           (setv z (cLog (vec2 1.0))))
        #[[
float hypot(vec2 c) {
  float x = abs(c.x);
  float y = abs(c.y);
  float t = min(x, y);
  x = max(x, y);
  t = (t / x);
  if (c.x == 0.0 && c.y == 0.0) {
    return 0.0;
  } else {
    return (x * sqrt((1.0 + (t * t))));
  }
}

vec2 cLog(vec2 c) {
  return vec2(log(hypot(c)), atan(c.x, c.y));
}
vec2 z = cLog(vec2(1.0));
]]]
       ["Library: vertex-dumb"
       (library.vertex-dumb)
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
  vec3 col = vec3(0.0);
  vec2 uv = (((gl_FragCoord.xy / iResolution.xy) * 2.0) - 1.0);
  uv.y = (uv.y * -(iResolution.y / iResolution.x));
  vec2 pos = (center + (uv * range));
  col = color(pos);
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
  float ci = 0.0;
  while (idx < 42.0) {
    z = ((z * z) + c);
    if (dot(z, z) > 100.0) {
      break;
    }
    idx = (idx + 1.0);
  }
  if (idx < 42.0) {
    ci = ((idx + 1.0) - log2((0.5 * log2(dot(z, z)))));
    ci = sqrt((ci / 256.0));
  } else {
    return vec3(0.0);
  }
  return vec3((0.5 + (0.5 * cos(((6.2831 * ci) + 0)))), (0.5 + (0.5 * cos(((6.2831 * ci) + 0.4)))), (0.5 + (0.5 * cos(((6.2831 * ci) + 0.7)))));
}

vec3 main(void) {
  return color(vec2(0.0));
}
]]]]]
  (if (and (= (len sys.argv) 2) (not (in (get sys.argv 1) test)))
      (continue))
  (setv result (hy2glsl hy-input))
  (if (= (.strip result) (.strip expected-glsl-output))
      (print "== OK:" test "==")
      (do
        (print "== KO:" test "==")
        (print result))))

(for [[test hy-input expected-params]
      [["Uniform metadata params"
        '(shader (uniform float mod :default 1.0))
        {
         "mod"
         {
          'name "mod"
          'type 'float
          'default 1.0
          }
         }]
       ["Library: fragment-plane params"
        (library.fragment-plane `(defn color [uv] (vec3 0.)))
        {
         "iResolution"
         {
          'name "iResolution"
          'type 'vec2
          }
         "center"
         {
          'name "center"
          'type 'vec2
          }
         "range"
         {
          'name "range"
          'type 'float
          }
         }]]]
  (if (and (= (len sys.argv) 2) (not (in (get sys.argv 1) test)))
      (continue))
  (setv params {})
  (hy2glsl hy-input params)
  (if (= params expected-params)
      (print "== OK:" test "==")
      (do
        (print "== KO:" test "==")
        (print params))))
