package text_renderer


import "core:c"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import sg "sokol:gfx"
import fs "vendor:fontstash"

import "glint:shaders"

@(private)
TextVec :: struct #packed {
  position: linalg.Vector3f32,
  texcoord0: linalg.Vector2f32,
}

Font_State :: struct {
	fc:      ^fs.FontContext,
	desc:    Desc,
	inter:   int,
	pip:     sg.Pipeline,
	shader:  sg.Shader,
	sampler: sg.Sampler,
	atlas:   sg.Image,
}

fstate_create :: proc(desc: Desc) -> (font_state: Font_State) {
	font_state.desc = desc_defaults(desc)
	font_state.fc = new(fs.FontContext)
	fs.Init(font_state.fc, font_state.desc.atlas.x, font_state.desc.atlas.y, .TOPLEFT)
	font_state.inter = fs.AddFont(font_state.fc, "Inter", Inter, false)
	if !fs.AddFallbackFont(font_state.fc, font_state.inter, font_state.inter) {
		fmt.println("failed to add fallback font")
	}

	font_state.shader = sg.make_shader(shaders.text_shader_desc(sg.query_backend()))

	font_state.pip = sg.make_pipeline(
		{
			shader = font_state.shader,
			layout = {
				attrs = {
					shaders.ATTR_text_position = {format = .FLOAT3},
					shaders.ATTR_text_texcoord0 = {format = .FLOAT2},
				},
			},
			colors = {
				0 = {
					blend = {
						enabled = true,
						src_factor_rgb = .ONE,
						dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
						src_factor_alpha = .ONE,
						dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
					},
				},
			},
		},
	)

	font_state.sampler = sg.make_sampler({min_filter = .LINEAR, mag_filter = .LINEAR})

	font_state.atlas = sg.make_image(
		sg.Image_Desc {
			width = c.int(font_state.desc.atlas.x),
			height = c.int(font_state.desc.atlas.y),
			pixel_format = .R8,
			usage = .DYNAMIC,
		},
	)

	return
}

fstate_rebuild :: proc(self: ^Font_State) {
	sg.update_image(
		self.atlas,
		{
			subimage = {
				0 = {
					0 = {
						ptr = raw_data(self.fc.textureData),
						size = len(self.fc.textureData) * size_of(byte),
					},
				},
			},
		},
	)
}

fstate_update_if_needed :: proc(self: ^Font_State) {
	if int(sg.query_image_width(self.atlas)) != self.fc.width ||
	   int(sg.query_image_height(self.atlas)) != self.fc.height {
		fstate_rebuild(self)
		fs.__dirtyRectReset(self.fc)
	} else if self.fc.dirtyRect[0] < self.fc.dirtyRect[2] &&
	   self.fc.dirtyRect[1] < self.fc.dirtyRect[3] {
		fstate_rebuild(self)
		fs.__dirtyRectReset(self.fc)
	}
}


fstate_destroy :: proc(self: ^Font_State) {
	sg.destroy_sampler(self.sampler)
	sg.destroy_pipeline(self.pip)
	sg.destroy_shader(self.shader)
	sg.destroy_image(self.atlas)
	fs.Destroy(self.fc)
	free(self.fc)
}

//This is extremly inefficient 
//just a PoC (proof-of-concept)
//precomputing text before the actual render is recommended
//this is the on-demand renderer
//
// yes this example produces a new VBO for every text
// thats why I will do a second implementation where the text
// is precomputing requiring only one *immutable* vbo
//text_render :: proc(
//	font: ^Font_State,
//	content: string,
//	pos: linalg.Vector2f32,
//	size: f32,
//	color: linalg.Vector4f32 = {1.0, 1.0, 1.0, 1.0},
//	model: linalg.Matrix4f32,
//	proj: linalg.Matrix4f32,
//) {
//	num_elements := len(content) * 6
//	vbo_raw := make([]TextVec, num_elements)
//	defer delete(vbo_raw)
//
//	pos := pos
//	pos.x = math.round(pos.x)
//	pos.y = math.round(pos.y)
//
//	state := fs.__getState(font.fc)
//	state^ = fs.State {
//		size    = size,
//		blur    = 0.0,
//		spacing = 0.0,
//		font    = font.inter,
//		ah      = .LEFT,
//		av      = .BASELINE,
//	}
//
//	glyph_i := 0
//
//	for iter := fs.TextIterInit(font.fc, pos.x, pos.y, content); true; {
//		quad: fs.Quad
//		fs.TextIterNext(font.fc, &iter, &quad) or_break
//		base := glyph_i * 6
//		vbo_raw[base + 0] = TextVec{quad.x0, quad.y0, 1.0, quad.s0, quad.t0}
//		vbo_raw[base + 1] = TextVec{quad.x1, quad.y0, 1.0, quad.s1, quad.t0}
//		vbo_raw[base + 2] = TextVec{quad.x0, quad.y1, 1.0, quad.s0, quad.t1}
//		vbo_raw[base + 3] = TextVec{quad.x1, quad.y0, 1.0, quad.s1, quad.t0}
//		vbo_raw[base + 4] = TextVec{quad.x0, quad.y1, 1.0, quad.s0, quad.t1}
//		vbo_raw[base + 5] = TextVec{quad.x1, quad.y1, 1.0, quad.s1, quad.t1}
//
//		glyph_i += 1
//	}
//
//	buf := sg.make_buffer(
//		{
//			type = .VERTEXBUFFER,
//			data = {ptr = &vbo_raw[0], size = uint(size_of(TextVec) * num_elements)},
//		},
//	)
//	defer sg.destroy_buffer(buf)
//
//	params := shaders.Text_Vs_Params {
//		model  = model,
//		proj   = proj,
//		color0 = color,
//	}
//
//	binding := sg.Bindings {
//		vertex_buffers = {0 = buf},
//		samplers = {shaders.SMP_text_smp = font.sampler},
//		images = {shaders.IMG_text_tex = font.atlas},
//	}
//
//	sg.apply_pipeline(font.pip)
//	sg.apply_bindings(binding)
//	sg.apply_uniforms(
//		shaders.UB_text_vs_params,
//		{ptr = &params, size = size_of(shaders.Text_Vs_Params)},
//	)
//
//	sg.draw(0, c.int(num_elements), 1)
//}

Text :: struct {
	font:         ^Font_State,
	content:      string,
	pos:          linalg.Vector2f32,
	size:         f32,
	num_vertices: int,
	buffer:       sg.Buffer,
}

text_create :: proc(
	font: ^Font_State,
	content: string,
	pos: linalg.Vector2f32,
	size: f32,
) -> Text {
	text := Text {
		font    = font,
		content = content,
		pos     = pos,
		size    = size,
	}

	text_update_buffer(&text)
	return text
}

text_update_buffer :: proc(text: ^Text) {
	fs_state := fs.__getState(text.font.fc)
	fs_state^ = fs.State {
		size    = text.size,
		blur    = 0.0,
		spacing = 0.0,
		font    = text.font.inter,
		ah      = .LEFT,
		av      = .BASELINE,
	}

	num_elements := len(text.content) * 6
	vbo_raw := make([]TextVec, num_elements)
	defer delete(vbo_raw)

	pos := text.pos
	pos.x = math.round(pos.x)
	pos.y = math.round(pos.y)

	glyph_i := 0
	for iter := fs.TextIterInit(text.font.fc, pos.x, pos.y, text.content); true; {
		quad: fs.Quad
		fs.TextIterNext(text.font.fc, &iter, &quad) or_break
		base := glyph_i * 6


		vbo_raw[base + 0] = TextVec{{quad.x0, quad.y0, 1.0}, {quad.s0, quad.t0}}
		vbo_raw[base + 1] = TextVec{{quad.x1, quad.y0, 1.0}, {quad.s1, quad.t0}}
		vbo_raw[base + 2] = TextVec{{quad.x0, quad.y1, 1.0}, {quad.s0, quad.t1}}
		vbo_raw[base + 3] = TextVec{{quad.x1, quad.y0, 1.0}, {quad.s1, quad.t0}}
		vbo_raw[base + 4] = TextVec{{quad.x0, quad.y1, 1.0}, {quad.s0, quad.t1}}
		vbo_raw[base + 5] = TextVec{{quad.x1, quad.y1, 1.0}, {quad.s1, quad.t1}}
		glyph_i += 1
	}

	if text.buffer.id != sg.INVALID_ID {
		sg.destroy_buffer(text.buffer)
	}

	text.buffer = sg.make_buffer(
		{
			type = .VERTEXBUFFER,
			data = {ptr = &vbo_raw[0], size = uint(size_of(TextVec) * glyph_i * 6)},
		},
	)

	text.num_vertices = glyph_i * 6
}

text_render :: proc(
	text: ^Text,
	model: linalg.Matrix4f32,
	proj: linalg.Matrix4f32,
	color: linalg.Vector4f32,
) {
	params := shaders.Text_Vs_Params {
		model  = model,
		proj   = proj,
		color0 = color,
	}

	binding := sg.Bindings {
		vertex_buffers = {0 = text.buffer},
		samplers = {shaders.SMP_text_smp = text.font.sampler},
		images = {shaders.IMG_text_tex = text.font.atlas},
	}

	sg.apply_pipeline(text.font.pip)
	sg.apply_bindings(binding)
	sg.apply_uniforms(shaders.UB_text_vs_params, {ptr = &params, size = size_of(params)})
	sg.draw(0, c.int(text.num_vertices), 1)
}
