package app

Event :: union {}

Event_CB :: struct($Ctx: typeid) {
	handle:   proc(ctx: ^Ctx, loop: ^Event_Loop(Ctx), event: Event),
	shutdown: proc(ctx: ^Ctx),
}

Event_Loop :: struct($Ctx: typeid) {
	app:       Glint_App,
	events:    [dynamic]Event,
	callbacks: Event_CB(Ctx),
	ctx:       ^Ctx,
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
		},
		nil
}

destroy_loop :: proc($Ctx: typeid, self: ^Event_Loop(Ctx)) {
	if self.callbacks.shutdown != nil {
		self.callbacks.shutdown(self.ctx)
	}

	delete(self.events)
}
