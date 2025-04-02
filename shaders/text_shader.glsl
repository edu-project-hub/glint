 @vs vs
in vec3 position;
in vec3 color0;
in vec2 texcoord0;

out vec2 texcoord;
out vec3 color;
void main() {
  gl_Position = vec4(position, 1.0);
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
  frag_color = texture(sampler2D(tex, smp), texcoord) * vec4(color, 1.0);
}
@end

@program sfontstash vs fs
