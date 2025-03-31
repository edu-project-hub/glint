package app

import "core:c"
import "vendor:glfw"

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
		dims = desc.dims if desc.dims[0] > 0 && desc.dims[1] > 0 else {800, 600},
		title = desc.title if desc.title != "" else "glint",
		gl_version = desc.gl_version if desc.gl_version[0] > 0 && desc.gl_version[0] > 0 else {4, 1},
		depth_buffer = desc.depth_buffer,
		no_vsync = desc.no_vsync,
	}
}
