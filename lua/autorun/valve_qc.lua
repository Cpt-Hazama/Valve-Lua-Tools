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
    Example
        local tbl = { "anim1", "anim2", "anim3" }
        Valve.CreateSequences( "anims")
        Valve.CreateSequences( tbl )
-----------------------------------------------------------]]
Valve.CreateSequences = function(smds)
    if type(smds) != "table" then
        smds = Valve.ReadSMDs(smds)
    end
    local list = {}
    for _,smd in pairs(smds) do
        print("\n")
        print('$Sequence "' .. smd .. '" {')
            print('\t "animations/' .. smd .. '.smd"')
            print('\t activity "ACT_' .. smd .. '" 1')
            print('\t fps 60')
            print('\t walkframe 900 LX LY')
        print('}')
    end
end