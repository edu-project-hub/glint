package main

import "core:c"
import "vendor:glfw"
import sg "sokol:gfx"

Glfw_Desc :: struct {
  width: c.int,
  height: c.int,
  title: cstring,
  sample_count: c.int,
  no_depth_buffer: bool,
  version_major: c.int,
  version_minor: c.int,
}

@(private="file")
Glfw_State :: struct {
  sample_count: c.int,
  no_depth_buffer: bool,
  version_major: c.int,
  version_minor: c.int,
  window: glfw.WindowHandle,
}

state := Glfw_State{}

glfw_init :: proc(desc: Glfw_Desc) {
  assert(desc.width > 0)
  assert(desc.height > 0)
  assert(desc.title != nil)
  glfw_def :: proc(val: c.int, def: c.int) -> c.int {
    if val == 0 {
      return def
    } else {
      return val
    }
  }

  desc_def := desc
  desc_def.sample_count = glfw_def(desc_def.sample_count, 1)
  desc_def.version_major = glfw_def(desc_def.version_major, 4)
  desc_def.version_minor = glfw_def(desc_def.version_minor, 1)
  state.sample_count = desc_def.sample_count
  state.no_depth_buffer = desc_def.no_depth_buffer
  state.version_major = desc_def.version_major
  state.version_minor = desc_def.version_minor
  // FIXME(robin): Handle errors
  glfw.Init()
  glfw.WindowHint(glfw.COCOA_RETINA_FRAMEBUFFER, false)
  if (desc_def.no_depth_buffer) {
    glfw.WindowHint(glfw.DEPTH_BITS, false)
    glfw.WindowHint(glfw.STENCIL_BITS, false)
  }
  sample_count := cast(c.int) 0
  if desc_def.sample_count != 1 {
    sample_count = desc_def.sample_count
  }
  glfw.WindowHint(glfw.SAMPLES, sample_count)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, desc_def.version_major)
  glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, desc_def.version_minor)
  glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
  glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  state.window = glfw.CreateWindow(desc_def.width, desc_def.height, desc_def.title, nil, nil)
  glfw.MakeContextCurrent(state.window)
  glfw.SwapInterval(1)
}

glfw_width :: proc() -> c.int {
  width, _: c.int = glfw.GetFramebufferSize(state.window)
  return width
}

glfw_height :: proc() -> c.int {
  _, height: c.int = glfw.GetFramebufferSize(state.window)
  return height
}

glfw_environment :: proc() -> sg.Environment {
  return {
    defaults = {
      color_format = .RGBA8,
      depth_format = .NONE if state.no_depth_buffer else .DEPTH_STENCIL,
      sample_count = state.sample_count,
    }
  }
}

glfw_swapchain :: proc() -> sg.Swapchain {
  width, height: c.int = glfw.GetFramebufferSize(state.window)
  return {
    width = width,
    height = height,
    sample_count = state.sample_count,
    color_format = .RGBA8,
    depth_format = .NONE if state.no_depth_buffer else .DEPTH_STENCIL,
    gl = {
      // TODO(robin): Add Metal support
      // we just assume here that the GL framebuffer is always 0
      framebuffer = 0,
    }
  }
}

glfw_window :: proc() -> glfw.WindowHandle {
  return state.window
}
