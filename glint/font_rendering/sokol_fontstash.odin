/*
  This is a full port of sokol fontstash by RoBaertschi
*/
package font_rendering

import "core:c"
import "core:mem"
import "core:fmt"
import fs "vendor:fontstash"
import "vendor:nanovg"

import sg "sokol:gfx"
// We use sgl here because the origional also used sgl
import sgl "sokol:gl"

import "../shaders"

Sokol_Fons_Desc :: struct {
	width:  int,
	height: int,
}

Font_Instance :: struct {
	pos_min: [2]f32,
	pos_max: [2]f32,
	uv_min:  [2]f32,
	uv_max:  [2]f32,
	color:   [4]u8,
}

Sokol_Fons :: struct {
	desc:                  Sokol_Fons_Desc,
	shd:                   sg.Shader,
	pip:                   sgl.Pipeline,
	img:                   sg.Image,
	smp:                   sg.Sampler,
	cur_width, cur_height: int,
	img_dirty:             bool,
	instances:             [dynamic]Font_Instance,
}

@(private = "file")
sfons_render_create :: proc(desc: Sokol_Fons_Desc, width: int, height: int) -> Sokol_Fons {
	assert((width > 8) && (height > 8))
	sfons := Sokol_Fons{}
	sfons.instances = make([dynamic]Font_Instance)

	if sfons.shd.id == sg.INVALID_ID {
		shd_desc := shaders.sfontstash_shader_desc(sg.query_backend())
		sfons.shd = sg.make_shader(shd_desc)
	}

	if sfons.pip.id == sg.INVALID_ID {
		sfons.pip = sgl.make_pipeline(
			sg.Pipeline_Desc {
				shader = sfons.shd,
				colors = {
					0 = {
						blend = {
							enabled = true,
							src_factor_rgb = .SRC_ALPHA,
							dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
						},
					},
				},
			},
		)

	}
	if sfons.smp.id == sg.INVALID_ID {
		sfons.smp = sg.make_sampler(sg.Sampler_Desc{min_filter = .LINEAR, mag_filter = .LINEAR})
	}

	sfons.cur_width = width
	sfons.cur_height = height

	assert(sfons.img.id == sg.INVALID_ID)
	sfons.img = sg.make_image(
		sg.Image_Desc {
			width = c.int(sfons.cur_width),
			height = c.int(sfons.cur_height),
			usage = .DYNAMIC,
			pixel_format = .R8,
		},
	)
	return sfons
}

sfons_render_resize :: proc(sfons: ^Sokol_Fons, width: int, height: int) {
	if sfons.img.id != sg.INVALID_ID {
		sg.destroy_image(sfons.img)
		sfons.img.id = sg.INVALID_ID
	}

	sfons.cur_width = width
	sfons.cur_height = height

	sfons.img = sg.make_image(
		sg.Image_Desc {
			width = c.int(sfons.cur_width),
			height = c.int(sfons.cur_height),
			usage = .DYNAMIC,
			pixel_format = .R8,
		},
	)
}

sfons_render_update :: proc(sfons: ^Sokol_Fons) {
	sfons.img_dirty = true
}

sfons_render_draw :: proc(sfons: ^Sokol_Fons) {
	sgl.enable_texture()
	defer sgl.disable_texture()
	sgl.texture(sfons.img, sfons.smp)
	sgl.push_pipeline()
	defer sgl.pop_pipeline()
	sgl.load_pipeline(sfons.pip)
	sgl.begin_triangles()
	defer sgl.end()

	for instance in sfons.instances {
		c: [4 * 2]f32
		c[0] = instance.pos_min.x
		c[1] = instance.pos_min.y
		c[2] = instance.pos_max.x
		c[3] = instance.pos_min.y
		c[4] = instance.pos_max.x
		c[5] = instance.pos_max.y
		c[6] = instance.pos_min.x
		c[7] = instance.pos_max.y

		verts: [6][4]f32
		verts[0] = {c[0], c[1], instance.uv_min.x, instance.uv_min.y}
		verts[1] = {c[4], c[5], instance.uv_max.x, instance.uv_max.y}
		verts[2] = {c[2], c[3], instance.uv_max.x, instance.uv_min.y}
		verts[3] = {c[0], c[1], instance.uv_min.x, instance.uv_min.y}
		verts[4] = {c[6], c[7], instance.uv_min.x, instance.uv_max.y}
		verts[5] = {c[4], c[5], instance.uv_max.x, instance.uv_max.y}

		for vert in verts {
      fmt.println("Drawing", vert.x, vert.y, vert.z, vert.w, transmute(u32)instance.color)
			sgl.v2f_t2f_c1i(vert.x, vert.y, vert.z, vert.w, transmute(u32)instance.color)
		}

	}

	clear(&sfons.instances)

	//for i: int = 0; i < nverts; i += 1 {
	//	sgl.v2f_t2f_c1i(
	//		verts[2 * i + 0],
	//		verts[2 * 1 + 1],
	//		tcoords[2 * i + 0],
	//		tcoords[2 * i + 1],
	//		colors[i],
	//	)
	//}
}

@(private = "file")
sfons_desc_defaults :: proc(#by_ptr desc: Sokol_Fons_Desc) -> Sokol_Fons_Desc {
	res := desc
	res.width = 512 if res.width == 0 else res.width
	res.height = 512 if res.height == 0 else res.height
	return res
}

sfons_create :: proc(#by_ptr desc: Sokol_Fons_Desc) -> Sokol_Fons {
	defs := sfons_desc_defaults(desc)
	return sfons_render_create(defs, defs.width, defs.height)
}

sfons_flush :: proc(sfons: ^Sokol_Fons, fc: ^fs.FontContext) {
	if sfons.img_dirty {
		sfons.img_dirty = false
		sg.update_image(
			sfons.img,
			sg.Image_Data {
				subimage = {
					0 = {0 = {ptr = raw_data(fc.textureData), size = len(fc.textureData)}},
				},
			},
		)
	}
}

sfons_draw_text :: proc(
	fc: ^fs.FontContext,
	sfons: ^Sokol_Fons,
	text: string,
	font: int,
	pos: [2]f32,
	size: f32 = 36,
	color: [4]u8 = max(u8),
	blur: f32 = 0,
	spacing: f32 = 0,
	align_h: fs.AlignHorizontal = .LEFT,
	align_v: fs.AlignVertical = .BASELINE,
	x_inc: ^f32 = nil,
	y_inc: ^f32 = nil,
) {
	state := fs.__getState(fc)
	state^ = fs.State {
		size    = size, // TODO(robin): * os_get_dpi()
		blur    = blur,
		spacing = spacing,
		font    = font,
		ah      = align_h,
		av      = align_v,
	}

	if y_inc != nil {
		_, _, lh := fs.VerticalMetrics(fc)
		y_inc^ += lh
	}

	for iter := fs.TextIterInit(fc, pos.x, pos.y, text); true; {
		quad: fs.Quad
		fs.TextIterNext(fc, &iter, &quad) or_break

		new_instance := Font_Instance {
			pos_min = {quad.x0, quad.y0},
			pos_max = {quad.x1, quad.y1},
			uv_min  = {quad.s0, quad.t0},
			uv_max  = {quad.s1, quad.t1},
			color   = color,
		}
    fmt.println(new_instance)
		append(&sfons.instances, new_instance)
	}

	if x_inc != nil {
		last := sfons.instances[len(sfons.instances) - 1]
		x_inc^ += last.pos_max.x - pos.x
	}
}

sfons_destroy :: proc(sfons: Sokol_Fons) {
	sg.destroy_image(sfons.img)
	sg.destroy_sampler(sfons.smp)
	sgl.destroy_pipeline(sfons.pip)
	sg.destroy_shader(sfons.shd)
	delete(sfons.instances)
}
