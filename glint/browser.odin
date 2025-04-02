package main

import "core:fmt"
import "glint:app"
import "glint:shaders"
import "glint:text_renderer"
import dx "sokol:debugtext"
import sg "sokol:gfx"

// odinfmt: disable
vertices := [?]f32{
  0.0,  0.5, 0.5,   1.0, 0.0, 0.0, 1.0,
  0.5, -0.5, 0.5,   0.0, 1.0, 0.0, 1.0,
 -0.5, -0.5, 0.5,   0.0, 0.0, 1.0, 1.0,
}
// odinfmt: enable

Glint_Browser :: struct {
	vbuf:     sg.Buffer,
	shd:      sg.Shader,
	pipeline: sg.Pipeline,
	tr:       text_renderer.Text_Rendering_State,
}

prepare :: proc(self: ^Glint_Browser) {
  dx.setup({
    fonts = {
      0 = dx.font_kc853(),
    },
  })
	self.vbuf = sg.make_buffer(
		{type = sg.Buffer_Type.VERTEXBUFFER, data = {ptr = &vertices, size = size_of(vertices)}},
	)

	self.shd = sg.make_shader(shaders.triangle_shader_desc(sg.query_backend()))

	self.pipeline = sg.make_pipeline(
		{
			shader = self.shd,
			layout = {
				attrs = {
					shaders.ATTR_triangle_position = {format = .FLOAT3},
					shaders.ATTR_triangle_color0 = {format = .FLOAT4},
				},
			},
		},
	)

  self.tr = text_renderer.setup({})
}

shutdown :: proc(self: ^Glint_Browser) {
  text_renderer.shutdown(self.tr)
	sg.destroy_pipeline(self.pipeline)
	sg.destroy_shader(self.shd)
	sg.destroy_buffer(self.vbuf)
  dx.shutdown()
}

handler :: proc(
	self: ^Glint_Browser,
	evl: ^app.Event_Loop(Glint_Browser),
	event: app.Event,
) -> app.Glint_Loop_Err {
	switch v in event {
	case app.EvCloseRequest:
		app.exit_loop(Glint_Browser, evl)
		break
	case app.EvResizeRequest:
    dx.canvas(f32(v.dims.x), f32(v.dims.y))
		app.update_window(&evl.app, v.dims)
		break
	}

	return nil
}

render :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser)) -> app.Glint_Loop_Err {
  text_renderer.draw_text(&self.tr, "HELLO WORLD PLS WORK!!", {100, 100}, 23)
  text_renderer.draw_text(&self.tr, "HELLO WORLD PLS WORK!!", {100, 200}, color = {0.7, 0.2, 0.2})

	bind := sg.Bindings {
		vertex_buffers = {0 = self.vbuf},
	}

	sg.apply_pipeline(self.pipeline)
	sg.apply_bindings(bind)
	sg.draw(0, 3, 1)

  w, h := app.get_framebuffer_size(&evl.app)
  text_renderer.draw(&self.tr, int(w), int(h))

  dx.draw()
	return nil
}

error :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), err: app.Glint_Loop_Err) {
	fmt.print("Error: %s\n", err)
	app.exit_loop(Glint_Browser, evl)
}
