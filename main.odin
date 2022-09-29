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

// milliseconds
TARGET_FRAME_TIME : u32 : 1000/60

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

	player: Entity,
	player_speed: i32,

	player_left_clips: [4]Pos,
	player_right_clips: [4]Pos,
	player_up_clips: [4]Pos,
	player_down_clips: [4]Pos,

	moving_left: bool,
	moving_right: bool,
	moving_up: bool,
	moving_down: bool,
}

ctx := CTX{
	player_speed = 10,

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

}

main :: proc()
{
    SDL.Init(SDL.INIT_VIDEO)
	SDL_Image.Init(SDL_Image.INIT_PNG)

    ctx.window = SDL.CreateWindow(WINDOW_TITLE, WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, WINDOW_FLAGS)
    ctx.renderer = SDL.CreateRenderer(
    	ctx.window,
    	-1,
    	SDL.RENDERER_SOFTWARE
    	/* SDL.RENDERER_PRESENTVSYNC */
    	// SDL.RENDERER_PRESENTVSYNC | SDL.RENDERER_ACCELERATED | SDL.RENDERER_TARGETTEXTURE
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

	start : u32
	end : u32

	game_loop: for
	{
		start = SDL.GetTicks()

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
					case .SPACE:
						fmt.println("Space")
				}

			}

			if event.type == SDL.EventType.KEYUP
			{ }

    	}
    	// end event handling

    	// ctx.player_speed = 20

    	animation_speed := start / 175
    	idx := animation_speed %% 4 // 0 , 1, 2, 3

    	if ctx.moving_left
    	{
    		src := ctx.player_left_clips[idx]
    		ctx.player.source.x = src.x
    		ctx.player.source.y = src.y

    		move_player(-ctx.player_speed, 0)
    	}

    	if ctx.moving_right
    	{

    		src := ctx.player_right_clips[idx]
    		ctx.player.source.x = src.x
    		ctx.player.source.y = src.y

    		move_player(ctx.player_speed, 0)
    	}

    	if ctx.moving_up
    	{
    		src := ctx.player_up_clips[idx]
    		ctx.player.source.x = src.x
    		ctx.player.source.y = src.y

    		move_player(0, -ctx.player_speed)
    	}

    	if ctx.moving_down
    	{

    		src := ctx.player_down_clips[idx]
    		ctx.player.source.x = src.x
    		ctx.player.source.y = src.y

    		move_player(0, ctx.player_speed)
    	}

		SDL.RenderCopy(ctx.renderer, ctx.player.tex, &ctx.player.source, &ctx.player.dest)



		// check end once all update and render is completed
		end = SDL.GetTicks()

		// CAP frame rate
		// if this doesn't match your monitor, movement will be laggy
    	for (end - start) < TARGET_FRAME_TIME
    	{
			end = SDL.GetTicks()
    	}

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
}
