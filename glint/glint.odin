package main

import "core:fmt"
import sapp "sokol:app"
import sg "sokol:gfx"
import slog "sokol:log"

init :: proc "c" () {
	sg.setup({})
}

clean :: proc "c" () {
	sg.shutdown()
}

main :: proc() {
	sapp.run(
		{
			init_cb = init,
			cleanup_cb = clean,
			width = 800,
			height = 600,
			window_title = "glint",
			logger = {func = slog.func},
		},
	)
}
