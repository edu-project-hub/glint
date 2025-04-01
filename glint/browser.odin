package main

import "core:fmt"
import "glint:app"
import "glint:shaders"
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
}

prepare :: proc(self: ^Glint_Browser) {
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
}

shutdown :: proc(self: ^Glint_Browser) {
	sg.destroy_buffer(self.vbuf)
	sg.destroy_shader(self.shd)
	sg.destroy_pipeline(self.pipeline)
}

handler :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), event: app.Event) {
	switch v in event {
	case app.EvCloseRequest:
		app.exit_loop(Glint_Browser, evl)
		break
	case app.EvResizeRequest:
		app.update_window(&evl.app, v.dims)
		break
	}
}

render :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser)) {
	bind := sg.Bindings {
		vertex_buffers = {0 = self.vbuf},
	}

	sg.apply_pipeline(self.pipeline)
	sg.apply_bindings(bind)
	sg.draw(0, 3, 1)
}

error :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), err: app.Glint_Loop_Err) {
	fmt.print("Error: %s\n", err)
	app.exit_loop(Glint_Browser, evl)
}
