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
    
  }
}