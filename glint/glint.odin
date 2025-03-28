package main

import "core:fmt"
import gfx "sokol:gfx" 
import "vendor:glfw"

main :: proc() {
  gfx.setup({
  })

	fmt.println("Hello, Glint!")
}
