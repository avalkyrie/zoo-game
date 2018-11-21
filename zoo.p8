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

state={menu=game,lvl=10,phase=introphase}

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

	key0 = 239,
	key1 = 240,
	key2 = 241,
	key3 = 242,
	key4 = 243,

	tank = 49,
	bow = 182,
	bubble = 48,
	grad = 166,
	pearl = 134,

	monkey = 120,
	monkeykeys = 158,
	monkeyswim = 159,

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

function _init()
	reload(0x2000, 0x2000, 0x1000) -- reload map tiles

	state.phase = introphase

	-- setup menu items
	if (state.menu == game) then
		menuitem(1, "restart level", function() _init() playsound(1) end)
		menuitem(2, "next level", nextlevel)
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
	player.goal = nil
	player.delay = 0
	player.delayfunc = nil

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
		exit.x = 8
		exit.y = 0
		exit.sprite = index.cexit
		aas(blocks, {198,3,2,199,4,2,198,5,2}) -- trash cans
		--aas(sprites, {192,2,7,193,2,4,194,9,7,195,9,4}) -- signs

		aas(sprites, {195,9,2})
		aas(sprites, {201,2,1,202,6,1, 202,1,1})
		aa(animals, index.rabbit, {4,5,6,6})
		aa(sprites, index.key1, {4,1})
		dialog[introphase] = {
			"noah: *huffs* finally",
			"noah: alright folks, it's closing time!",
			"noah: i hope you had a great time at the zoo! ",
			"mom: now kids what do you say to noah the zookeeper for showing us around today?",
			"kids: thank you noah!",
			"noah: no problem see you next time!",
			"noah: i thought this day would never end! i can finally go home.",
			"<mackers1>",
			"noah: did my boss leave me another one of her \"helpful\" notes. what is it this time...",
			"note on door: noah can you please lock the office when you're done? had to leave early. sorry! exhibits should be locked already!                    ~karen",
			"<mackers2>",
			"noah: of course. perfect. wait where are my keys? they were on my belt a second ago..",
			"<mackers3>",
			"noah: mackers has them! you stupid monkey come back here!",
			"noah: of course. he dropped one of the keys behind the trash cans. let's see if i can manage to grab it without running into those prickly rose bushes."
		}
		
		dialog[keyitemphase] = {"noah: the key to the bunny enclosures! now i have to go through this whole zoo to catch that *#%$ monkey! he went right through this door..."}
		
		player.goal = "goal: collect yellow key"
	elseif (state.lvl == 2) then
		-- w. garden 1
		maprect = {12, 24, 12, 8, 2, 3}
		player.x = 11
		player.y = 4
		exit.x = 13
		exit.y = 5
		exit.sprite = index.cexit
		aa(blocks, index.block, {10,3,10,6, 3,7, 2,5, 3,4, 4,5, 2,4, 2,6,4,3, 5,4,5,5,4,6,4,7,4,8,6,6,6,3})
		aa(animals, index.rabbit, {9,7,11,8,9,1,11,2})
		sprites[3][5] = index.key2
		dialog[introphase] = {
			"<mackers2.1>",
			"noah: wait! at least he dropped the tundra key before he left.",
			"noah: why are all these crates laying in the middle of the bunny enclosure? i am the only one who does any work here?"}
		dialog[keyitemphase] = {"noah: the key to the tundra! guess i can go follow him or mess around here for a bit..."}
		player.goal = "goal: collect pink key"
	elseif (state.lvl == 6) then
		-- rainforest 1
		maprect = {0, 8, 8, 8, 4, 4}
		player.isvertical = true
		player.x = 8
		player.y = 1
		exit.x = 0
		exit.y = 7
		exit.sprite = index.cexit
		sprites[3][6] = index.key1
		blocks[6][4] = index.block
		animals[2][5] = index.usnake
		dialog[introphase] = {
			"noah: it sure is high up here in the trees! there you are mackers!",
			"<mackers6.1>",
			"noah: no wait! i'm scared of heights! get me down!"
		}
		dialog[keyitemphase] = {
			"noah: oh great, it looks like he dropped another key...",
			"noah: right next to that not so friendly looking snake!",
		}
		dialog[outrophase] = {
			"noah: the key to the aquarium! he can't get far! monkeys can't swim...right?"
		}
		player.goal = "goal: collect yellow key"
	elseif (state.lvl == 7) then
		-- aquarium 1 - new
		maprect = {40, 0, 6, 11, 5, 3}
		player.x = 5
		player.y = 1
		player.oxygen = 6
		player.sprite = index.playerscuba
		exit.x = 1
		exit.y = 0
		exit.sprite = index.cexit
		sprites[4][11] = index.key3
		aas(animals, {index.jelly1,2,3,index.jelly2,6,4,index.jelly1,2,6,index.ujelly2,3,10})
		aa(sprites, index.tank, {4,6,5,11,6,8,3,5,3,1})
		dialog[introphase] = {
			"noah: well, i guess *most monkeys* can't swim, but this one can! mackers get back here!",
			"<mackers7.1>",
			"noah: agh. i'm not a great diver but i have to get that key!  good thing all these oxygen tanks are scattered around the aquarium. i wonder if these jellyfish sting..."
		}
		player.goal = "goal: get red key"
	elseif (state.lvl == 8) then
		-- aquarium 1 
		maprect = {0, 16, 8, 8, 4, 4}
		player.x = 1
		player.y = 8
		player.oxygen = 6
		player.sprite = index.playerscuba
		exit.x = 1
		exit.y = 0
		exit.sprite = index.cexit
		sprites[2][1] = index.key3
		aas(animals, {index.flturtle,4,3,index.blturtle,5,3,index.jelly1,2,2,index.jelly1,1,2,index.jelly1,6,7})
		aa(sprites, index.tank, {2,5, 3,6, 5,4})
		dialog[introphase] = {
			"noah: mackers, when did you learn to scuba dive?",
			"<mackers8.1>",
			"noah: oh, one of those stubborn turtles looks hungry. sometimes they just need a push in the right direction...don't we all?",
		}
		dialog[outrophase] = {
			"noah: guess we are going to have to get more jellyfish for the exhibit...but that seems like a problem for tomorrow me.",
		}
		player.goal = "goal: get red key"
	elseif (state.lvl == 9) then
		-- aquarium 2 
		maprect = {24, 16, 9, 10, 3.5, 2.5}
		player.x = 1
		player.y = 1
		player.oxygen = 6
		player.sprite = index.playerscuba
		player.goalsprite = index.grad
		player.goalneededcount = 4
		exit.x = 5	  
		exit.y = 0
		exit.sprite = index.cexit
		aa(sprites, index.tank, {6,1,7,2,1,4,4,5,8,7,3,8,7,10})
		aa(sprites, index.bubble, {6,4,9,9})
		aa(sprites, index.grad, {9,3,6,3,6,7,7,9})
		animals[4][4] = index.fturtle
		animals[3][4] = index.bturtle
		animals[2][7] = index.flturtle
		animals[3][7] = index.blturtle
		aa(animals, index.fish, {8,1,9,1,6,8,7,8})
		aa(animals, index.jelly1, {4,3,5,3,6,6,7,6})
		dialog[introphase] = {
			"<advancescreen2>",
			"noah: i need this day to be over.",
			"noah: where is that %$\x8f#\x92 monkey?",
			"karen: noah? are you still at the zoo?",
			"noah: yes, karen.",
			"noah: i haven't left yet. i'm just about to leave now-",
			"karen: oh, not yet! please make sure the penguins are ready for the evening before you go. they are in the tundra.",
			"noah: i know where the penguins are, karen. i work here.",
			"karen: great! their bowties are in the tundra too!",
			"noah: bowties? where are these penguins going, the opera?",
			"noah: karen?",
			"<9>",
			"noah: ..."
		}
		player.goal = "fish grads:"
	elseif (state.lvl == 3) then
		-- tundra 1
		maprect = {0, 0, 8, 6, 4, 4}
		player.x = 4
		player.y = 6
		exit.x = 6
		exit.y = 0
		exit.sprite = index.cexit
		sprites[7][4] = index.key0
		aa(animals, index.dpenguin, {3,1,4,1,5,1})	
		dialog[introphase] = {
			"<mackers3.1>",
			"noah: stop monkeying around! you're on thin ice mackers!",
			"noah: oh this ice is slippery. how do these cute penguins waddle around so easily?"
			}
		player.goal = "goal: collect red key"
	elseif (state.lvl == 4) then
		-- tundra 2 - new level
		maprect = {27, 0, 11, 8, 2, 2}
		player.x = 4
		player.y = 7
		player.goalsprite = index.bow
		player.goalneededcount = 3
		exit.x = 12
		exit.y = 8
		exit.sprite = index.cexit
		aa(sprites, index.bow, {8,1,7,4,9,6})
		aa(blocks, index.block, {7,5})
		aa(animals, index.dpenguin, {2,6,6,6,10,6})
		dialog[introphase] = {
			"<advancescreen1>",
			"noah: i need this day to be over.",
			"noah: where is that %$\x8f#\x92 monkey?",
			"karen: noah? are you still at the zoo?",
			"noah: yes, karen.",
			"noah: i haven't left yet. i'm just about to leave now-",
			"karen: oh, not yet! please make sure the penguins are ready for the evening before you go. they are in the tundra.",
			"noah: i know where the penguins are, karen. i work here.",
			"karen: great! their bowties are in the tundra too!",
			"noah: bowties? where are these penguins going, the opera?",
			"noah: karen?",
			"<4>",
			"noah: alright little penguins, hold still. i've got to put these bow ties on you.",
			"noah: you're going to look great. ",
		}
		dialog[outrophase] = {
			"<4end>",
			"noah: looking dapper, kids! great. time to get out of here...now where are the rest of my keys",
		}
		player.goal = "goal: bow ties "
	elseif (state.lvl == 5) then
		-- tundra 3
		player.goalsprite = index.bow
		player.goalneededcount = 1
		aa(sprites, index.bow, {4,4})
		aa(animals, index.dpenguin, {2,6})
		maprect = {8, 0, 8, 8, 4, 4}
		player.x = 3
		player.y = 1
		exit.x = 9
		exit.y = 7
		exit.sprite = index.cexit
		aa(blocks, index.block, {5,3,2,8})
		
		dialog[introphase] = {
			"noah: oh wow. how convenient.",
			"noah: my key is on the *other* side of this freezing water.",
			"noah: how am i supposed to get across?",
			"noah: i wonder if these crates float...",
		}
		dialog[outrophase] = {
			"noah: glad those crates could bridge the gap! ",
			"noah: brrr...i didn't realize how cold it was. good thing this is the key to the jungle. i can warm up and hopefully find that monkey!",
		}
		player.goal = "goal: bow tie "
	elseif (state.lvl == 10) then
		-- boss
		maprect = {34, 14, 9, 13, 3.5, 2}
		player.x = 4
		player.y = 8
		exit.x = 4
		exit.y = 0
		exit.sprite = index.cexit
		aas(animals, {index.monkey,6,2})
		aa(blocks, index.block, {5,8,6,11})

		dialog[introphase] = {
			"noah: .."
		}
		dialog[keyitemphase] = {
			"noah: finally!",
			"monkey: the monkey looks defeated."
		}
		player.goal = "goal: get the %\x8f$\x92 monkey"
	elseif (state.lvl == 11) then
		-- end menu
		maprect = {96, 0, 16, 16, 0, 0}
		aa(animals, 218, {5,8}) -- hat bunny
		aa(animals, 217, {12,8}) -- hat monkey
		aas(sprites, {203,8,7,204,9,7,219,8,8,220,9,8}) --cake
		aas(blocks, {243,5,10,242,5,12,241,5,14}) --keys

		dialog[introphase] = {
			"noah: finally, home! i get to enjoy the rest of my birthday in peace and quiet!",
			"karen and coworkers: surprise! happy birthday!",
			"noah: karen? what are you and all the other zookeepers doing here? i thought you left early-",
			"karen and coworkers: we were getting ready for your party silly. we had to stall!",
			"noah: mackers stealing my keys?",
			"coworkers: that was us.",
			"noah: the fish and the penguins?",
			"coworkers: yup. us too!",
			"noah: the fire kitsune?",
			"coworkers: you sound mad...",
			"noah: get out.",
			":             the end",
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
		elseif (state.phase != gamephase and (btnp(4) or btnp(5))) then
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
	iteratemap(
		function(i,j)
			if (blocks[i][j] and band(fget(mgetspr(i,j)), fwater) > 0) then
				blocks[i][j] = nil
				msetspr(index.wblock,i,j)
			end
		end
	)

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

	-- draw ice sheen
	drawice()

	-- draw sprites
	iteratemap(
		function(i,j)
			sprgrid(sprites[i][j], i, j)
			sprgrid(animals[i][j], i, j)
			sprgrid(blocks[i][j], i, j)
		end
	)

	-- draw title header
	rectfill(14, 12, 62, 20, 11)
	print ("i t ' s	  a",  16, 14, 1)

	-- draw subtitle
	rectfill(28, 74, 94, 82, 6)
	print("pico-8 prototype", 30, 76, 1);

	-- blink start text
	rectfill(28, 108, 94, 116, 6)
	if (tick % 120 >= 60) then
		print("press z to start", 30, 110, 1)
	else
		print("press z to start", 30, 110, 3)
	end

end

function draw_endmenu()
	cls()

	-- draw map
	map(maprect[1], maprect[2], maprect[5]*gridsize, maprect[6]*gridsize, maprect[3], maprect[4])

	-- draw dialog
	if (state.phase != gamephase and dialog[state.phase]) then
		local d = dialog[state.phase][dialogindex]
		local dx = splitdialog(d)
		drawbox(dx)
	end

	if (state.phase == introphase and dialogindex < 2) return

	-- draw sprites
	iteratemap(
		function(i,j)
			sprgrid(sprites[i][j], i, j-1.5)
			sprgrid(animals[i][j], i, j-1.5)
		end
	)

	if (state.phase == introphase) return

	-- draw keys for our names
	iteratemap(
		function(i,j)
			sprgrid(blocks[i][j], i+2, j+1)
		end
	)

	local x = 20

	local s1 = "thank you for playing"
	local s2 = "our prototype!"
	print(s1, (128 - #s1 * textwidth) / 2, 58)
	print(s2, (128 - #s2 * textwidth) / 2, 68)

	-- draw logo text
	local len = #"weird sisters"
	local logox = (128 - len*textwidth - 1)/2
	local logoy = 10
	rectfill(logox - 5, logoy - 5, logox + len*textwidth + 5, logoy + 22, 5)
	print ("weird sisters\n\n interactive", logox, logoy, 7)

	x = 60
	local y = 82
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
	iteratemap(
		function(i,j)
			local spr = sprites[i][j];
			if (spr and (spr >= index.key0 and spr <= index.key4)) then
				drawoutline(spr, (i + maprect[5] - 1)*gridsize, (j + maprect[6] - 1)*gridsize)
			end
			
			sprgrid(spr, i, j)
			sprgrid(animals[i][j], i, j)
			sprgrid(blocks[i][j], i, j)
		end
	)

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
			spr(230+i, 8*(10+i),0)
		end
	end

	-- debug
	if (blkmsg != nil and blkmsg != 0) then
		print(blkmsg)
		blkmsg = nil
	end

	-- ui
	if (player.goalneededcount > 0) then
		local goalstring = player.goal .. player.goalcount .. "/" .. player.goalneededcount
		print(goalstring, 0, 2, 6)
		spr(player.goalsprite, #goalstring * textwidth + 2, 1)
	elseif (player.goal) then
		print (player.goal, 0, 2, 6)
	end

	-- dialog
	if (state.phase != gamephase and dialog[state.phase]) then
		if (state.phase == introphase and hasplayedintro == true) return
		if (state.phase == keyitemphase and hasplayedkey == true) return
		if (state.phase == outrophase and hasplayedoutro == true) return

		local d = dialog[state.phase][dialogindex]
		
		local dx = splitdialog(d)
		
		if (dx and dx[1] == "karen") then
			drawbossbox(dx)
		else
			drawbox(dx)
		end
	end
end

function nextlevel()
	state.lvl += 1
	
	hasplayedintro = false
	hasplayedkey = false
	hasplayedoutro = false
	
	if (state.lvl == 11) state.menu = endmenu
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

function splitdialog(text) 
	if (text == nil) return
	
	-- This is a bit hacky but it make the text more natural to enter
	if (#text) then
		local str = text
		
		local splitchar = 0
		for i = 1, #str do
			if (sub(str, i, i) == ":") then
				splitchar = i
				break
			end
		end
		
		text = {}
		text[1] = sub(str, 1, splitchar - 1)
		
		-- split the rest of the text on whitespace into lines
		local maxwidth = 30
		
		if (text[1] == "karen") then
			maxwidth = 28
		end
		
		local lastindex = splitchar + 2
		local index = lastindex - 1
		local lineindex = 2
		
		while index < #str do
			index += maxwidth -- try to fill an entire line
			
			local removedSpace = false
			
			if (index >= #str) then
				-- remainder of string case
				index = #str
			else
				if (sub(str, index+1, index+1) == " ") then
					-- full word should fit
					removedSpace = true
				else 
					local backwards = index
					while backwards > lastindex do
						if (sub(str, backwards, backwards) == " ") then
							index = backwards - 1
							removedSpace = true
							break
						end
						
						backwards -= 1
					end
				end
			end
			
			text[lineindex] = sub(str, lastindex, index)

			lastindex = index + 1
			if (removedSpace == true) then
				lastindex += 1
			end
			
			lineindex += 1
		end
	end
	
	return text
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
		iteratemap(
			function(x,y)
				if (mgetspr(x, y) == 1) then
					msetspr(2, x, y)
				elseif(mgetspr(x, y) == 2) then
					msetspr(1, x, y)
				end
			end
		)
	end
end

function animatestaticanimals()
	if ((tick % 80) == 1) then
		iteratemap(
			function(i, j)
				animals[i][j] = swap(animals[i][j], index.jelly1, index.jelly2)
				animals[i][j] = swap(animals[i][j], index.ujelly1, index.ujelly2)
			end
		)
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
	local py = player.y or 15
	local w = maprect[4]

	iteratemap(
		function(i,j)
			if (band(fget(mgetspr(i,j)), fice) > 0) then
				if (j == (py+1-i)%w+1) sprgrid(index.ice+4, i, j)
				if (j == (py  -i)%w+1) sprgrid(index.ice+3, i, j)
				if (j == (py-1-i)%w+1) sprgrid(index.ice+2, i, j)
				if (j == (py-2-i)%w+1) sprgrid(index.ice+1, i, j)
			end
		end
	)
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
	iteratemap(
		function(i,j)
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
	)
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
	iteratemap(
		function(i,j)
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
	)
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

	-- special case for monkey boss
	local a = animals[x][y]
	if (a and (a == index.monkey)) return a, 22

	local s = sprites[x][y]
	if (s == nil) return false

	-- instants
	if (s >= index.key0 and s <= index.key4) return s, 24
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
		animals[x][y] = nil
		
		if (s == index.bow) then
			player.helditem = s
			player.sprite = index.playerbow
		end
		
		if (s == index.grad) then
			player.helditem = s
			player.sprite = index.playergradscuba
		end

		if (s == index.monkey) then
			player.helditem = s
			player.sprite = 188
		end
		
		playsound(fx)
	else 
		return nil
	end

	if (s == index.tank) player.oxygen = 6

	if ((s >= index.key0 and s <= index.key4) or s == index.monkey) then
		exit.sprite = index.oexit

		player.goal = ""

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
	
	iteratemap(
		function(i,j)
			if (wearitem(i, j, sprites[i][j])) then
				sprites[i][j] = nil
				player.goalcount += 1
			end
		end
	)

	if (player.goalsprite and player.goalcount == player.goalneededcount) then
		exit.sprite = index.oexit
		state.phase = keyitemphase
		dialogindex = 1

		player.goalneededcount = 0
		player.goal = ""
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

function iteratemap(f)
	for i=1, maprect[3] do
		for j=1, maprect[4] do
			f(i, j)
		end
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

	iteratemap(
		function(i,j)
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
	)

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
	iteratemap(
		function(i,j)
			local a = animals[i][j]
			
			if (a == index.fturtle and isjelly(i+1, j)) then
				animals[i+1][j] = nil
				eatsfx = 15
			elseif (a == index.flturtle and isjelly(i-1, j)) then
				animals[i-1][j] = nil
				eatsfx = 15
			end
		end
	)

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
	iteratemap(
		function(i,j)
			if (animals[i][j]) count += 1
		end
	)

	-- todo: make this behave more like the game of life (too many nearby rabbits will prohibit more rabbits, [maybe not kill any though])
	if (count > 50) return

	iteratemap(
		function(i,j)
			local a = animals[i][j]
			if (a==index.rabbit and bred[i][j] == false) then
				iterateadjacent(function(x, y) trytobreed(a, bred, i, j, x, y) end, i, j)
			end
		end
	)
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

	-- death from being surrounded
	-- this is a hack, should use moveplayer but that has side effects and needs refactored
	local surrounded = 0;
	iterateadjacent(function(x, y) 
		if (isoutsidemap(x, y)) then
			surrounded += 1
		else
			if (blocks[x][y] or animals[x][y] or sprites[x][y] or (band(fget(mgetspr(x, y)), fwalkable) == 0)) then 
				surrounded += 1
			end
		end
	end, player.x, player.y)

	if (surrounded == 4 and not player.isvertical) then
		killplayer()
		return true;
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

	if (animals[x][y] and canpickup(x, y) == false) return false
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
			-- only start slide if the player will be on ice, not the block
			if (band(fget(mgetspr(x, y)), fice) > 0) then
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
00000000ccccccccc7ccccc744444449dd66666dd6666666bb3bbb3b00000000bb3bbb3000000000bb3bbb30bb3bbb3b00000000bb3bbb3b0b3bbb3b00000000
00000000ccccccc77ccccccc94494449d666666666666666b3bbbbbbd0606060b3bbbbb000000000b3bbbbb0b3bbbbbb00000000b3bbbbbb03bbbbbb00000000
007007007ccccc7ccccc7ccc449944446666666666666666bb3bb3bb60606060bb3bb3b000000000bb3bb3b0bb3bb3bb00000000bb3bb3bb0b3bb3bb00000000
00077000cccc7cccc7c7cccc44444444666666666666666d3bb3bbbbbbbbbbb33bb3bbb0000000003bb3bbb03bb3bbbb000000003bb3bbbb0bb3bbbb00000000
00077000ccc7c7cccc7ccccc444994446666666666666666bbbbbbb33bb3bbbbbbbbbbb000000000bbbbbbb0bbbbbbb300000000bbbbbbb30bbbbbb300000000
00700700cc7ccccccccccccc44444444666666666666666d00000000bb3bb3bb0000000000000000bb3bbbb0bb3bbbb0000000000b3bbbbb0b3bbbbb00000000
000000007ccccccccccc7c7c99449994666666666666666db0b030b0b3bbbbbbb0b030b000000000bbbb3bb0bbbb3bb0000000000bbb3bbb0bbb3bbb00000000
00000000c7ccccc7ccccc7cc94444444d66666666dd6dddd30b0b0b0bbbbbbbb30b0b0b0000000003bbbb3b03bbbb3b0000000000bbbb3bb0bbbb3bb00000000
33333333494444443394993349944444333b333300000000bb3bbb3bd03bbb3bd00000000000000000000000bb3bbb30000000000b3bbb3b0000000000000000
3333333344444944339449334444494433b3b3b3d0606060b3bbbbbbd0bbbbbbd06060600000000000000000b3bbbbb00000000003bbbbbb0000000000000000
33333333949494993394493394944499333bbb3b60606060bb3bb3bb603bb3bb606060600000000000000000bb3bb3b0000000000b3bb3bb0000000000000000
333333333344443333949933333333333b3b3bb3bbbbbbb03bb3bbbb60b3bbbb60bbbbb300000000000000003bb3bbbb000000003bb3bbbb0000000000000000
3333333333944933339499333333333333b3bb3b3bb3bbb0bbbbbbb360bbbbb360b3bbbb0000000000000000bbbbbbb300000000bbbbbbb30000000000000000
333333333394993333944933333333333b3bb3b3bb3bb3b0bb3bbbbb60000000603bb3bb0000000000000000bb3bbbbb00000000bb3bbbbb0000000000000000
33333333339449333394493333333333333b3333b3bbbbb0bbbb3bbb60b030b060bbbbbb0000000000000000bbbb3bbb00000000bbbb3bbb0000000000000000
333333333394993333949933333333333333b333bbbbbbb03bbbb3bbd0b0b0b0d0bbbbbb00000000000000003bbbb3bb000000003bbbb3bb0000000000000000
cccccccc00000007777777700000000000770000d03bbb3bbb3bbb30bbbbbbbbbbbbbbbb11111111111111111111114155555555555555550000000000000000
cccccccc00000077777777000000000007700000d0bbbbbbb3bbbbb0b3bbebbbb3bbb9bb11111111111111111141141155555555555555550000000000000000
cccccccc00000777777770000000000077000000603bb3bbbb3bb3b0bbbeaebbbbbb9a9b11111111113111111114111155555555555555550000000000000000
cccccccc0000777777770000000000077000000060b3bbbb3bb3bbb0bebbebbbbbbbb9bb11111111131113111411114155555555555555550000000000000000
cccccccc0007777777700000000000770000000060bbbbb3bbbbbbb0bbbbbbbbbb9bbbbb11111111113131111141411455555555555555550000000000000000
cccccccc00777777770000000000077000000000603bbbbbbb3bbbb0bbebbb3bb9a9bb3b11111111131113111444111155555555555555550000000000000000
cccccccc0777777770000000000077000000000060bb3bbbbbbb3bb0bbb3bbbbbb9b3bbb11111111113131114141141157756675555555550000000000000000
cccccccc77777777000000000007700000000000d0bbb3bb3bbbb3b0bbbbbbbbbbbbbbbb11111111111111111114111166777776555555550000000000000000
00777700000550001111111116111116cccccccc77777777bbbbbbbb0000000000000000776666570000000000000000cccccccc000000000000000000000000
07cccc70005555001111111661111111ccccccccccc7cc7cbbbbbbbb0000000000000000556666650244442000000000c244442c000000000000000000000000
7ccc7cc700aaaaa06111116111116111ccccccccccccccccbb3bbbbb0000000000000000666666660424424004999940c424424c000000000000000000000000
7cccc7c70055550a1111611116161111ccccccccccccccccbbbbbbbb0000000000000000656666660442244009444490c442244c000000000000000000000000
7cccc7c70055550a1116161111611111ccccccccccccccccbbbbbbbb0000000000000000666656660442244009499490c442244c000000000000000000000000
7ccc7cc700aaaa0a1161111111111111ccccccccccccccccbbbbbb3b0000000000000000666665660424424009499490c424424c000000000000000000000000
07cccc70005555a06111111111116161c7cc7cccccccccccbb3bbbbb0000000000000000766666670244442009444490c244442c000000000000000000000000
0077770000555500161111161111161177777777ccccccccbbbbbbbb0000000000000000776666770000000004999940cccccccc000000000000000000000000
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
0000000000088000000000000000000000005535355000000000055353550000000000000001010000eeee0000eeee000e00e00ee00e00e00000000000000000
000000000088000800000000000000000005535553550000000055355535500005000005000010000ee77ee00ee77ee0e00e00e00e00e00e0000000000000000
000000000888808800000000000000000033333333333bb00bb33333333333000550055505555500ee7777eeee7777ee0e00e00ee00e00e00000000000000000
000000008808888000000000000000000535535535535b5bb5b535535535535005555555555555000eeeeee00eeeeee0e00e00e00e00e00e0000000000000000
00000000888888800000000000000000bb33333333333bbbbbb33333333333bb0055555055555550e00e00e00e00e00e0eeeeee00eeeeee00000000000000000
00000000088880880000000000000000000bb3333bbb00000000bbb3333bb00000555000555575550e00e00ee00e00e0ee7777eeee7777ee0000000000000000
000000000080000800000000000000000bbbb00000bbb000000bbb00000bbbb00005500050055055e00e00e00e00e00e0ee77ee00ee77ee00000000000000000
00000000000800000000000000000000bbb000000bbb00000000bbb000000bbb00000000000000000e00e00ee00e00e000eeee0000eeee000000000000000000
00000000000000000000000006006000000000000000000000000000000000000000044000000000000000000000000000000bb0000bbbb00000000000000000
0000000000000000000000000e00e00000000000000000000000000000000000044400440000000000000000000000000000bbb80bbbb00b0000000000000000
0000000000000000000000000e00e0000000000000000000000000000000000045f5400400000000000000000000000000bbbb000bb000000000000000000000
00000000000000000000000006666000000000000000000000000000000000000fff00040000000000000000000000000bbbb00000000bb00000000000000000
0000000000000000000000000d6d666000000000000000000000000000000000044440440000000000000000000000000bb00000000bbbb00000000000000000
00000000000000000000000006666667000000000000000000000000000000000044444000000000000000000000000000000bb000bbbb000000000000000000
000000000000000000000000066666670000000000000000000000000000000000444400000000000000000000000000b00bbbb08bbb00000000000000000000
0000000000000000000000000666666000000000000000000000000000000000040044000000000000000000000000000bbbb0000bb000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000002200000022000000022000000000000000000000000001111111116111116
00000000000000000000000000000000000000000000000000000000000000000002900020029002000022900000000000000000000000001011111061111111
00000000000000000000000000000000000000000000000000000000000000000002200022022022000022000000000000000000000000006001100010000011
000000000000000000000000000000000000000000000000000000000000000000222200e222222e000222200000000000000000000000001000000000000001
0000000000000000000000000000000000000000000000000000000000000000022222200e2222e02222e2200000000000000000000000001100001100007770
000000000000000000000000000000000000000000000000000000000000000022e22e2200e22e00022e2220000000000000000000000000110001110770d700
00000000000000000000000000000000000000000000000000000000000000002e0929e200092900002222000000000000000000000000006110011117770000
0000000000000000000000000000000000000000000000000000000000000000e022220e00222200000909000000000000000000000000001611111611111111
00000000111d11111111dd111111d111000000000000000000000000000000000001100000011000000011000000000000000000000000000044400000009440
000000001dddd1ddd11dddddd11dd1d100000000000000000000000000000000000190001001900100001190000000000000000000000000045f540409999044
0000000011d2ddd2dd1ddd2ddd1dddd10000000000000000000000000000000000011000110110110000110000000000000000000000000000fff00496669004
00000000ddd222222dddd22d2ddd22dd0000000000000000000000000000000000111100c111111c000111100000000000000000000000000444440409990004
000000001ddd2d2222d222dd22d22dd100000000000000000000000000000000011111100c1111c01111c1100000000000000000000000002534404404444044
00000000111ddd2222dd2dd222dd2d110000000000000000000000000000000011c11c1100c11c00011c1110000000000000000000000000b1c4444000444440
0000000011dd222dd2222d22d2222dd1000000000000000000000000000000001c0919c100091900001111000000000000000000000000000044400000444400
000000001dd222dddd22222ddd2222d100000000000000000000000000000000c011110c00111100000909000000000000000000000000000440440004004400
000000001dddd22ddd222ddddd222dd1000000000000000000000000055a55000555a55000000000000000000000000000000000007777000077770000077700
00000000dd22dd22d22ddd2dd222dd1100000000000000000000aa000055a00800555a00000000000cccc000000000000000000007ccc57007ccc570007ccc70
00000000ddd22dd222dd222d22ddd1110000000000000000555555a5088880880c99990000000000cc44cc0000000000000000007c5555c77c5555c707c55557
000000001ddd222222d22d2d22d2d1110000000000000000005555a088088880c96669c000000000cc040c440000000000000000756665c7756665c707566657
00000000111d2d222222dddd2222ddd10000000000000000005555a088888880cc999c0000000000cc444c4d0000000000000000765556c7765556707c655567
00000000111ddd2222222d222dd22ddd000000000000000000555500088880880ceeecc0000000000ceeecff00000000000000007c666cc77c666c707cc666c7
0000000011dd222d22dd222222dd22dd0000000000000000000000000080000804aaa4c00000000004aaa440000000000000000007666c700766670007c66670
000000001dd222ddd22d22ddd22dddd10000000000000000000000000008000000a0a0000000000000a0a4000000000000000000007777000077700000777700
000000001d2222ddd22222dddd222dd1000000000000000008000080005550000055500000000000000000000000000000000000070009777077707700ccc00c
000000001dd2222d22d2222dd222dd11000000000000000088800888005950000055500000ccc0000000000000000000044ccc0070ccc907775557700c666cc0
0000000011d2dd222dd2dd2222ddd11100000000000000008888888800555000008880000c44cc00000000000000000004cc44400c99990075555570c66666c0
000000001dd22d22dd222d2222d2ddd10000000000000000088828800582850005555500cc040cc00000000000000000c4c4d4d4c96669c075757577c65656cc
00000000dd22ddd2d22dddd222222ddd0000000000000000888228880577750005555500cc444c000000000000000000c44cfff0cc999c0075555570c66666c0
000000001dddd1ddd2dd11dddddd2d1100000000000000002820028205777500055555000ceee8c00000000000000000cc4444000ceeecc0777777770c555ccc
000000001d1dd11ddddd111dd1ddddd1000000000000000002000020055755000555550004aaa2c000000000000000000444440004aaa4c077555770006660c0
00000000111d11111dd1111d111d1111000000000000000000000000009990000095900000a0a800000000000000000000a0a40070a0a00707777700000000c0
555555555555555555555555555555550044440000444400000000000000000000000000000b0b0000b0b0b00000000000000000000000000000000000000000
5ccccc755bbbb3b551111145543aaab5044bb44004411440ccccccccbbbbbbbb555555550033beb0003b3b000000000009000000000000000000000000000000
5cccc7755b3b3bb551311115543aaab504bbbb4004111140c111111cb333333b500000050e3ebb000333e3e00000000090000000000000000000000000000000
5ccc77c553b33b3553114115543aaab504bbbb4004111140c111111cb333333b5000000503bbbbb003b33b3b00000000d0000000000000000000000000000000
5cc77c755b3333b5513114155433343504bbb94004111940ccccccccbbbbbbbb555555550bb3b3e3be3b33b000000000d0000000000000000000000000000000
5555555555555555555555555555555504bbbb40041111401cc77cc13bb77bb3d557755d0b3e33333b33b333000eeeeeeeeee000000000000000000000000000
5000000550000005500000055000000504bbbb40041111401cccccc13bbbbbb3d555555d0333333003333330000fffff4fffe000000000000000000000000000
5000000550000005500000055000000504bbbb40041111401cccccc13bbbbbb3d555555d00555500005555000004ffffff4fe000000000000000000000000000
004444000044440000444400004444000000000000000000000005000000050000000500000a0440000a0060000fff4fffffe000000000000000000000000000
044bb4400443344004433440044cc440000000000000000000000500aa0005aa0000050000ee0044000ee060000777777777e000000000000000000000000000
04baab40043aa3400433334004cccc400000055555000000055555500aa55aa0005555000eee0004000eee60000ff4fff4ffe000000000000000000000000000
04babb40043a33400433334004cccc40000055000550000005505050055050500050550045f54004000666600004fffffff4e000000000000000000000000000
04baab40043aa3400433394004ccc9400000500000500000050505500aa50aa0005505000fff00440666d6d00777777777777770000000000000000000000000
04babb40043a33400433334004cccc40000111000bbb000005555550aa5555aa0055550000444440766666600066666666666600000000000000000000000000
04baab40043aa3400433334004cccc40111151000b5bbbbb05655650056556500056550000444400766666600000000000000000000000000000000000000000
04bbbb40043333400433334004cccc4011015cc0335b0b0b05555550055555500055550004404400066666600000000000000000000000000000000000000000
0044440000444400004444000044440010011c5553bb000b00000000000000000000000000000000000000055555555500000000000000000000000000999900
044cc44004411440044224400440044000000cc0330000000000000000000000000000000000000555555555bbbbbbb500000000000000000000000000900900
04caac40041aa140042aa2400400004000000c000300000000000000000000000000000555555555bbbbbbb6777bbbb500000000000000000000000000999900
04cacc40041a1140042a22400400004000000cc033000000000000000000000555555555aaaaaaa67777777677777bb500000000000000000000000000090000
04caac40041aa140042aa2400400004000000c00030000000000000555555555aaaaaaa6aa777776777777767777bbb500000000000000000000000000090000
04cacc40041a1140042a22400400004000000cc0330000005555555599999996aaaaaaa6aaaaaaa6bbbbbbb6bbbbbbb500000000000000000000000000099000
04caac40041aa140042aa2400400004000000000000000005888888699999996aaaaaaa6aaaaaaa6bbbbbbb6bbbbbbb500000000000000000000000000090000
04cccc40041111400422224004000040000000000000000055555555555555555555555555555555555555555555555500000000000000000000000000099900
00aaaa0000eeee000088880000bbbb00770a0aaa0aaa0000007777770aaaaaa00077777772777777777777770000000000000000000000000000000000000000
00a00a0000e00e000080080000b00b0007700000aa000000a0777777000000000772222272777777222222220000000000000000000000000000000000000000
00aaaa0000eeee000088880000bbbb0007777777a00a7777a0777777777777777727777772777777777777770000000000000000000000000000000000000000
000a0000000e000000080000000b0000a0777777a0a77777a0777777777777777277777772777777777777770000000000000000000000000000000000000000
000a0000000e000000080000000b00000077777700777777a0777777777777777277777772777777777777770000000000000000000000000000000000000000
000aa000000ee00000088000000bb000a077777700777777a0777777777777777277777772777777777777770000000000000000000000000000000000000000
000a0000000e000000080000000b0000a077777700777777a0777777777777777277777772777777777777770000000000000000000000000000000000000000
000aaa00000eee0000088800000bbb00a07777770077777700777777777777777277777772777777777777770000000000000000000000000000000000000000
__gff__
0043438001010000000001010001010000a1a180000001000000000100010000050505050500000101010101808000000000434305050100000180808100000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000040400000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000
__map__
2d202020202020202020393920203939000a0a0a000a0a0a0a0a002d2d2d20202020202d2d2d0000292929292b9100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936363616161616163616363636161636
2d20202020202020202020202020342000000000000a0a0a0a0a002d2d2d20202020202d2d2d00002a29292b29a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936362836163636163636363616272716
2c2c2020202d2c2c202020342020392000000000000a0a000a0a002d2d2d20202020202d2d2d00009329292929b100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916361616163616161616161616362716
20202020202d2020343434393434343400000000000000000000002c2c2c20202020202c2c2c0000a2932929292900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916162020201620202016202020161636
20202020202c20200201020201020201000000000000000000000020202020202020202020200000b2b329292b9100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916163636201620202016202020163636
34343434343434343939010101020202000a0a0a0a0a0000000000203434343434343434342000002a29292929a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f00002929292929292929292929292929292936363620161620362016201620161616
2c2c2c2c2c2c2c2c39393902393939390000000000000000000000343939393939393939393400009293292929b100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003e00002929292929292929292929292929292916362016161620362016203620271636
000000000000000039393902393939390000000000000a0a0a0a0039393939393939393939390000a2b32b29292900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916162016281620162036201620163636
10141014121010141010141414101010121010121010101000000000000000000000000000000000a32a2a292b2a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916162020201620202036202020363636
14111414121313131010101414141010121010121010101000000000000000000000000000000000a2932929299100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292916163636363636361636361616163636
10121410121010101412101414101410121010101010121400000000000000000000000000000000a2a2932929a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029292929292929292929292929292929360b06060606060606060606060d3636
10121014121410101012141214141010121013131313111300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029292929292929292929292929292929360a05050505050505050505050e3616
10121410111313131012101214141410121010101010121400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029292929292929292929292929292929360a05050505050505050505050e2716
14121010121010101311131210141010121410101010121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000029292929292929292929292929292929361b07070707070707070707071d3616
1012030101010101141210121410101012101410121412100000000000000000000039393939393939393900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936361627161636363616281616282816
0303030303030303101214121014121010141010121012100000000000000000000032393939393939393200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002929292929292929292929292929292936363627271616163636362816281616
2929b1b2b2b2a2a2363636363636363600000000000000002929292929292b29290032323939393939323200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a292929292ba1a2363636363636363600000000000000002a2a2929292b2b29290033333239393932323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2929292a2929b1b20d0e0f1d1d1e0d0e00000000000000002b2929292929292b29008f8e3233333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2a2929292b29290e0f1d1d1d1d1e0d00000000000000002929292929292929290032333333323333323300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292a29292929292b36363636363636360000000000000000292b2929292929292a00333335353535338f8e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9293292929292b293636363636363636000000000000000029292b2929292929290033353339392039333200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b2b329292929292a3636363636363636e6e7e7e7e7e7e7e8292929292929292b290033203535352035333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2b2b292a292b2a29363636363636363600000000000000002a2929292929292b2b0033202020202020333500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040400000404040404042528360116282b2b292929292929290033333339202039353900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040400000404040404042528280136362929292929292929290035333320333335203500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040400000416161616041706060506062929292b2929292a290020333939353520202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040418070707071504040000041636163604040404040404000000000000000000002d2d2d2d2d2d2d2d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040425161616162604040000041636361604040404040404000000000000000000002d2d2d2d2d2d2d2d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04042516161616260404000004161616160418070705070700000000000000000000203d2020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04041706060606080404000004040404040425283601162700000000000000000000203d20202020203d3d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404040404040404040400000404040404042536270136360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
