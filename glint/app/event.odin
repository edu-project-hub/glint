package app

import "core:fmt"
import "core:mem"

EvCloseRequest :: struct {}
RedrawRequest :: struct {}

Event :: union {
	EvCloseRequest,
	RedrawRequest,
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
	events:    [dynamic]Event,
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
	app, err := create_app(desc)
	if err != nil {
		return {}, err
	}

	return Event_Loop(Ctx) {
			app = app,
			events = make([dynamic]Event, 0, 10),
			callbacks = callbacks,
			ctx = ctx,
			running = true,
		},
		nil
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

			event := pop(&self.events)
			#partial switch v in event {
			case RedrawRequest:
        start_render(&self.app)
        self.callbacks.handle(self.ctx, self, event)
        end_render(&self.app)
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
	_, err := append_elem(&self.events, event)
	if err != nil {
		return err
	}

	return nil
}

destroy_loop :: proc($Ctx: typeid, self: ^Event_Loop(Ctx)) {
	if self.callbacks.shutdown != nil {
		self.callbacks.shutdown(self.ctx)
	}

	delete(self.events)
}

exit_loop :: proc($Ctx: typeid, self: ^Event_Loop(Ctx)) {
	self.running = false
}
