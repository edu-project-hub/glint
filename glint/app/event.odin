package app

import "core:fmt"
import "core:mem"
import sg "sokol:gfx"
import slog "sokol:log"

EvCloseRequest :: struct {
}
EvResizeRequest :: struct {
	dims: [2]i32,
}

Event :: union {
	EvCloseRequest,
	EvResizeRequest,
	// Additional events such as key input, mouse movements, window movement, focus gained, focus lost, and others can be added here.
}

Internal_Error :: struct {
	msg: string,
}
User_Err :: struct {
	message: string,
	error:   any,
}

Glint_Loop_Err :: union {
	mem.Allocator_Error,
	Internal_Error,
	User_Err,
}

Event_CB :: struct($Ctx: typeid) {
	handle:   proc(ctx: ^Ctx, loop: ^Event_Loop(Ctx), event: Event) -> Glint_Loop_Err,
	prepare:  proc(ctx: ^Ctx),
	shutdown: proc(ctx: ^Ctx),
	render:   proc(ctx: ^Ctx, loop: ^Event_Loop(Ctx)) -> Glint_Loop_Err,
	error:    proc(ctx: ^Ctx, loop: ^Event_Loop(Ctx), err: Glint_Loop_Err),
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

pop_event :: proc(events: ^[dynamic]Event) -> (Event, bool) {
	assert(events != nil, "Events queue must not be nil")
	if len(events^) == 0 {
		return {}, false
	}

	//TODO(robaertschi): Wouldn't it make sense to use a double ended queue, or just pop the events of the end.

	event := pop(events)
	return event, true
}


run_loop :: proc($Ctx: typeid, self: ^Event_Loop(Ctx)) -> Glint_Loop_Err {
	assert(self.callbacks.render != nil, "Render callback must be set")
	assert(self.callbacks.handle != nil, "Handle callback must be set")
	assert(self.callbacks.error != nil, "Error callback must be set")

	if self.callbacks.prepare != nil {
		self.callbacks.prepare(self.ctx)
	}

	for {
		if !self.running {
			break
		}

		if self.callbacks.render != nil {
			sg.begin_pass({swapchain = get_swapchain(&self.app)})
			self.callbacks.render(self.ctx, self)
			sg.end_pass()
			sg.commit()
			swap_buffers(&self.app)
		}

		for {
			if len(self.events) == 0 {
				break
			}

			event, ok := pop_event(self.events)
			if !ok {
				self.callbacks.error(
					self.ctx,
					self,
					Internal_Error{msg = "Failed to pop event from queue"},
				)
				break
			}

			err := self.callbacks.handle(self.ctx, self, event)
			if err != nil {
				exit_loop(Ctx, self)
				return err
			}
		}
		err := poll_events(Ctx, &self.app, self)
		if err != nil {
			self.callbacks.error(self.ctx, self, err)
			break
		}
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
