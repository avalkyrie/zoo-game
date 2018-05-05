pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- game state
startmenu = 1
endmenu = 3
game = 4

introphase = "intro"
outrophase = "outro"
keyitemphase = "keyitem"
gamephase = "game"

state={menu=game,lvl=4,phase=introphase}

maprect = {} -- x, y, width, height, xdrawoffset, ydrawoffset

-- player
player = {}

-- consts
gridsize = 8
dimensions = 16
textwidth = 4

-- sprite indexes
index = {
	player = 64,
	playerscuba = 87,
	death = 191,
	shockdeath = 190,
	
	playerbow = 185,
	playergrad = 169,
	playergradscuba = 168,
	 
	block = 58,
	wblock = 60,

	cexit = 210,
	oexit = 227,

	key = 242,
	key2 = 243,

	tank = 49,
	bow = 182,
	bubble = 48,
	grad = 166,
	pearl = 134,

	monkey = 120,

	lpenguin = 79,
	rpenguin = 80,
	dpenguin = 81,
	dbowpenguin = 183,
	upenguin = 82,
	ubowpenguin = 184,
	
	fwhale = 105,
	bwhale = 104,

	fish = 97,
	gradfish = 167,

	jelly1 = 106,
	jelly2 = 107,
	ujelly1 = 108,
	ujelly2 = 109,

	bturtle = 100,
	fturtle = 101,
	blturtle = 103,
	flturtle = 102,

	rabbit = 115,

	usnake = 124,
	dsnake = 125,

	pbird1 = 136,
	pbird2 = 137,
	pbird3 = 138,
	pnest = 139,
	penest = 140,

	bbird1 = 152,
	bbird2 = 153,
	bbird3 = 154,
	bnest = 155,
	benest = 156,

	ybird1 = 169,
	ybird2 = 170,
	ynest = 171,
	yenest = 172,

	ice = 32,
}

-- text boxes
dialog = {}
dialogindex = 1
hasplayedintro = false
hasplayedkey = false
hasplayedoutro = false

-- sprite flags
fwalkable = 0x1
fwater = 0x2
fice = 0x4
fclimbable = 0x20
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

-- counters
steps = 0
asteps = 0

function _init()
	reload(0x2000, 0x2000, 0x1000) -- reload map tiles

	state.phase = introphase

	-- setup menu items
	if (state.menu == game) then
		menuitem(1, "restart level", function() _init() playsound(1) end)
		menuitem(2, "next level", nextlevel)
	elseif (state.menu == endmenu) then
		menuitem(1, "restart", function() state.menu = startmenu state.lvl = 0 _init() end)
		menuitem(2)
	else 
		menuitem(1)
		menuitem(2)
	end
	
	player.sdx = 0 -- slide direction
	player.sdy = 0
	player.sframe = 0 -- frame of a slide animation
	player.sblock = false -- true if sliding block in front of player
	player.buff = 0 -- buffered key input
	player.animaldelay = 0 -- slight delay after movement before animals move
	player.sprite = index.player
	player.isvertical = false
	player.oxygen = -1
	player.isbubbleslide = false
 	player.helditem = nil
	player.goalsprite = nil
	player.goalneededcount = 0
	player.goalcount = 0
	player.delay = 0
	player.delayfunc = nil

	steps=0
	asteps=0

	dialog = {}
	dialogindex = 1

	-- clear sprites between levels
	sprites = emptyarray(dimensions)
	animals = emptyarray(dimensions)
	blocks = emptyarray(dimensions)

	-- config levels
	if (state.lvl == 0) then
		-- start menu
		maprect = {112, 0, dimensions, dimensions, 0, 0}
		aa(animals, index.rabbit, {2,9,2,10,1,8})
		aa(animals, index.bbird1, {2,5})
		aa(animals, index.pbird2, {15,2,16,5})
		aa(animals, index.monkey, {5,13})
	elseif (state.lvl == 1) then
		-- plaza
		maprect = {0, 24, 10, 8, 3, 3}
		player.x = 6
		player.y = 8
		exit.x = 0
		exit.y = 3
		exit.sprite = index.cexit
		aas(blocks, {198,3,2,199,4,2,198,5,2}) -- trash cans
		aas(sprites, {192,1,7,193,1,4,194,10,7,195,10,4}) -- signs
		--aas(sprites, {197,1,6,196,10,3,196,10,6}) -- static doors
		aas(sprites, {201,2,1,202,6,1})
		aa(animals, index.rabbit, {4,5,6,6})
		aa(sprites, index.key, {4,1})
		dialog[introphase] = {
			{"announcer","birnam zoo will be closing in","in 5 min"},
			{"noah", "finally"},
			{"noah", "closing time. i hope you had a","great time at the zoo!"},
			{"mom", "now kids, what do you say","to noah the zookeeper for","showing us around today?"},
			{"kids", "thank you noah!"},
			{"noah", "no problem, see you next time!"},
			{"noah", "i thought this day would never","end! i can finally go home."},
			{"note on door", "noah, can you","please lock the office when","you're done? had to leave","early. sorry! exhibits should","be locked already!","                    ~karen"},
			{"noah", "of course. perfect.","wait, where are my keys? they","were on my belt a second","ago.."},
			{"noah", "mackers has them! you stupid","monkey, come back here!"}
		}
		dialog[keyitemphase] = {{"noah", "the key to the west garden!","now if i can find mackers..."}}
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
		sprites[2][5] = index.key
		dialog[introphase] = {{"noah", "wait! at least he dropped the","rainforest key before he left."}}
		dialog[keyitemphase] = {{"noah", "the key! guess i can go","back or mess around here for","a bit..."}}
	elseif (state.lvl == 3) then
		-- rainforest 1
		maprect = {0, 8, 8, 8, 4, 4}
		player.isvertical = true
		player.x = 8
		player.y = 1
		exit.x = 0
		exit.y = 7
		exit.sprite = index.cexit
		sprites[3][6] = index.key2
		blocks[6][4] = index.block
		animals[2][5] = index.usnake
		dialog[introphase] = {{"noah", "that snake doesn't look","very friendly..."}}
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
		player.y = 8
		player.oxygen = 6
		player.sprite = index.playerscuba
		exit.x = 1
		exit.y = 0
		exit.sprite = index.cexit
		sprites[8][8] = index.key
		aas(animals, {index.flturtle,7,2,index.blturtle,8,2,index.ujelly1,2,1,index.jelly1,1,1,index.jelly1,6,6})
		aa(sprites, index.tank, {2,3, 7,3, 5,7, 8,6})
		dialog[introphase] = {{"noah", "mackers, when did you learn to","scuba dive?"}}
	elseif (state.lvl == 5) then
		-- aquarium 2 
		maprect = {24, 16, 9, 10, 3.5, 2.5}
		player.x = 5
		player.y = 1
		player.oxygen = 6
		player.sprite = index.playerscuba
		player.goalsprite = index.grad
		player.goalneededcount = 4
		exit.x = 5	  
		exit.y = 0
		exit.sprite = index.oexit
		aa(sprites, index.tank, {4,1,6,1,8,2,1,4,4,5,8,7,3,8,7,10})
		aa(sprites, index.bubble, {6,4,9,9})
		aa(sprites, index.grad, {9,3,6,3,6,7,7,9})
		animals[4][4] = index.fturtle
		animals[3][4] = index.bturtle
		animals[3][7] = index.bturtle
		animals[4][7] = index.fturtle
		aa(animals, index.fish, {8,1,9,1,6,8,7,8})
		aa(animals, index.jelly1, {4,3,5,3,6,6,7,6})
		dialog[introphase] = {
			{"karen", "noah? do you copy? noah?"},
			{"noah", "karen? i'm a bit underwater","at the moment..."},
			{"karen", "you in the aquarium?","perfect!"},
			{"karen", "the schools of fish passed","all their tests today!"},
			{"karen", "can you make sure they","graduate before you leave?","thx!"},
			{"noah", "can't it wait till tomorrow?", "karen?"},
			{"noah", "karen?"},
			{"noah", "oh, well, i'm here anyway..."}
		}
	elseif (state.lvl == 6) then
		-- tundra 1
		maprect = {0, 0, 8, 6, 4, 4}
		player.x = 4
		player.y = 6
		exit.x = 6
		exit.y = 0
		exit.sprite = index.cexit
		sprites[7][4] = index.key
		aa(animals, index.dpenguin, {3,1,4,1,5,1})	
		dialog[introphase] = {{"noah", "stop monkeying around,","the ice is slippery!"}}
	elseif (state.lvl == 7) then
		-- tundra 2
		maprect = {8, 0, 8, 8, 4, 4}
		player.x = 1
		player.y = 3
		player.goalsprite = index.bow
		player.goalneededcount = 3
		exit.x = 6
		exit.y = 9
		exit.sprite = index.oexit
		aa(sprites, index.bow, {2,4,4,2,6,1})
		aa(blocks, index.block, {2,2,6,2})
		aa(animals, index.dpenguin, {3,1,4,1,5,1})
		animals[4][5] = index.bwhale
		animals[3][5] = index.fwhale
		
		dialog[introphase] = {
			{"noah", "i need this day to be over."},
			{"noah", "where is that %$\x8f#\x92 monkey?"},
			{"karen", "noah? are you still at the", "zoo?"},
			{"noah", "yes, karen."},
			{"noah", "i haven't left yet.","i'm just about to leave now-"},
			{"karen", "oh, not yet! please make","sure the penguins are ready","for the evening before you","go. they are in the tundra."},
			{"noah", "i know where the penguins are,","karen. i work here."},
			{"karen", "great! their bowties are in","the tundra too!"},
			{"noah", "bowties? where are these","penguins going, the opera?"},
			{"noah", "karen?"},
		}
		dialog[outrophase] = {{"noah", "penguins looking dapper, great.","time to get out of here...wait,","where is the door back?"}}
	elseif (state.lvl == 8) then
		-- tundra 2
		maprect = {34, 14, 9, 13, 3.5, 1}
		player.x = 4
		player.y = 13
		exit.x = 4
		exit.y = 1
		exit.sprite = index.oexit
		animals[3][5] = index.bwhale
		animals[2][5] = index.fwhale
		animals[8][5] = index.bwhale
		animals[7][5] = index.fwhale
		aa(animals, index.rpenguin, {2,10,2,11,2,12})
		sprites[3][6] = index.pearl
		aa(blocks, index.block, {1,6,6,7,1,8,7,8,8,8,5,9,9,9,9,10,1,11})
		
		dialog[introphase] = {
			{"noah", "oh no! how did the fire","kitsune escape the mythical","creature enclosure! how am i","supposed to reach the door?"},
			{"karen", "i'm here! you almost done","with those penguins?"},
			{"noah", "i don't have time for this,","the fire kitsune is in the","tundra and i can't get to the","door!"},
			{"karen", "that's all? well, you just","need the pearl, the soul of","the kitsune, and to find a","way to freeze it in order","to-"},
			{"noah", "oh, that's it? find the soul","of a kitsune and freeze it?","thanks karen!"}
		}
		dialog[outrophase] = {{"noah", "phew! someone else has got to","thaw that thing out tomorrow.","for now, i'm going home!"}}
	elseif (state.lvl == 9) then
		-- end menu
		maprect = {96, 0, 16, 16, 0, 0}
		aa(animals, 218, {5,8}) -- hat bunny
		aa(animals, 217, {12,8}) -- hat monkey
		aas(sprites, {203,8,7,204,9,7,219,8,8,220,9,8}) --cake
		aas(blocks, {243,5,10,242,5,12,241,5,14}) --keys

		dialog[introphase] = {
			{"noah", "finally, home! i get to enjoy","the rest of my birthday in","peace and quiet!"},
			{"karen and coworkers", "surprise!","happy birthday!"},
			{"noah", "karen? what are you and all","the other zookeepers doing","here? i thought you left","early-"},
			{"karen and coworkers", "we were getting ready for your","party silly. we had to stall!"},
			{"noah", "mackers stealing my keys?"},
			{"coworkers", "that was us."},
			{"noah", "the fish and the penguins?"},
			{"coworkers", "yup. us too!"},
			{"noah", "the fire kitsune?"},
			{"coworkers", "you sound mad..."},
			{"noah", "get out."},
			{"", "           the end"},
		}
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
		movestartmenuanimals()
		
		-- z/x to start game
		if (btn(4) or btn(5)) then
			state.menu = game

			if (state.lvl == 0) state.lvl = 1
			_init()
			return
		end
	end

	if (state.phase != gamephase) then
		if (state.phase == introphase and hasplayedintro == true) then
			state.phase = gamephase
			dialogindex = 1
		elseif (state.phase == keyitemphase and hasplayedkey == true) then
			state.phase = gamephase
			dialogindex = 1
		elseif (state.phase == outrophase and hasplayedoutro == true) then
			state.phase = gamephase
			dialogindex = 1
		elseif (state.phase != gamephase and btnp() > 0) then
			dialogindex += 1

			if (dialog[state.phase] and dialogindex > #dialog[state.phase]) then
				if (state.phase == introphase) hasplayedintro = true
				if (state.phase == keyitemphase) hasplayedkey = true
				if (state.phase == outrophase) hasplayedoutro = true
				state.phase = gamephase
				dialogindex = 1
			end
		end

		if (state.phase == keyitemphase and dialog[keyitemphase] == nil) state.phase = gamephase
	end

	if (state.phase != gamephase) return
	if (state.menu == endmenu) return

	-- delay slightly after player death
	if (player.delay > 0) then
		player.delay -= 1
		return
	end
	if (player.delayfunc != nil) player.delayfunc()

	if (checkdeath()) return

	-- buffer last key press unless we are sliding/falling
	local b = btnp()
	if (b > 0 and player.sdx == 0 and player.sdy == 0) player.buff = b

	-- start sliding for bubble bounces
	if (sprites[player.x][player.y] == index.bubble) then
		player.sdx = 0
		player.sdy = -1
		player.isbubbleslide = true
		sprites[player.x][player.y] = nil
	end

	-- skip player movement while animals are moving
	if (player.animaldelay > 0 and player.isbubbleslide == false) then
		player.animaldelay -= 1
		
		if (player.animaldelay == 0) then
			movepatrolinganimals()
			moverandomanimals()
			breedrabbits()
			checkanimaleaten()
			return
		end

		return
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

				if (player.isbubbleslide) then
					player.animaldelay = 25
					player.isbubbleslide = false
				else
					player.animaldelay = 10
				end
			end
		end
	else
		-- normal player movement
		local b = btnp()
		if (b == 0) b = player.buff
		player.buff = 0

		local dx = 0
		local dy = 0
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
			player.oxygen-=1

			if (player.sdx == 0 and player.sdy == 0) then
				-- didn't start sliding
				playsound(40)
				player.animaldelay = 10
			else
				playsound(39)
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
		if (hasplayedoutro or dialog[state.phase] == nil) then
			nextlevel()
		else
			state.phase = outrophase
		end
	end

	-- animate map tiles
	animatewater()
	animatestaticanimals()

	-- resolve items
	pickup(player.x, player.y)
	updatewornitems()
end

function _draw()
	tick+=1
	if (tick > 2000) tick = 0;

	if (state.menu==startmenu) draw_startmenu()
	if (state.menu==game) draw_level()
	if (state.menu==endmenu) draw_endmenu()
end

function draw_startmenu()
	cls()

	-- draw map
	map(maprect[1], maprect[2], maprect[5]*gridsize, maprect[6]*gridsize, maprect[3], maprect[4])

	-- draw title header
	rectfill(14, 12, 62, 20, 11)
	print ("i t ' s	  a",  16, 14, 1)

	-- blink start text
	rectfill(28, 74, 94, 82, 1)
	if (tick % 120 >= 60) then
		print("press z to start", 30, 76, 13)
	end

	-- draw sprites
	for i=1, dimensions do
		for j=1, dimensions do
			sprgrid(sprites[i][j], i, j)
			sprgrid(animals[i][j], i, j)
			sprgrid(blocks[i][j], i, j)
		end
	end
end

function draw_endmenu()
	cls()

	-- draw map
	map(maprect[1], maprect[2], maprect[5]*gridsize, maprect[6]*gridsize, maprect[3], maprect[4])

	-- draw dialog
	if (state.phase != gamephase and dialog[state.phase]) then
		local d = dialog[state.phase][dialogindex]
		if (d and d[1] == "karen") then
			drawbossbox(d)
		else
			drawbox(d)
		end
	end

	if (state.phase == introphase and dialogindex < 2) return

	-- draw sprites
	for i=1, dimensions do
		for j=1, dimensions do
			sprgrid(sprites[i][j], i, j)
			sprgrid(animals[i][j], i, j)
		end
	end

	if (state.phase == introphase) return

	-- draw keys for our names
	for i=1, dimensions do
		for j=1, dimensions do
			sprgrid(blocks[i][j], i, j)
		end
	end

	local x = 20

	print("thank you for playing our demo!", 3, 6)

	-- draw logo text
	local len = #"weird sisters"
	local logox = (128 - len*textwidth - 1)/2
	local logoy = 24
	rectfill(logox - 5, logoy - 5, logox + len*textwidth + 5, logoy + 22, 5)
	print ("weird sisters\n\n interactive", logox, logoy, 7)

	x = 44
	local y = 75
	print ("ava", x, y, 7)
	print ("rachel", x, y+16, 7)
	print ("jessica", x, y+32, 7)

end

function draw_level()
	cls()

	-- draw map with border
	local ox = maprect[5]*gridsize
	local oy = maprect[6]*gridsize
	local width = 2
	rectfill(ox-width, oy-width, ox+maprect[3]*gridsize+width-1, oy+maprect[4]*gridsize+width-1, 5)
	map(maprect[1], maprect[2], ox, oy, maprect[3], maprect[4])
	
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

	if (player.isbubbleslide) then
		-- swap between the two bubble animations and flip animation every 4 squares
		spr(174 + player.y % 2, pox, poy, 1, 1, flr(player.y/2) % 2 == 0)
	else
		drawoutline(player.sprite, pox, poy)
		spr(player.sprite, pox, poy)
	end

	-- draw block pushed by player one square ahead of the player
	if (player.sblock) spr(index.block, pox+gridsize*player.sdx, poy+gridsize*player.sdy)

	-- oxygen meter
	if (player.oxygen > -1) then
		for i=0, player.oxygen-1 do
			spr(230+i, 8*(15+i-6),0)
			--sprgrid(230+i, maprect[3]+maprect[5]-6+i, maprect[4]+1)
		end
	end

	-- debug
	if (blkmsg != nil and blkmsg != 0) then
		print(blkmsg)
		blkmsg = nil
	end

	-- ui
	local message = "steps " .. steps

	if (player.goalsprite) then
		print(message, 0, 1)

		local goalx = (#message+2) * textwidth
		spr(player.goalsprite, goalx, 0)
		print(player.goalcount .. "/" .. player.goalneededcount, goalx+gridsize+textwidth, 1)
	else 
		print(message)
	end

	-- dialog
	if (state.phase != gamephase and dialog[state.phase]) then
		if (state.phase == introphase and hasplayedintro == true) return
		if (state.phase == keyitemphase and hasplayedkey == true) return
		if (state.phase == outrophase and hasplayedoutro == true) return

		local d = dialog[state.phase][dialogindex]
		if (d and d[1] == "karen") then
			drawbossbox(d)
		else
			drawbox(d)
		end
	end
end

function nextlevel()
	state.lvl += 1
	
	hasplayedintro = false
	hasplayedkey = false
	hasplayedoutro = false
	
	if (state.lvl == 9) state.menu = endmenu
	_init()
end

function drawbossbox(sa)
	drawdialogbox(sa, 244, 245, 246, 247, true)
end

function drawbox(sa)
	drawdialogbox(sa, 248, 248, 249, 250, false)
end

-- sound turned off until someone who actually knows sounds can redo them
function playsound(s)
	--sfx(s)
end

-- number of lines to fit, special top left corner, regular corner, side, top
function drawdialogbox(text, sc, c, s, t, isboss)
	if (text == nil) return

	local xmin = 0
	local xmax = 15
	local ymax = 14
	local ymin = ymax - (#text-1)

	if (isboss) xmin += 1

	-- noah is left aligned, everyone else is right aligned
	local namex = xmin
	if (text[1] != "") then 
		if (text[1] != "noah") then
			local offset = 128 - (#text[1])*textwidth - 7

			local bgcolor = 7
			if (isboss) bgcolor = 10

			rectfill(offset-2, ymin*8-7, 128-7, ymax*8-9, bgcolor)
			print (text[1], offset, ymin*8-6, 0)
		else
			rectfill(xmin*8+7, ymin*8-7, xmin*8 + (#text[1])*textwidth + 9, ymax*8-1, 7)
			print (text[1], xmin*8+9, ymin*8-6, 2)
		end
	end


	for i = 0, 15 do
		for j = 0, 15 do
			local x = i*gridsize
			local y = j*gridsize

			-- corners
			if (i==xmin and j==ymin and isboss) sprflip(sc, x, y, 0)
			if (i==xmin and j==ymin and isboss == false) sprflip(c, x, y, 0)

			if (i==xmin and j==ymax) sprflip(c, x, y, 2)
			if (i==xmax and j==ymin) sprflip(c, x, y, 1)
			if (i==xmax and j==ymax) sprflip(c, x, y, 3)

			-- top and bottom
			if (i>xmin and i<xmax) then
				if (j==ymin) sprflip(t, x, y)
				if (j==ymax) sprflip(t, x, y, 2)
			end

			-- sides
			if (j>ymin and j<ymax) then
				if (i==xmin) sprflip(s, x, y)
				if (i==xmax) sprflip(s, x, y, 1)
			end
		end
	end

	-- background
	rectfill(xmin*8+8, ymin*8+8, xmax*8-1, ymax*8-1, 7)

	-- text (fancy currently disabled)
	printfancytext(false, false, text, xmin, ymin)

	-- radio
	local box = 215
	if (tick % 50 < 25) box = 214
	if (isboss) spr(box, 0, (ymin - 1)*8)

end

function printfancytext(iswavy, israinbow, text, xmin, ymin)
	local color = 12 - (tick / 20) % 4
	if (israinbow == false) color = 0

	for i=2, #text do
		for j=1, #(text[i]) do
			local ywave = 0
			if (iswavy) ywave = flr(cos((tick+j)/35) * 3)
			if (ywave >= 4) ywave = 3

			print (sub(text[i], j, j), xmin*8 + (j-1)*4 + 5, (ymin+(i-2))*8 + 5 + ywave, color)

			if (israinbow == true and c != " ") color += 1
			if (color > 12) color = 8
		end
	end
end

-- draw sprite with flipping, 0 = none, 1 = x, 2 = y, 3 = x+y
function sprflip(s, x, y, r)
	spr(s, x, y, 1, 1, r == 1 or r == 3, r == 2 or r == 3)
end

function animatewater()
	if ((tick % 80) == 1) then 
		for x=1, maprect[3] do
			for y=1, maprect[4] do
				if (mgetspr(x, y) == 1) then
					msetspr(2, x, y)
				elseif(mgetspr(x, y) == 2) then
					msetspr(1, x, y)
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

	for i=1, dimensions do
		for j=1, dimensions do
			if (band(fget(mgetspr(i,j)), fice) > 0) then
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

			-- this doesn't check if we've already drawn at a location since it's less lines of code
			if (sget(px,py) > 0) then
				rect(x+i-1, y+j, x+i+1, y+j, 5)
				rect(x+i, y+j-1, x+i, y+j+1, 5)
			end
		end
	end
end

function emptyarray(dim, defaultval)
	array = {}
	for i = 1, dim do
		array[i] = {}
		for j = 1, dim do
			array[i][j] = defaultval
		end
	end
	return array
end

function sprgrid(s, x, y)
	if (s) spr(s, (x + maprect[5] - 1)*gridsize, (y + maprect[6] - 1)*gridsize)
end

function mgetspr(x, y)
	if (isoutsidemap(x, y)) return

	return mget(x + maprect[1] - 1, y + maprect[2] - 1)
end

function msetspr(s, x, y)
	if (isoutsidemap(x, y)) return

	mset(x+maprect[1]-1, y+maprect[2]-1, s)
end

function isoutsidemap(x, y)
	if (x < 1 or x > maprect[3] or y < 1 or y > maprect[4]) return true
	return false
end

function movepatrolinganimals()
	-- track which animals have already moved
	moved = emptyarray(dimensions, false)

	-- move animals in place from top of grid to bottom of grid
	for i=1, dimensions do
		for j=1, dimensions do
			if (moved[i][j] == false) then 
				local a = animals[i][j]

				-- todo: this is getting out of hand
				if (a == index.dpenguin or a == index.upenguin) then
					moveanimal(a, index.upenguin, index.dpenguin, i, j, false, 8)
				elseif (a == index.dbowpenguin or a == index.ubowpenguin) then
						moveanimal(a, index.ubowpenguin, index.dbowpenguin, i, j, false, 8)
				elseif(a == index.lpenguin or a == index.rpenguin) then
					moveanimal(a, index.lpenguin, index.rpenguin, i, j, true, 8)
				elseif(a == index.usnake or a == index.dsnake) then
					moveanimal(a, index.usnake, index.dsnake, i, j, false, 9)
				end

				if (a==index.fturtle or a==index.flturtle) then
					movebiganimal(a, moved, index.flturtle, index.fturtle, index.blturtle, index.bturtle, i, j, 12)
				end
			end
		end
	end

	asteps += 1
end

function movestartmenuanimals()
	if (tick%50 != 0) return

	moverandomanimals()

	if (tick %100 != 0) breedrabbits()
end

function moverandomanimals()
	-- track which animals have already moved
	moved = emptyarray(dimensions, false)

	-- move animals in place from top of grid to bottom of grid
	for i=1, dimensions do
		for j=1, dimensions do
			animals[i][j] = swap(animals[i][j], index.bbird1, index.bbird2)
			animals[i][j] = swap(animals[i][j], index.pbird1, index.pbird2)
			local a = animals[i][j]

			if (a and moved[i][j] == false and animalmovesrandomly(a)) then
				local dx, dy = randomdirection(i, j)
				local ni = i + dx
				local nj = j + dy
				animals[i][j] = nil
				animals[ni][nj] = a
				moved[ni][nj] = true
			end
		end
	end
end

function animalmovesrandomly(a)
	if (a == index.rabbit or a == index.bbird1 or a == index.bbird2 or a == index.pbird1 or a == index.pbird2 or a == index.monkey) return true
	return false
end

-- returns a dx, dy random delta to move in
function randomdirection(x, y)
	local dx = 0
	local dy = 0

	-- randomly pick l/r or u/d to move in
	if (flr(rnd(2)) == 0) then 
		dx = flr(rnd(3)-1)
	else
		dy = flr(rnd(3)-1)
	end

	if (acanmove(x, y, dx, dy)) return dx, dy
	return 0, 0
end

function movebiganimal(a, moved, lf, rf, lb, rb, i, j)
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
		animals[i+dx][j+dy] = animals[i][j]
		animals[i][j] = nil
		moved[i+dx][j+dy] = true
	else
		animals[i][j] = flipped
	end

	if (fx) playsound(fx)

end

-- returns (sprite, sfx) if picked up
function canpickup(x, y)
	if (isoutsidemap(x, y)) return nil

	local s = sprites[x][y]

	-- instants
	if (s == index.key or s == index.key2) return s, 24
	if (s == index.tank) return s, 22
	
	-- useable items
	if (player.helditem) return false
	
	if (s == index.bow) return s, 22
	if (s == index.grad) return s, 22

	return false
end

function pickup(x, y)
	if (isoutsidemap(x, y)) return nil

	local s, fx = canpickup(x,y)

	if (s) then
		sprites[x][y] = nil
		
		if (s == index.bow) then
			player.helditem = s
			player.sprite = index.playerbow
		end
		
		if (s == index.grad) then
			player.helditem = s
			player.sprite = index.playergradscuba
		end
		
		playsound(fx)
	end

	if (s == index.tank) player.oxygen = 6

	if (s == index.key or s == index.key2) then
		exit.sprite = index.oexit

		state.phase = keyitemphase
		dialogindex = 1
	end

	return s
end

function acanmove(ax, ay, dx, dy)
	if (dx == 0 and dy == 0) return false

	local x = ax + dx
	local y = ay + dy

	if (isoutsidemap(x, y)) return false

	local s = mgetspr(x, y)
	local flags = fget(s)

	if (animals[x][y]) return false
	if (blocks[x][y]) return false
	
	if (canwearitem(ax, ay, sprites[x][y])) return true
	
	if (sprites[x][y]) return false
	if (player.x == x and player.y == y) return false
	if (band(flags, fwater) > 0) return false
	if (band(flags, fwalkable) > 0) return true

	return false
end


function updatewornitems()
	-- try to take item from the player first, then from environment
	iterateadjacent(function(x, y) 
		if (wearitem(x, y, player.helditem)) then
			player.helditem = nil
			player.goalcount += 1

			if (player.sprite == index.playergradscuba) then
				player.sprite = index.playerscuba
			else
				player.sprite = index.player
			end
		end
	end, player.x, player.y)
	
	for i=1, maprect[3] do
		for j=1, maprect[4] do
			if (wearitem(i, j, sprites[i][j])) then
				sprites[i][j] = nil
				player.goalcount += 1
			end
		end
	end
end

function iterateadjacent(f, x, y)
	if (x <= maprect[3]) then
		f(x+1, y)
	end
	if (x > 0) then
		f(x-1, y)
	end
	if (y <= maprect[4]) then
		f(x, y+1)
	end
	if (y > 0) then
		f(x, y-1)
	end
end

-- returns returns true if the animal wears the item
function canwearitem(x, y, item)
	if (isoutsidemap(x, y)) return false

	if (item == nil) return false
	local s = animals[x][y]
	
	if (s == index.upenguin or s == index.dpenguin and item == index.bow) then
		return true
	end
	
	if (s == index.fish and item == index.grad) then
		return true
	end
	
	return false
end

function wearitem(x, y, item)
	if (isoutsidemap(x, y)) return false

	if (item == nil) return false
	local s = animals[x][y]
	
	if (s == index.upenguin or s == index.dpenguin and item == index.bow) then
		if (s == index.upenguin) animals[x][y] = index.ubowpenguin
		if (s == index.dpenguin) animals[x][y] = index.dbowpenguin
		return true
	end
	
	if (s == index.fish and item == index.grad) then
		animals[x][y] = index.gradfish
		return true
	end
	
	return false
end

function checkanimalattack()
	local killsfx = 0

	local killedbyjelly = false
	local killed = false

	for i=1, maprect[3] do
		for j=1, maprect[4] do
			local a = animals[i][j]
			if (band(fget(a), fdeath) > 0) then
				-- check 4 adjacent squares to animal for the player
				iterateadjacent(function(x, y) 
					if (x == player.x and y == player.y) killed = true 
				end, i, j)
			end

			-- jelly death
			if (a==index.ujelly1 or a==index.ujelly2 or a==index.jelly1 or a==index.jelly2) then
				if ((player.x==i-1 or player.x==i+1) and player.y==j) killedbyjelly = true
				if (a==index.ujelly1 or a==index.ujelly2) then
					if (player.y==j-1 and player.x==i) killedbyjelly = true
				else
					if (player.y==j+1 and player.x==i) killedbyjelly = true
				end
			end
		end
	end

	if (killedbyjelly) return true, true
	if (killed) return true, false
	return false, false
end

function isjelly(x, y)
	if (isoutsidemap(x, y)) return false

	local a = animals[x][y]
	if (a==index.ujelly1 or a==index.ujelly2 or a==index.jelly1 or a==index.jelly2) return true
	return false
end

function isturtle(x, y)
	if (isoutsidemap(x, y)) return false

	local a = animals[x][y]
	if (a==index.fturtle or a==index.flturtle or a==index.bturtle or a==index.blturtle) return true
	return false
end

function checkanimaleaten()
	local eatsfx = 0

	-- doesn't handle cases where there are chains of predators
	for i=1, maprect[3] do
		for j=1, maprect[4] do
			local a = animals[i][j]
			
			if (a == index.fturtle and isjelly(i+1, j)) then
				animals[i+1][j] = nil
				eatsfx = 15
			elseif (a == index.flturtle and isjelly(i-1, j)) then
				animals[i-1][j] = nil
				eatsfx = 15
			end
		end
	end

	if (eatsfx > 0) then
		playsound(eatsfx)
		return true
	end

	return false
end

-- the cirrrrclleeeeee of lifeeeeeee
function breedrabbits()
	-- track which animals have already bred
	local bred = emptyarray(dimensions, false)

	local count = 0
	for i=1, dimensions do
		for j=1, dimensions do
			if (animals[i][j]) count += 1
		end
	end

	-- todo: make this behave more like the game of life (too many nearby rabbits will prohibit more rabbits, [maybe not kill any though])
	if (count > 50) return

	for i=1, dimensions do
		for j=1, dimensions do
			local a = animals[i][j]
			if (a==index.rabbit and bred[i][j] == false) then
				iterateadjacent(function(x, y) trytobreed(a, bred, i, j, x, y) end, i, j)
			end
		end
	end
end

function trytobreed(animal, bred, x, y, nx, ny)
	if (isoutsidemap(x, y) or isoutsidemap(nx, ny)) return

	if (bred[nx][ny] == false and animal == animals[nx][ny]) then
		if (placechild(bred, nx, ny) or placechild(bred, x, y)) then
			bred[x][y] = true
			bred[nx][ny] = true
			return true
		end
	end

	return false
end

function placechild(bred, x, y)
	if (acanmove(x, y, -1, 0)) then
		animals[x-1][y] = index.rabbit
		bred[x-1][y] = true
		return true
	elseif(acanmove(x, y, 1, 0)) then
		animals[x+1][y] = index.rabbit
		bred[x+1][y] = true
		return true
	elseif(acanmove(x, y, 0, -1)) then
		animals[x][y-1] = index.rabbit
		bred[x][y-1] = true
		return true
	elseif(acanmove(x, y, 0, 1)) then
		animals[x][y+1] = index.rabbit
		bred[x][y+1] = true
		return true
	end

	return false
end

function killplayer(s, isshock)
	if (s) playsound(s)

	--blkmsg = "death"
	player.delay = 60
	player.sprite = index.death
	if (isshock) player.sprite = index.shockdeath
	player.delayfunc = _init
end

function checkdeath()
	-- death by map sprite (e.g. water tile, fire)
	local s = mgetspr(player.x, player.y)
	if (band(fget(s), fdeath) > 0) then
		killplayer(21)
		return true
	end

	-- death by animal
	local killed, jellykilled = checkanimalattack()
	if (killed or jellykilled) then
		killplayer(1, jellykilled)
		return true
	end

	-- death from nitrogen
	if (player.oxygen == 0) then
		killplayer()
		return true
	end

	return false
end

-- check if transitioning between these two blocks is a slide movement
function moveisslide(x, y, dx, dy)	
	if (band(fget(mgetspr(x, y)), fice) > 0 or band(fget(mgetspr(x+dx, y+dy)), fice) > 0) return true 
	return false
end

function isblock(x, y)
	if (isoutsidemap(x, y)) return false

	if (blocks[x][y]) return true
	return false
end

function canpushblockto(x, y, flags)
	if (isoutsidemap(x, y)) return false

	if (animals[x][y]) return false
	if (blocks[x][y]) return false
	if (sprites[x][y]) return false
	if (band(flags, fwalkable) > 0) return true
	if (band(flags, fwater) > 0) return true
	if (band(flags, fice) > 0) return true
	return false
end

function vcanpushblockto(x, y, flags)
	if (isoutsidemap(x, y)) return false

	if (animals[x][y]) return false
	if (blocks[x][y]) return false
	if (sprites[x][y]) return false
	
	return true
end

function canwalkto(x, y, flags)
	if (isoutsidemap(x, y)) return false

	if (animals[x][y]) return false
	if (blocks[x][y]) return true
	if (sprites[x][y] and sprites[x][y] == index.bubble) return true
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

	if (isoutsidemap(x, y)) return false

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
				--	playsound(27, 1)
				--else
				--	playsound(29, 1) -- into water
				--end
				
				blocks[nx][ny] = blocks[x][y]
				blocks[x][y] = nil
			end
		else
			return false
		end
	end

	-- try to move a turtle vertically
	if (isturtle(x, y) and player.isbubbleslide == false) then
		if (canpushblockto(nx, ny, nflags)) then
			local a = animals[x][y]
			local deltax = 0
			if (a == index.fturtle or a == index.blturtle) deltax = -1
			if (a == index.flturtle or a == index.bturtle) deltax = 1

			if (canpushblockto(nx+deltax, ny, fget(mgetspr(nx+deltax, ny)))) then
				animals[nx][ny] = animals[x][y]
				animals[x][y] = nil

				animals[nx+deltax][ny] = animals[x+deltax][y]
				animals[x+deltax][y] = nil
			end
		else
			return false
		end
	end

	-- if we are being propelled by a bubble, stop when we hit sprites
	if (player.isbubbleslide == true and (isturtle(x, y))) return false

	-- if we are sliding and not currently on ice, stop moving
	if (player.isbubbleslide == false and (player.sdx != 0 or player.sdy != 0) and band(fget(mgetspr(player.x,player.y)), fice) == 0) return false


	-- if we are sliding and now standing on an item, stop moving
	if ((player.sdx != 0 or player.sdy != 0) and canpickup(player.x, player.y)) return false

	-- normal slide or walk
	if (canwalkto(x, y, flags)) then
		if (moveisslide(player.x, player.y, dx, dy) or player.isbubbleslide) then
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

function standable(x, y)
	local flags = fget(mgetspr(x, y))
	if (band(flags, fstandable) > 0) return true

	if (blocks[x][y]) return true

	return false
end

function climbable(x, y)
	local flags = fget(mgetspr(x, y))
	if (band(flags, fclimbable) > 0) return true
	return false
end

-- vertical movement, returns true if the player can move
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

	-- check for exit tile (may be out of bounds)
	if (x == exit.x and y == exit.y and exit.sprite == index.oexit and player.sblock == false) then
		player.x = x
		player.y = y
		return true
	end

	-- check if out of bounds
	if (isoutsidemap(x, y)) return false

	-- stop falling if we can stand here, otherwise keep falling
	if (player.sdy > 0) then
		if (standable(player.x, player.y+1)) return false
		
		return true
	end

	-- try to push blocks
	if (isblock(x, y) and dy == 0) then
		if (vcanpushblockto(nx, ny, nflags)) then
			-- let the block fall if we pushed it off a cliff
			if (standable(nx, ny+1) == false) then
				for i=1, maprect[4] do
					if (standable(nx, i)) break
					blocks[nx][i-1] = nil
					blocks[nx][i] = blocks[x][y]
				end
			else
				blocks[nx][ny] = blocks[x][y]
			end

			blocks[x][y] = nil
		else
			return false
		end
	end

	-- try to climb
	if (dy != 0) then
		if (canwalkto(x, y, flags) and vcanpushblockto(x, y, flags) and s != index.wblock) then
			player.x += dx
			player.y += dy
			return true
		end
	end

	-- try to move left or right
	if (dx != 0) then
		-- look forward and below to see if we can stand there
		local bx = player.x+dx
		local by = player.y+1
		local bs = mgetspr(bx, by)
		local bflags = fget(bs)

		-- standable map tiles
		if (standable(bx, by) or climbable(x, y)) then
			player.x += dx
			return true
		else
			-- fall off ledge
			player.x += dx
			player.sdx = 0
			player.sdy = 1
			return true
		end
	end

	return false
end

__gfx__
00000000ccccccccc7ccccc7444444490000000066566566bb3bbb3b00000000bb3bbb3070000000000000070000000770077007000000000000000000000000
00000000ccccccc77ccccccc944944490000000066566566b3bbbbbb60506060b3bbbbb000007700007007000000000700007077aaaaaaaaaaaaaaaaaaaaaaaa
007007007ccccc7ccccc7ccc449944440000000055566555bb3bb3bb50506050bb3bb3b000077070000770000000000707777770aa000aa000aa000aa000aaaa
00077000cccc7cccc7c7cccc4444444400000000666666663bb3bbbbbbbbbbb33bb3bbb000070770000770000000007777077000a000aa000aa000aa000aaaaa
00077000ccc7c7cccc7ccccc444994440000000066666666bbbbbbb33bb3bbbbbbbbbbb000007700007007000007777770007700000aa000aa000aa000aaaaaa
00700700cc7ccccccccccccc44444444000000005556655500000000bb3bb3bb000000000000000000000000000700077700070000aa000aa000aa000aaaaaaa
000000007ccccccccccc7c7c994499940000000066566566b0b030b0b3bbbbbbb0b030b007000070000700000077007707700700aaaaaaaaaaaaaaaaaaaaaaaa
00000000c7ccccc7ccccc7cc94444444000000006656656630b0b0b0bbbbbbbb30b0b0b070000000000070000077777007777700000000000000000000000000
33333333499444443344443349944444333b333300000000bb3bbb3b603bbb3b6000000000077700070000000070770007000000000000000000000000000000
3333333344444944334444334444494433b3b3b360506060b3bbbbbb60bbbbbb6050606000777700777007007770077707000000aaaaaaaaaaaaaaaa00000000
33333333949444993344443394944499333bbb3b50506050bb3bb3bb503bb3bb5050605000677760670076007777777777000000aaaaaaaaaaaaaaaa00000000
333333333344443333444433333333333b3b3bb3bbbbbbb03bb3bbbb60b3bbbb60bbbbb300066600000677707077770000000077aaaaaaaaaaaaaaaa00000000
3333333333444433334444333333333333b3bb3b3bb3bbb0bbbbbbb360bbbbb360b3bbbb07000000000067600770070000000770aaaaaaaaaaaaaaaa00000000
333333333344443333444433333333333b3bb3b3bb3bb3b0bb3bbbbb50000000503bb3bb06700006000006007777770000077700aaaaaaaaaaaaaaa000000000
33333333334444333344443333333333333b3333b3bbbbb0bbbb3bbb60b030b060bbbbbb00670000700600007700000000070700aaaaaaaaaaaaaaaa00000000
333333333344443333444433333333333333b333bbbbbbb03bbbb3bb60b0b0b060bbbbbb00060000000000000000000000777700000000000000000000000000
cccccccc00000007777777700000000000770000603bbb3bbb3bbb30bbbbbbbbbbbbbbbb11111111111111111111111155555555555555550000000000000000
cccccccc0000007777777700000000000770000060bbbbbbb3bbbbb0b3bbebbbb3bbb9bb11111111111111111141141155555555555555550000000000000000
cccccccc00000777777770000000000077000000503bb3bbbb3bb3b0bbbeaebbbbbb9a9b11111111113111111111111155555555555555550000000000000007
cccccccc0000777777770000000000077000000060b3bbbb3bb3bbb0bebbebbbbbbbb9bb11111111131113111111111155555555555555550000000000077007
cccccccc0007777777700000000000770000000060bbbbb3bbbbbbb0bbbbbbbbbb9bbbbb11111111113131111111411455555555555555550000000000707000
cccccccc00777777770000000000077000000000503bbbbbbb3bbbb0bbebbb3bb9a9bb3b11111111131113111411111155555555555555550000000000770070
cccccccc0777777770000000000077000000000060bb3bbbbbbb3bb0bbb3bbbbbb9b3bbb11111111113131111141141157756675555555550000000007000077
cccccccc7777777700000000000770000000000060bbb3bb3bbbb3b0bbbbbbbbbbbbbbbb11111111111111111111111166777776555555550000000000000700
11777711000550001111111117111117cccccccc77777777bbbbbbbb0000000000000000555555550000000000000000cccccccccccccccc0000000000000000
17cccc71005555001111111771111111ccccccccccc7cc7cbbbbbbbb0ee00ee00ee0ee00565557550544445000000000c544445cc15555170000007000000070
7ccc7cc700aaaaa07111117111117111ccccccccccccccccbb3bbbbbe88ee88ee88e88e0555555550454454005444450c454454cc51551670000700000000700
7cccc7c70055550a1111711117171111ccccccccccccccccbbbbbbbbe888888ee88888e0555555750445544004544540c445544cc551166c0077070000000770
7cccc7c70055550a1117171111711111ccccccccccccccccbbbbbbbbe888888e0e888e00555655550445544004455440c445544cc55166570770070000007700
7ccc7cc700aaaa0a1171111111111111ccccccccccccccccbbbbbb3b0e8888e000e8e000555557550454454004455440c454454cc516616c0077700007770700
17cccc71005555a07111111111117171c7cc7cccccccccccbb3bbbbb00e88e00000e0000575565550544445004544540c544445cc166561c0000700070077000
1177771100555500171111171111171177777777ccccccccbbbbbbbb000ee00000000000555555560000000005444450ccccccccc77c7ccc0000000770077007
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000900900000000000090000009000000000000550000
00ccc00000cccc0000cccc0000cccc0000cccc0000ccc00000ccc00000cccc0000cccc0000cccc0000cccc9009cccc0000cccc9000ccc9000000000009955000
0c44cc000cc444c00cc444c00cc444c00cc444c00ccccc000ccccc000c444cc00c444cc00c444cc00cc9999009999cc00cc999900c9999000000000000555500
cc040cc0ccc040c0ccc040c0ccc040c0ccc040c0ccccccc0ccccccc00c040ccc0c040ccc0c040ccccc966690096669cccc966690c46664c00000000000755500
cc444c00ccc44400ccc44400ccc44400ccc44400cccccc00cccccc0000444ccc00444ccc00444cccccc9990000999ccca4e99900ce999e000000000000775500
0ceeecc00cce4e400ccee0000ccee0000ccee0000cccccc00cccccc0000eecc0000eecc004e4ecc00ccee000000eecc0aaee00000ceeecc00000000000775500
04aaa4c000caa00000c4a00000c4aa0000a4a00004aaa4c004aaa4c0000a4acc000a4ccc000aaccc00c4a000000a4c000000000000aaa0c00000000000755500
00a0a00000a0a000000aa000000a00000000a00000a0a00000a00000000a0000000aa000000a0a00000aa000000aa0000000000000a0a0000000000000995000
00005500005550000055500000000000000000000000000000000000000009000000009000000090000000900900000009000000090000000000000000eeee00
00055990005950000055500000ccc00000ccc00000ccc00000ccc00000ccc90000cccc9000cccc9000cccc9009cccc0009cccc0009cccc00000000000eeefee0
0055550000555000005550000c44cc000c44cc000c44cc000ccccc000c9999000cc999900cc999900cc9999009999cc009999cc009999cc0000ee0000edffde0
005557000557550005555500c40404c0cc040cc0cc040cc0ccccccc0c96669c0cc966690cc966690cc966690096669cc096669cc096669cc00eeee000effffe0
005577000577750005555500ce444e00cc444c00cc444c00cccccc00cc999c00ccc99900ccc99900ccc9990000999ccc00999ccc00999ccc0edffde00e666ee0
0055770005777500055555000ceeecc00ceeecc00ceeecc00cccccc00ceeecc00c4ee0000cc4e0000cce4e4004e4ecc004e4ecc0000ee4c000ffff000ebbbbe0
00555700055755000555550000aaa0c004aaa4c004aaa4c004aaa4c004aaa4c000aaa00000caa00000aaa000000aaa00000aac00000aaa00000bb00000ebbe00
00059900009990000095900000a0a0000000a00000a000000000a00000a0a0000000a000000aa0000000a000000a0000000aa000000a0000000cc000000bb000
00000000000dd000550000550000000000005535355000000000055353550000000000000001010000eeee0000eeee000e00e00ee00e00e00000000000000000
0022200000dd000d05500005550000000005535553550000000055355535500005000005000010000ee77ee00ee77ee0e00e00e00e00e00e0000000033000000
205250220dddd0dd05550555555555000033333333333bb00bb33333333333000550055505555500ee7777eeee7777ee0e00e00ee00e00e00000000073000000
22222220dd0dddd000555555555585500535535535535b5bb5b535535535535005555555555555000eeeeee00eeeeee0e00e00e00e00e00e3000330007303300
00222200ddddddd00055555555555555bb33333333333bbbbbb33333333333bb0055555055555550e00e00e00e00e00e0eeeeee00eeeeee03333383000733830
022202200dddd0dd0555055555567670000bb3333bbb00000000bbb3333bb00000555000555575550e00e00ee00e00e0ee7777eeee7777ee7676333300073333
2202202200d0000d05500000555555000bbbb00000bbb000000bbb00000bbbb00005500050055055e00e00e00e00e00e0ee77ee00ee77ee03333333b0073333b
20002000000d00005500000555000000bbb000000bbb00000000bbb000000bbb00000000000000000e00e00ee00e00e000eeee0000eeee000000033307300333
000000406000000600000000060060000333000203350ddd0999000000777700000004400777000044004044e000e00000000bb0000bbbb00000000000000000
0666000460000066900909500e00e0008b830022033333d04549000007777770044400440a57007004440004eeee00000000bbb80bbbb00b0000000000000000
6686604066006660995900900e00e000bbb3022000000300444999007777777745f54004aa777770064640440e0e000000bbbb000bb000000000000000000000
6666604006556000399309500666600000b32223003f330004999449565777770fff00040777777004f44440eeeeeeee0bbbb00000000bb000b3b00000b3b300
0066604400550555999959900d6d666000b3223333ff000004494449666777770444404407777770044444400eeeeee00bb00000000bbbb00333333003333330
006666640555555505995990066666670bb323303000003004449449077777770044444007777700044444400eeeeee000000bb000bbbb000b3b3b3b033b3b30
006666600055555509999950066666670b3b3b303300033004040049007777700044440000a7a000040400400eeeeee0b00bbbb08bbb00000033300000333300
0006066000d0d00d0909009006666660030303300333330004040040006000600400440000a0a000040400400e0e00e00bbbb0000bb000000000000000000000
555555550000000000000000000000000000700000000000a099900a00cccc000002200000022000000022000000000000000000000000000000000000000000
000000050000000000000000000000077007770770000000999669900cc55cc00002900020029002000022900000000000000000000000000000000000000000
0000000500000000000000000000007cc777c77cc7000000996776900c5665c70002200022022022000022000000000000000700000000000000000000000000
0000000500000000000000000000707ccc7ccc7cc707000009676690cc56557700222200e222222e000222200000000000007770000000000000000000000000
0000000500000000000000000707c77ccc6ccc7cc77c707008966980c2c5578c022222200e2222e02222e2202000000220077772000000000000000000000000
0000000500000000000000007c7ccc6ccc6ccc6cc7ccc7c700888800cc2288cc22e22e2200e22e00022e22200e2002e00e2772e0000000000000000000000000
0000000500000000000000007c6ccc6cc666c666c6ccc6c7000880000cc88cc02e0929e200092900002222002ee22ee22ee22ee2000000000000000000000000
000000050000000000000000666666666666666666666666008888000c8822c0e022220e002222000009090002eeee2002eeee20000000000000000000000000
00000900000000000000000000000000000aa0a00000000000000000000000000001100000011000000011000000000000000000000000000044400000009440
000009890000000000000000000a000000a90000000000000000000000000000000190001001900100001190000000000000000000000000045f540409999044
000ffff990000000000000000000aa00a09900aaa000a000000000000000000000011000110110110000110000000000000007000000000000fff00496669004
00fffffff000000000000000000009a00989a0098a000a00000000000000000000111100c111111c000111100000000000007770000000000444440409990004
0ffff999880000000000000000a0098998889098890aaa000000000000000000011111100c1111c01111c1101000000110077771000000002534404404444044
ffffff8800000000000000000a90a988888899889a9989a0000000000000000011c11c1100c11c00011c11100c1001c00c1771c000000000b1c4444000444440
fff9998ff000000000000000a9999888888888888998889a00000000000000001c0919c100091900001111001cc11cc11cc11cc1000000000044400000444400
0ffffffff8800000000000009988888888888888888888890000000000000000c011110c001111000009090001cccc1001cccc10000000000440440004004400
0000000000000000000f888000000000000000000000000000000000055a55000555a55000000000000000000000000000000000007777000077770000077700
0000f0000000fff00ffff80000000000000a000000a00a000000aa000055a00d00555a000555a50000000000000000000000000007ccc57007ccc570007ccc70
0f8f0000000ff99fffff9000000000a000a0000000aa0000555555a50dddd0dd0c99990000555a000000000000000000000007007c5555c77c5555c707c55557
ffffff00fffffffffffff90000000a000a9a0a000a000000005555a0dd0dddd0c96669c0cc040cc0000000000000000000007770756665c7756665c707566657
00fffffffff9ffff9999ff800a0000a9a99900a009a0a000005555a0ddddddd0cc999c00cc444c00000000009000000990077779765556c7765556707c655567
000ff99ffff099fff000988800a00a9999899999a9900a00005555000dddd0dd0ceeecc00ceeecc0000000000a9009a00a9779a07c666cc77c666c707cc666c7
0fff9009ffff0999fff800080a9a099898899989999999a00000000000d0000d04aaa4c004aaa4c0000000009aa99aa99aa99aa907666c700766670007c66670
00090000900f000099888000a999a988888899889988999a00000000000d000000a0a00000a0a0000000000009aaaa9009aaaa90007777000077700000777700
000f00000008000000000000000000000000000000000000080000800055500000555000000000000c111c000c111c0000000000070009770077700700ccc00c
0f8f0000ff8800000000000000000000000000000000000088800888005950000055500000ccc0000c191c000c191c000000000070ccc907075557700c666cc0
ffff000ff99fff80000000000000000000000000000000008888888800555000008880000c44cc000c111c000c111c00000000000c99990075555570c66666c0
00ffff0ff9fff98800000000000000000a0000000a000000088828800582850005555500cc040cc0c1228570c116557000000000c96669c075757577c65656cc
0ffffff0fff999000000000000000a000090000000a00000888228880577750005555500cc444c00c16771c0c16771c000000000cc999c0075555570c66666c0
09ffffffff9ff0000000000000a000a00a9900000900000a2820028205777500055555000ceee8c0c17761c0c17761c0000000000ceeecc0077777770c555ccc
00f99ff99ffff800000000000900009999999009999000a002000020055755000555550004aaa2c0c55611c0c55611c00000000004aaa4c000555070006660c0
00f0fff0099988800000000099900998998990999899099900000000009990000095900000a0a80007999c0007999c000000000070a0a00700000070000000c0
55555555555555555555555555555555004444000044440000000000000000000000000000000044440000000000000000000000000000000000000000000000
5ccccc755bbbb3b5511111455433bbb5044bb440044114400000000000000000000000000000444444440000000000000900000000000000000000000000d000
5cccc7755b3b3bb551311115543bbbb504bbbb4004111140ccccccccbbbbbbbb5555555500004444444400000000000090000000000000000000000000dd000d
5ccc77c553b33b35531141155433bbb504bbbb4004111140c111111cb333333b50000005000044444444000000000000d000000000000000000000000d0dd0d0
5cc77c755b3333b5513114155433343504bbb94004111940c111111cb333333b50000005000044444444000000000000d00000000000000000000000dddddd00
5555555555555555555555555555555504bbbb4004111140ccccccccbbbbbbbb555555550000444444440000000eeeeeeeeee00000000000000000000dddd0d0
5000000550000005500000055000000504bbbb40041111401cc77cc13bb77bb3055775500000440990440000000fffff4fffe000000000000000000000d0000d
5000000550000005500000055000000504bbbb400411114001cccc1003bbbb300055550000009009900900000004ffffff4fe0000000000000000000000d0000
004444000044440000444400004444000000000000000000000005000000050000000500000a0440000a0060000fff4fffffe000000000000000000000000000
044bb4400443344004433440044cc440000000000000000000000500aa0005aa0000050000ee0044000ee060000777777777e00000000000000000000555a500
04baab40043aa3400433334004cccc400000055555000000055555500aa55aa0005555000eee0004000eee60000ff4fff4ffe000000000000000000000555a00
04babb40043a33400433334004cccc40000055000550000005505050055050500050550045f54004000666600004fffffff4e0000000000000000000cc040cc0
04baab40043aa3400433394004ccc9400000500000500000050505500aa50aa0005505000fff00440666d6d007777777777777700000000000000000cc444c00
04babb40043a33400433334004cccc40000111000bbb000005555550aa5555aa005555000044444076666660006666666666660000000000000000000ceeecc0
04baab40043aa3400433334004cccc40111151000b5bbbbb05655650056556500056550000444400766666600000000000000000000000000000000004aaa4c0
04bbbb40043333400433334004cccc4011015cc0335b0b0b05555550055555500055550004404400066666600000000000000000000000000000000000a0a000
0044440000444400004444000044440010011c5553bb000b00000000000000000000000000000000000000055555555500000000000000000000000000000000
044cc44004411440044224400440044000000cc0330000000000000000000000000000000000000555555555bbbbbbb500000000000000000000000000000000
04caac40041aa140042aa2400400004000000c000300000000000000000000000000000555555555bbbbbbb6777bbbb500000000000000000000000000000000
04cacc40041a1140042a22400400004000000cc033000000000000000000000555555555aaaaaaa67777777677777bb500000000000000000000000000000000
04caac40041aa140042aa2400400004000000c00030000000000000555555555aaaaaaa6aa777776777777767777bbb500000000000000000000000000000000
04cacc40041a1140042a22400400004000000cc0330000005555555599999996aaaaaaa6aaaaaaa6bbbbbbb6bbbbbbb500000000000000000000000000000000
04caac40041aa140042aa2400400004000000000000000005888888699999996aaaaaaa6aaaaaaa6bbbbbbb6bbbbbbb500000000000000000000000000000000
04cccc40041111400422224004000040000000000000000055555555555555555555555555555555555555555555555500000000000000000000000000000000
0011110000cccc000033330000bbbb00770a0aaa0aaa0000007777770aaaaaa00077777772777777777777770555555555555550000000000000000000000000
0010010000c00c000030030000b00b0007700000aa000000a07777770000000007722222727777772222222255595a5a5bb5bb55000000000000000000000000
0011110000cccc000033330000bbbb0007777777a00a7777a07777777777777777277777727777777777777758595a5a5bb5bbb5000000000000000000000000
00010000000c000000030000000b0000a0777777a0a77777a07777777777777772777777727777777777777758595a5a5bb5bbb5000000000000000000000000
00010000000c000000030000000b00000077777700777777a07777777777777772777777727777777777777758595a5a5bb5bbb5000000000000000000000000
00011000000cc00000033000000bb000a077777700777777a07777777777777772777777727777777777777758595a5a5bb5bbb5000000000000000000000000
00010000000c000000030000000b0000a077777700777777a07777777777777772777777727777777777777755595a5a5bb5bb55000000000000000000000000
00011100000ccc0000033300000bbb00a07777770077777700777777777777777277777772777777777777770555555555555550000000000000000000000000
__gff__
0043438000810000000500010100000000a1a180000001000005010101000000050505050500000101010101808001010000434305050100008080808181010100000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000040400000
0000000000000000000000000000000000000040404000000000000000000000000000404040000000000000000000000000004040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000
__map__
2d202020202020202c20202020202020000a0a0a000a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936363616161616163616363636161636
2d20202020202020202020202020202000000000000a0a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936362836163636163636363616272716
2c2c2020202d2c2c202020202020202000000000000a0a000a0a0a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916361616163616161616161616362716
20202020202d2020202034343434343400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916162020201624202016202122161636
20202020202c20202d2d02020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916163636231620202016212220163636
34343434343434342d2d020202020202000a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f00002929292929292929292929292929292936363623161620362016221621161616
2c2c2c2c2c2c2c2c363602022836271600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e00002929292929292929292929292929292916362316161620362116203622271636
000000000000000036363627363628270000000000000a0a0a0a0a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916162416281620162236211620163636
1014101412101014101014141410101012101012101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916162020201621222036222020363636
1410141412131313101010141414101012101012101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916163636363636361636361616163636
1012141012101010141210141410141012101010101012140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936160606060606060606060606163636
1012101412141010101214121414101012101313131311130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936260505050505050505050505253616
1012141011131313101210121414141012101010101012140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936260505050505050505050505252716
1412101012101010131113121014101012141010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936160707070707070707070707363616
101203010101010114121012141010101210141012141210000000000000000000002d2d20202020202d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936361627161636363616281616282816
030303030303030310121412101412101014101012101210000000000000000000002d2d202020a0a1a22d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936363627271616163636362816281616
2b29292a292b2929363636363636363600000000000000002a2b292929292b2929002c2c20202020202c2c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2a2929292b2b2a363636363636363600000000000000002a2a2929292b2b29290032323434343434323200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0329292a29292b2b0d0e0f1d1d1e0d0e00000000000000002b2929292929292b290032323232323232323200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
032b2929292b292b0e0f1d1d1d1d1e0d00000000000000002929292929292929290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2929292929292b36363636363636360000000000000000292b2929292929292a0020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2929292929292b293636363636363636000000000000000029292b2929292929290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b29292929292b3636363636363636e6e7e7e7e7e7e7e8292929292929292b290020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b292a292b2b2b363636363636363600000000000000002a2929292929292b2b0020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
