package main

import "core:fmt"
import "glint:app"
import "glint:common"
import "glint:shaders"
import sg "sokol:gfx"
import slog "sokol:log"
import "vendor:glfw"

main :: proc() {
	glint_app: app.Glint_App

	app_res := app.init({
    dims = common.pair_init(i32, 800, 600),
		title = "glint",
		gl_version = common.pair_init(u8, 4, 1),
		no_depth_buffer = true,
		vsync = true,
  }) 
	switch v in app_res {
	case app.Glint_App_Err:
		fmt.println(v)
	case app.Glint_App:
		glint_app = v
	}

  app.make_this(&glint_app)

	sg.setup(app.get_sokol_desc(&glint_app))
	defer sg.shutdown()

	vertices := [?]f32 {
		0.0,
		0.5,
		0.5,
		1.0,
		0.0,
		0.0,
		1.0,
		0.5,
		-0.5,
		0.5,
		0.0,
		1.0,
		0.0,
		1.0,
		-0.5,
		-0.5,
		0.5,
		0.0,
		0.0,
		1.0,
		1.0,
	}

	vbuf := sg.make_buffer({data = {ptr = &vertices, size = size_of(vertices)}})
	defer sg.destroy_buffer(vbuf)

	shd := sg.make_shader(shaders.triangle_shader_desc(sg.query_backend()))
	defer sg.destroy_shader(shd)

	pip := sg.make_pipeline(
		{
			shader = shd,
			layout = {
				attrs = {
					shaders.ATTR_triangle_position = {format = .FLOAT3},
					shaders.ATTR_triangle_color0 = {format = .FLOAT4},
				},
			},
		},
	)
	defer sg.destroy_pipeline(pip)

	bind := sg.Bindings {
		vertex_buffers = {0 = vbuf},
	}

	for !glfw.WindowShouldClose(app.get_window(&glint_app)) {
		{
			//FIXME(fabbboy): should be handled by event
			sg.begin_pass({swapchain = app.get_swchain(&glint_app)})
			defer sg.end_pass()
			sg.apply_pipeline(pip)
			sg.apply_bindings(bind)
			sg.draw(0, 3, 1)
		}
		glfw.SwapBuffers(app.get_window(&glint_app))
		glfw.PollEvents()
	}

}
