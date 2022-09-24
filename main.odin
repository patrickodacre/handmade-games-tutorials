package main

import "core:fmt"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

WINDOW_TITLE :: "Some Game Title"
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 960
WINDOW_H : i32 = 540

// https://pkg.odin-lang.org/vendor/sdl2/#WindowFlag
// WINDOW_FLAGS  :: SDL.WindowFlags{.SHOWN}
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN

PLAYER_WIDTH :: 25
PLAYER_HEIGHT :: 36

Entity :: struct
{
	tex: ^SDL.Texture,
	source: SDL.Rect,
	dest: SDL.Rect,
}

Pos :: struct
{
	x: i32,
	y: i32,
}

CTX :: struct
{
	window: ^SDL.Window,
	renderer: ^SDL.Renderer,

	target_fps_in_milliseconds: f64,

	player: Entity,

	player_left_clips: [4]Pos,
	player_right_clips: [4]Pos,
	player_up_clips: [4]Pos,
	player_down_clips: [4]Pos,


	player_move_delay: f64,
	player_velocity: f64,

	// in ms
	prev_time: f64,
	now_time: f64,
	delta_time: f64,

	moving_left: bool,
	moving_right: bool,
	moving_up: bool,
	moving_down: bool,
}

ctx := CTX{

	// milliseconds
	target_fps_in_milliseconds = 1000/60,

	player_left_clips = [4]Pos {
		Pos{x = 0, y = PLAYER_HEIGHT},
		Pos{x = PLAYER_WIDTH, y = PLAYER_HEIGHT},
		Pos{x = PLAYER_WIDTH * 2, y = PLAYER_HEIGHT},
		Pos{x = PLAYER_WIDTH, y = PLAYER_HEIGHT},
	},

	player_right_clips = [4]Pos {
		Pos{x = 0, y = PLAYER_HEIGHT * 2},
		Pos{x = PLAYER_WIDTH, y = PLAYER_HEIGHT * 2},
		Pos{x = PLAYER_WIDTH * 2, y = PLAYER_HEIGHT * 2},
		Pos{x = PLAYER_WIDTH, y = PLAYER_HEIGHT * 2},
	},

	player_up_clips = [4]Pos {
		Pos{x = 0, y = PLAYER_HEIGHT * 3},
		Pos{x = PLAYER_WIDTH, y = PLAYER_HEIGHT * 3},
		Pos{x = PLAYER_WIDTH * 2, y = PLAYER_HEIGHT * 3},
		Pos{x = PLAYER_WIDTH, y = PLAYER_HEIGHT * 3},
	},

	player_down_clips = [4]Pos {
		Pos{x = 0, y = 0},
		Pos{x = PLAYER_WIDTH, y = 0},
		Pos{x = PLAYER_WIDTH * 2, y = 0},
		Pos{x = PLAYER_WIDTH, y = 0},
	},

	player_velocity = 1,

}

main :: proc()
{
    SDL.Init(SDL.INIT_VIDEO)
	SDL_Image.Init(SDL_Image.INIT_PNG)

    ctx.window = SDL.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, WINDOW_FLAGS)
    ctx.renderer = SDL.CreateRenderer(
    	ctx.window,
    	-1,
    	SDL.RENDERER_PRESENTVSYNC | SDL.RENDERER_ACCELERATED | SDL.RENDERER_TARGETTEXTURE
	)

	// Create Entities
	player_img : ^SDL.Surface = SDL_Image.Load("assets/bardo.png")

	ctx.player = Entity{
		tex = SDL.CreateTextureFromSurface(ctx.renderer, player_img),
		source = SDL.Rect{
				x = ctx.player_down_clips[1].x,
				y = ctx.player_down_clips[1].y,
				w = PLAYER_WIDTH,
				h = PLAYER_HEIGHT,
			},
		dest = SDL.Rect{
				x = 100,
				y = 100,
				w = PLAYER_WIDTH * 2,
				h = PLAYER_HEIGHT * 2,
			},
	}


	event : SDL.Event
	state : [^]u8

	ctx.now_time = f64(SDL.GetTicks())

	game_loop: for
	{

		state = SDL.GetKeyboardState(nil)

		ctx.moving_left = state[SDL.Scancode.A] > 0
		ctx.moving_right = state[SDL.Scancode.D] > 0
		ctx.moving_up = state[SDL.Scancode.W] > 0
		ctx.moving_down = state[SDL.Scancode.S] > 0

    	if SDL.PollEvent(&event)
    	{
    		if event.type == SDL.EventType.QUIT
    		{
    			break game_loop
    		}

			if event.type == SDL.EventType.KEYDOWN
			{
				#partial switch event.key.keysym.scancode
				{
					case .L:
						fmt.println("Log:")
						fmt.println(ctx.delta_time)
					case .SPACE:
						fmt.println("Space")
				}

			}

			if event.type == SDL.EventType.KEYUP
			{ }

    	}
    	// end event handling
    	animation_speed := SDL.GetTicks() / 175
    	idx := animation_speed %% 4 // 0 , 1, 2, 3

    	// calculations necessary for Target FPS or Target PPS
    	ctx.prev_time = ctx.now_time
    	ctx.now_time = f64(SDL.GetTicks())
    	ctx.delta_time = ctx.now_time - ctx.prev_time

		// Method :: Target Pixels per Frame


		ctx.player_move_delay = max(0, ctx.player_move_delay - ctx.delta_time)

		if ctx.player_move_delay == 0
		{

	    	steps := i32(ctx.delta_time * ctx.player_velocity)

	    	if ctx.moving_left
	    	{
	    		src := ctx.player_left_clips[idx]
	    		ctx.player.source.x = src.x
	    		ctx.player.source.y = src.y

	    		move_player(-steps, 0)

	    		// ctx.player.dest.x -= steps
	    	}

	    	if ctx.moving_right
	    	{

	    		src := ctx.player_right_clips[idx]
	    		ctx.player.source.x = src.x
	    		ctx.player.source.y = src.y

	    		move_player(steps, 0)
	    		// ctx.player.dest.x += steps
	    	}

	    	if ctx.moving_up
	    	{
	    		src := ctx.player_up_clips[idx]
	    		ctx.player.source.x = src.x
	    		ctx.player.source.y = src.y

	    		move_player(0, -steps)
	    		// ctx.player.dest.y -= steps
	    	}

	    	if ctx.moving_down
	    	{

	    		src := ctx.player_down_clips[idx]
	    		ctx.player.source.x = src.x
	    		ctx.player.source.y = src.y

	    		move_player(0, steps)
	    		// ctx.player.dest.y += steps
	    	}
    	}

		// paint your background scene
		SDL.RenderCopy(ctx.renderer, ctx.player.tex, &ctx.player.source, &ctx.player.dest)

		// Method :: Target Seconds per Frame
		// delta_test := ctx.delta_time
    	// if delta_test < ctx.target_fps_in_milliseconds
    	// {
			// delta_test = f64(SDL.GetTicks()) - ctx.prev_time
    	// }

		// actual flipping / presentation of the copy
		// read comments here :: https://wiki.libsdl.org/SDL_RenderCopy
		SDL.RenderPresent(ctx.renderer)

		// clear the old renderer
		// clear after presentation so we remain free to call RenderCopy() throughout our update code / wherever it makes the most sense
		// make sure our background is black
		// render clear colors the entire screen whatever color is set here
		SDL.SetRenderDrawColor(ctx.renderer, 0, 0, 0, 100)
		SDL.RenderClear(ctx.renderer)

	} // end loop


	SDL.DestroyWindow(ctx.window)
	SDL.Quit()

}

move_player :: proc(dx, dy: i32)
{
	new_x := ctx.player.dest.x + dx
	new_y := ctx.player.dest.y + dy

	new_x = max(0, min(new_x, WINDOW_W - PLAYER_WIDTH))
	new_y = max(0, min(new_y, WINDOW_H - PLAYER_HEIGHT))

	ctx.player.dest.x = new_x
	ctx.player.dest.y = new_y

	ctx.player_move_delay = 3
}

