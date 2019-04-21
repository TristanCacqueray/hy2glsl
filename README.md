# hy2glsl: Hy to GLSL Language Translator

This is an exploratory experiment to translate Hy procedure to GLSL shader,
inspired by the [varjo translator](https://github.com/cbaggers/varjo).


## Data Types

Uniform, varying and outputs need to be typed. It may be possible to infer
the type by knowing the associated CPU (e.g. numpy) object type.

Function overloading is not supported as the current implementation maps
one function signature to one function name.

For function signature and variables, the types are inferred using this
process:

- Variable definition types are inferred from the value expression:
  - look for known constructor like vec2()
  - look for known variable type already inferred
  - look for known symbol type like float? or integer?
- Function argument types are inferred using a reverse order first pass
- Function return types are inferred from the last expression of the body.

This type inferrence process works for such shader:

```
(setv var (vec2 0.0))
(defn nested-func [arg] ...)
(defn func [a b] (nested-func (+ a b)))
(defn main [] (func var 2))
```

But it will fail when function arguments are solely defined by return type:

```
(defn func [] (return 42))
(defn other-func [a] a)
(defn main [] (other-func (func)))
```

Fortunately, shader usualy mutates return value before using them as a
function argument, therefor that primitive process works in most cases.


## Example:

A mandelbrot fragment shader in Hy:
```
(setv MAX_ITER 42.0)
(print (hy2glsl `(shader
  (version 350)
  (uniform vec2 iResolution)
  (uniform vec2 center)
  (uniform float range)
  (defn mandelbrot-color [coord]
    (setv idx 0.0)
    (setv z (vec2 0.0))
    (setv c coord)
    (while (< idx ~MAX_ITER)
      (setv z (+ (vec2 (- (* z.x z.x) (* z.y z.y))
                       (* 2.0 z.x z.y))
                 c))
      (if (> (dot z z) 500.0)
        (break))
      (setv idx (+ idx 1)))
    (vec3 (* 1.0 (/ idx ~MAX_ITER))))
  (defn main []
    (setv uv (- (* (/ gl_FragCoord.xy iResolution.xy) 2.) 1.0))
    (setv uv.y (* uv.y (- (/ iResolution.y iResolution.x))))
    (setv pos (+ center (* uv range)))
    (setv gl_FragColor (vec4 (mandelbrot-color pos) 1.0))))))
```

Results in:

```
#version 350
uniform vec2 iResolution;
uniform vec2 center;
uniform float range;

vec3 mandelbrot_color(vec2 coord) {
  float idx = 0.0;
  vec2 z = vec2(0.0);
  vec2 c = coord;
  while (idx < 42.0) {
    z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
    if (dot(z, z) > 500.0) {
      break;
    }
    idx = idx + 1;
  }
  return vec3(1.0 * idx / 42.0);
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / iResolution.xy * 2.0 - 1.0;
  uv.y = uv.y * -iResolution.y / iResolution.x;
  vec2 pos = center + uv * range;
  gl_FragColor = vec4(mandelbrot_color(pos), 1.0);
}
```

Or using the library, you would write:
```
(setv mandelbrot `(setv z (+ (cSquare z) c)))
(print (hy2glsl (fragment-plane (color-ifs mandelbrot))))
```


## Demo

In the example folder there is a loaded based on glumpy to test (and reload)
shader module:

```
python setup.py develop --user
pip install --user glumpy
pushd example
./loader.hy mandelbrot.hy
```
