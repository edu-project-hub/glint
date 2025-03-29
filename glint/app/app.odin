package app

import "core:c"

SAMPLE_COUNT: c.int : 1

Glint_App :: struct {
	state: Glfw_State,
}

glint_app_new :: proc(desc: Desc) {
  assert(desc.title != "")
  assert(desc.dims.first > 0)
  assert(desc.dims.second > 0) 

	state := Glfw_State{}
	state.sample_count = SAMPLE_COUNT
	state.no_depth_buffer = desc.depth_buffer
	state.version_major = c.int(desc.gl_version.first)
	state.version_minor = c.int(desc.gl_version.second)
}
