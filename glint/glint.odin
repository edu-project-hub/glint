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

	w, h := glfw.GetFramebufferSize(glfw_window())
	sfons := font_rendering.sfons_create({width = int(w), height = int(h)})
	defer font_rendering.sfons_destroy(sfons)

	for !glfw.WindowShouldClose(glfw_window()) {
		w, h := glfw.GetFramebufferSize(glfw_window())
		font_rendering.sfons_render_resize(&sfons, int(w), int(h))
		font_rendering.sfons_draw_text(
			&fc,
			&sfons,
			"HELLO WORLD DEEZ NUTS",
			font,
			{0, 0},
			size = 100,
		)
		{
			sgl.defaults()
			font_rendering.sfons_render_draw(&sfons)
			sg.begin_pass({action = pass_action, swapchain = glfw_swapchain()})
			defer sg.end_pass()
			sgl.draw()
		}
		sg.commit()
		glfw.SwapBuffers(glfw_window())
		glfw.PollEvents()
	}

}
