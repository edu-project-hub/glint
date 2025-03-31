package app

import "core:c"
import "vendor:glfw"
import "glint:common"

Glfw_State :: struct {
	sample_count:    c.int,
	no_depth_buffer: bool,
	version_major:   c.int,
	version_minor:   c.int,
	window:          glfw.WindowHandle,
}


Desc :: struct {
	dims:         common.Pair(i32),
	title:        string,
	gl_version:   common.Pair(u8),
	no_depth_buffer: bool,
	vsync:        bool,
}

desc_init :: proc() -> Desc {
	return Desc {
		dims = common.pair_init(i32, 800, 600),
		title = "glint",
		gl_version = common.pair_init(u8, 4, 1),
		no_depth_buffer = true,
		vsync = true,
	}
}
