package main

import "core:fmt"
import "glint:app"
import "glint:shaders"
import sg "sokol:gfx"
import slog "sokol:log"
import "vendor:glfw"

handler :: proc(self: ^int, evl: ^app.Event_Loop(int), event: app.Event) {
	switch v in event {
	case app.EvCloseRequest:
    app.exit_loop(int, evl)
	}
}

shutdown :: proc(self: ^int) {

}


main :: proc() {
	ctx := 0

	evl, oerr := app.create_loop(
		int,
		{
			dims = {800, 600},
			title = "glint",
			gl_version = {4, 1},
			depth_buffer = false,
			no_vsync = true,
		},
		app.Event_CB(int){handle = handler, shutdown = shutdown},
		&ctx,
	)
	defer app.destroy_loop(int, &evl)

	app.run_loop(int, &evl)
}
