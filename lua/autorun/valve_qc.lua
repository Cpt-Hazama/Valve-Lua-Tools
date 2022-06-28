Valve = Valve or {}
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
--[[---------------------------------------------------------
	Generates and prints a list of $sequences to the console in QC format
		- smds = The list of animation names or the SMD txt file name
        - defArgs = The default arguments to use for the sequences
    Example
        local tbl = { "anim1", "anim2", "anim3" }
        Valve.CreateSequences( "anims")
        Valve.CreateSequences( tbl )
-----------------------------------------------------------]]
Valve.CreateSequences = function(smds,defArgs)
    if type(smds) != "table" then
        smds = Valve.ReadSMDs(smds)
    end
    local list = {}
    local addLoop = defArgs.Loop or false
    local setFPS = defArgs.FPS or 30
    local walkframes = defArgs.WalkFrames or false
    for _,smd in pairs(smds) do
        print("\n")
        print('$Sequence "' .. smd .. '" {')
            print('\t "animations/' .. smd .. '.smd"')
            print('\t activity "ACT_' .. smd .. '" 1')
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
end