package app

import "../common"

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
