package app

import "core:c"
import sg "sokol:gfx"
import slog "sokol:log"
import "vendor:glfw"

SAMPLE_COUNT: c.int : 1

Glint_App_Err :: enum {
	Glfw_Init_Failed,
	Glfw_Window_Failed,
}

Glint_App :: struct {
	state: Glfw_State,
	desc:  Desc,
}

Glint_App_Result :: union {
	Glint_App,
	Glint_App_Err,
}

init :: proc(desc: Desc) -> Glint_App_Result {
	assert(desc.title != "")
	assert(desc.dims.first > 0)
	assert(desc.dims.second > 0)

	state := Glfw_State{}
	state.sample_count = SAMPLE_COUNT
	state.no_depth_buffer = desc.no_depth_buffer
	state.version_major = c.int(desc.gl_version.first)
	state.version_minor = c.int(desc.gl_version.second)

	if (glfw.Init() == false) {
		return Glint_App_Err.Glfw_Init_Failed
	}

	if (desc.no_depth_buffer) {
		glfw.WindowHint(glfw.DEPTH_BITS, false)
		glfw.WindowHint(glfw.STENCIL_BITS, false)
	}

	glfw.WindowHint(glfw.SAMPLES, SAMPLE_COUNT)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, state.version_major)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, state.version_minor)
	when ODIN_OS == .Darwin { 	// only needed on macos. Scoped compilation?
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
		glfw.WindowHint(glfw.COCOA_RETINA_FRAMEBUFFER, false)
	}
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	state.window = glfw.CreateWindow(
		desc.dims.first,
		desc.dims.second,
		cstring(raw_data(desc.title)),
		nil,
		nil,
	)
	if state.window == nil {
		return Glint_App_Err.Glfw_Window_Failed
	}

	return Glint_App{state = state, desc = desc}
}

make_this :: proc(app: ^Glint_App) {
	glfw.MakeContextCurrent(app.state.window)
	if app.desc.vsync {
		glfw.SwapInterval(1)
	}
}

get_sokol_desc :: proc(app: ^Glint_App) -> sg.Desc {
	return sg.Desc {
		environment = {
			defaults = {
				color_format = .RGBA8,
				depth_format = .NONE if app.desc.no_depth_buffer else .DEPTH_STENCIL,
				sample_count = app.state.sample_count,
			},
		},
		logger = {func = slog.func},
	}
}

// FIXME(fabbboy): move width and height to state 
// implement event loop to handle this and remove usage of GetFramebufferSize
@(private = "file")
glfw_get_dims :: proc(app: ^Glint_App) -> (c.int, c.int) {
	width, height: c.int = glfw.GetFramebufferSize(app.state.window)
	return width, height
}

get_swchain :: proc(app: ^Glint_App) -> sg.Swapchain {
	width, height := glfw_get_dims(app)

	return sg.Swapchain {
		width = width,
		height = height,
		sample_count = app.state.sample_count,
		color_format = .RGBA8,
		depth_format = .NONE if app.state.no_depth_buffer else .DEPTH_STENCIL,
		gl = {
			// TODO(robin): Add Metal support
			// we just assume here that the GL framebuffer is always 0
			framebuffer = 0,
		},
	}
}

deinit :: proc(app: ^Glint_App) {
  glfw.DestroyWindow(app.state.window)
  glfw.Terminate()
}

get_window :: proc(app: ^Glint_App) -> (glfw.WindowHandle) {
  return app.state.window
}