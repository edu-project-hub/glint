package app

import "core:c"
import "core:strings"
import sg "sokol:gfx"
import slog "sokol:log"
import "vendor:glfw"

SAMPLE_COUNT: c.int : 1

Desc :: struct {
	dims:         [2]i32,
	title:        string,
	gl_version:   [2]u8,
	depth_buffer: bool,
	no_vsync:     bool,
}

@(private)
desc_defaults :: proc(desc: Desc) -> Desc {
	return {
		dims = desc.dims if desc.dims.x > 0 && desc.dims.y > 0 else {800, 600},
		title = desc.title if desc.title != "" else "glint",
		gl_version = desc.gl_version if desc.gl_version.x > 0 && desc.gl_version.x > 0 else {4, 1},
		depth_buffer = desc.depth_buffer,
		no_vsync = desc.no_vsync,
	}
}


Glint_App_Err :: enum {
	Glfw_Init_Failed,
	Glfw_Window_Failed,
}

Glint_App :: struct {
	sample_count:  c.int,
	depth_buffer:  bool,
	version_major: c.int,
	version_minor: c.int,
	window:        glfw.WindowHandle,
	dims:          [2]i32,
}


create_app :: proc(desc: Desc) -> (Glint_App, Glint_App_Err) {
	assert(desc.title != "")
	assert(desc.dims.x > 0)
	assert(desc.dims.y > 0)

	desc_def := desc_defaults(desc)

	app := Glint_App{}
	app.sample_count = SAMPLE_COUNT
	app.depth_buffer = desc_def.depth_buffer
	app.version_major = c.int(desc_def.gl_version.x)
	app.version_minor = c.int(desc_def.gl_version.y)
	app.dims = desc.dims

	if (glfw.Init() == false) {
		return {}, Glint_App_Err.Glfw_Init_Failed
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

	copied_title := strings.clone_to_cstring(desc.title, context.allocator)
	defer delete(copied_title)

	app.window = glfw.CreateWindow(
		app.dims.x,
		app.dims.y,
		copied_title, // ilegal odin string is not null terminated
		nil,
		nil,
	)

	if app.window == nil {
		return {}, Glint_App_Err.Glfw_Window_Failed
	}

	glfw.MakeContextCurrent(app.window)
	if !desc.no_vsync {
		glfw.SwapInterval(1)
	}

	return app, nil
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

destroy_app :: proc(app: ^Glint_App) {
	glfw.DestroyWindow(app.window)
	app.window = nil
	glfw.Terminate()
}

get_window :: proc(app: ^Glint_App) -> glfw.WindowHandle {
	return app.window
}
