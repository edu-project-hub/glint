package main

import "core:fmt"
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
}

prepare :: proc(self: ^Glint_Browser) {
	font, err := objects.load_font("../arial.ttf", 16, 1024, 1024, {32, 126})
	if err != nil {
		fmt.println(err)
	}

	self.font = font


}

shutdown :: proc(self: ^Glint_Browser) {

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


	return nil
}

error :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), err: app.Glint_Loop_Err) {
	fmt.print("Error: %s\n", err)
	app.exit_loop(Glint_Browser, evl)
}
