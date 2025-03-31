package main

import "core:fmt"
import "glint:app"
import "glint:shaders"
import sg "sokol:gfx"
import slog "sokol:log"
import "vendor:glfw"

handler :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), event: app.Event) {
	switch v in event {
	case app.EvCloseRequest:
		app.exit_loop(Glint_Browser, evl)
	case app.RedrawRequest:
		break
	case app.ResizeRequest:
		app.update_window(&evl.app, v.dims)
	}
}

shutdown :: proc(self: ^Glint_Browser) {

}

main :: proc() {
	browser := Glint_Browser{}

	evl, oerr := app.create_loop(
		Glint_Browser,
		{
			dims = {800, 600},
			title = "glint",
			gl_version = {4, 1},
			depth_buffer = false,
			no_vsync = true,
		},
		app.Event_CB(Glint_Browser){handle = handler, shutdown = shutdown},
		&browser,
	)
	defer app.destroy_loop(Glint_Browser, &evl)

	app.run_loop(Glint_Browser, &evl)
}
