pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- game state
state={menu=1,lvl=1}

startmenu = 1
endmenu = 3
game = 4


maprect = {} -- x, y, width, height, xdrawoffset, ydrawoffset

-- player
player = {}

-- consts
gridsize = 8
dimensions = 16

-- sprite indexes
index = {
	player = 64,
	death = 191,
	 
	block = 58,
	wblock = 60,

	cexit = 210,
	oexit = 227,

	key = 242,
	key2 = 243,

	tank = 49,
	bow = 182,
	bubble = 48,
	grad = 141,
	pearl = 134,

	lpenguin = 79,
	rpenguin = 80,
	dpenguin = 81,
	upenguin = 82,
	fwhale = 105,
	bwhale = 104,

	fish = 221,
	hfish = 220,

	jelly1 = 106,
	jelly2 = 107,
	ujelly1 = 108,
	ujelly2 = 109,

	bturtle = 100,
	fturtle = 101,
	blturtle = 103,
	flturtle = 102,

	rabbit = 115,

	usnake = 125,
	dsnake = 126,

	pbird = 137,
	pbird2 = 138,
	pnest = 139,
	penest = 140,
	bbird = 153,
	bbird2 = 154,
	bnest = 155,
	benest = 156,
	ybird = 169,
	ybird2 = 170,
	ynest = 171,
	yenest = 172,

	ice = 32,
}

-- animations: todo: key is 1st sprite, value is max sprite #
anim = {
	water1 = 1,
	water2 = 2,
}

-- sprite flags
fwalkable = 0x1
fwater = 0x2
fice = 0x4
--ffire = 0x8
fdeath = 0x40
fstandable = 0x80

-- debug
blkmsg = 0

-- animations
tick = 0

-- current block sprite positions
sprites = {}
animals = {}
blocks = {}
exit = {}

-- temp structures
moved = {}

-- ui
steps = 0
asteps = 0

function _init()

	reload(0x2000, 0x2000, 0x1000) -- reload map tiles

	-- setup menu items
	if (state.menu == game) then
		menuitem(1, "restart level", function() _init() sfx(1) end)
		menuitem(2, "next level", function() state.lvl += 1 _init() sfx(1) end)
	end
	
	player.sdx = 0 -- slide direction
	player.sdy = 0
	player.sframe = 0 -- frame of a slide animation
	player.sblock = false -- true if sliding block in front of player
	player.buff = 0 -- buffered key input
	player.animaldelay = 0 -- slight delay after movement before animals move
	player.sprite = index.player
	player.isvertical = false
	
	player.delay = 0
	player.delayfunc = nil

	steps=0
	asteps=0

	-- clear sprites between levels
	for i = 1, dimensions do
		sprites[i] = {}
		animals[i] = {}
		blocks[i] = {}
		for j = 1, dimensions do
			sprites[i][j] = nil
			animals[i][j] = nil
			blocks[i][j] = nil
		end
	end

	-- config levels
	if (state.lvl == 1) then
		-- plaza
		maprect = {0, 24, 10, 8, 4, 4}
        player.x = 6
        player.y = 8
		exit.x = 0
		exit.y = 3
		exit.sprite = index.cexit
		aas(blocks, {198,3,2,199,4,2,198,5,2}) -- trash cans
		aas(sprites, {192,1,7,193,1,4,194,10,7,195,10,4}) -- signs
		aas(sprites, {197,1,6,196,10,3,196,10,6}) -- static doors
		aas(sprites, {201,2,1,202,6,1})
		sprites[4][1] = index.key
		aa(animals, index.rabbit, {4,5,6,6})
	elseif (state.lvl == 2) then
		-- w. garden 1
		maprect = {14, 24, 10, 8, 3, 3}
        player.x = 10
        player.y = 5
		exit.x = 11
		exit.y = 4
		exit.sprite = index.cexit

		aa(blocks, index.block, {8,6,2,4,1,5,3,5,2,6,5,1,5,3,4,1,4,2,3,1})
		aa(animals, index.rabbit, {7,7,9,8})

		animals[8][3] = index.bwhale
		animals[7][3] = index.fwhale

		--sprites[5][2] = index.bubble
		sprites[2][5] = index.key

	elseif (state.lvl == 3) then
		-- rainforest 1
		maprect = {0, 8, 8, 8, 4, 4}
		player.isvertical = true
        player.x = 8
        player.y = 2
		exit.x = 0
		exit.y = 8
		exit.sprite = index.cexit
		sprites[3][7] = index.key2
		blocks[6][5] = index.block
		animals[2][4] = index.usnake
	elseif (state.lvl == 10) then
		-- rainforest 2 - unused
		maprect = {8, 8, 16, 8, 0, 4}
		player.isvertical = true
        player.x = 12
        player.y = 2
		exit.x = 1
		exit.y = 8
		exit.sprite = index.oexit
		aas(sprites, {index.yenest,2,2,index.benest,15,2,index.penest,7,7})
		aas(animals, {index.pbird2,4,3,index.bbird2,13,6,index.usnake,2,8})
		aa(blocks, index.block, {2,5,11,3,14,3})
	elseif (state.lvl == 4) then
		-- aquarium 1
		maprect = {0, 16, 8, 8, 4, 4}
        player.x = 1
        player.y = 6
		exit.x = 1
		exit.y = 0
		exit.sprite = index.cexit
	    sprites[8][8] = index.key
		aa(animals, index.jelly1, {1,1,6,6})
		aas(animals, {index.fturtle,6,3,index.bturtle,5,3})
        aas(animals, {index.jelly2,1,2,index.ujelly1,2,1,index.fturtle,6,3,index.bturtle,5,3})
		aa(sprites, index.tank, {3,3,7,4,3,8,8,7})
	elseif (state.lvl == 5) then
		-- aquarium 2 
		maprect = {24, 16, 9, 11, 3.5, 2.5}
        player.x = 5
        player.y = 1
		exit.x = 5    
		exit.y = 0
		exit.sprite = index.oexit
		aa(sprites, index.tank, {4,1,6,1,8,2,1,4,4,5,7,7,3,8,1,10,5,10})
		aa(sprites, index.bubble, {6,4,9,9,3,11})
		aa(sprites, index.grad, {9,2,6,3,6,7,7,9})
		animals[4][4] = index.fturtle
		animals[3][4] = index.bturtle
		animals[4][7] = index.flturtle
		animals[5][7] = index.blturtle
		aa(animals, index.fish, {8,1,9,1,6,8,7,8})
		aa(animals, index.jelly1, {4,3,5,3,6,6,7,6})
   	elseif (state.lvl == 6) then
		-- tundra 1
		maprect = {0, 0, 8, 8, 4, 4}
        player.x = 4
        player.y = 8
		exit.x = 6
		exit.y = 0
		exit.sprite = index.cexit
		sprites[7][4] = index.key
		aa(animals, index.dpenguin, {3,1,4,1,5,1})
	elseif (state.lvl == 7) then
		-- tundra 2
		maprect = {8, 0, 9, 8, 4, 4}
        player.x = 1
        player.y = 3
		exit.x = 6
		exit.y = 9
		exit.sprite = index.oexit
		aa(sprites, index.bow, {2,4,4,2,6,1})
		aa(blocks, index.block, {2,2,6,2})
		aa(animals, index.dpenguin, {3,1,4,1,5,1})
		animals[4][5] = index.bwhale
		animals[3][5] = index.fwhale

	elseif (state.lvl == 8) then
		-- tundra 2
		maprect = {34, 14, 9, 13, 3.5, 1}
        player.x = 4
        player.y = 13
		exit.x = 10
		exit.y = 1
		exit.sprite = index.oexit
		animals[3][5] = index.bwhale
		animals[2][5] = index.fwhale
		animals[8][5] = index.bwhale
		animals[7][5] = index.fwhale
		aa(animals, index.rpenguin, {2,10,2,11,2,12})
		sprites[3][6] = index.pearl
		aa(blocks, index.block, {1,6,6,7,1,8,7,8,8,8,5,9,9,9,9,10,1,11})
	end
end

-- copy from list of points into the specified array
function aa(t, s, a)
	for i=1,#a/2 do
		t[a[i*2-1]][a[i*2]] = s
	end
end

-- copy from list of sprite numbers + points into the specified array
function aas(t, a)
	for i=1,#a/3 do
		local s = a[i*3-2]
		local x = a[i*3-1]
		local y = a[i*3]
		t[x][y] = s
	end
end

function _update60()

	if (state.menu == startmenu) then
		-- z/x to start game
		if (btn(4) or btn(5)) then
			state.menu = game			
			_init()
		end
	end

	--if (state.menu == endmenu) then
		-- z/x to reset?
	--end

	-- Update game
	if (state.menu != game) return

	local dx = 0
	local dy = 0

	-- delay slightly after player death
	if (player.delay > 0) then
		player.delay -= 1
		return
	end
	if (player.delayfunc != nil) then
		player.delayfunc()
	end

	-- check for death
	if (checkdeath()) then
		killplayer(21)
	end

	pickup(player.x, player.y)

	-- buffer last key pressed during animal movement
	local b = btnp()
	if (b > 0) player.buff = b

	-- skip player movement while animals are moving
	if (player.animaldelay > 0) then
		player.animaldelay -= 1
		
		if (player.animaldelay == 0) then 
			moveanimals()
			checkanimalattack()
			return
		end
	end

	-- player is sliding on ice, so update animation until we stop
	if (player.sdx != 0 or player.sdy != 0) then

		-- update pos every n frames
		if ((tick % 1) == 0) then
			player.sframe += 1
		end

		-- advance player one full grid unit and check if we can continue sliding
		if (player.sframe > gridsize) then 
			player.sframe = 0
			player.x += player.sdx
			player.y += player.sdy
						
			-- stop sliding if we were unable to move
			if (moveplayer(player.sdx,player.sdy) == false) then
				player.sdx = 0
				player.sdy = 0
				player.animaldelay = 10
			end
		end
	else
		-- normal player movement
		if (b == 0) b = player.buff
		player.buff = 0

		if (band(b, 0x1) > 0) then
			dx=-1
		elseif (band(b, 0x2) > 0) then
			dx=1
		elseif (band(b, 0x4) > 0) then
			dy=-1
		elseif (band(b, 0x8) > 0) then
			dy=1
		end

		if (moveplayer(dx,dy)) then
			steps+=1

			if (player.sdx == 0 and player.sdy == 0) then
				-- didn't start sliding
				sfx(40)
				player.animaldelay = 10
			else
				sfx(39)
			end
		end
	end

	-- update any tiles
	for i=1,maprect[3] do
		for j=1,maprect[4] do
			if (blocks[i][j] and band(fget(mgetspr(i,j)), fwater) > 0) then
				blocks[i][j] = nil
				msetspr(index.wblock,i,j)
			end
		end
	end

	-- did the player win?
	if (player.x == exit.x and player.y == exit.y) then
		blkmsg = "reached exit!"

		state.lvl += 1
		--if (state.lvl == 5) state.lvl = 1
		_init()
	end

	-- animate map tiles
	animatewater()
	animatestaticanimals()

end

function _draw()
	tick+=1
	if (tick > 2000) tick = 0;

	if (state.menu==startmenu) draw_startmenu()
	if (state.menu==game) draw_level()
	if (state.menu==endmenu) draw_ending()

end

function draw_startmenu()
	-- draw the start menu
	cls()

	--rectfill(0, 0, 127, 127, 13)

	map(112, 0, 0, 0, 16, 16)
	rectfill(38-2,94-2,102,100, 1)

	if (tick % 120 >= 60) then
		print("press z to start", 38, 94, 13)
	end


end

function draw_ending()
	-- needs some pixels here for when you win
end

function draw_level()
	cls()

	-- draw extra blocks if over ice


	-- draw map
	local ox = maprect[5]*gridsize
	local oy = maprect[6]*gridsize
	local wp = maprect[3]*gridsize
	local hp = maprect[4]*gridsize
	local w = 2
	if (player.isvertical) hp += gridsize
	rectfill(ox-w, oy-w, ox+wp+w-1, oy+hp+w-1, 5)

	if (player.isvertical) then
		for i=1,maprect[3] do
			sprgrid(3, i, maprect[4]+1)
			msetspr(3, i, maprect[4]+1)
		end

		map(maprect[1], maprect[2], ox, oy, maprect[3], maprect[4])
	else
		map(maprect[1], maprect[2], ox, oy, maprect[3], maprect[4])
	end




	-- draw ice sheen
	drawice()

	-- draw exit tile
	sprgrid(exit.sprite, exit.x, exit.y)

	-- draw sprites
	for i=1, dimensions do
		for j=1, dimensions do
			sprgrid(sprites[i][j], i, j)
			sprgrid(animals[i][j], i, j)
			sprgrid(blocks[i][j], i, j)
		end
	end

	-- draw player
	local pox = (player.x + maprect[5] - 1)*gridsize + player.sdx*player.sframe
	local poy = (player.y + maprect[6] - 1)*gridsize + player.sdy*player.sframe
	drawoutline(player.sprite, pox, poy)
	spr(player.sprite, pox, poy)

	-- draw block pushed by player one square ahead of the player
	if (player.sblock) spr(index.block, pox+gridsize*player.sdx, poy+gridsize*player.sdy)

	-- ui
	if (blkmsg != nil and blkmsg != 0) then
		print(blkmsg)
		blkmsg = nil
	else
		--print("steps: " .. steps .. "  [animal: " .. asteps .. "]")
		print("steps: " .. steps)
	end
end

function animatewater()
	if ((tick % 80) == 1) then 
		for x=1, dimensions do
			for y=1, dimensions do
				if (mget(x, y) == anim.water1) then
					mset(x, y, anim.water2)
				elseif(mget(x, y) == anim.water2) then
					mset(x, y, anim.water1)
				end
			end
		end
	end
end

function animatestaticanimals()
	if ((tick % 80) == 1) then
		for i=1, maprect[3] do
			for j=1, maprect[4] do
				animals[i][j] = swap(animals[i][j], index.jelly1, index.jelly2)
				animals[i][j] = swap(animals[i][j], index.ujelly1, index.ujelly2)
			end
		end
	end
end

-- if a== s1 or s2, swap it, otherwise return a. hack for less lines of code
function swap(a, s1, s2)
	if (a == 0) return 0
	if (a == s1) return s2
	if (a == s2) return s1
	return a
end

function drawice()
	local px = player.x
	local py = player.y

	local w = maprect[4]
	--local w = dimensions

	for i=1, dimensions do
		for j=1, dimensions do
			if (mgetspr(i,j) == index.ice) then
				--if (i == (px+1 -j)%w+1) sprgrid(index.ice+4, i, j)
				--if (i == (px - j )%w+1) sprgrid(index.ice+3, i, j)
				--if (i == (px-1 -j)%w+1) sprgrid(index.ice+2, i, j)
				--if (i == (px-2 -j)%w+1) sprgrid(index.ice+1, i, j)

				if (j == (py+1-i)%w+1) sprgrid(index.ice+4, i, j)
				if (j == (py  -i)%w+1) sprgrid(index.ice+3, i, j)
				if (j == (py-1-i)%w+1) sprgrid(index.ice+2, i, j)
				if (j == (py-2-i)%w+1) sprgrid(index.ice+1, i, j)
			end

		end
	end
end

function drawoutline(s, x, y)
	for i=0,7 do
		for j=0,7 do

			local px = (s%16)*8+i
			local py = flr(s/16)*8 + j

			if (sget(px,py) > 0) then
				--rect(x+i-1, y+j-1, x+i+1, y+j+1, 5)
				rect(x+i-1, y+j, x+i+1, y+j, 5)
				rect(x+i, y+j-1, x+i, y+j+1, 5)
			end
		end
	end
end

function sprgrid(s, x, y)
	if (s) spr(s, (x + maprect[5] - 1)*gridsize, (y + maprect[6] - 1)*gridsize)
end

function mgetspr(x, y)
	if (x < 1 or x > maprect[3] or y < 1 or y > maprect[4]) return nil

	return mget(x + maprect[1] - 1, y + maprect[2] - 1)
end

function msetspr(s, x, y)
	if (x < 1 or x > maprect[3] or y < 1 or y > maprect[4]) return
	mset(x+maprect[1]-1,y+maprect[2]-1,s)
end

function moveanimals()
	-- track which animals have already moved
	moved = {}
	for i=1, dimensions do
		moved[i] = {}
		for j=1, dimensions do
			moved[i][j] = false
		end
	end

	-- move animals in place from top of grid to bottom of grid
	for i=1, dimensions do
		for j=1, dimensions do
			if (moved[i][j] == false) then 
				local a = animals[i][j]

				if (a == index.dpenguin or a == index.upenguin) then
					moveanimal(a, index.upenguin, index.dpenguin, i, j, false, 8)
				elseif(a == index.lpenguin or a == index.rpenguin) then
					moveanimal(a, index.lpenguin, index.rpenguin, i, j, true, 8)
				elseif(a == index.usnake or a == index.dsnake) then
					moveanimal(a, index.usnake, index.dsnake, i, j, false, 9)
				end

				if (a==index.fturtle or a==index.flturtle) then
					movebiganimal(a, index.flturtle, index.fturtle, index.blturtle, index.bturtle, i, j, 12)
				end
			end
		end
	end

	asteps += 1
end

function movebiganimal(a, lf, rf, lb, rb, i, j)
	local turned = nil
	local tbutt = nil
	local butt = nil
	local dx = 0
	local dy = 0

	if (a == lf) then
		dx=-1
		dy=0
		turned = rf
		tbutt = rb
		butt = lb
	elseif(a == rf) then
		dx=1
		dy=0
		turned = lf
		tbutt = lb
		butt = rb
	else
		return
	end

	if (acanmove(i,j,dx,dy)) then
		animals[i-dx][j-dy] = nil
		animals[i][j] = butt
		animals[i+dx][j+dy] = a
		moved[i+dx][j+dy] = true
	else
		if (a==lf) then
			animals[i+1][j] = turned
			animals[i][j] = tbutt
			moved[i+1][j] = true
		else
			animals[i-dx][j-dy] = turned
			animals[i][j] = tbutt
			moved[i-dx][j-dy] = true
		end
	end
end

function moveanimal(a, up, down, i, j, leftright, fx)
	local flipped = nil
	local dx = 0
	local dy = 0

	if (a == down) then
		if (leftright) then
			dx=1
		else
			dy=1
		end
		flipped = up
	elseif(a == up) then
		if (leftright) then
			dx=-1
		else
			dy=-1
		end

		flipped = down
	else
		return
	end

	if (acanmove(i,j,dx,dy)) then
		animals[i][j] = nil
		animals[i+dx][j+dy] = a
		moved[i+dx][j+dy] = true
	else
		animals[i][j] = flipped
	end

	if (fx) sfx(fx)

end

function ispushablebiganimal(x, y)
	local a = animals[x][y]
	if (a==index.fturtle or a==index.flturtle or a==index.bturtle or a==index.blturtle) return true
	return false
end

-- returns (sprite, sfx) if picked up
function canpickup(x, y)
	if (x <= 0 or y <= 0) return nil

	local s = sprites[x][y]

	if (s == index.key or s == index.key2) return s, 24
	if (s == index.tank) return s, 22
	if (s == index.bow) return s, 22

	return false
end

function pickup(x, y)
	if (x <= 0 or y <= 0) return nil

	local s, fx = canpickup(x,y)

	if (s) then
		sprites[x][y] = nil
		sfx(fx)
	end

	if (s == index.key or s == index.key2) then
		exit.sprite = index.oexit
	end

	return s
end

function acanmove(ax, ay, dx, dy)
	if (dx == 0 and dy == 0) return false

	local x = ax + dx
	local y = ay + dy

	if (x <= 0 or y <= 0) return false

	local s = mgetspr(x, y)
	local flags = fget(s)

	if (animals[x][y]) return false
	if (blocks[x][y]) return false
	if (player.x == x and player.y == y) return false
	if (band(flags, fwater) > 0) return false
	if (band(flags, fwalkable) > 0) return true

	return false
end

function checkanimalattack()
	for i=1, maprect[3] do
		for j=1, maprect[4] do
			local a = animals[i][j]
			if (band(fget(a), fdeath) > 0) then
				if (player.x >= i-1 and player.x <= i+1 and player.y >= j-1 and player.y <= j+1) then
					killplayer(3)
					return
				end
			end

			-- jelly death
			if (a==index.ujelly1 or a==index.ujelly2 or a==index.jelly1 or a==index.jelly2) then
				if ((player.x==i-1 or player.x==i+1) and player.y==j) killplayer(4)

				if (a==index.ujelly1 or a==index.ujelly2) then
					if (player.y==j-1 and player.x==i) killplayer(4)
				else
					if (player.y==j+1 and player.x==i) killplayer(4)
				end
			end
		end
	end
end

function killplayer(s)
    if (s) sfx(s)
    
	--blkmsg = "death"
	player.delay = 60
	player.sprite = index.death
	player.delayfunc = _init
end

function checkdeath()
	local s = mgetspr(player.x, player.y)
	if (band(fget(s), fdeath) > 0) return true
	return false
end

-- check if transitioning between these two blocks is a slide movement
function moveisslide(x, y, dx, dy)	
	if (band(fget(mgetspr(x, y)), fice) > 0 or band(fget(mgetspr(x+dx, y+dy)), fice) > 0) return true 
	return false
end

function isblock(x, y)
	if (x <= 0 or y <= 0) return false
	if (blocks[x][y]) return true
	return false
end

function canpushblockto(x, y, flags)
	if (x <= 0 or y <= 0) return false

	if (animals[x][y]) return false
	if (blocks[x][y]) return false
	if (band(flags, fwalkable) > 0) return true
	if (band(flags, fwater) > 0) return true
	if (band(flags, fice) > 0) return true
	return false
end

function canwalkto(x, y, flags)
	if (x <= 0 or y <= 0) return false

	if (animals[x][y]) return false
	if (blocks[x][y]) return true
	if (sprites[x][y] and canpickup(x, y) == false) return false
	if (band(flags, fwalkable) > 0) return true
	if (band(flags, fwater) > 0) return true
	if (band(flags, fice) > 0) return true
	return false
end

-- return true if the player can move to the adjacent block
function moveplayer(dx, dy)
	if (player.isvertical) return vmoveplayer(dx, dy)

	if (dx == 0 and dy == 0) return false

	local x = player.x + dx
	local y = player.y + dy
	local nx = x + dx
	local ny = y + dy
	local s = mgetspr(x, y)
	local ns = mgetspr(nx, ny)
	local flags = fget(s)
	local nflags = fget(ns)


	-- handle normally out of bounds exit tiles (may have 0-index)
	if (x == exit.x and y == exit.y and exit.sprite == index.oexit and player.sblock == false) then
		player.x = x
		player.y = y
		return true
	end

	if (x <= 0 or y <= 0) return false

	-- try to continue sliding a block
	if (player.sblock) then
		-- drop block in water
		if (band(flags, fwater) > 0) then
			msetspr(index.wblock,x,y)
			player.sblock = false
			return false
		end

		-- continue pushing unless we already pushed it onto non-ice
		if (band(flags, fice) > 0 and canpushblockto(nx, ny, nflags)) return true

		-- stop pushing here
		blocks[x][y] = index.block
		player.sblock = false
		return false
	end

	-- try to move by pushing or sliding a block
	if (isblock(x, y)) then
		if (player.sdx != 0 or player.sdy != 0) then
			-- if sliding, hitting a block stops the player
			return false
		end

		if (canpushblockto(nx, ny, nflags)) then
			if (moveisslide(x, y, dx, dy)) then
				blocks[x][y] = nil
				player.sblock = true
			else
				--if (band(nflags, fwalkable) > 0 and band(nflags, fwater) == 0) then
				--	sfx(27, 1)
				--else
				--	sfx(29, 1) -- into water
				--end
				
				blocks[nx][ny] = blocks[x][y]
				blocks[x][y] = nil
			end
		else
			return false
		end
	end

	-- if we are sliding and not currently on ice, stop moving
	if ((player.sdx > 0 or player.sdy > 0) and band(fget(mgetspr(player.x,player.y)), fice) == 0) return false

	-- normal slide or walk
	if (canwalkto(x, y, flags)) then
		if (moveisslide(player.x, player.y, dx, dy)) then
			player.sdx = dx
			player.sdy = dy
		else 
			player.x += dx
			player.y += dy
		end

		return true
	end

	return false
end


-- return true if the player can move to the adjacent block
function vmoveplayer(dx, dy)
	if (dx == 0 and dy == 0) return false


	local x = player.x + dx
	local y = player.y + dy
	local nx = x + dx
	local ny = y + dy
	local s = mgetspr(x, y)
	local ns = mgetspr(nx, ny)
	local flags = fget(s)
	local nflags = fget(ns)

	-- check for stopping a slide
	if (player.sdy != 0) then
		local bx = player.x
		local by = player.y + 1

		
		if (blocks[bx][by]) return false
		if (by > maprect[4]) return false

		if (band(fget(mgetspr(bx,by)), fstandable) > 0) return false

		if (fget(mgetspr(bx,by)) == 0) return true

		--if (canwalkto(bx, by, fget(mgetspr(bx,by))) == true) return false

		return true
	end


	local bx = 0
	local by = 0
	if (dx != 0) then
		-- look forward and below to see if we can stand there
		bx = player.x+dx
		by = player.y+1
		local bs = mgetspr(bx,by)
		local bflags = fget(bs)

		-- standable map tiles
		if (band(bflags, fstandable) > 0) then
			player.x += dx
			player.y += dy
			return true
		end

		-- standable blocks
		if (bx > 0 and by > 0 and blocks[bx][by]) then
			player.x += dx
			player.y += dy
			return true
		end

		-- try to move to an adjacent tree
		if (canwalkto(x,y,flags)) then
			player.x += dx
			player.y += dy
			return true
		end

		-- try to fall off of a branch
		if (canwalkto(x,y,flags) == false) then
			player.x += dx
			player.sdx = 0
			player.sdy = 1
			return true
		end
	else
		-- try to climb up/down
		if (canwalkto(x, y, flags)) then
			player.x += dx
			player.y += dy
			return true
		end
	end



	return false
end

__gfx__
00000000ccccccccc7ccccc7444444490000000066566566bb3bbb3b00000000bb3bbb3070000000000000070000000770077007000000000000000000000000
00000000ccccccc77ccccccc944944490000000066566566b3bbbbbb60506060b3bbbbb000007700007007000000000700007077000000000000000000000000
007007007ccccc7ccccc7ccc449944440000000055566555bb3bb3bb50506050bb3bb3b000077070000770000000000707777770000000000000000000000000
00077000cccc7cccc7c7cccc4444444400000000666666663bb3bbbbbbbbbbb33bb3bbb000070770000770000000007777077000000000000000000000000000
00077000ccc7c7cccc7ccccc444994440000000066666666bbbbbbb33bb3bbbbbbbbbbb000007700007007000007777770007700000000000000000000000000
00700700cc7ccccccccccccc44444444000000005556655500000000bb3bb3bb0000000000000000000000000007000777000700000000000000000000000000
000000007ccccccccccc7c7c994499940000000066566566b0b030b0b3bbbbbbb0b030b007000070000700000077007707700700000000000000000000000000
00000000c7ccccc7ccccc7cc94444444000000006656656630b0b0b0bbbbbbbb30b0b0b070000000000070000077777007777700000000000000000000000000
33333333499444443344443349944444333b333300000000bb3bbb3b603bbb3b6000000000077700070000000070770007000000000000000000000000000000
3333333344444944334444334444494433b3b3b360506060b3bbbbbb60bbbbbb6050606000777700777007007770077707000000000000000000000000000000
33333333949444993344443394944499333bbb3b50506050bb3bb3bb503bb3bb5050605000677760670076007777777777000000000000000000000000000000
333333333344443333444433333333333b3b3bb3bbbbbbb03bb3bbbb60b3bbbb60bbbbb300066600000677707077770000000077000000000000000000000000
3333333333444433334444333333333333b3bb3b3bb3bbb0bbbbbbb360bbbbb360b3bbbb07000000000067600770070000000770000000000000000000000000
333333333344443333444433333333333b3bb3b3bb3bb3b0bb3bbbbb50000000503bb3bb06700006000006007777770000077700000000000000000000000000
33333333334444333344443333333333333b3333b3bbbbb0bbbb3bbb60b030b060bbbbbb00670000700600007700000000070700000000000000000000000000
333333333344443333444433333333333333b333bbbbbbb03bbbb3bb60b0b0b060bbbbbb00060000000000000000000000777700000000000000000000000000
ccccccccccccccc77777777ccccccccccc77cccc603bbb3bbb3bbb30000000000000000011111111111111111111111155555555555555550000000000000000
cccccccccccccc77777777ccccccccccc77ccccc60bbbbbbb3bbbbb0000000000000000011111111111111111141141155555555555555550000000000000000
ccccccccccccc77777777ccccccccccc77cccccc503bb3bbbb3bb3b0000000000000000011111111113111111111111155555555555555550000000000000007
cccccccccccc77777777ccccccccccc77ccccccc60b3bbbb3bb3bbb0000000000000000011111111131113111111111155555555555555550000000000077007
ccccccccccc77777777ccccccccccc77cccccccc60bbbbb3bbbbbbb0000000000000000011111111113131111111411455555555555555550000000000707000
cccccccccc77777777ccccccccccc77ccccccccc503bbbbbbb3bbbb0000000000000000011111111131113111411111155555555555555550000000000770070
ccccccccc77777777ccccccccccc77cccccccccc60bb3bbbbbbb3bb0000000000000000011111111113131111141141157756675555555550000000007000077
cccccccc77777777ccccccccccc77ccccccccccc60bbb3bb3bbbb3b0000000000000000011111111111111111111111166777776555555550000000000000700
11777711000550001111111117111117cccccccc77777777000000000000000000000000555555550000000000000000cccccccccccccccc0000000000000000
17cccc71005555001111111771111111ccccccccccc7cc7c000000000ee00ee00ee0ee00565557550544445000000000c544445cc15555170000007000000070
7ccc7cc700aaaaa07111117111117111cccccccccccccccc00000000e88ee88ee88e88e0555555550454454005444450c454454cc51551670000700000000700
7cccc7c70055550a1111711117171111cccccccccccccccc00000000e888888ee88888e0555555750445544004544540c445544cc551166c0077070000000770
7cccc7c70055550a1117171111711111cccccccccccccccc00000000e888888e0e888e00555655550445544004455440c445544cc55166570770070000007700
7ccc7cc700aaaa0a1171111111111111cccccccccccccccc000000000e8888e000e8e000555557550454454004455440c454454cc516616c0077700007770700
17cccc71005555a07111111111117171c7cc7ccccccccccc0000000000e88e00000e0000575565550544445004544540c544445cc166561c0000700070077000
1177771100555500171111171111171177777777cccccccc00000000000ee00000000000555555560000000005444450ccccccccc77c7ccc0000000770077007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000900900000000000090000009000000000000550000
00ccc00000cccc0000cccc0000cccc0000cccc0000ccc00000ccc00000cccc0000cccc0000cccc0000cccc9009cccc0000cccc9000ccc90000ccc00009955000
0c44cc000cc444c00cc444c00cc444c00cc444c00ccccc000ccccc000c444cc00c444cc00c444cc00cc9999009999cc00cc999900c9999000c44cc0000555500
cc040cc0ccc040c0ccc040c0ccc040c0ccc040c0ccccccc0ccccccc00c040ccc0c040ccc0c040ccccc966690096669cccc966690c46664c0cc040cc000755500
cc444c00ccc44400ccc44400ccc44400ccc44400cccccc00cccccc0000444ccc00444ccc00444cccccc9990000999ccca4e99900ce999e00cc444c0000775500
0ceeecc00cce4e400ccee0000ccee0000ccee0000cccccc00cccccc0000eecc0000eecc004e4ecc00ccee000000eecc0aaee00000ceeecc00ceee8c000775500
04aaa4c000caa00000c4a00000c4aa0000a4a00004aaa4c004aaa4c0000a4acc000a4ccc000aaccc00c4a000000a4c000000000000aaa0c004aaa2c000755500
00a0a00000a0a000000aa000000a00000000a00000a0a00000a00000000a0000000aa000000a0a00000aa000000aa0000000000000a0a00000a0a80000995000
00005500005550000055500000000000000000000000000000000000000009000000009000000090000000900900000009000000090000000000000000eeee00
00055990005950000055500000ccc00000ccc00000ccc00000ccc00000ccc90000cccc9000cccc9000cccc9009cccc0009cccc0009cccc00000000000eeefee0
0055550000555000005550000c44cc000c44cc000c44cc000ccccc000c9999000cc999900cc999900cc9999009999cc009999cc009999cc0000ee0000edffde0
005557000557550005555500c40404c0cc040cc0cc040cc0ccccccc0c96669c0cc966690cc966690cc966690096669cc096669cc096669cc00eeee000effffe0
005577000577750005555500ce444e00cc444c00cc444c00cccccc00cc999c00ccc99900ccc99900ccc9990000999ccc00999ccc00999ccc0edffde00e666ee0
0055770005777500055555000ceeecc00ceeecc00ceeecc00cccccc00ceeecc00c4ee0000cc4e0000cce4e4004e4ecc004e4ecc0000ee4c000ffff000ebbbbe0
00555700055755000555550000aaa0c004aaa4c004aaa4c004aaa4c004aaa4c000aaa00000caa00000aaa000000aaa00000aac00000aaa00000bb00000ebbe00
00059900009990000095900000a0a0000000a00000a000000000a00000a0a0000000a000000aa0000000a000000a0000000aa000000a0000000cc000000bb000
0000000000444000550000550000000000005535355000000000055353550000000000000001010000eeee0000eeee000e00e00ee00e00e00000000000000000
00222000045f540405500005550000000005535553550000000055355535500005000005000010000ee77ee00ee77ee0e00e00e00e00e00e0000000033000000
2052502200fff00405550555555555000033333333333bb00bb33333333333000550055505555500ee7777eeee7777ee0e00e00ee00e00e00000000073000000
222222200444440400555555555585500535535535535b5bb5b535535535535005555555555555000eeeeee00eeeeee0e00e00e00e00e00e3000330007303300
00222200253440440055555555555555bb33333333333bbbbbb33333333333bb0055555055555550e00e00e00e00e00e0eeeeee00eeeeee03333383000733830
02220220b1c444400555055555567670000bb3333bbb00000000bbb3333bb00000555000555575550e00e00ee00e00e0ee7777eeee7777ee7676333300073333
220220220044400005500000555555000bbbb00000bbb000000bbb00000bbbb00005500050055055e00e00e00e00e00e0ee77ee00ee77ee03333333b0073333b
20002000044044005500000555000000bbb000000bbb00000000bbb000000bbb00000000000000000e00e00ee00e00e000eeee0000eeee000000033307300333
000000406000000600000000060060000333000203350ddd0999000000777700000004400777000044004044e000e0000000944000000bb0000bbbb000000000
0666000460000066900909500e00e0008b830022033333d04549000007777770044400440a57007004440004eeee0000099990440000bbb80bbbb00b00000000
6686604066006660995900900e00e000bbb3022000000300444999007777777745f54004aa777770064640440e0e00009666900400bbbb000bb0000000000000
6666604006556000399309500666600000b32223003f330004999449565777770fff00040777777004f44440eeeeeeee099900040bbbb00000000bb000b3b300
0066604400550555999959900d6d666000b3223333ff000004494449666777770444404407777770044444400eeeeee0044440440bb00000000bbbb003333330
006666640555555505995990066666670bb323303000003004449449077777770044444007777700044444400eeeeee00044444000000bb000bbbb00033b3b30
006666600055555509999950066666670b3b3b303300033004040049007777700044440000a7a000040400400eeeeee000444400b00bbbb08bbb000000333300
0006066000d0d00d0909009006666660030303300333330004040040006000600400440000a0a000040400400e0e00e0040044000bbbb0000bb0000000000000
555555550000000000000000000000000000700000000000a099900a00cccc00000220000002200000002200000000000000000000000000055a550000000000
000000050000000000000000000000077007770770000000999669900cc55cc00002900020029002000022900000000000000000000000000055a00d0555a500
0000000500000000000000000000007cc777c77cc7000000996776900c5665c700022000220220220000220000000000000007000000aa000dddd0dd00555a00
0000000500000000000000000000707ccc7ccc7cc707000009676690cc56557700222200e222222e000222200000000000007770555555a5dd0dddd0cc040cc0
0000000500000000000000000707c77ccc6ccc7cc77c707008966980c2c5578c022222200e2222e02222e2202000000220077772005555a0ddddddd0cc444c00
0000000500000000000000007c7ccc6ccc6ccc6cc7ccc7c700888800cc2288cc22e22e2200e22e00022e22200e2002e00e2772e0005555a00dddd0dd0ceeecc0
0000000500000000000000007c6ccc6cc666c666c6ccc6c7000880000cc88cc02e0929e200092900002222002ee22ee22ee22ee20055550000d0000d04aaa4c0
000000050000000000000000666666666666666666666666008888000c8822c0e022220e002222000009090002eeee2002eeee2000000000000d000000a0a000
00000900000000000000000000000000000aa0a0000000000c111c000c111c0000011000000110000000110000000000000000000000000005ad0000000d0000
000009890000000000000000000a000000a90000000000000c191c000c191c00000190001001900100001190000000000000000000ccc0000dd005ad0dd0000d
000ffff990000000000000000000aa00a09900aaa000a0000c111c000c111c0000011000110110110000110000000000000007000c44cc00000d0dd0000d0dd0
00fffffff000000000000000000009a00989a0098a000a00c1165570c122857000111100c111111c000111100000000000007770cc040cc00000000d0000000d
0ffff999880000000000000000a0098998889098890aaa00c16771c0c16771c0011111100c1111c01111c1101000000110077771cc444cc05ad0000000d00000
ffffff8800000000000000000a90a988888899889a9989a0c17761c0c17761c011c11c1100c11c00011c11100c1001c00c1771c00cee55a5dd0005addd00000d
fff9998ff000000000000000a9999888888888888998889ac55611c0c55611c01c0919c100091900001111001cc11cc11cc11cc104aaa55000d00dd000d00dd0
0ffffffff88000000000000099888888888888888888888907999c0007999c00c011110c001111000009090001cccc1001cccc1000a0a0000000000d0000000d
0000000000000000000f88800000000000000000000000000005500000c11c070055500005555555555555500000000000000000007777000077770000077700
0000f0000000fff00ffff80000000000000a000000a00a00005500050c11cc750059500055595a5a5bb5bb55000000000000000007ccc57007ccc570007ccc70
0f8f0000000ff99fffff9000000000a000a0000000aa000005555055c11117550055500058595a5a5bb5bbb500000000000007007c5555c77c5555c707c55557
ffffff00fffffffffffff90000000a000a9a0a000a000000550555501101551c0582850058595a5a5bb5bbb50000000000007770756665c7756665c707566657
00fffffffff9ffff9999ff800a0000a9a99900a009a0a000555555501115511c0577750058595a5a5bb5bbb59000000990077779765556c7765556707c655567
000ff99ffff099fff000988800a00a9999899999a9900a0005555055c1551c110577750058595a5a5bb5bbb50a9009a00a9779a07c666cc77c666c707cc666c7
0fff9009ffff0999fff800080a9a099898899989999999a000500005075cc0c10557550055595a5a5bb5bb559aa99aa99aa99aa907666c700766670007c66670
00090000900f000099888000a999a988888899889988999a005500000711c00c00999000055555555555555009aaaa9009aaaa90007777000077700000777700
000f0000000800000000000000000000000000000000000008000080000000000000000000000000000000000000000555555555070009770077700700ccc00c
0f8f0000ff88000000000000000000000000000000000000888008880000000000000000000000000000000555555555bbbbbbb570ccc907075557700c666cc0
ffff000ff99fff80000000000000000000000000000000008888888800000000000000000000000555555555bbbbbbb6777bbbb50c99990075555570c66666c0
00ffff0ff9fff98800000000000000000a0000000a00000008882880000000000000000555555555aaaaaaa67777777677777bb5c96669c075757577c65656cc
0ffffff0fff999000000000000000a000090000000a00000888228880000000555555555aaaaaaa6aa777776777777767777bbb5cc999c0075555570c66666c0
09ffffffff9ff0000000000000a000a00a9900000900000a282002825555555599999996aaaaaaa6aaaaaaa6bbbbbbb6bbbbbbb50ceeecc0077777770c555ccc
00f99ff99ffff800000000000900009999999009999000a0020000205888888699999996aaaaaaa6aaaaaaa6bbbbbbb6bbbbbbb504aaa4c000555070006660c0
00f0fff009998880000000009990099899899099989909990000000055555555555555555555555555555555555555555555555570a0a00700000070000000c0
55555555555555555555555555555555004444000044440000000000000000000000000000000044440000000000000000000000000000000000000000000000
5ccccc755bbbb3b5511111455433bbb5044bb4400441144000000000000000000000000000004444444400000000000000000000000000000000000033000000
5cccc7755b3b3bb551311115543bbbb504bbbb4004111140ccccccccbbbbbbbb5555555500004444444400000000000000000000000000000000000073000000
5ccc77c553b33b35531141155433bbb504bbbb4004111140c111111cb333333b5000000500004444444400000000000000b3b00000b3b3003000330007303300
5cc77c755b3333b5513114155433343504bbb94004111940c111111cb333333b5000000500004444444400000000000003333330033333303333383000733830
5555555555555555555555555555555504bbbb4004111140ccccccccbbbbbbbb555555550000444444440000000000000b3b3b3b033b3b307676333300073333
5000000550000005500000055000000504bbbb40041111401cc77cc13bb77bb30557755000004409904400000000000000333000003333003333333b0073333b
5000000550000005500000055000000504bbbb400411114001cccc1003bbbb300055550000009009900900000000000000000000000000000000033307300333
00444400004444000044440000444400000000000000000000000500000005000000050000000000000000000000000005ad0000000d000000000000000dd000
044bb4400443344004433440044cc440000000000000000000000500aa0005aa000005000000000000000000000000000dd005ad0dd0000d0000d00000dd000d
04baab40043aa3400433334004cccc400000055555000000055555500aa55aa000555500000000000000000000000000000d0dd0000d0dd000dd000d0dddd0dd
04babb40043a33400433334004cccc4000005500055000000550505005505050005055000000000000000000000000000000000d0000000d0d0dd0d0dd0dddd0
04baab40043aa3400433394004ccc9400000500000500000050505500aa50aa0005505000000000000000000000000005ad0000000d00000dddddd00ddddddd0
04babb40043a33400433334004cccc40000111000bbb000005555550aa5555aa00555500000000000000000000000000dd0005addd00000d0dddd0d00dddd0dd
04baab40043aa3400433334004cccc40111151000b5bbbbb05655650056556500056550000000000000000000000000000d00dd000d00dd000d0000d00d0000d
04bbbb40043333400433334004cccc4011015cc0335b0b0b0555555005555550005555000000000000000000000000000000000d0000000d000d0000000d0000
0044440000444400004444000044440010011c5553bb000b0aaa00000aaaaaa00000aaa000077700007770000077700000777777777777777777770000000000
044cc44004411440044224400440044000000cc033000000aa00000000000000000000aa00777770077777000777770007722222222222222222277000000000
04caac40041aa140042aa2400400004000000c0003000000a00a7777777777777777a00a00777777777777777777770077277777777777777777727700000000
04cacc40041a1140042a22400400004000000cc033000000a0a777777777777777777a0a07777777777777777777777072777777777777777777772700000000
04caac40041aa140042aa2400400004000000c000300000000777777777777777777770077777777777777777777777772777777777777777777772700000000
04cacc40041a1140042a22400400004000000cc03300000000777777777777777777770077777777777777777777777772777777777777777777772700000000
04caac40041aa140042aa24004000040000000000000000000777777777777777777770067777777777777777777777672777777777777777777772700000000
04cccc40041111400422224004000040000000000000000000777777777777777777770006777777777777777777776072777777777777777777772700000000
0011110000cccc000033330000bbbb0000000000770a0aaa00777777777777777777770000777777777777777777770072777777777777777777772700000000
0010010000c00c000030030000b00b00000000000770000000777777777777777777770007777777777777777777777072777777777777777777772700000000
0011110000cccc000033330000bbbb00000000000777777700777777777777777777770077777777777777777777777772777777777777777777772700000000
00010000000c000000030000000b000000000000a077777700777777777777777777770077777777777777777777777772777777777777777777772700000000
00010000000c000000030000000b00000000000000777777a0a777777777777777777a0a67777777777777777777777672777777777777777777772700000000
00011000000cc00000033000000bb00000000000a0777777a00a7777777777777777a00a06677777677777767777766077277777777777777777727700000000
00010000000c000000030000000b000000000000a0777777aa00000000000000000000aa00067776067777606777600007722222222222222222277000000000
00011100000ccc0000033300000bbb0000000000a07777770aaa00000aaaaaa00000aaa000006660006666000666000000777777777777777777770000000000
__gff__
0043438000810000000500010100000000818180000001000005010101000000050505050500000000010101808001010000434305050000008080808181010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000404000
0000000000000000000000000000000000000040404000000000000000000000000000404040000000000000000000000000004040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000
__map__
20202020202020202c20202020202020000a0a0a000a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161616161616161616161616161616
2020202020202020202020202020202000000000000a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016162625151826251807161815169916
2d2d2020202d2c2c202020202020202000000000000a0a000a0a0a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016162625262516161706161708161616
2d2d2020202d20202020202020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003f0000000000000000000000000000000016162625262516160608162526161616
2d2d2020202d20202c2c0202010202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0c0000000000000000000000000000000016891616161616161616161616161698
2c2c2020202d20200715010101010101000a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f1b1c2f00000000000000000000000000000016161620202016232420162021221616
20202020202c2020162616161616161600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e2e3f2e00000000000000000000000000000016161620202016242020162122201616
202020202020202016261616161616160000000000000a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161616162316201620162216211616
1014101412101014101014141410101012101012101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016731616231616201621162016221616
1410141412101410101010141414101012101012101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161623161616201622162116201616
1010141012131313141210141410141012101010101012140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016167324202016212220162220201616
1012101412141010101214121414101012101313131311130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161616161616161616161616161616
1012141012101410101210121414141012101010101012140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161606060606060606060606061616
1412101011131313131113121014101012141010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016162605050505050505050505052516
101210101210141014121012141010101210141012141210000000000000000000002d2d20202020202d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016162605780505050505050505052516
141203030101010110121412101412101014101012101210000000000000000000002d2d202020a0a1a22d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161607070707070707070707071616
2929030303030303292903030303030329290303030303032a2b292929292b2929002c2c20202020202c2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
29292929292b2b2a29292929292b2b2a29292929292b2b2a2a2a2929292b2b29290032323434343434323200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303292929292b2b0303292929292b2b0303292929292b2b2b2929292929292b290032323232323232323200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
032b2929292b292b032b2929292b292b032b2929292b292b2929292929292929290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2929292929292b2a2929292929292b2a2929292929292b292b2929292929292a0020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2929292929292b29d729292929292b292929292929292b2929292b2929292929290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b29292929292b2bf5e7e7e7e7e7e8e6e7e7e7e7e7e7e8292929292929292b290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b292a292b2b2b2bf6f7f7f7f7f7f8f6f7f7f7f7f7f7d72a2929292929292b2b0020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050500000000050505050501010101012b2b292929292929290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050500000000050505050501010101012929292929292929290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050500000000050505050501010101012929292b2929292a290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050518070707071505050000000020202005050505050505000000000000000000002d2d2d2d2d2d2d2d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050525161616162605050000000020202005050505050505000000000000000000002d2d2d2d2d2d2d2d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05052516161616260505000000002020200505180705071500000000000000000000203d2020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05051706060606080505000000002020200505251601162600000000000000000000203d20202020203d3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050505050505050500000000202020050525160116260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300001d760127601475015750197500e7500b7400270001700047000270002700027000270002700017000170001700017000b70016700167001f7001f700207000e7000b7000a70005700017000270001700
000100000f1500e1500d1500b15009150071500515021150041500415004150071500c1502215026150291502c1502e1502f1502b15027150201501b1500d1500d1500b1500c1500c1500b1500a1500a1500e150
00010000107501c7501b7501a750127501f750147502475014750207501a750147501c7501b7501b75021750177501475025750187501b7501b7501b750187501b750227501e7501c7501f750207501b7501d750
0005000013440164400e4400d4300b42007420044200441000000000001c400000001e400000001f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00001864018630196300b63013630186201065019600000001960019600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000041100a11017110181100c120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00000f75010750107501175011750107500f7500d7000c7000c7000d7000c7000b7000b7000a7000a70009700097000000000000000000000000000000000000000000000000000000000000000000000000
000600001a1501b1501d1501f15021150211502410025100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000973007740077400c740097400c7500d750177501b7501e75022740247402474023730217201e720157101a7301374011740167501675000000000000000000000000000000000000000000000000000
00040000153301d320203301d33018330183301032013320163201932000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000c550125501555017550195501a5501b5501f550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000000000185501b5501b5501c5501d5501e5501f550215501850025500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e00001a4501b4501d4502045000000000002245000000254502645000000274502a4502d450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002a4402c4402b4502a45027450194502544023430214301f4201d4201d4200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a000000000265602b5502c550195401d5302155022560285602c50020500235001e2001f2001f2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000192601c2601e2501f2501f250182500c2400270001700047000270002700027000270002700017000170001700017000b70016700167001f7001f700207000e7000b7000a70005700017000270001700
000f000015250182501c250000002225027250000002a2502e2502e25029250202501725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000010750117501b7501a750127501f750147502475014750207501a750147501c7501b7501b75021750177501475025750187501b7501b7501b750187501b750227501e7501c7501f750207501b7501d750
000700001315014150171501b1501e1501f150211501b15022150281502e1502b150291503400036000370001b0001c0001e0001f000210002800028000280002800019100181000000000000000000000000000
000300001845018450184501b4501d45023450274502a450304501440000000144001440015400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000d250092500a2500b2500c2500e2500c2501025009250142501a250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000161501715017150181502c650191500e6501a1501a1500d6501b150182501c1502b6501d15008650192501f15013650201502a650201502d650201501165020150201501f1501f1501f1501f1501f150
0003000017450194501a450194501a4501c4501d4501d450253001d4001d4001c4002c300000002d3002e3002c300223001330000000000000000000000000000000000000000000000000000000000000000000
000300000d1500c1400712001100111001c700000001d7001f7001f7001a700107000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000f760127601475015750197500e7500b7400270001700047000270002700027000270002700017000170001700017000b70016700167001f7001f700207000e7000b7000a70005700017000270001700
000500000c7400c7300b7200a7100a710097100871007710047500670006700057000570005700057000570005700057000670006700000000000000000000000000000000000000000000000000000000000000
000d0000127501771017710097000e700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
