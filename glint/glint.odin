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
		break
	case app.EvRedrawRequest:
		bind := sg.Bindings {
			vertex_buffers = {0 = self.vbuf},
		}

		sg.apply_pipeline(self.pipeline)
		sg.apply_bindings(bind)
		sg.draw(0, 3, 1)
		break
	case app.EvResizeRequest:
		app.update_window(&evl.app, v.dims)
		break
	}
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
		app.Event_CB(Glint_Browser){handle = handler, prepare = prepare, shutdown = shutdown},
		&browser,
	)
	defer app.destroy_loop(Glint_Browser, &evl)

	app.run_loop(Glint_Browser, &evl)
}
