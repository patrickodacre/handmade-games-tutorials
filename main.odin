package main

import "core:fmt"
import SDL "vendor:sdl2"
import SDL_Image "vendor:sdl2/image"

WINDOW_TITLE :: "Some Game Title"
WINDOW_X : i32 = SDL.WINDOWPOS_UNDEFINED // centered
WINDOW_Y : i32 = SDL.WINDOWPOS_UNDEFINED
WINDOW_W : i32 = 1200
WINDOW_H : i32 = 1000

// https://pkg.odin-lang.org/vendor/sdl2/#WindowFlag
// WINDOW_FLAGS  :: SDL.WindowFlags{.SHOWN}
WINDOW_FLAGS  :: SDL.WINDOW_SHOWN

PLAYER_WIDTH :: 24
PLAYER_HEIGHT :: 36

Entity :: struct
{
	tex: ^SDL.Texture,
	source: SDL.Rect,
	dest: SDL.Rect,
}

CTX :: struct
{
	window: ^SDL.Window,
	renderer: ^SDL.Renderer,
	player: Entity,

	moving_left: bool,
	moving_right: bool,
	moving_up: bool,
	moving_down: bool,
}

ctx := CTX{}

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
				x = 0,
				y = 0,
				w = PLAYER_WIDTH,
				h = PLAYER_HEIGHT,
			},
		dest = SDL.Rect{
				x = 100,
				y = 100,
				w = PLAYER_WIDTH * 4,
				h = PLAYER_HEIGHT * 4,
			},
	}


	event : SDL.Event
	state : [^]u8

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
					case .SPACE:
						fmt.println("Space")
				}

			}

			if event.type == SDL.EventType.KEYUP
			{ }

    	}
    	// end event handling


    	if ctx.moving_left
    	{
    		ctx.player.source.x = 0
    		ctx.player.source.y = PLAYER_HEIGHT
    		ctx.player.dest.x -= 10
    	}

    	if ctx.moving_right
    	{
    		ctx.player.source.x = 0
    		ctx.player.source.y = PLAYER_HEIGHT * 2
    		ctx.player.dest.x += 10
    	}

    	if ctx.moving_up
    	{
    		ctx.player.source.x = 0
    		ctx.player.source.y = PLAYER_HEIGHT * 3

    		ctx.player.dest.y -= 10
    	}

    	if ctx.moving_down
    	{
    		ctx.player.source.x = 0
    		ctx.player.source.y = 0
    		ctx.player.dest.y += 10
    	}

		// paint your background scene
		SDL.RenderCopy(ctx.renderer, ctx.player.tex, &ctx.player.source, &ctx.player.dest)

		// actual flipping / presentation of the copy
		// read comments here :: https://wiki.libsdl.org/SDL_RenderCopy
		SDL.RenderPresent(ctx.renderer)

		// clear the old renderer
		// clear after presentation so we remain free to call RenderCopy() throughout our update code / wherever it makes the most sense
		SDL.RenderClear(ctx.renderer)

	} // end loop


	SDL.DestroyWindow(ctx.window)
	SDL.Quit()

}