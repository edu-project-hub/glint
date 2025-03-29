package app 

import "../common"

Desc :: struct {
  dims: common.Pair(u32),
  title: string,
  gl_version: common.Pair(u8),
  depth_buffer: bool
}

desc_init :: proc() -> Desc {
  return Desc {
    dims = common.pair_init(u32, 600,800),
    title = "glint",
    gl_version = common.pair_init(u8, 4,1),
    depth_buffer = false
  }
}