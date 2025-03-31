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
	sample_count:    c.int,
	depth_buffer: bool,
	version_major:   c.int,
	version_minor:   c.int,
	window:          glfw.WindowHandle,
	dims:            [2]i32
}


create :: proc(desc: Desc) -> (Glint_App, Glint_App_Err, bool) {
	assert(desc.title != "")
	assert(desc.dims[0]> 0)
	assert(desc.dims[1]> 0)

  desc_def := desc_defaults(desc)

	app := Glint_App{}
	app.sample_count = SAMPLE_COUNT
	app.depth_buffer = desc_def.depth_buffer
	app.version_major = c.int(desc_def.gl_version[0])
	app.version_minor = c.int(desc_def.gl_version[1])
	app.dims = desc.dims

	if (glfw.Init() == false) {
		return {}, Glint_App_Err.Glfw_Init_Failed, false
	}

	if (app.depth_buffer) {
		glfw.WindowHint(glfw.DEPTH_BITS, false)
		glfw.WindowHint(glfw.STENCIL_BITS, false)
	}

	glfw.WindowHint(glfw.SAMPLES, SAMPLE_COUNT)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, app.version_major)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, app.version_minor)
	when ODIN_OS == .Darwin { 	// only needed on macos. Scoped compilation?
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
		glfw.WindowHint(glfw.COCOA_RETINA_FRAMEBUFFER, false)
	}
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	app.window = glfw.CreateWindow(
		app.dims[0],
		app.dims[1],
		cstring(raw_data(desc.title)),
		nil,
		nil,
	)

	if app.window == nil {
		return {}, Glint_App_Err.Glfw_Window_Failed, false
	}

	glfw.MakeContextCurrent(app.window)
	if !desc.no_vsync {
    glfw.SwapInterval(1)
  }

	return app, nil, true
}

get_env :: proc(app: ^Glint_App) -> sg.Environment {
	return sg.Environment {
		defaults = {
			color_format = .RGBA8,
			depth_format = .NONE if app.depth_buffer else .DEPTH_STENCIL,
			sample_count = app.sample_count,
		},
	}
}

// FIXME(fabbboy): move width and height to state 
// implement event loop to handle this and remove usage of GetFramebufferSize
@(private = "file")
glfw_get_dims :: proc(app: ^Glint_App) -> (c.int, c.int) {
	width, height: c.int = glfw.GetFramebufferSize(app.window)
	return width, height
}

get_swapchain :: proc(app: ^Glint_App) -> sg.Swapchain {
	width, height := glfw_get_dims(app)

	return sg.Swapchain {
		width = width,
		height = height,
		sample_count = app.sample_count,
		color_format = .RGBA8,
		depth_format = .NONE if app.depth_buffer else .DEPTH_STENCIL,
		gl = {
			// TODO(robin): Add Metal support
			// we just assume here that the GL framebuffer is always 0
			framebuffer = 0,
		},
	}
}

destroy :: proc(app: ^Glint_App) {
	glfw.DestroyWindow(app.window)
	app.window = nil
	glfw.Terminate()
}

get_window :: proc(app: ^Glint_App) -> glfw.WindowHandle {
	return app.window
}
