@header import "core:math/linalg"
@ctype mat4 linalg.Matrix4f32
@ctype vec4 linalg.Vector4f32

@vs vs_text
in vec3 position;
in vec2 texcoord;

layout(binding=0) uniform text_vs_params {
    mat4 model;
    mat4 proj;
    vec4 color;
};

out vec2 uv;
out vec4 text_color;

void main() {
    gl_Position = proj * model * vec4(position, 1.0);
    uv = texcoord;
    text_color = color;
}
@end

@fs fs_text
layout(binding = 0) uniform texture2D tex;
layout(binding = 1) uniform sampler tex_sampler;

in vec2 uv;
in vec4 text_color;

out vec4 frag_color;

void main() {
    float alpha = texture(sampler2D(tex, tex_sampler), uv).r;
   frag_color = vec4(text_color.rgb, text_color.a * alpha);
}
@end

@program text vs_text fs_text
