@header import "core:math/linalg"
@ctype mat4 linalg.Matrix4f32
@vs vs

layout(binding=0) uniform vs_params {
   mat4 proj;
};

in vec3 position;
in vec3 color0;
in vec2 texcoord0;

out vec2 texcoord;
out vec3 color;
void main() {
  gl_Position = proj * vec4(position, 1.0);
  color = color0;
  texcoord = texcoord0;
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
in vec2 texcoord;
in vec3 color;
out vec4 frag_color;
void main() {
  float alpha = texture(sampler2D(tex, smp), texcoord).r;
  alpha = alpha > 0.1 ? alpha : 0.0;
  frag_color = alpha * vec4(color, 1.0);
}
@end

@program sfontstash vs fs
