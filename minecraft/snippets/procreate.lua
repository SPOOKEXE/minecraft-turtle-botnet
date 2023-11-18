
local fs, turtle, peripheral, sleep
-->> IGNORE ABOVE IN PRODUCTION <<--

local function populateDisk()
	assert( fs.isDir('/disk'), "No disk inserted into disk drive." )

	local source = fs.open('startup.lua', 'r').readAll()

	-- create a new startup script inside the turtle that loads the actual turtle brain into the turtle itself
	source = 'local SRC = [===[' .. source .. ']' .. '===]'
	source = source..string.format([[
		file = fs.open('startup.lua', 'w')
		file.write(SRC)
		file.close()
		shell.execute('reboot')
	]], source)

	local file = fs.open('/disk/startup', 'w')
	file.write(source)
	file.close()
end

-- NOTE: make sure to have a pickaxe equipped in left hand
local function procreate( disk_drive_slot, floppy_slot, turtle_slot, fuel_slot )
	-- place the disk drive
	turtle.select(disk_drive_slot)
	turtle.place()

	-- place floppy inside disk drive
	turtle.select(floppy_slot)
	turtle.drop( 1 )

	-- write the turtle source to the disk drive floppy
	populateDisk()

	-- go upward and place new turtle
	turtle.up()
	turtle.select(turtle_slot)
	turtle.place()

	-- give the new turtle some fuel
	turtle.select(fuel_slot)
	turtle.drop(4) -- TODO: check fuel type and give an amount based on that

	-- turn on the turtle and let it load the brain
	peripheral.call('front', 'turnOn')
	peripheral.call('front', 'reboot')
	sleep(2)

	-- go down and pickup the floppy/disk drive
	turtle.down()
	turtle.select(floppy_slot) -- floppy
	turtle.suck(1)
	turtle.select(disk_drive_slot) -- disk drive
	turtle.dig('left')
end

-- ( disk_drive_slot, floppy_slot, turtle_slot, fuel_slot )
print("Procreate!!!")
procreate( 13, 14, 15, 16 )
