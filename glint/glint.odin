package main

import "core:fmt"
import "glint:app"
import "glint:common"
import "glint:shaders"
import sg "sokol:gfx"
import sgl "sokol:gl"
import slog "sokol:log"
import fs "vendor:fontstash"
import "vendor:glfw"

main :: proc() {
	glfw_init({title = "glint Browser", width = 640, height = 480, no_depth_buffer = true})
	defer glfw.Terminate()

	sg.setup({environment = glfw_environment(), logger = {func = slog.func}})
	defer sg.shutdown()

	sgl.setup({logger = {func = slog.func}})
	defer sgl.shutdown()

	pass_action := sg.Pass_Action {
		colors = {0 = {load_action = .CLEAR, clear_value = {0.5, 0, 0, 0}}},
	}

	//vertices := [?]f32{
	//   0.0,  0.5, 0.5,   1.0, 0.0, 0.0, 1.0,
	//   0.5, -0.5, 0.5,   0.0, 1.0, 0.0, 1.0,
	//  -0.5, -0.5, 0.5,   0.0, 0.0, 1.0, 1.0,
	//}
	//
	//vbuf := sg.make_buffer({
	//  data = {
	//    ptr = &vertices, size = size_of(vertices)
	//  },
	//})
	//defer sg.destroy_buffer(vbuf)
	//
	//shd := sg.make_shader(shaders.triangle_shader_desc(sg.query_backend()))
	//defer sg.destroy_shader(shd)
	//
	//pip := sg.make_pipeline({
	//  shader = shd,
	//  layout = {
	//    attrs = {
	//      shaders.ATTR_triangle_position = {format = .FLOAT3},
	//      shaders.ATTR_triangle_color0 = {format = .FLOAT4},
	//    },
	//  },
	//})
	//defer sg.destroy_pipeline(pip)
	//
	//bind := sg.Bindings{
	//  vertex_buffers = {
	//    0 = vbuf,
	//  }
	//}

	fc: fs.FontContext
	fs.Init(&fc, 512, 512, .TOPLEFT)
	font := fs.AddFontMem(&fc, "Inter", font_rendering.Inter, false)
	if !fs.AddFallbackFont(&fc, font, font) {
		fmt.println("AddFallbackFont returned false")
		return
	}

	for !glfw.WindowShouldClose(app.get_window(&glint_app)) {
		{
			//FIXME(fabbboy): should be handled by event
			sg.begin_pass({swapchain = app.get_swchain(&glint_app)})
			defer sg.end_pass()
			sgl.draw()
		}
		glfw.SwapBuffers(app.get_window(&glint_app))
		glfw.PollEvents()
	}

}
