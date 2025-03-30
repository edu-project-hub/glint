package font_rendering

import "core:c"
import fs "vendor:fontstash"
// Don't know fontstash but I would've used: https://github.com/nothings/stb 
// specifically: https://github.com/nothings/stb/blob/master/stb_truetype.h
// but if fontstash fits the bill why not just suggestion

import sg "sokol:gfx"

Text_Decoration :: enum {
  Bold,
  Italic,
}

Inter :: #load("Inter/Inter-VariableFont_opsz-wght.ttf")

Text_Decorations :: bit_set[Text_Decoration]

Text_Renderer :: struct{
  atlas_image: sg.Image,

  fs: fs.FontContext,
}

render_text :: proc(r: ^Text_Renderer, text: string, deocrations: Text_Decorations) {
  
}

create_atlas :: proc(r: ^Text_Renderer) {
  r.atlas_image = sg.make_image(sg.Image_Desc{
    usage = .DYNAMIC,
    render_target = true,
    num_mipmaps = 1,
    width = c.int(r.fs.width),
    height = c.int(r.fs.height),
  })
}

write_atlas :: proc(r: ^Text_Renderer) {
  //sg.update_image(r.atlas_image, { r.fs.textureData  })
}

//Context :: struct {
//  // stuff
//  image: Maybe(sg.Image),
//  width: c.int,
//  height: c.int,
//}
//
//render_create :: proc(user_ptr: rawptr, width, height: c.int) -> c.int {
//  c := cast(^Context)user_ptr
//
//  if c.image != nil {
//    sg.destroy_image(c.image.(sg.Image))
//  }
//
//  c.image = sg.make_image(sg.Image_Desc{
//    render_target = true,
//    usage = .DYNAMIC,
//    width = width,
//    height = height,
//  })
//
//  c.width = width
//  c.height = height
//
//  return 1
//}
//
//render_resize :: proc(user_ptr: rawptr, width, height: c.int) -> c.int {
//  return render_create(user_ptr, width, height)
//}
//
//render_update :: proc(user_ptr: rawptr, rect: [^]c.int, data: [^]c.char) {
//  c := cast(^Context)user_ptr
//  w := rect[2] - rect[0]
//  h := rect[3] - rect[1]
//
//  if c.image == nil {
//    return
//  }
//
//
//}
//
//test :: proc() {
//}
