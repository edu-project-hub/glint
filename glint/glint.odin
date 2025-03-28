package main

import "core:fmt"
import sg "sokol:gfx"
import slog "sokol:log"
import "vendor:glfw"

main :: proc() {
  glfw_init({
    title = "glint Browser",
    width = 640,
    height = 480,
    no_depth_buffer = true,
  })
  defer glfw.Terminate()

  sg.setup({
    environment = glfw_environment(),
    logger = { func = slog.func },
  })
  defer sg.shutdown()

  vertices := [?]f32{
     0.0,  0.5, 0.5,   1.0, 0.0, 0.0, 1.0,
     0.5, -0.5, 0.5,   0.0, 1.0, 0.0, 1.0,
    -0.5, -0.5, 0.5,   0.0, 0.0, 1.0, 1.0,
  }

  vbuf := sg.make_buffer({
    data = {
      ptr = &vertices, size = size_of(vertices)
    },
  })
  defer sg.destroy_buffer(vbuf)

  shd := sg.make_shader({
    vertex_func = {
      source = `
      #version 410
      layout(location=0) in vec4 position;
      layout(location=1) in vec4 color0;
      out vec4 color;
      void main() {
        gl_Position = position;
        color = color0;
      }
      `
    },
    fragment_func = { source = `
      #version 410
      in vec4 color;
      out vec4 frag_color;
      void main() {
        frag_color = color;
      }
    ` }
  })
  defer sg.destroy_shader(shd)

  pip := sg.make_pipeline({
    shader = shd,
    layout = {
      attrs = {
        0 = {format = .FLOAT3},
        1 = {format = .FLOAT4},
      },
    },
  })
  defer sg.destroy_pipeline(pip)

  bind := sg.Bindings{
    vertex_buffers = {
      0 = vbuf,
    }
  }

  for !glfw.WindowShouldClose(glfw_window()) {
    {
      sg.begin_pass({swapchain = glfw_swapchain()})
      defer sg.end_pass()
      sg.apply_pipeline(pip)
      sg.apply_bindings(bind)
      sg.draw(0, 3, 1)
    }
    glfw.SwapBuffers(glfw_window())
    glfw.PollEvents()
  }

}
