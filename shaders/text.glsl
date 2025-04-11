@header import "core:math/linalg"
@ctype mat4 linalg.Matrix4f32
@ctype vec4 linalg.Vector4f32
@vs vs

layout(binding=0) uniform text_vs_params {
   mat4 proj;
   mat4 model;
   vec4 color0;
};

in vec3 position;
in vec2 texcoord0;

out vec2 texcoord;
out vec4 color;
void main() {
  gl_Position = proj * model * vec4(position, 1.0);
  color = color0;
  texcoord = texcoord0;
}
@end

@fs fs
layout(binding=0) uniform texture2D text_tex;
layout(binding=0) uniform sampler text_smp;
in vec2 texcoord;
in vec4 color;
out vec4 frag_color;
void main() {
  float alpha = texture(sampler2D(text_tex, text_smp), texcoord).r;
  alpha = alpha > 0.1 ? alpha : 0.0;
  frag_color = alpha * color;
}
@end

@program text vs fs
