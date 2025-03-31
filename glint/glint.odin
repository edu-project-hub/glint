package main

import "core:fmt"
import "glint:app"
import "glint:font_rendering"
import "glint:shaders"
import dt "sokol:debugtext"
import sg "sokol:gfx"
import sgl "sokol:gl"
import slog "sokol:log"
import fs "vendor:fontstash"
import "vendor:glfw"

main :: proc() {

	glint_app, err := app.create(
		{
			dims = {800, 600},
			title = "glint",
			gl_version = {4, 1},
			depth_buffer = false,
			no_vsync = true,
		},
	)

	if err != nil {
		fmt.println(err)
		unreachable()
	}

	sg.setup({environment = app.get_env(&glint_app), logger = {func = slog.func}})
	defer sg.shutdown()

	dt.setup(
		dt.Desc {
			logger = {func = slog.func},
			fonts = {
				0 = dt.font_kc853(),
				1 = dt.font_kc854(),
				2 = dt.font_z1013(),
				3 = dt.font_cpc(),
				4 = dt.font_c64(),
				5 = dt.font_oric(),
			},
		},
	)
	defer dt.shutdown()
	
	// odinfmt: disable
  vertices := [?]f32{
    0.0,  0.5, 0.5,   1.0, 0.0, 0.0, 1.0,
    0.5, -0.5, 0.5,   0.0, 1.0, 0.0, 1.0,
   -0.5, -0.5, 0.5,   0.0, 0.0, 1.0, 1.0,
  }

	// odinfmt: enable

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
			width, height := app.get_dims(&glint_app)
			dt.canvas(f32(width), f32(height))
			dt.puts("Hello World!")

			//FIXME(fabbboy): should be handled by event
			sg.begin_pass({swapchain = app.get_swapchain(&glint_app)})
			defer sg.end_pass()
			dt.draw()
			sg.apply_pipeline(pip)
			sg.apply_bindings(bind)
			sg.draw(0, 3, 1)
		}
		sg.commit()
		glfw.SwapBuffers(app.get_window(&glint_app))
		glfw.PollEvents()
	}

}
