package text_renderer

import "core:c"
import "core:fmt"
import sg "sokol:gfx"
import fs "vendor:fontstash"

import "glint:shaders"

Text_Decoration :: enum {
	Bold,
	Italic,
}

Text_Decorations :: bit_set[Text_Decoration]

Inter :: #load("Inter/Inter-VariableFont_opsz-wght.ttf")

Desc :: struct {
	atlas: [2]int,
}

Text_Rendering_State :: struct {
	fc:       ^fs.FontContext,
	renderer: ^Text_Renderer,
	desc:     Desc,
	inter:    int,
}

@(private)
desc_defaults :: proc(desc: Desc) -> Desc {
	desc := desc
	desc.atlas.x = desc.atlas.x if desc.atlas.x > 0 else 512
	desc.atlas.y = desc.atlas.y if desc.atlas.y > 0 else 512
	return desc
}

setup :: proc(desc: Desc) -> (trs: Text_Rendering_State) {
	trs.desc = desc_defaults(desc)
  trs.fc = new(fs.FontContext)
	fs.Init(trs.fc, trs.desc.atlas.x, trs.desc.atlas.y, .TOPLEFT)
	trs.inter = fs.AddFont(trs.fc, "Inter", Inter, false)
	if !fs.AddFallbackFont(trs.fc, trs.inter, trs.inter) {
		fmt.println("failed to add fallback font")
	}
	trs.renderer = new(Text_Renderer)
  text_renderer_init(trs.renderer, trs.fc, trs.desc.atlas.x, trs.desc.atlas.y)

	return
}

draw_text :: proc(
	trs: ^Text_Rendering_State,
	text: string,
	pos: [2]f32,
	size: f32 = 36,
	color: [3]f32 = {1, 1, 1},
	blur: f32 = 0,
	spacing: f32 = 0,
	align_h: fs.AlignHorizontal = .LEFT,
	align_v: fs.AlignVertical = .BASELINE,
	//x_inc: ^f32 = nil,
	//y_inc: ^f32 = nil,
) {
	state := fs.__getState(trs.fc)
	state^ = fs.State {
		size    = size, // TODO(robin): * os_get_dpi()
		blur    = blur,
		spacing = spacing,
		font    = trs.inter,
		ah      = align_h,
		av      = align_v,
	}

	//if y_inc != nil {
	//	_, _, lh := fs.VerticalMetrics(fc)
	//	y_inc^ += lh
	//}

	for iter := fs.TextIterInit(trs.fc, pos.x, pos.y, text); true; {
		quad: fs.Quad
		fs.TextIterNext(trs.fc, &iter, &quad) or_break
		text_renderer_draw_quad(trs.renderer, color, quad)
	}

	//if x_inc != nil {
	//	last := sfons.instances[len(sfons.instances) - 1]
	//	x_inc^ += last.pos_max.x - pos.x
	//}
}

draw :: proc(trs: ^Text_Rendering_State) {
  text_renderer_update_buffer(trs.renderer)
	text_renderer_draw(trs.renderer)
}

shutdown :: proc(trs: Text_Rendering_State) {
	trs := trs
	text_renderer_destroy(trs.renderer^)
  free(trs.renderer)
	fs.Destroy(trs.fc)
  free(trs.fc)
}

Vertex :: struct #packed {
	position: [3]f32,
	color:    [3]f32,
	texcoord: [2]f32,
}

BUFFER_SIZE :: 4096

Text_Renderer :: struct {
	texture:            sg.Image,
	fc:                 ^fs.FontContext,
	start_vertex_index: int,
	end_vertex_index:   int,
	vertices:           [BUFFER_SIZE]Vertex,
	buffer:             sg.Buffer,
	shd:                sg.Shader,
	smp:                sg.Sampler,
	pip:                sg.Pipeline,
	bnd:                sg.Bindings,
}

text_renderer_init :: proc(tr: ^Text_Renderer, fc: ^fs.FontContext, width, height: int) {
	tr.fc = fc
	text_renderer_create_texture(tr, width, height)
	tr.buffer = sg.make_buffer({usage = .DYNAMIC, size = BUFFER_SIZE})
	tr.shd = sg.make_shader(shaders.sfontstash_shader_desc(sg.query_backend()))
	tr.smp = sg.make_sampler({min_filter = .LINEAR, mag_filter = .LINEAR})

	tr.pip = sg.make_pipeline(
		{
			shader = tr.shd,
			layout = {
				attrs = {
					shaders.ATTR_sfontstash_position = {format = .FLOAT3},
					shaders.ATTR_sfontstash_color0 = {format = .FLOAT3},
					shaders.ATTR_sfontstash_texcoord0 = {format = .FLOAT2},
				},
			},
		},
	)
	tr.bnd = sg.Bindings {
		vertex_buffers = {0 = tr.buffer},
		samplers = {0 = tr.smp},
		images = {0 = tr.texture},
	}
}

text_renderer_destroy :: proc(tr: Text_Renderer) {
	sg.destroy_image(tr.texture)
	sg.destroy_buffer(tr.buffer)
	sg.destroy_shader(tr.shd)
	sg.destroy_sampler(tr.smp)
	sg.destroy_pipeline(tr.pip)
}

text_renderer_create_texture :: proc(tr: ^Text_Renderer, width, height: int) {
	assert(tr != nil)
	assert(tr.texture.id == sg.INVALID_ID)

	tr.texture = sg.make_image(
		sg.Image_Desc {
			width = c.int(width),
			height = c.int(height),
			pixel_format = .R8,
			usage = .DYNAMIC,
		},
	)
  text_renderer_update_texture(tr, width, height)
}

text_renderer_update_texture :: proc(tr: ^Text_Renderer, width, height: int) {
	sg.update_image(
		tr.texture,
		{
			subimage = {
				0 = {0 = {ptr = raw_data(tr.fc.textureData), size = len(tr.fc.textureData)}},
			},
		},
	)
  fmt.println(tr.texture.id, tr.texture.id == sg.INVALID_ID, sg.query_image_state(tr.texture))
}

// The returned slice is guaranteed to be size long
text_renderer_push_vertices :: proc(tr: ^Text_Renderer, size: int) -> []Vertex {
	tr.start_vertex_index = tr.end_vertex_index
	tr.end_vertex_index += size
	return tr.vertices[tr.start_vertex_index:tr.end_vertex_index]
}

text_renderer_draw_quad :: proc(tr: ^Text_Renderer, color: [3]f32, q: fs.Quad) {
	v := text_renderer_push_vertices(tr, 6)
	v[0].texcoord = {q.s0, q.t0}
	v[1].texcoord = {q.s1, q.t0}
	v[2].texcoord = {q.s0, q.t1}
	v[5].texcoord = {q.s1, q.t1}

	v[0].position = {q.x0, q.y0, 0}
	v[1].position = {q.x1, q.y0, 0}
	v[2].position = {q.x0, q.y1, 0}
	v[5].position = {q.x1, q.y1, 0}

	v[3] = v[1]
	v[4] = v[2]

	for &v in &v {
		v.color = color
	}
}

text_renderer_update_buffer :: proc(tr: ^Text_Renderer) {
	sg.update_buffer(tr.buffer, {size = len(tr.vertices), ptr = raw_data(tr.vertices[:])})
}

text_renderer_draw :: proc(tr: ^Text_Renderer) {
	sg.apply_pipeline(tr.pip)
	sg.apply_bindings(tr.bnd)
  //fmt.println("drew", 0, c.int(tr.end_vertex_index), 1)
	sg.draw(0, c.int(tr.end_vertex_index), 1)

	tr.start_vertex_index = 0
	tr.end_vertex_index = 0
}
