package main

import "core:fmt"
import "glint:app"
import "glint:shaders"
import sg "sokol:gfx"
import slog "sokol:log"
import "vendor:glfw"

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
		app.Event_CB(Glint_Browser) {
			handle = handler,
			prepare = prepare,
			shutdown = shutdown,
			render = render,
			error = error,
		},
		&browser,
	)
	defer app.destroy_loop(Glint_Browser, &evl)

	err := app.run_loop(Glint_Browser, &evl)
	if err != nil {
		#partial switch e in err {
		case app.User_Err:
			fmt.println(e.error)
		case:
			fmt.println("Different error type:", err)
		}
	}
}
