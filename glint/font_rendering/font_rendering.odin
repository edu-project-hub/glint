package font_rendering

import "core:c"
import fs "vendor:fontstash"

import sg "sokol:gfx"

Text_Decoration :: enum {
	Bold,
	Italic,
}

Text_Decorations :: bit_set[Text_Decoration]

Inter :: #load("Inter/Inter-VariableFont_opsz-wght.ttf")

Text_Renderer :: struct {
	texture: sg.Image,
	fc:      fs.FontContext,
}

text_renderer_create_texture :: proc(tr: ^Text_Renderer, width, height: int) {
	assert(tr != nil)

	tr.texture = sg.make_image(
		sg.Image_Desc {
			width = c.int(width),
			height = c.int(height),
			pixel_format = .R8,
			usage = .DYNAMIC,
			data = sg.Image_Data {
				subimage = {
					0 = {0 = {ptr = raw_data(tr.fc.textureData), size = len(fc.textureData)}},
				},
			},
		},
	)
}
