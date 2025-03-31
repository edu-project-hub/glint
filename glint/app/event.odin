package app

import "core:fmt"
import "core:mem"
import sg "sokol:gfx"
import slog "sokol:log"

EvCloseRequest :: struct {}
RedrawRequest :: struct {}
ResizeRequest :: struct {
	dims: [2]i32,
}

Event :: union {
	EvCloseRequest,
	RedrawRequest,
	ResizeRequest,
}

Handle_Nil :: struct {}

Glint_Loop_Err :: union {
	mem.Allocator_Error,
	Handle_Nil,
}

Event_CB :: struct($Ctx: typeid) {
	handle:   proc(ctx: ^Ctx, loop: ^Event_Loop(Ctx), event: Event),
	shutdown: proc(ctx: ^Ctx),
}

Event_Loop :: struct($Ctx: typeid) {
	app:       Glint_App,
	events:    ^[dynamic]Event,
	callbacks: Event_CB(Ctx),
	ctx:       ^Ctx,
	running:   bool,
}

create_loop :: proc(
	$Ctx: typeid,
	desc: Desc,
	callbacks: Event_CB(Ctx),
	ctx: ^Ctx,
) -> (
	Event_Loop(Ctx),
	Glint_App_Err,
) {
	events := new([dynamic]Event)
	app, err := create_app(desc, events)
	if err != nil {
		return {}, err
	}

	sg.setup({logger = {func = slog.func}, environment = get_env(&app)})

	return Event_Loop(Ctx) {
			app = app,
			events = events,
			callbacks = callbacks,
			ctx = ctx,
			running = true,
		},
		nil
}

pop :: proc(events: ^[dynamic]Event) -> (Event, bool) {
	if len(events^) == 0 {
		return {}, false
	}

	event := events[0]
	ordered_remove(events, 0)
	return event, true
}


run_loop :: proc($Ctx: typeid, self: ^Event_Loop(Ctx)) -> Glint_Loop_Err {
	if self.callbacks.handle == nil {
		return Handle_Nil{}
	}

	for {
		if !self.running {
			break
		}

		for {
			if len(self.events) == 0 {
				break
			}

			event, ok := pop(self.events)
			if !ok {
				break
			}
			#partial switch v in event {
			case RedrawRequest:
				sg.begin_pass({swapchain = get_swapchain(&self.app)})
				self.callbacks.handle(self.ctx, self, event)
				sg.end_pass()
				sg.commit()
				swap_buffers(&self.app)
				continue
			}

			self.callbacks.handle(self.ctx, self, event)
		}
		poll_events(Ctx, &self.app, self)
		push_event(Ctx, self, RedrawRequest{})
	}

	return nil
}

push_event :: proc($Ctx: typeid, self: ^Event_Loop(Ctx), event: Event) -> mem.Allocator_Error {
	_, err := append_elem(self.events, event)
	if err != nil {
		return err
	}

	return nil
}

destroy_loop :: proc($Ctx: typeid, self: ^Event_Loop(Ctx)) {
	if self.callbacks.shutdown != nil {
		self.callbacks.shutdown(self.ctx)
	}

	sg.shutdown()
	free(self.events)
}

exit_loop :: proc($Ctx: typeid, self: ^Event_Loop(Ctx)) {
	self.running = false
}
