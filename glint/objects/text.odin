package objects

import "core:c"
import "core:math/linalg"
import "core:os"
import "core:unicode"
import "glint:shaders"
import sg "sokol:gfx"
import tt "vendor:stb/truetype"

Font_Error :: enum {
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
}

CharInfo :: struct {
	uv_min:   [2]f32, // top-left UV coordinates
	uv_max:   [2]f32, // bottom-right UV coordinates
	size:     [2]f32, // width, height in pixels
	offset:   [2]f32, // offset from baseline
	xadvance: f32, // horizontal advance
}

load_font :: proc(
	filepath: string,
	font_size: f32,
	height, width: int,
	char_range: [2]u32,
) -> (
	Font,
	Font_Error,
) {
	font: Font

	font.atlas_height = height
	font.atlas_width = width
	font.font_size = font_size

	font_data, ok := os.read_entire_file(filepath)
	if !ok {
		return {}, Font_Error.Font_Err_Open_Font
	}
	defer delete(font_data)

	if !tt.InitFont(&font.font_info, &font_data[0], 0) {
		return {}, Font_Error.Font_Err_Load_Font
	}

	bitmap, err := make_slice([]u8, height * width)
	if err != nil {
		return {}, Font_Error.Font_Err_OFM
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

destroy_font :: proc(self: ^Font) {
	sg.destroy_image(self.atlas)
}
