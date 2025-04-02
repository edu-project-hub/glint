package objects

import "core:c"
import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:unicode"
import "glint:shaders"
import sg "sokol:gfx"
import tt "vendor:stb/truetype"

Text_Error :: enum {
	Font_Err_Open_Font,
	Font_Err_Load_Font,
	Font_Err_OFM,
}

Font :: struct {
	atlas:        sg.Image,
	font_info:    tt.fontinfo,
	chars:        [128]CharInfo,
	atlas_width:  int,
	atlas_height: int,
	font_size:    f32,
	text_shader:  sg.Shader,
	text_sampler: sg.Sampler,
}

CharInfo :: struct {
	uv_min:   [2]f32, // top-left UV coordinates
	uv_max:   [2]f32, // bottom-right UV coordinates
	size:     [2]f32, // width, height in pixels
	offset:   [2]f32, // offset from baseline
	xadvance: f32, // horizontal advance
}

font_create :: proc(
	filepath: string,
	font_size: f32,
	height, width: int,
	char_range: [2]u32,
) -> (
	Font,
	Text_Error,
) {
	f, err := load_font(filepath, font_size, height, width, char_range)
	if err != nil {
		font_destroy(&f)
		//TODO(robaertschi): please explain why err is nil even when load_font returned a error enum 
		return {}, err
	}

	f.text_shader = sg.make_shader(shaders.text_shader_desc(sg.query_backend()))
	f.text_sampler = sg.make_sampler(sg.Sampler_Desc{min_filter = .LINEAR, mag_filter = .LINEAR})

	return f, nil
}

load_font :: proc(
	filepath: string,
	font_size: f32,
	height, width: int,
	char_range: [2]u32,
) -> (
	Font,
	Text_Error,
) {
	font: Font

	font.atlas_height = height
	font.atlas_width = width
	font.font_size = font_size

	font_data, ok := os.read_entire_file(filepath)
	if !ok {
		return {}, Text_Error.Font_Err_Open_Font
	}
	defer delete(font_data)


	if !tt.InitFont(&font.font_info, &font_data[0], 0) {
		return {}, Text_Error.Font_Err_Load_Font
	}

	bitmap, err := make_slice([]u8, height * width)
	if err != nil {
		return {}, Text_Error.Font_Err_OFM
	}
	defer delete(bitmap)

	scale := tt.ScaleForPixelHeight(&font.font_info, font_size)

	x, y := 0, 0
	row_height := 0

	for codepoint := char_range.x; codepoint <= char_range.y; codepoint += 1 {
		char_index := int(codepoint)
		if char_index >= 128 {
			continue
		}

		if tt.FindGlyphIndex(&font.font_info, rune(codepoint)) == 0 {
			continue
		}

		x0, y0, x1, y1: i32
		tt.GetCodepointBitmapBox(
			&font.font_info,
			rune(codepoint),
			scale,
			scale,
			&x0,
			&y0,
			&x1,
			&y1,
		)

		glyph_width := int(x1 - x0)
		glyph_height := int(y1 - y0)

		if glyph_width <= 0 || glyph_height <= 0 {
			continue
		}

		if x + glyph_width >= width {
			y += row_height
			x = 0
			row_height = 0
		}

		if y + glyph_height >= height {
			break
		}

		tt.MakeCodepointBitmap(
			&font.font_info,
			&bitmap[x + y * width],
			i32(glyph_width),
			i32(glyph_height),
			i32(width),
			scale,
			scale,
			rune(codepoint),
		)

		advance_width, left_side_bearing: i32
		tt.GetCodepointHMetrics(
			&font.font_info,
			rune(codepoint),
			&advance_width,
			&left_side_bearing,
		)

		font.chars[char_index] = CharInfo {
			uv_min   = {f32(x) / f32(width), f32(y) / f32(height)},
			uv_max   = {f32(x + glyph_width) / f32(width), f32(y + glyph_height) / f32(height)},
			size     = {f32(glyph_width), f32(glyph_height)},
			offset   = {f32(x0), f32(y0)},
			xadvance = f32(advance_width) * scale,
		}

		x += glyph_width + 1
		row_height = max(row_height, glyph_height)
	}


	img_data := sg.Image_Data{}
	img_data.subimage[0][0] = sg.Range {
		ptr  = &bitmap[0],
		size = uint(height * width),
	}

	img_desc := sg.Image_Desc {
		width        = c.int(width),
		height       = c.int(height),
		pixel_format = sg.Pixel_Format.R8,
		data         = img_data,
	}

	font.atlas = sg.make_image(img_desc)

	return font, nil
}

font_destroy :: proc(self: ^Font) {
	sg.destroy_image(self.atlas)
	sg.destroy_shader(self.text_shader)
	sg.destroy_sampler(self.text_sampler)
}


Text :: struct {
	font:     ^Font,
	uv_tl:    u32,
	uv_br:    u32,
	vbo:      Maybe(sg.Buffer),
	pipeline: Maybe(sg.Pipeline),
	bind:     Maybe(sg.Bindings),
}

text_create :: proc(font: ^Font, projection: linalg.Matrix4f32) -> Text {
	return {font = font, uv_br = 0, uv_tl = 0, vbo = nil, pipeline = nil, bind = nil}
}

text_set :: proc(self: ^Text, content: string) {
	switch v in self.vbo {
	case sg.Buffer:
		sg.destroy_buffer(v)
	}

	num_chars := len(content)
	totalVerts := num_chars * 6
	vertices := make([]linalg.Vector4f32, totalVerts)

	pen_x, pen_y: f32 = 0.0, 0.0
	vertex_index := 0

	for r in content {
		char_idx := int(r)
		if char_idx < 0 || char_idx >= 128 {
			continue
		}

		info := self.font.chars[char_idx]

		x0 := pen_x + info.offset[0]
		y0 := pen_y + info.offset[1]
		x1 := x0 + info.size[0]
		y1 := y0 + info.size[1]

		u0 := info.uv_min[0]
		v0 := info.uv_min[1]
		u1 := info.uv_max[0]
		v1 := info.uv_max[1]

		vertices[vertex_index] = linalg.Vector4f32{x0, y0, u0, v0}
		vertices[vertex_index + 1] = linalg.Vector4f32{x1, y0, u1, v0}
		vertices[vertex_index + 2] = linalg.Vector4f32{x0, y1, u0, v1}
		vertices[vertex_index + 3] = linalg.Vector4f32{x0, y1, u0, v1}
		vertices[vertex_index + 4] = linalg.Vector4f32{x1, y0, u1, v0}
		vertices[vertex_index + 5] = linalg.Vector4f32{x1, y1, u1, v1}

		vertex_index += 6
		pen_x += info.xadvance
	}

	self.uv_tl = 0
	self.uv_br = u32(totalVerts)

	vb_desc: sg.Buffer_Desc = sg.Buffer_Desc {
		size = c.size_t(totalVerts * size_of(linalg.Vector4f32)),
		type = .VERTEXBUFFER,
		usage = .IMMUTABLE,
		data = sg.Range{ptr = &vertices[0], size = uint(totalVerts * size_of(linalg.Vector4f32))},
	}
	self.vbo = sg.make_buffer(vb_desc)

	self.bind = sg.Bindings {
		vertex_buffers = {0 = self.vbo.(sg.Buffer)},
		images = {shaders.IMG_tex = self.font.atlas},
		samplers = {shaders.SMP_tex_sampler = self.font.text_sampler},
	}
	self.pipeline = sg.make_pipeline(
		{
			shader = self.font.text_shader,
			layout = {
				attrs = {
					shaders.ATTR_text_position = {format = .FLOAT2},
					shaders.ATTR_text_texcoord = {format = .FLOAT2},
				},
			},
		},
	)
}

convert_matrix_to_array :: proc(m: matrix[4, 4]f32) -> [4][4]f32 {
	a: [4][4]f32
	for i in 0 ..< 4 {
		for j in 0 ..< 4 {
			a[i][j] = m[i, j]
		}
	}
	return a
}


text_destroy :: proc(self: ^Text) {
	switch v in self.vbo {
	case sg.Buffer:
		sg.destroy_buffer(v)
	}

	switch v in self.pipeline {
	case sg.Pipeline:
		sg.destroy_pipeline(v)
	}
}

text_render :: proc(self: ^Text, model: linalg.Matrix4f32) {
	data := shaders.Text_Vs_Params {
		model = convert_matrix_to_array(model),
		color = {1.0, 2.0, 2.0, 1.0},
	}

	sg.apply_pipeline(self.pipeline.(sg.Pipeline))
	sg.apply_bindings(self.bind.(sg.Bindings))
	sg.apply_uniforms(
		shaders.UB_text_vs_params,
		sg.Range{ptr = &data, size = size_of(shaders.Text_Vs_Params)},
	)
	sg.draw(0, self.uv_br, 1)
}
