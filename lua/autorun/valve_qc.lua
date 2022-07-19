Valve = Valve or {}

// lua_run Valve.CreateSequences("phemsee",{Auto = true},"phemsee",true)

local table_insert = table.insert
local table_remove = table.remove

local string_find = string.find
local string_lower = string.lower
local string_upper = string.upper
local string_sub = string.sub
local string_Replace = string.Replace
local string_len = string.len
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
Valve.GenerateSMDFile = function(fileName,tbl)
    file.CreateDir("valve/smd")

    local function AddSequence(f,smdDat,isFirst)
        local smd = smdDat.smd
        local addLoop = smdDat.loop or false
        local setFPS = smdDat.fps or 30
        local walkframes = smdDat.walkframes or false

        print("SMD MODEL " .. smd .. ".smd")
        if !isFirst then
            f:Write("\n")
        end
        f:Write("\n")
        f:Write('$Sequence "' .. smd .. '" {')
            f:Write("\n")
            f:Write('\t "animations/' .. smd .. '.smd"')
            f:Write("\n")
            f:Write('\t activity "ACT_' .. string_upper(smd) .. '" 1')
            if setFPS then
                f:Write("\n")
                f:Write('\t fps ' .. setFPS)
            end
            if addLoop then
                f:Write("\n")
                f:Write('\t loop')
            end
            if walkframes then
                f:Write("\n")
                f:Write('\t walkframe ' .. walkframes .. ' LX LY')
                print("@" .. smd .. " : 0 - " .. walkframes .. "")
            end
            f:Write("\n")
        f:Write('}')
    end

    local f = file.Open("valve/smd/" .. fileName .. ".txt","w","DATA")
        print("Compiling '" .. fileName .. ".txt' ...")
        f:Write("// Compiled using Valve Lua Tools")
        f:Write("\n")
        for i,v in pairs(tbl) do
            AddSequence(f,v,i == 1)
        end
    f:Close()
    local f = file.Open("valve/smd/" .. fileName .. ".txt","r","DATA")
        local bytes = f:Size()
        print("sequences     " .. bytes .. " bytes (" .. #tbl .. " seq)")
        print("Completed '/common/GarrysMod/garrysmod/data/valve/smd/" .. fileName .. ".txt'")
    f:Close()

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
Valve.CreateSequences = function(smds,defArgs,fileName,findInDir)
    if type(smds) != "table" then
        if findInDir then
            smds = file.Find("valve/smd/" .. smds .. "/*.smd","DATA")
        else
            smds = Valve.ReadSMDs(smds)
        end
    end
    if smds == nil or istable(smds) && #smds <= 0 then
        print("No SMD files found ...")
        return
    end
    local list = {}
    local auto = defArgs.Automatic or false
    local addLoop = defArgs.Loop or false
    local setFPS = defArgs.FPS or 30
    local walkframes = defArgs.WalkFrames or false
    for _,smd in pairs(smds) do
        if string_find(smd,".smd") then
            smd = string_sub(smd,1,-5)
        end
        if auto then
            local smdName = string_lower(smd)
            if string_find(smdName,"idle") or string_find(smdName,"wait") or string_find(smdName,"walk") or string_find(smdName,"run") or string_find(smdName,"all") or string_find(smdName,"glide") or string_find(smdName,"loop") then
                addLoop = true
            elseif string_find(smdName,"walk") or string_find(smdName,"run") or string_find(smdName,"attack") or string_find(smdName,"range") or string_find(smdName,"jump") or string_find(smdName,"land") then
                walkframes = 900
            end
        end
        if !fileName then
            print("\n")
            print('$Sequence "' .. smd .. '" {')
                print('\t "animations/' .. smd .. '.smd"')
                print('\t activity "ACT_' .. string_upper(smd) .. '" 1')
                if setFPS then
                    print('\t fps ' .. setFPS)
                end
                if addLoop then
                    print('\t loop')
                end
                if walkframes then
                    print('\t walkframe ' .. walkframes .. ' LX LY')
                end
            print('}')
        end
        list[#list +1] = {
            smd = smd,
            fps = setFPS,
            loop = addLoop,
            walkframes = walkframes
        }
    end
    if fileName then
        Valve.GenerateSMDFile(fileName,list)
    end
end