package main

import "core:fmt"
import "core:strings"
import "core:math"
import "core:thread"
import "core:sync"
import "core:net"
import "core:os"
import rl "vendor:raylib"

logf  :: fmt.printf
logln :: fmt.println

vec :: [2] f32

Text :: struct {
	text   : string,
	pos    : f32, // x
	parent : ^Text,
	first_child : ^Text,
}

Node :: struct {
	name: string,
	children: [] ^Node,

	// visualization data
	parent  : ^Node,

	// deprecated
	text : ^Text,
}

base_path : string

main :: proc() {
	os.set_current_directory(os.args[0][:strings.last_index(os.args[0], "/")])
	logln("CWD:", os.args[0][:strings.last_index(os.args[0], "/")])
	
	t := thread.create_and_start(draw)

	receive()
}

ast_lock : sync.Atomic_Mutex
// ast: string = "(t ((e) (s) (t)))"
ast: ^Node

receive :: proc() {

	input_untyped, err_create := net.create_socket(net.Address_Family.IP4, net.Socket_Protocol.UDP)
	assert(err_create == nil)
	input := input_untyped.(net.UDP_Socket)

	endpoint, err_resolve := net.resolve_ip4("127.0.0.1:8779")
	assert(err_resolve == nil)
	err_bind := net.bind(input, endpoint)
	fmt.assertf(err_bind == nil, "%d", err_bind)

	for {
		buf := make_slice([] u8, 1024 * 16)
		buf_len, _, err_recv := net.recv_udp(input, buf) 
		fmt.assertf(err_recv == nil, "%d", err_recv)

		logln("buf:", string(buf[:buf_len]))
		logln()

		sync.atomic_mutex_lock(&ast_lock)
		ast = unzip(string(buf[:buf_len])).children[0]
		// calc_tree(ast)
		sync.atomic_mutex_unlock(&ast_lock)
	}
}


unzip :: proc(str: string) -> (node: ^Node) {
	children: [dynamic] ^Node
	bytes := transmute([] u8) str
	
	node = new(Node)

	for r, i in str {

		if r == '(' {
			if node.name == "" do node.name = strings.clone(str[:i])
			bytes[i] = '#'
			append_elem(&children, unzip(str[i + 1:]))
		}

		if r == ')' {
			if node.name == "" do node.name = strings.clone(str[:i])
			break
		}
	}

	for r, i in str {
		bytes[i] = '#'
		if r == ')' do break
	}

	for &child in children {
		child.parent = node 
	}

	node.children = children[:]
	return
}

font : rl.Font
font_size : i32 : 14

camera: rl.Camera2D 

draw :: proc() {
	rl.SetConfigFlags({ rl.ConfigFlag.WINDOW_RESIZABLE })
	rl.InitWindow(1280, 720, "AST visualization")
	rl.SetTargetFPS(25)

	font = rl.LoadFontEx("font.ttf", font_size, nil, 0)
	
	camera.zoom = 1

	prev_mouse := rl.GetMousePosition()
	prev_zoom : f32

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.BeginMode2D(camera)
		defer rl.EndMode3D()

		scroll := rl.GetMouseWheelMove()
		zoom := camera.zoom + scroll * 0.04
		if zoom <= 0 do zoom = 0.04
		camera.zoom = zoom
		if scroll != 0 && math.floor(prev_zoom) != math.floor(zoom) {
			font = rl.LoadFontEx("font.ttf", font_size * i32(math.ceil(zoom)), nil, 0)
		}
		prev_zoom = zoom

		mouse := rl.GetMousePosition()
		defer prev_mouse = mouse
		if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
			camera.target = rl.GetScreenToWorld2D(camera.offset + prev_mouse - mouse, camera)
		}

		rl.ClearBackground({ 20,
			20, 20, 255 })

		if sync.atomic_mutex_guard(&ast_lock) {
			// draw_tree()
			draw_tree2(ast)
		}

	}
	assert(false, "die")
}



siblings : [dynamic] [2] i32
draw_tree2 :: proc(node: ^Node, level : i32 = 0) {
	@static y : i32
	if node == nil do return

	if level == 0 {
		y = 0
		clear(&siblings)
	}

	y += font_size + 4
	x := level * font_size * 2 + 4

	x2 := x - font_size * 2
	y2 := y + font_size / 3

	col_branch : rl.Color : { 60, 50, 20, 255 }

	rl.DrawLine(x - 4, y2, x2, y2, col_branch )

	{ // vertical lines
		#reverse for s in siblings {
			if s.x < x do break
			if s.x == x {
				p := pop(&siblings)
				rl.DrawLine(x2, y2, x2, p.y - 4, col_branch)
				break
			}
			pop(&siblings)
		}

		append_elem(&siblings, [2] i32 { x, y })

		if len(node.parent.children) == 1 {
			rl.DrawLine(x2, y2, x2, y - 4, col_branch)
		}
	}

	rl.DrawTextEx(font, strings.clone_to_cstring(node.name), { f32(x), f32(y) }, 14, 1, { 20, 200, 20, 255 })
	
	for c in node.children {
		draw_tree2(c, level + 1)
	}
}

