package main

import "core:fmt"
import "core:math/linalg"
import "glint:app"
import "glint:objects"
import "glint:shaders"
import sg "sokol:gfx"

// odinfmt: disable
vertices := [?]f32{
  0.0,  0.5, 0.5,   1.0, 0.0, 0.0, 1.0,
  0.5, -0.5, 0.5,   0.0, 1.0, 0.0, 1.0,
 -0.5, -0.5, 0.5,   0.0, 0.0, 1.0, 1.0,
}
// odinfmt: enable

Glint_Browser :: struct {
	font: objects.Font,
	text: objects.Text,
}

prepare :: proc(self: ^Glint_Browser) {
	font, err := objects.font_create("../arial.ttf", 16, 1024, 1024, {32, 126})
	if err != nil {
		fmt.println(err)
		panic("lol")
	}

  fmt.println(font.atlas)

	l := -1.0 // Left
	r := 1.0 // Right
	b := -1.0 // Bottom
	t := 1.0 // Top
	n := 0.1 // Near
	f := 100.0 // Far
	
 // odinfmt: disable
	ortho := linalg.Matrix4f32{
    f32(2.0 / (r - l)), 0.0,             0.0,            f32( -(r + l) / (r - l)),
    0.0,            f32(2.0 / (t - b)),  0.0,             f32(-(t + b) / (t - b)),
    0.0,            0.0,            f32(-2.0 / (f - n)),  f32(-(f + n) / (f - n)),
    0.0,            0.0,             0.0,             1.0,
  }
 // odinfmt: enable

	self.font = font
	text := objects.text_create(&self.font, ortho)


	self.text = text
	objects.text_set(&self.text, "hello world")
}

shutdown :: proc(self: ^Glint_Browser) {
	objects.text_destroy(&self.text)
	objects.font_destroy(&self.font)
}

handler :: proc(
	self: ^Glint_Browser,
	evl: ^app.Event_Loop(Glint_Browser),
	event: app.Event,
) -> app.Glint_Loop_Err {
	switch v in event {
	case app.EvCloseRequest:
		app.exit_loop(Glint_Browser, evl)
		break
	case app.EvResizeRequest:
		app.update_window(&evl.app, v.dims)
		break
	}


	return nil
}

render :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser)) -> app.Glint_Loop_Err {
  //odinfmt: disable
  model := linalg.Matrix4f32 {
    f32(1), f32(0), f32(0), f32(0),
    f32(0), f32(1), f32(0), f32(0),
    f32(0), f32(0), f32(1), f32(0),
    f32(0), f32(0), f32(0), f32(1),
  };
  //odinfmt: enable

	//objects.text_render(&self.text, 0, 0, model)

	return nil
}

error :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), err: app.Glint_Loop_Err) {
	fmt.print("Error: %s\n", err)
	app.exit_loop(Glint_Browser, evl)
}
