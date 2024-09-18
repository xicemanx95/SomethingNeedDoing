--[[
Fully Unified Task Automation (F.U.T.A.)

What does it do?

configure AR to run a script after AR is done and it have it run THIS script.
This script will, after AR is done, do various things based on a set of rules you will configure in a separate file (FUTAconfig_McVaxius.lua)

It could be ocean fishing, triple triad, inventory cleaning, going for a jog around the housing ward, delivering something to specific person, crafting. or whatever!

Requirements : SND, vnavmesh, dropbox, visland, pandora, simpletweaks
and maybe more - let's see where we go with it
everything from the folder you found this
and https://github.com/Jaksuhn/SomethingNeedDoing/blob/master/Community%20Scripts/AutoRetainer%20Companions/RobustGCturnin/_functions.lua

throw everything into %AppData%\XIVLauncher\pluginConfigs\SomethingNeedDoing\

What is working?
	Fishing
		Geting Fisher Levels and determining who is the lowest level fisher - we cant safely AYS RELOG yet..
		Fully cycling ocean fishing to the char with lowest level of fishing job
	Outputting to log file if Red Onion Helm Detected
	Updating Inventories, FC, Chocobo saddlebags for Atools by opening them.
		******************************************************************************************
		*DONT ASK ABOUT THIS IN PUNISH DISC OR YOU WILL BE SENT TO THE TEASPOON DROPPING CLOSET
		*Repricing items in retainers first time 100%, 11% chance after that unless you configure it differently.
		you may need to turn off retainer window bailout in /ays expert   or set it to 30 or 60 seconds.. still tbd on this
		*DONT ASK ABOUT THIS IN PUNISH DISC OR YOU WILL BE SENT TO THE TEASPOON DROPPING CLOSET
		******************************************************************************************
	Doing GC Turnins when configured inventory slots free is below a certain amount
	Visiting personal houses when we reach specified number of retainer cleanings
	Rebuying Ceruleum Fuel
	Trickling in repair kits

nice to have working
	(From Cabbage @ Punish disc) gardening -> https://gist.github.com/cabbscripts/6d265058d5e605b90adb8362c7638976
		it uses YA's list priority to harvest -> reseed -> quit, could add watering in too
		and assumes your plots are stacked on top of the housing entrance 

Known issues and resolution
	changing the table structure right now i can't do dynamically and safely (please help me!) so i am versioning things if i change the table structure so you
	can at least keep your old configs / counters if you need them.    there is probably a nice way to do this without deleting your configs but this is where we are :(
	also - if you dont have a fully busy roster of retainers, ocean fishing via this method isnt reccommended, you should just use the persistent ocean fishing script thats also on this repo somewhere. i won't be updating that one though.
	

--]]
------------------------------------------------------------
-------------------Static Variables-------------------------
------------------------------------------------------------
table_version = 2 -- don't change this. I will change it. this way your old configs are stored and someday someone can help me figure out how to migrate shit
------------------------------------------------------------
----------------------GLOBAL VARIABLES----------------------
------------------------------------------------------------
FUTA_config_file = "FUTAconfig_McVaxius_"..table_version..".lua"
force_fishing = 0 -- Set to 1 if you want the default indexed char to fish whenever possible
venture_cleaning = 20 -- How many venture coins do we need to have left we do a cleaning - useful for leveling new retainer abusers 21072 is item id
folderPath = os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\"
loadfiyel = os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\_functions.lua"
fullPath = os.getenv("appdata") .. "\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\" .. FUTA_config_file
functionsToLoad = loadfile(loadfiyel)
functionsToLoad()
dont_report_good_stuff = 0 --by default reporting everything, if you turn this on, it will not report on "good" stuff (we made x MRK!) aside from personal home entries
logfile_differentiator = " - Account 1"  --example of extra text to throw into log file say if your pointing a few clients to same log file for convenience
force_equipstuff = 0 --should we try to force recommended equip every chance we get? by default we won't do it
------------------------------------------
--Config and change back after done!------
------------------------------------------
re_organize_return_locations = 0 -- only set this one time and run the script so it can clean up the return locations, 0 magitek fuel = limsa bell, +fuel = fc entrance
------------------------------------------
------------------------------------------
------------------------------------------

--yield("/wintitle Final Fantasy XIV")   --FOR HACKY FISHIN SWITCHER WITH AHK
--yield("/wait 5")
--yield("/waitaddon _ActionBar <maxwait.600><wait.2>")

--update atools w fc and inventory
RestoreYesAlready()
yield("/echo Fully Unified Task Automation (F.U.T.A.) Initializing .....")
yield("/freecompanycmd")
yield("/echo Free Company command executed.")
yield("/inventory")
yield("/echo Inventory command executed.")
yield("/saddlebag")
yield("/echo Saddlebag command executed.")
yield("/echo Fully Unified Task Automation (F.U.T.A.) atools database updated")
yield("/echo Non Aggregated Recursive Integration (N.A.R.I.) Initializing .....")
yield("/bmrai off")
yield("/vbmai off")
yield("/rotation Cancel")
yield("/echo Script breakers disabled")		
FUTA_processors = {} -- Initialize variable

-- 3D Table   {}[i][j][k]
----  -> --?- -> not possible yet/partially implemented
----  -> --X- -> not implemented
----  -> --Y- -> not implemented
FUTA_defaults = {
    {
        {"Firstname Lastname@Server", 0}, 			--Y--{}[i][1][1..2]--name@server and return type 0 return home to fc entrance, 1 return home to a bell, 2 don't return home, 3 is gridania inn, 4 limsa bell near aetheryte, 5 personal estate entrance, 6 bell near personal home
        {"FISH", 0},								--?--{}[i][2][1..2]--level, 0 = dont do anything, 100 = dont do anything, 101 = automatically pick this char everytime, minimum = pick this char if no 101 exists
		{"CLEAN", 100, 0, 0, 50},					--Y--{}[i][3][1..5]--chance to do random cleaning/100 if 100 it will be changed to 11 after 1 run, process_gc_rank = 0=no,1=yes. expert_hack = 0=no,1=yes. clean_inventory = 0=no, >0 check inventory slots free and try to clean out inventory.
		{"FUEL", 0, 0},								--Y--{}[i][4][1..3]--fuel safety stock trigger, fuel to buy up to i[4][3] amount when hitting i[4][2] amount or lower leave i[4][2] at 0 if you dont want it to process this
		{"TT", 0, 0},								--N--{}[i][5][1..3]--minutes of TT, npc to play 1= roe 2= manservant
		{"CUFF", 0},						    	--N--{}[i][6][1..2]--minutes of cufff-a-cur to run . assumes in front of an "entrance"
		{"MRK", 0},									--Y--{}[i][7][1..2]--the artisan list ID to trigger after each QV check on this char, just make an artisan list with magitek repair mats and put the ID there
		{"FCB", "nothing", "nothing"},				--N--{}[i][8][1..3]--refresh FC buffs if they have 1 or less hours remaining on them. (remove and re-assign)
		{"PHV", 0, 100},							--Y--{}[i][9][1..3]--0 = no personal house 1 = has a personal house, personal house visit counter, once it reaches {}[][][2] it will reset to 1 after a visit, each ar completion will +1 it
		{"DUTY", "Teaspoon Dropping Closet", -5, 0},--N-{}[i][10][1..4]--name of duty, number of times to run (negative values for one time run - set to 0 after), normal 0 unsynced 1    				https://www.youtube.com/watch?v=TsFGJqXnqBE
		{"MINI", 0, 0, 0},							--N-{}[i][11][1..4]--Daily mini cactpot, [2] year [3] month [4] day, if we are in the next day after reset time. then we go run it again and set the time. again.
		{"VERM", 0, 0, 0}							--N-{}[i][12][1..4]--Verminion, [2] year [3] month [4] day, if we are in the next week after reset time. then we go run it again and set the time. again.
    }
}

-- Read and deserialize the data
serializedData = readSerializedData(fullPath)
deserializedTable = {}
if serializedData then
    deserializedTable = deserializeTable(serializedData)
	-- Assign the deserialized table to FUTA_processors
    FUTA_processors = deserializedTable

    -- Check the deserialized table
    --yield("/echo Deserialized table:")
    --printTable(FUTA_processors)
else
    yield("/echo Error: Serialized data is nil.")
end

--loadfiyel2 = os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\FUTAconfig_McVaxius.lua"
--functionsToLoad2 = loadfile(loadfiyel2)
--functionsToLoad2()

function getRandomNumber(min, max)
    return math.random(min, max)
end

zungazunga() -- Get out of anything quickly


hoo_arr_weeeeee = -1 -- Who are we? Default to -1 for figuring out if new char or not

for i = 1, #FUTA_processors do
    if GetCharacterName(true) == FUTA_processors[i][1][1] then
        hoo_arr_weeeeee = i
    end
end

if hoo_arr_weeeeee == -1 then
    -- We have a new char to add to the table!
    FUTA_processors[#FUTA_processors + 1] = {}
    -- Initialize all levels with defaults
    for j = 1, #FUTA_defaults[1] do
        FUTA_processors[#FUTA_processors][j] = {}
        for k = 1, #FUTA_defaults[1][j] do
            FUTA_processors[#FUTA_processors][j][k] = FUTA_defaults[1][j][k]
        end
    end

    -- Assign the character name
    FUTA_processors[#FUTA_processors][1][1] = GetCharacterName(true)
	hoo_arr_weeeeee = #FUTA_processors --we added it, lets cardinality it
end

-- Check if any table data is missing and put in a default value
for i = 1, #FUTA_processors do
    --yield("/echo Type of FUTA_processors["..i.."]:" .. type(FUTA_processors[i]))
    for j = 2, #FUTA_defaults[1] do
        --yield("/echo Type of FUTA_processors["..i.."]["..j.."]:" .. type(FUTA_processors[i][j]))
        for k = 1, #FUTA_defaults[1][j] do
            --yield("/echo Type of FUTA_processors["..i.."]["..j.."]["..k.."]:" .. type(FUTA_processors[i][j][k]))
            if FUTA_processors[i][j][k] == nil then
                FUTA_processors[i][j][k] = FUTA_defaults[1][j][k]
            end
        end
    end
end

yield("/echo N.A.R.I. Table Processor Completed")


--[[
-- Function to recursively print table contents
function printTable(t, indent)
    indent = indent or ""
    if type(t) ~= "table" then
        yield("/echo " .. indent .. tostring(t))
        return
    end
    
    for k, v in pairs(t) do
        local key = tostring(k)
        if type(v) == "table" then
            yield("/echo " .. indent .. key .. " =>")
            printTable(v, indent .. "  ") -- Recursive call with increased indent
        else
            yield("/echo " .. indent .. key .. " => " .. tostring(v))
        end
    end
end

-- Debug: Output the contents of FUTA_processors
if #FUTA_processors == 0 then
    yield("/echo FUTA_processors is empty!")
else
    yield("/echo FUTA_processors contents:")
    for i = 1, #FUTA_processors do
        yield("/echo Entry " .. i .. ":")
        printTable(FUTA_processors[i], "  ")
    end
end
--]]

--one-off-hackeries
if re_organize_return_locations == 1 then
	if GetItemCount(10155) >  0 then
		FUTA_processors[hoo_arr_weeeeee][1][2] = 0  --configure for return to fc house if we have repair kits
	end
end

-- After tablebunga() call
tablebunga(FUTA_config_file, "FUTA_processors", folderPath)
yield("/echo tablebunga() completed successfully")

-- Begin to do stuff
wheeequeheeheheheheheehhhee = 0 -- Secret variable
yield("/echo Debug: Beginning to do stuff")

--check for red onion helm
check_ro_helm()

---------------------------------------------------------------------------------
------------------------------FISHING  START-------------------------------------
---------------------------------------------------------------------------------
if FUTA_processors[hoo_arr_weeeeee][2][2] > -1 then  -- -1 is ignore+disable for this feature
	--we dont have a fishing level setup
    yield("/echo Let's see if fishing is even a thing on this char and update the database")
	yield("/wait 0.5")	
	if tonumber(GetLevel(17)) > 0 then
		FUTA_processors[hoo_arr_weeeeee][2][2] = tonumber(GetLevel(17))
		tablebunga(FUTA_config_file, "FUTA_processors", folderPath)
		yield("/echo tablebunga() completed successfully w new fishing data")
	end
	if tonumber(GetLevel(17)) == 0 then
		FUTA_processors[hoo_arr_weeeeee][2][2] = -1  --fishing is disabled don't check it again
		tablebunga(FUTA_config_file, "FUTA_processors", folderPath)
		yield("/echo this char is not a fisher")
	end
end

--fishing - always check first since it takes some time sometimes to get it going
--dont do anything else if we are fishing. just return home and resume AR after
if os.date("!*t").hour % 2 == 0 and os.date("!*t").min < 15 then
    if os.date("!*t").min >= 1 then
        wheeequeheeheheheheheehhhee = 1
    end
end
yield("/echo Debug: Time check completed")

-- Determine who is the lowest level fisher of them all.
lowestID = 1
--first get a non 0 value
for i = 1, #FUTA_processors do
    if FUTA_processors[i][2][2] > 0 then
        lowestID = i
    end
end
--now look for a smaller one
for i = 1, #FUTA_processors do
    if FUTA_processors[i][2][2] > 0 and FUTA_processors[i][2][2] < FUTA_processors[lowestID][2][2] then
        lowestID = i
    end
end

yield("/echo Debug: Lowest ID determined -> "..lowestID.." Corresponding to -> "..FUTA_processors[lowestID][1][1].. " With a level of -> "..FUTA_processors[lowestID][2][2])

-- If the lowest guy is max level, we aren't fishing
if FUTA_processors[lowestID][2][2] == 100 and force_fishing == 0 or FUTA_processors[lowestID][2][2] == -1 then
    wheeequeheeheheheheheehhhee = 0
    yield("/echo Lowest char is max level or no chars have fishing so we aren't fishing")
end

-- It's fishing time
if wheeequeheeheheheheheehhhee == 1 then
    if GetCharacterCondition(31) == false then
        if GetCharacterCondition(32) == false then
            ungabungabunga() -- We really try hard to be safe here
            yield("/echo Debug: Preparing for fishing")
            
            loadfiyel2 = os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\FUTA_fishing.lua"
            functionsToLoad = loadfile(loadfiyel2)
            functionsToLoad()
			
            yield("/waitaddon _ActionBar <maxwait.600><wait.2>")
			
			--FOR HACKY FISHIN SWITCHER WITH AHK --- START
			if FUTA_processors[lowestID][1][1] ~= GetCharacterName(true) then
				--if we are on wrong char. we gotta kill AR
				yield("/ays multi d")
				yield("/wait 1")
				yield("/ays reset")
				yield("/wait 5")

				--[[Hacky shit left here for posterity
					--FOR HACKY FISHING SWITCHER WITH AHK --- START
					--do sheet
					yield("/echo Hacky AHK shit")
					-- make a ahk file from scratch
					local file = io.open(folderPath .. "not_a_key_logger.ahk", "w")
					file:write("WinActivate, Flantasy\n")
					file:write("Sleep, 5000\n")
					--file:write("Send, {ENTER}/ays relog "..string.match(FUTA_processors[lowestID][1][1], "([^@]+)").." {ENTER}\n")
					file:write("Send, {ENTER}/ays relog "..FUTA_processors[lowestID][1][1].." {ENTER}\n")
					file:write("Sleep, 45000\n")
					file:write("Send, {ENTER}/pcraft run FUTA {ENTER}\n")
					file:close()
					-- Call a batch file using its full path
					--os.execute("cmd /c start \"\" \ "..os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\not_a_key_logger.ahk")
					os.execute('cmd /c start "" "' .. os.getenv("appdata") .. '\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\not_a_key_logger.ahk"')
					yield("/wintitle Flantasy")
					--end the script here
					yield("/pcraft stop")				--os.execute(os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\not_a_key_logger.ahk")
					yield("/wintitle Flantasy")
					--end the script here
					yield("/pcraft stop")
					--FOR HACKY FISHING SWITCHER WITH AHK --- END
				--]]
			end
			
            fishing()
            yield("/echo Debug: Fishing completed")

            -- Drop a log file entry on the charname + Level
            local file = io.open(folderPath .. "FeeshLevels.txt", "a")
            if file then
                currentTime = os.date("*t")
                formattedTime = string.format("%04d-%02d-%02d %02d:%02d:%02d", currentTime.year, currentTime.month, currentTime.day, currentTime.hour, currentTime.min, currentTime.sec)
                FUTA_processors[lowestID][2][2] = GetLevel()
                file:write(formattedTime.." - "..logfile_differentiator.."["..lowestID.."] - "..FUTA_processors[lowestID][1][1].." - Fisher Lv - "..FUTA_processors[lowestID][2][2].."\n")
                file:close()
                yield("/echo Text has been written to '" .. folderPath .. "FeeshLevels.txt'")
            else
                yield("/echo Error: Unable to open file for writing")
            end
            tablebunga(FUTA_config_file, "FUTA_processors", folderPath)
            yield("/echo Debug: Log file entry completed")
        end
    end
end
---------------------------------------------------------------------------------
------------------------------FISHING END----------------------------------------
---------------------------------------------------------------------------------
if wheeequeheeheheheheheehhhee == 0 then

	----------------------------
	--CLEAN--
	----------------------------
    -- Start of processing things when there is no fishing   
	if FUTA_processors[hoo_arr_weeeeee][3][2] > 0 then
		cleanrand = getRandomNumber(0, 99)
		yield("/echo rolling dice to see if we do a repricing -> "..cleanrand.." out of chance -> "..FUTA_processors[hoo_arr_weeeeee][3][2])
        if cleanrand < FUTA_processors[hoo_arr_weeeeee][3][2] then
			wheeequeheeheheheheheehhhee = 1  --re using this var because we can and it means the same thing at end of script
            yield("/echo Debug: Inventory cleaning adjustment started")
			--kneecapping AR for now because it interferes with am
			yield("/ays multi d")
			yield("/wait 1")
			yield("/ays reset")
			yield("/wait 1")
			yield("/ays multi d")
			yield("/wait 5")
			clean_inventory()
--			yield("/echo Debug:Debug:Debug:Debug:Debug:Debug:Debug:")
            zungazunga()
            -- If [3] was 100, we set it back down to 10 because 100 means a one-time guaranteed cleaning
            if FUTA_processors[hoo_arr_weeeeee][3][2] > 99 then
                FUTA_processors[hoo_arr_weeeeee][3][2] = 5 --for easier find replace shenanigans  [2] = 11 -> [2] = 99, for example
                tablebunga(FUTA_config_file, "FUTA_processors", folderPath)
                yield("/echo Debug: Inventory cleaning adjustment completed -> and 100 chance changed to 11")
            end
        end
    end
	 --In case we just ran it and need to avoid double triggering it
	if FUTA_processors[hoo_arr_weeeeee][3][2] == -1 then
		yield("/echo Debug: Inventory cleaning adjustment completed -> -1 changed to 11")
		FUTA_processors[hoo_arr_weeeeee][3][2] = 5 
	end
	if wheeequeheeheheheheheehhhee == 1 then
		FUTA_processors[hoo_arr_weeeeee][3][2] = -1
		yield("/echo Debug: Inventory cleaning adjustment completed -> chance changed to -1 to avoid double send")
	end

	----------------------------
	--CLEAN2 Electric boogaloo--
	----------------------------
	--check inventory size and do gcturnin shit 
	yield("/echo Do we need to clear inventory?")
	if FUTA_processors[hoo_arr_weeeeee][3][2] < 1000 then
		if GetInventoryFreeSlotCount() < FUTA_processors[hoo_arr_weeeeee][3][5] and FUTA_processors[hoo_arr_weeeeee][3][5] > 0 or GetItemCount(21072) < venture_cleaning then
			if FUTA_processors[hoo_arr_weeeeee][3][2] > 0 then 
				FUTA_processors[hoo_arr_weeeeee][3][2] = 100 --queue up a "clean" after next set of QV - but only if we are even allowing it on this one
			end
			yield("/echo Yes we need to clean inventory and turnin GC stuff!")
			loadfiyel2 = os.getenv("appdata").."\\XIVLauncher\\pluginConfigs\\SomethingNeedDoing\\FUTA_GC.lua"
			functionsToLoad = loadfile(loadfiyel2)
			functionsToLoad()
			FUTA_robust_gc()
			FUTA_processors[hoo_arr_weeeeee][3][2] = FUTA_processors[hoo_arr_weeeeee][3][2] + 1000 --to keep it from double running after it turns itself on in case there was some weird overflow with submarine items
			if GetInventoryFreeSlotCount() < (FUTA_processors[hoo_arr_weeeeee][3][5] + 20) then
				loggabunga("FUTA_", logfile_differentiator.." - Inventory still low after cleaning -> "..FUTA_processors[hoo_arr_weeeeee][1][1])
			end
		end
	end
	if FUTA_processors[hoo_arr_weeeeee][3][2] > 1000 then
		FUTA_processors[hoo_arr_weeeeee][3][2] = FUTA_processors[hoo_arr_weeeeee][3][2] - 1000 --reset it for next actual run
	end
	----------------------------
	-----Buy Ceruleum Fuel------
	----------------------------
	if FUTA_processors[hoo_arr_weeeeee][4][2] > 0 then
		if GetItemCount(10155) < FUTA_processors[hoo_arr_weeeeee][4][2] then
			ungabungabunga() -- get out of any screens we are in
			enter_workshop()
			try_to_buy_fuel(FUTA_processors[hoo_arr_weeeeee][4][3])
		end
	end

	----------------------------
	----Trickle Repair Kits-----
	----------------------------
	if FUTA_processors[hoo_arr_weeeeee][7][2] > 0 then
		if GetInventoryFreeSlotCount() < 20 then
			loggabunga("FUTA_", logfile_differentiator.." - MRK -> Not enough space to safely synth -> "..FUTA_processors[hoo_arr_weeeeee][1][1])
		end
		if GetItemCount(10386) < 20 then
			loggabunga("FUTA_", logfile_differentiator.." - MRK -> Not enough G6DM -> "..FUTA_processors[hoo_arr_weeeeee][1][1])
		end
		if GetItemCount(10335) < 20 then
			loggabunga("FUTA_", logfile_differentiator.." - MRK -> Not enough DMC -> "..FUTA_processors[hoo_arr_weeeeee][1][1])
		end
		if GetInventoryFreeSlotCount() > 19 and GetItemCount(10386) and GetItemCount(10335) then
			mrkMade = GetItemCount(10373)
			yield("/artisan lists "..FUTA_processors[hoo_arr_weeeeee][7][2].." start")
			--begin waiting for crafting to finish
			threetimes = 0
			while GetCharacterCondition(5) == true or threetimes < 3 do
				yield("/echo Waiting on artisan to finish what its doing....")
				zungazunga()
				yield("/wait 5")
				if GetCharacterCondition(5) == true then
					threetimes = 0 --reset it if we are still changing jobs in between
				end
				if GetCharacterCondition(5) == false then 
					threetimes = threetimes + 1 
				end
			end
			zungazunga()
			yield("/wait 5")
			zungazunga()
			yield("/wait 5")
			mrkMade = GetItemCount(10373) - mrkMade
			if dont_report_good_stuff == 0 then
				loggabunga("FUTA_", logfile_differentiator.." - MRK -> "..FUTA_processors[hoo_arr_weeeeee][1][1].." -> MRK made -> "..mrkMade)
			end
		end
	end
	
	----------------------------
	--PHV Personal House Visit--
	----------------------------
	--This should be done last--
	----------------------------
	if FUTA_processors[hoo_arr_weeeeee][9][2] > 0 then
		yield("/echo Personal House Visit counter Incremented by 1")
		FUTA_processors[hoo_arr_weeeeee][9][2] = 1 + FUTA_processors[hoo_arr_weeeeee][9][2]
		if FUTA_processors[hoo_arr_weeeeee][9][2] > FUTA_processors[hoo_arr_weeeeee][9][3] then
			FUTA_processors[hoo_arr_weeeeee][9][2] = 1
			yield("/li home")
			CharacterSafeWait()
			return_fc_entrance() --does the same thing just enters target
			CharacterSafeWait()
			loggabunga("FUTA_", logfile_differentiator.." - Home Visit Executed by -> "..FUTA_processors[hoo_arr_weeeeee][1][1])
			zungazunga()
			FUTA_return() --return to configured location
		end
	end
end

-- Stop beginning to do stuff
yield("/echo Debug: Finished all processing")
tablebunga(FUTA_config_file, "FUTA_processors", folderPath)
zungazunga()
yield("/echo onto the next one ..... ")
if wheeequeheeheheheheheehhhee == 1 then
	yield("/ays multi e") --if we had to toggle AR
end