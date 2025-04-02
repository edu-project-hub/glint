package app

import "base:runtime"
import "core:c"
import "core:fmt"
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

@(private)
Callback_Data :: struct {
	events: ^[dynamic]Event,
	ctx:    runtime.Context,
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
	cb_data:       ^Callback_Data,
}

glfwBufferResizeCallback :: proc "c" (win: glfw.WindowHandle, width, height: c.int) {
	window_data := cast(^Callback_Data)glfw.GetWindowUserPointer(win)
	context = window_data.ctx

	dims := [2]i32{i32(width), i32(height)}
	runtime.append_elem(window_data.events, EvResizeRequest{dims = dims})
}

create_app :: proc(desc: Desc, queue: ^[dynamic]Event) -> (Glint_App, Glint_App_Err) {
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

	cb_data := new(Callback_Data)
	cb_data.ctx = context
	cb_data.events = queue

	app.cb_data = cb_data

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

	app.window = glfw.CreateWindow(app.dims.x, app.dims.y, copied_title, nil, nil)

	if app.window == nil {
		return {}, Glint_App_Err.Glfw_Window_Failed
	}

	glfw.MakeContextCurrent(app.window)
	if !desc.no_vsync {
		glfw.SwapInterval(1)
	}
	glfw.SetWindowUserPointer(app.window, app.cb_data)
	glfw.SetFramebufferSizeCallback(app.window, glfwBufferResizeCallback)

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


get_swapchain :: proc(app: ^Glint_App) -> sg.Swapchain {
	return sg.Swapchain {
		width = app.dims.x,
		height = app.dims.y,
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

poll_events :: proc($Ctx: typeid, app: ^Glint_App, evl: ^Event_Loop(Ctx)) -> Glint_Loop_Err {
	glfw.PollEvents()
	if glfw.WindowShouldClose(app.window) == true {
		err := push_event(Ctx, evl, EvCloseRequest{})
		if err != nil {
			return err
		}
	}

	return nil
}

@(private)
swap_buffers :: proc(app: ^Glint_App) {
	glfw.SwapBuffers(get_window(app))
}

update_window :: proc(app: ^Glint_App, dims: [2]i32) {
	app.dims = dims
}

destroy_app :: proc(app: ^Glint_App) {
	glfw.DestroyWindow(app.window)
	app.window = nil
	glfw.Terminate()
}

get_window :: proc(app: ^Glint_App) -> glfw.WindowHandle {
	return app.window
}

get_framebuffer_size :: proc(app: ^Glint_App) -> (c.int, c.int) {
  return glfw.GetFramebufferSize(get_window(app))
}
