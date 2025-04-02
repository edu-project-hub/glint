package shaders
import sg "sokol:gfx"
import "core:math/linalg"
/*
    #version:1# (machine generated, don't edit!)

    Generated by sokol-shdc (https://github.com/floooh/sokol-tools)

    Cmdline:
        sokol-shdc --input shaders/text.glsl --output glint/shaders/text.glsl.odin --slang glsl410 -f sokol_odin

    Overview:
    =========
    Shader program: 'text':
        Get shader desc: text_shader_desc(sg.query_backend())
        Vertex Shader: vs
        Fragment Shader: fs
        Attributes:
            ATTR_text_position => 0
            ATTR_text_texcoord0 => 1
    Bindings:
        Uniform block 'text_vs_params':
            Odin struct: Text_Vs_Params
            Bind slot: UB_text_vs_params => 0
        Image 'text_tex':
            Image type: ._2D
            Sample type: .FLOAT
            Multisampled: false
            Bind slot: IMG_text_tex => 0
        Sampler 'text_smp':
            Type: .FILTERING
            Bind slot: SMP_text_smp => 0
*/
ATTR_text_position :: 0
ATTR_text_texcoord0 :: 1
UB_text_vs_params :: 0
IMG_text_tex :: 0
SMP_text_smp :: 0
Text_Vs_Params :: struct #align(16) {
    using _: struct #packed {
        proj: linalg.Matrix4f32,
        model: linalg.Matrix4f32,
        color0: linalg.Vector4f32,
    },
}
/*
    #version 410

    uniform vec4 text_vs_params[9];
    layout(location = 0) in vec3 position;
    layout(location = 1) out vec4 color;
    layout(location = 0) out vec2 texcoord;
    layout(location = 1) in vec2 texcoord0;

    void main()
    {
        gl_Position = (mat4(text_vs_params[0], text_vs_params[1], text_vs_params[2], text_vs_params[3]) * mat4(text_vs_params[4], text_vs_params[5], text_vs_params[6], text_vs_params[7])) * vec4(position, 1.0);
        color = text_vs_params[8];
        texcoord = texcoord0;
    }

*/
@(private="file")
vs_source_glsl410 := [485]u8 {
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x34,0x31,0x30,0x0a,0x0a,0x75,0x6e,
    0x69,0x66,0x6f,0x72,0x6d,0x20,0x76,0x65,0x63,0x34,0x20,0x74,0x65,0x78,0x74,0x5f,
    0x76,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x5b,0x39,0x5d,0x3b,0x0a,0x6c,0x61,
    0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,
    0x30,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x33,0x20,0x70,0x6f,0x73,0x69,0x74,
    0x69,0x6f,0x6e,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,
    0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x31,0x29,0x20,0x6f,0x75,0x74,0x20,0x76,0x65,
    0x63,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,
    0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x6f,
    0x75,0x74,0x20,0x76,0x65,0x63,0x32,0x20,0x74,0x65,0x78,0x63,0x6f,0x6f,0x72,0x64,
    0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,
    0x6e,0x20,0x3d,0x20,0x31,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x32,0x20,0x74,
    0x65,0x78,0x63,0x6f,0x6f,0x72,0x64,0x30,0x3b,0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,
    0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,
    0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x28,0x6d,0x61,0x74,0x34,
    0x28,0x74,0x65,0x78,0x74,0x5f,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x5b,
    0x30,0x5d,0x2c,0x20,0x74,0x65,0x78,0x74,0x5f,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,
    0x6d,0x73,0x5b,0x31,0x5d,0x2c,0x20,0x74,0x65,0x78,0x74,0x5f,0x76,0x73,0x5f,0x70,
    0x61,0x72,0x61,0x6d,0x73,0x5b,0x32,0x5d,0x2c,0x20,0x74,0x65,0x78,0x74,0x5f,0x76,
    0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x5b,0x33,0x5d,0x29,0x20,0x2a,0x20,0x6d,
    0x61,0x74,0x34,0x28,0x74,0x65,0x78,0x74,0x5f,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,
    0x6d,0x73,0x5b,0x34,0x5d,0x2c,0x20,0x74,0x65,0x78,0x74,0x5f,0x76,0x73,0x5f,0x70,
    0x61,0x72,0x61,0x6d,0x73,0x5b,0x35,0x5d,0x2c,0x20,0x74,0x65,0x78,0x74,0x5f,0x76,
    0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x5b,0x36,0x5d,0x2c,0x20,0x74,0x65,0x78,
    0x74,0x5f,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,0x6d,0x73,0x5b,0x37,0x5d,0x29,0x29,
    0x20,0x2a,0x20,0x76,0x65,0x63,0x34,0x28,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,
    0x2c,0x20,0x31,0x2e,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x63,0x6f,0x6c,0x6f,
    0x72,0x20,0x3d,0x20,0x74,0x65,0x78,0x74,0x5f,0x76,0x73,0x5f,0x70,0x61,0x72,0x61,
    0x6d,0x73,0x5b,0x38,0x5d,0x3b,0x0a,0x20,0x20,0x20,0x20,0x74,0x65,0x78,0x63,0x6f,
    0x6f,0x72,0x64,0x20,0x3d,0x20,0x74,0x65,0x78,0x63,0x6f,0x6f,0x72,0x64,0x30,0x3b,
    0x0a,0x7d,0x0a,0x0a,0x00,
}
/*
    #version 410

    uniform sampler2D text_tex_text_smp;

    layout(location = 0) in vec2 texcoord;
    layout(location = 0) out vec4 frag_color;
    layout(location = 1) in vec4 color;

    void main()
    {
        vec4 _24 = texture(text_tex_text_smp, texcoord);
        float _27 = _24.x;
        frag_color = color * ((_27 > 0.100000001490116119384765625) ? _27 : 0.0);
    }

*/
@(private="file")
fs_source_glsl410 := [342]u8 {
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x34,0x31,0x30,0x0a,0x0a,0x75,0x6e,
    0x69,0x66,0x6f,0x72,0x6d,0x20,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x32,0x44,0x20,
    0x74,0x65,0x78,0x74,0x5f,0x74,0x65,0x78,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x6d,
    0x70,0x3b,0x0a,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,
    0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x32,
    0x20,0x74,0x65,0x78,0x63,0x6f,0x6f,0x72,0x64,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,
    0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,
    0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x34,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,
    0x6c,0x6f,0x72,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,
    0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x31,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,
    0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x6d,
    0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x76,0x65,0x63,0x34,
    0x20,0x5f,0x32,0x34,0x20,0x3d,0x20,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x74,
    0x65,0x78,0x74,0x5f,0x74,0x65,0x78,0x5f,0x74,0x65,0x78,0x74,0x5f,0x73,0x6d,0x70,
    0x2c,0x20,0x74,0x65,0x78,0x63,0x6f,0x6f,0x72,0x64,0x29,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x20,0x5f,0x32,0x37,0x20,0x3d,0x20,0x5f,0x32,0x34,
    0x2e,0x78,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x63,0x6f,0x6c,
    0x6f,0x72,0x20,0x3d,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x2a,0x20,0x28,0x28,0x5f,
    0x32,0x37,0x20,0x3e,0x20,0x30,0x2e,0x31,0x30,0x30,0x30,0x30,0x30,0x30,0x30,0x31,
    0x34,0x39,0x30,0x31,0x31,0x36,0x31,0x31,0x39,0x33,0x38,0x34,0x37,0x36,0x35,0x36,
    0x32,0x35,0x29,0x20,0x3f,0x20,0x5f,0x32,0x37,0x20,0x3a,0x20,0x30,0x2e,0x30,0x29,
    0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
}
text_shader_desc :: proc (backend: sg.Backend) -> sg.Shader_Desc {
    desc: sg.Shader_Desc
    desc.label = "text_shader"
    #partial switch backend {
    case .GLCORE:
        desc.vertex_func.source = transmute(cstring)&vs_source_glsl410
        desc.vertex_func.entry = "main"
        desc.fragment_func.source = transmute(cstring)&fs_source_glsl410
        desc.fragment_func.entry = "main"
        desc.attrs[0].base_type = .FLOAT
        desc.attrs[0].glsl_name = "position"
        desc.attrs[1].base_type = .FLOAT
        desc.attrs[1].glsl_name = "texcoord0"
        desc.uniform_blocks[0].stage = .VERTEX
        desc.uniform_blocks[0].layout = .STD140
        desc.uniform_blocks[0].size = 144
        desc.uniform_blocks[0].glsl_uniforms[0].type = .FLOAT4
        desc.uniform_blocks[0].glsl_uniforms[0].array_count = 9
        desc.uniform_blocks[0].glsl_uniforms[0].glsl_name = "text_vs_params"
        desc.images[0].stage = .FRAGMENT
        desc.images[0].multisampled = false
        desc.images[0].image_type = ._2D
        desc.images[0].sample_type = .FLOAT
        desc.samplers[0].stage = .FRAGMENT
        desc.samplers[0].sampler_type = .FILTERING
        desc.image_sampler_pairs[0].stage = .FRAGMENT
        desc.image_sampler_pairs[0].image_slot = 0
        desc.image_sampler_pairs[0].sampler_slot = 0
        desc.image_sampler_pairs[0].glsl_name = "text_tex_text_smp"
    }
    return desc
}
