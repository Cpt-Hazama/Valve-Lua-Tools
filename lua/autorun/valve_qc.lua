Valve = Valve or {}

local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat

local string_find = string.find
local string_lower = string.lower
local string_upper = string.upper
local string_sub = string.sub
local string_Replace = string.Replace
local string_len = string.len
local string_Explode = string.Explode
local string_gsub = string.gsub
local string_format = string.format

if SERVER then
    util.AddNetworkString("Valve.FlashWindow")
else
    net.Receive("Valve.FlashWindow",function()
        system.FlashWindow()
    end)
end

local function Valve_HasValue(tbl, val)
	if !istable(tbl) then return false end
	for x = 1, #tbl do
		if tbl[x] == val then
			return true
		end
	end
	return false
end
--
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Generates a QC txt file for Sequences, should be ran through Valve.CreateSequences rather than just by itself
		- name = The generated file name
		- tbl = The SMD data
    Example
        local tbl = {
            {
                smd = "idle",
                fps = 30,
                loop = true,
                walkframes = 0
            }
            {
                smd = "walk",
                fps = 30,
                loop = true,
                walkframes = 35
            }
        }
        Valve.GenerateSMDFile( "zombie", tbl )
-----------------------------------------------------------]]
Valve.GenerateSMDFile = function(fileName,tbl,gameID,exData)
    file.CreateDir("valve/smd")

    local function GetRealFrameData(f,smd)
        local totalFrames = 0
        local finalFrame = 0
        local SMD_Data = file.Open("data/valve/smd/" .. fileName .. "/" .. smd .. ".smd","rb","GAME")
            local data = SMD_Data:Read(SMD_Data:Size())
            local animationData = string_Explode("\n",data)
            local boneData = {}
            for fileLineNumber,lineData in pairs(animationData) do
                if string_find(lineData,"time") then
                    local time = string_Explode(" ",lineData)
                    totalFrames = totalFrames + 1
                    boneData[totalFrames] = {}

                    for i = fileLineNumber + 1, #animationData do
                        if string_find(animationData[i],"time") or string_find(animationData[i],"end") then break end
                        local boneInfo = string_Explode(" ",animationData[i])
                        boneData[totalFrames][boneInfo[3]] = {
                            Pos = Vector(boneInfo[4],boneInfo[5],boneInfo[6]),
                            Ang = Angle(boneInfo[7],boneInfo[8],boneInfo[9])
                        }
                    end
                end
            end
        SMD_Data:Close()

        local duplicateFrame = nil
        local lastFrameData = nil
        local totalDuplicatesInARow = 0
        local goalTolerance = 4
        for frameNumber,frameData in SortedPairs(boneData) do
            if lastFrameData then
                local isDuplicate = nil
                for boneName,boneData in SortedPairs(frameData) do
                    if lastFrameData[boneName] then
                        if lastFrameData[boneName].Pos != boneData.Pos or lastFrameData[boneName].Ang != boneData.Ang then
                            isDuplicate = false
                            break
                        else
                            isDuplicate = true
                        end
                    end
                end
                if isDuplicate then
                    totalDuplicatesInARow = totalDuplicatesInARow + 1
                    if totalDuplicatesInARow >= goalTolerance then
                        duplicateFrame = frameNumber -goalTolerance
                        break
                    end
                else
                    totalDuplicatesInARow = 0
                end
            end
            lastFrameData = frameData
        end

        return totalFrames, duplicateFrame
    end

    local function AddSequence(f,smdDat,isFirst,eventData)
        local smd = smdDat.smd
        local smdName = string_lower(smd)
        local addLoop = string_find(smdName,"idle") or string_find(smdName,"0000") or string_find(smdName,"wait") or string_find(smdName,"walk") or string_find(smdName,"run") or string_find(smdName,"glide") or string_find(smdName,"loop")
        local setFPS = smdDat.fps or false
        local walkframes = smdDat.walkframes or false
        local checkframes = smdDat.checkframes or false
        local scale = smdDat.scale or false
        local totalFrames, realLastFrame = GetRealFrameData(f,smd)

        print("SMD MODEL " .. smd .. ".smd")
        if !isFirst then
            f:Write("\n")
        end
        f:Write("\n")
        f:Write('$Sequence "' .. smd .. '" {')
            f:Write("\n")
            f:Write('	"animations/' .. smd .. '.smd"')
            f:Write("\n")
            f:Write('	activity "ACT_' .. string_upper(smd) .. '" 1')
            if setFPS then
                f:Write("\n")
                f:Write('	fps ' .. setFPS)
            end
            if scale then
                f:Write("\n")
                f:Write('	scale ' .. scale)
            end
            if addLoop then
                f:Write("\n")
                f:Write('	loop')
            end
            if checkframes then
                if realLastFrame then
                    f:Write("\n")
                    f:Write('	frames 0 ' .. realLastFrame)
                    totalFrames = realLastFrame
                end
                if walkframes then
                    if walkframes == true then
                        local calcIncrease = totalFrames /16
                        for i = 1, 16 do
                            local calculateFrame = math.Round(calcIncrease * i)
                            if calculateFrame > totalFrames then
                                calculateFrame = totalFrames
                            end
                            f:Write("\n")
                            f:Write('	walkframe ' .. calculateFrame .. ' LX LY')
                        end
                        -- f:Write('	walkframe ' .. (realLastFrame or totalFrames) .. ' LX LY')
                        print("@" .. smd .. " : 0 - " .. (realLastFrame or totalFrames) .. "")
                    else
                        f:Write("\n")
                        f:Write('	walkframe ' .. (realLastFrame or totalFrames) .. ' LX LY')
                        print("@" .. smd .. " : 0 - " .. (realLastFrame or totalFrames) .. "")
                    end
                end
            else
                if walkframes then
                    local calcIncrease = totalFrames /16
                    for i = 1, 16 do
                        local calculateFrame = math.Round(calcIncrease * i)
                        if calculateFrame > totalFrames then
                            calculateFrame = totalFrames
                        end
                        f:Write("\n")
                        f:Write('	walkframe ' .. calculateFrame .. ' LX LY')
                    end
                    -- f:Write('	walkframe ' .. totalFrames .. ' LX LY')
                    print("@" .. smd .. " : 0 - " .. totalFrames .. "")
                end
            end

            if eventData then
                if eventData[smd] then
                    f:Write("\n")
                    for i,v in pairs(eventData[smd]) do
                        f:Write("\n")
                        local eventDataFormatted = string_format('	{ event %s %s "%s" }', v.eventFlag, v.eventFrame, v.eventData)
                        f:Write(eventDataFormatted)
                        -- local evData = v.eventData
                        -- evData = string_gsub(evData,"\n","")
                        -- f:Write('	{ event ' .. v.eventFlag .. ' ' .. v.eventFrame .. ' "' .. evData .. '" }')
                    end
                end
            end

            f:Write("\n")
        f:Write('}')
    end

    local function defaultExecute()
        local eventFiles = file.Find("valve/smd/" .. fileName .. "/events.QCI","DATA")
        local eventData = {}
        if eventFiles then
            -- local totalTests = 0
            for _,eventFile in pairs(eventFiles) do
                local f = file.Open("valve/smd/" .. fileName .. "/events.QCI","rb","DATA")
                    local data = f:Read(f:Size())
                    local eventLines = string_Explode("\n",data)
                    local curSequence
                    for _,line in pairs(eventLines) do
                        if string_find(line,"$Sequence") then
                            -- if totalTests >= 1 then break end
                            curSequence = line:match("\"(.-)\"")
                            eventData[curSequence] = {}
                            -- totalTests = totalTests +1
                        end
                        if string_find(line,"{ event") then
                            local eventInfo = string_Explode(" ",line)
                            local eventDataFix = table_concat(eventInfo," ",5)
                            eventDataFix = string_Replace(eventDataFix,'"',"")
                            eventDataFix = string_Replace(eventDataFix," }","")
                            -- eventDataFix = string_gsub(eventDataFix,"\n","")
                            local event = {
                                eventFlag = eventInfo[3],
                                eventFrame = eventInfo[4],
                                eventData = eventDataFix
                            }
                            -- print("---------New Event Line-------------")
                            -- print("Flag",event.eventFlag)
                            -- print("Frame",event.eventFrame)
                            -- print("Data",event.eventData)
                            table_insert(eventData[curSequence],event)
                        end
                    end
                f:Close()
            end
        end
        local f = file.Open("valve/smd/" .. fileName .. ".txt","w","DATA")
            print("Compiling '" .. fileName .. ".txt' ...")
            f:Write("// Compiled using Valve Lua Tools")
            f:Write("\n")
            for i,v in pairs(tbl) do
                AddSequence(f,v,i == 1,eventData)
            end
        f:Close()
    end

    if gameID == nil then
        defaultExecute()
    elseif gameID == "GBFR" then
        local function GBFR_AddSequence(f,smdDat,isFirst,eventData)
            local actTrans = {
                // Main
                ["0000"] = "ACT_IDLE_ANGRY",
                ["0001"] = "ACT_IDLE",
                ["0a30"] = "ACT_WALK",
                ["0a20"] = "ACT_WALK_STIMULATED",
                ["0015"] = "ACT_RUN",
                ["0010"] = "ACT_RUN_STIMULATED",
                ["0020"] = "ACT_SPRINT",
                // Jump
                ["0031"] = "ACT_JUMP",
                ["0032"] = "ACT_GLIDE",
                ["0033"] = "ACT_LAND",
                // Blends
                ["0070"] = "ACT_WALK_AGITATED",
                ["0071"] = "ACT_WALK_AGITATED",
                ["0072"] = "ACT_WALK_AGITATED",
                ["0073"] = "ACT_WALK_AGITATED",
                // Dead
                ["0563"] = "ACT_WALK_STEALTH",
            }
            local smd = smdDat.smd
            local smdName = string_lower(smd)
            local addLoop = actTrans[smdName] != nil
            local setFPS = smdDat.fps or false
            local walkframes = smdDat.walkframes or false
            if actTrans[smdName] && string_find(actTrans[smdName],"IDLE") then
                walkframes = false
            end
            local checkframes = smdDat.checkframes or false
            local scale = smdDat.scale or false
            local totalFrames, realLastFrame = GetRealFrameData(f,smd)
    
            print("SMD MODEL " .. smd .. ".smd")
            if !isFirst then
                f:Write("\n")
            end
            f:Write("\n")
            f:Write('$Sequence "' .. smd .. '" {')
                f:Write("\n")
                f:Write('	"animations/' .. smd .. '.smd"')
                f:Write("\n")
                if actTrans[smdName] then
                    f:Write('	activity "' .. actTrans[smdName] .. '" 1')
                else
                    f:Write('	activity "ACT_' .. string_upper(smd) .. '" 1')
                end
                if setFPS then
                    f:Write("\n")
                    f:Write('	fps ' .. setFPS)
                end
                if scale then
                    f:Write("\n")
                    f:Write('	scale ' .. scale)
                end
                if addLoop then
                    f:Write("\n")
                    f:Write('	loop')
                end
                if walkframes then
                    local calcIncrease = totalFrames /32
                    for i = 1, 32 do
                        local calculateFrame = math.floor(math.Round(calcIncrease * i))
                        if calculateFrame > totalFrames then
                            calculateFrame = totalFrames
                        end
                        f:Write("\n")
                        if addLoop then
                            f:Write('	walkframe ' .. calculateFrame .. ' LX')
                        else
                            f:Write('	walkframe ' .. calculateFrame .. ' LX LY')
                        end
                    end
                    -- f:Write('	walkframe ' .. totalFrames .. ' LX LY')
                    print("@" .. smd .. " : 0 - " .. totalFrames .. "")
                end
    
                if eventData then
                    if eventData[smd] then
                        f:Write("\n")
                        for i,v in pairs(eventData[smd]) do
                            f:Write("\n")
                            local eventDataFormatted = string_format('	{ event %s %s "%s" }', v.eventFlag, v.eventFrame, v.eventData)
                            f:Write(eventDataFormatted)
                        end
                    end
                end
    
                f:Write("\n")
            f:Write('}')
        end
    
        local eventFiles = file.Find("valve/smd/" .. fileName .. "/events.QCI","DATA")
        local eventData = {}
        if eventFiles then
            for _,eventFile in pairs(eventFiles) do
                local f = file.Open("valve/smd/" .. fileName .. "/events.QCI","rb","DATA")
                    local data = f:Read(f:Size())
                    local eventLines = string_Explode("\n",data)
                    local curSequence
                    for _,line in pairs(eventLines) do
                        if string_find(line,"$Sequence") then
                            curSequence = line:match("\"(.-)\"")
                            eventData[curSequence] = {}
                        end
                        if string_find(line,"{ event") then
                            local eventInfo = string_Explode(" ",line)
                            local eventDataFix = table_concat(eventInfo," ",5)
                            eventDataFix = string_Replace(eventDataFix,'"',"")
                            eventDataFix = string_Replace(eventDataFix," }","")
                            local event = {
                                eventFlag = eventInfo[3],
                                eventFrame = eventInfo[4],
                                eventData = eventDataFix
                            }
                            table_insert(eventData[curSequence],event)
                        end
                    end
                f:Close()
            end
        end
        local f = file.Open("valve/smd/" .. fileName .. ".txt","w","DATA")
            print("Compiling '" .. fileName .. ".txt' ...")
            f:Write("// Compiled using Valve Lua Tools")
            f:Write("\n")
            for i,v in pairs(tbl) do
                GBFR_AddSequence(f,v,i == 1,eventData)
            end
        f:Close()
    elseif gameID == "Genshin" then
        local function AddSequence_Unique(f,smdDat,isFirst,hasPhys,fileName)
            local smd = smdDat.smd
            local addLoop = smdDat.loop or false
            local setFPS = smdDat.fps or false
            local walkframes = smdDat.walkframes or false
            local checkframes = smdDat.checkframes or true

            print("SMD MODEL " .. smd .. ".smd")
            if !isFirst then
                f:Write("\n")
            end

            local totalFrames, realLastFrame = CheckForRedudantFrames(f,smd)
            local cutFrames = realLastFrame or totalFrames

            if hasPhys then
                f:Write("\n")
                f:Write('$Sequence "a_' .. smd .. '" {')
                    f:Write("\n")
                    f:Write('	"animations_phys/' .. smd .. '.smd"')
                    f:Write("\n")
                    f:Write('	weightlist phys_params')
                    f:Write("\n")
                    f:Write('	hidden')
                    f:Write("\n")
                    f:Write('	numframes ' .. cutFrames)
                    f:Write("\n")
                f:Write('}')
                f:Write("\n")
            end
            f:Write("\n")
            f:Write('$Sequence "' .. smd .. '" {')
                f:Write("\n")
                f:Write('	"animations/' .. smd .. '.smd"')
                f:Write("\n")
                f:Write('	activity "ACT_' .. string_upper(smd) .. '" 1')
                if hasPhys then
                    f:Write("\n")
                    f:Write('	addlayer "a_' .. smd .. '"')
                end
                if setFPS then
                    f:Write("\n")
                    f:Write('	fps ' .. setFPS)
                end
                if scale then
                    f:Write("\n")
                    f:Write('	scale ' .. scale)
                end
                if addLoop then
                    f:Write("\n")
                    f:Write('	loop')
                end
                f:Write("\n")
                f:Write('	frames 0 ' .. cutFrames)
                if walkframes then
                    f:Write("\n")
                    if walkframes == true then
                        if string_find(smd,"Cycle") or string_find(smd,"Run") or string_find(smd,"Walk") then
                            f:Write('	walkframe ' .. cutFrames .. ' LX LY')
                        elseif string_find(smd,"Climb") or string_find(smd,"Jump") then
                            f:Write('	LX LY LZ')
                        else
                            f:Write('	LX LY')
                        end
                        print("@" .. smd .. " : 0 - " .. cutFrames)
                    else
                        f:Write('	walkframe ' .. walkframes .. ' LX LY')
                        print("@" .. smd .. " : 0 - " .. walkframes .. "")
                    end
                end
                f:Write("\n")
            f:Write('}')
        end

        local f = file.Open("valve/smd/" .. fileName .. ".txt","w","DATA")
            print("Compiling '" .. fileName .. ".txt' ...")
            f:Write("// Compiled using Valve Lua Tools")
            f:Write("\n")
            for i,v in pairs(tbl) do
                AddSequence_Unique(f,v,i == 1,exData == true or Valve_HasValue(exData,v.smd),fileName)
            end
        f:Close()
    else
        defaultExecute()
    end
    local f = file.Open("valve/smd/" .. fileName .. ".txt","r","DATA")
        local bytes = f:Size()
        print("sequences     " .. bytes .. " bytes (" .. #tbl .. " seq)")
        print("Completed '/common/GarrysMod/garrysmod/data/valve/smd/" .. fileName .. ".txt'")
    f:Close()

    if CLIENT then
        system.FlashWindow()
    else
        net.Start("Valve.FlashWindow")
        net.Broadcast()
    end

    print('Note: If you do not want to manually add the sequences to the QC file, you can simply copy the file to the QC folder, change the .TXT extension, and add $include "' .. fileName .. '.qc" to the original QC file.')
end
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Generates a SMD txt file from a list of animation names (use 'dir /s /b /o:gn' to get the list via cmd)
		- name = The generated file name
		- tbl = The list of animation names
    Example
        local tbl = { "anim1", "anim2", "anim3" }
        Valve.GenerateSMD( "anims", tbl )
-----------------------------------------------------------]]
Valve.CreateSMDTable = function(name,tbl)
    local data = file.Read("valve/smd/" .. fileName,"DATA")
    file.CreateDir("valve/smd")
    file.Write("valve/smd/" .. fileName .. ".txt",util.TableToJSON(tbl))
end
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Reads the SMD txt file and returns a table of animation names
        - fileName = The generated file name
    Example
        local tbl = Valve.ReadSMDTable( "anims" )
	Returns
		- nil, couldn't find the file
		- table, the list of animation names
-----------------------------------------------------------]]
Valve.ReadSMDs = function(fileName)
    local data = file.Read("valve/smd/" .. fileName .. ".txt","DATA")
	if data == nil then
        return
    end

    return util.JSONToTable(data)
end
--------------------------------------------------------------------------------------------------------------------------------------------
Valve.ReadSMDData = function(dir,smd) -- Test function
    local function loadNextConsoleBatch(f)
        f:Seek(4095)
    end

    local function loadNextConsoleBatch(f)
        f:Seek(4095)
    end

    local f = file.Open("valve/smd/" .. dir .. "/" .. smd .. ".smd","rb","DATA")
        if f == nil then
            return
        end
        local len = string_len(f:Read())
        f:Seek(0)
        print("Parsing SMD file, please be patient ...")
        while f:Tell() < len do
            local line = f:Read()
            if string_find(line,"version") then
                local version = string_sub(line,string_find(line," ")+1)
                print("SMD Version: " .. version)
            end
            print(line)
            loadNextConsoleBatch(f)
        end
    f:Close()
end
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Generates and prints a list of $sequences to the console in QC format
		- smds = The list of animation names or the SMD txt file name
        - defArgs = The default arguments to use for the sequences
        - fileName = If set, it will generate a QC file for the sequences with this name
        - findInDir = If set to true, it will search in the smds directory for .SMD files and use them
    Example
        local tbl = { "anim1", "anim2", "anim3" }
        Valve.CreateSequences( "anims", {Auto = true}, "SMD_List", true)
        Valve.CreateSequences( "anims", {FPS = 60, WalkFrames = 900})
        Valve.CreateSequences( tbl )
-----------------------------------------------------------]]
Valve.CreateSequences = function(smds,defArgs,fileName,findInDir,exData)
    local setName = fileName or smds
    local checkDir = findInDir or true
    if type(smds) != "table" then
        if checkDir then
            smds = file.Find("valve/smd/" .. smds .. "/*.smd","DATA")
        else
            smds = Valve.ReadSMDs(smds)
        end
    end
    if smds == nil or istable(smds) && #smds <= 0 then
        print("No SMD files found ...")
        return
    end
    local gameID = defArgs.GameID or nil
    local list = {}
    local auto = defArgs.Automatic or false
    local addLoop = defArgs.Loop or false
    local setFPS = defArgs.FPS or false
    local walkframes = defArgs.WalkFrames or false
    local checkFrames = defArgs.CheckFrames or false
    local scale = defArgs.Scale or false
    for _,smd in pairs(smds) do
        if string_find(string_lower(smd),".smd") then
            smd = string_sub(smd,1,-5)
        end
        if auto then
            local smdName = string_lower(smd)
            if string_find(smdName,"walk") or string_find(smdName,"run") or string_find(smdName,"attack") or string_find(smdName,"range") or string_find(smdName,"jump") or string_find(smdName,"land") then
                walkframes = true
            end
        end
        list[#list +1] = {
            smd = smd,
            fps = setFPS,
            loop = addLoop,
            walkframes = walkframes,
            checkframes = checkFrames,
            scale = scale
        }
    end
    Valve.GenerateSMDFile(setName,list,gameID,exData)
end