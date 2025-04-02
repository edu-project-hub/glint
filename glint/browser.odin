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
	font, err := objects.font_create("arial.ttf", 32.0, 512, 512, {32, 127})
	if err != nil {
		fmt.println(err)
	}

	fmt.println(font.atlas)

	l := -1.0 // Left
	r := 1.0 // Right
	b := -1.0 // Bottom
	t := 1.0 // Top
	n := 0.1 // Near
	f := 100.0 // Far

	self.font = font
	text := objects.text_create(&self.font)


	self.text = text
	objects.text_set(&self.text, "FuCk")
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
	view := linalg.identity_matrix(linalg.Matrix4f32)
	model := linalg.identity_matrix(linalg.Matrix4f32)
	proj := linalg.matrix_ortho3d_f32(
		0.0,
		f32(evl.app.dims.x),
		f32(evl.app.dims.y),
		0.0,
		-1.0,
		1.0,
	)

	color := linalg.Vector4f32{0.1, 0.2, 0.3, 1.0}

	objects.text_render(&self.text, model, proj, view, color, {120.0, 9.0, 000.0})

	return nil
}

error :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), err: app.Glint_Loop_Err) {
	fmt.print("Error: %s\n", err)
	app.exit_loop(Glint_Browser, evl)
}
