package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "glint:app"
import "glint:shaders"
import "glint:text_renderer"
import dx "sokol:debugtext"
import sg "sokol:gfx"

// odinfmt: disable
vertices := [?]f32{
  0.0,  0.5, 0.5,   1.0, 0.0, 0.0, 1.0,
  0.5, -0.5, 0.5,   0.0, 1.0, 0.0, 1.0,
 -0.5, -0.5, 0.5,   0.0, 0.0, 1.0, 1.0,
}
// odinfmt: enable

Text_Entity :: struct {
    text: text_renderer.Text,
    position: [2]f32,
    velocity: [2]f32,
    color: [4]f32,
}

Glint_Browser :: struct {
    vbuf:     sg.Buffer,
    shd:      sg.Shader,
    pipeline: sg.Pipeline,
    tr:       text_renderer.Text_Rendering_State,
    inter:    text_renderer.Font_State,
    texts:    [3]Text_Entity,
    window_dims: [2]i32,
}

prepare :: proc(self: ^Glint_Browser) {
    dx.setup({fonts = {0 = dx.font_kc853()}})
    self.vbuf = sg.make_buffer(
        {type = sg.Buffer_Type.VERTEXBUFFER, data = {ptr = &vertices, size = size_of(vertices)}},
    )

    self.shd = sg.make_shader(shaders.triangle_shader_desc(sg.query_backend()))

    self.pipeline = sg.make_pipeline(
        {
            shader = self.shd,
            layout = {
                attrs = {
                    shaders.ATTR_triangle_position = {format = .FLOAT3},
                    shaders.ATTR_triangle_color0 = {format = .FLOAT4},
                },
            },
        },
    )

    self.tr = text_renderer.setup({})
    self.inter = text_renderer.fstate_create({})
    
    self.window_dims = {800, 600} 
    
    for i in 0..<3 {
        self.texts[i].text = text_renderer.text_create(&self.inter, "hello robin", {0, 0}, 48)
        self.texts[i].position = {f32(100 + i * 200), f32(100 + i * 100)}
        
        self.texts[i].velocity = {
            rand.float32_range(-3, 3),
            rand.float32_range(-3, 3),
        }
        
        switch i {
        case 0:
            self.texts[i].color = {0.2, 0.7, 0.3, 1.0}
        case 1:
            self.texts[i].color = {0.8, 0.2, 0.3, 1.0}
        case 2:
            self.texts[i].color = {0.3, 0.4, 0.9, 1.0}
        }
    }
}

shutdown :: proc(self: ^Glint_Browser) {
    text_renderer.shutdown(self.tr)
    text_renderer.fstate_destroy(&self.inter)
    
    sg.destroy_pipeline(self.pipeline)
    sg.destroy_shader(self.shd)
    sg.destroy_buffer(self.vbuf)
    dx.shutdown()
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
        dx.canvas(f32(v.dims.x), f32(v.dims.y))
        app.update_window(&evl.app, v.dims)
        self.window_dims = v.dims
        break
    }

    return nil
}

update_text_positions :: proc(self: ^Glint_Browser) {
    text_width := 180  
    text_height := 48  
    
    for i in 0..<3 {
        self.texts[i].position.x += self.texts[i].velocity.x
        self.texts[i].position.y += self.texts[i].velocity.y
        
        if self.texts[i].position.x <= 0 || self.texts[i].position.x + f32(text_width) >= f32(self.window_dims.x) {
            self.texts[i].velocity.x *= -1
            
            if self.texts[i].position.x <= 0 {
                self.texts[i].position.x = 0
            } else {
                self.texts[i].position.x = f32(self.window_dims.x) - f32(text_width)
            }
        }
        
        if self.texts[i].position.y <= 0 || self.texts[i].position.y + f32(text_height) >= f32(self.window_dims.y) {
            self.texts[i].velocity.y *= -1
            
            if self.texts[i].position.y <= 0 {
                self.texts[i].position.y = 0
            } else {
                self.texts[i].position.y = f32(self.window_dims.y) - f32(text_height)
            }
        }
    }
}

render :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser)) -> app.Glint_Loop_Err {
    text_renderer.fstate_update_if_needed(&self.inter)
    
    update_text_positions(self)
    
    bind := sg.Bindings {
        vertex_buffers = {0 = self.vbuf},
    }

    sg.apply_pipeline(self.pipeline)
    sg.apply_bindings(bind)
    sg.draw(0, 3, 1)

    w, h := app.get_framebuffer_size(&evl.app)
    text_renderer.draw(&self.tr, int(w), int(h))

    proj := linalg.matrix_ortho3d_f32(0, f32(evl.app.dims.x), f32(evl.app.dims.y), 0, -1, 1)
    
    for i in 0..<3 {
        model := linalg.identity_matrix(linalg.Matrix4f32)
        model = linalg.mul(model, linalg.matrix4_translate_f32({self.texts[i].position.x, self.texts[i].position.y, 0}))
        text_renderer.text_render(&self.texts[i].text, model, proj, self.texts[i].color)
    }

    dx.draw()
    return nil
}

error :: proc(self: ^Glint_Browser, evl: ^app.Event_Loop(Glint_Browser), err: app.Glint_Loop_Err) {
    fmt.print("Error: %s\n", err)
    app.exit_loop(Glint_Browser, evl)
}