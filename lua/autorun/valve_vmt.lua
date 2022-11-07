Valve = Valve or {}

local table_insert = table.insert
local table_remove = table.remove

local string_find = string.find
local string_lower = string.lower
local string_upper = string.upper
local string_sub = string.sub
local string_Replace = string.Replace
local string_len = string.len
local string_endsWith = string.EndsWith
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Generates necessary data to create a VMT file
		- dir = The directory of the textures
		- saveDir = The name of the directory where it will save the VMTs in the data/ folder
        - forceShader = Set the shader type manually, or set to false to automatically detect it
        - tbValues = A table of values to set in the VMT file
    Example
        local tbl = {Translucent = true, NoDecal = true}
        Valve.SetupVMT("models/cpthazama/mgr/khamsin","khamsin",false,tbl)
-----------------------------------------------------------]]
Valve.SetupVMT = function(dir,saveDir,forceShader,tbValues)
    local vtfs = file.Find("materials/" .. dir .. "/*.vtf", "GAME")
    if vtfs == nil or istable(vtfs) && #vtfs <= 0 then
        print("No VTF files found ...")
        return
    end
    local sortList = {}
    local list = {}

    for _,vtf in pairs(vtfs) do
        local isSubVTF = false
        if string_find(vtf,".vtf") then
            vtf = string_sub(vtf,1,-5)
        end
        if string_find(vtf,"_diffuse") then
            vtf = string_sub(vtf,1,-9)
        end

        if string_endsWith(vtf,"_n") or string_endsWith(vtf,"_normal") then
            local def_vtf = string_sub(vtf,1,-3)
            sortList[def_vtf] = sortList[def_vtf] or {}
            sortList[def_vtf].Normal = vtf
            -- print("Found normal map: " .. vtf)
            isSubVTF = true
        elseif string_endsWith(vtf,"_s") then
            local def_vtf = string_sub(vtf,1,-3)
            sortList[def_vtf] = sortList[def_vtf] or {}
            sortList[def_vtf].Specular = vtf
            -- print("Found specular map: " .. vtf)
            isSubVTF = true
        elseif string_endsWith(vtf,"_exponent") then
            local def_vtf = string_sub(vtf,1,-10)
            sortList[def_vtf] = sortList[def_vtf] or {}
            sortList[def_vtf].Exponent = vtf
            -- print("Found exponent map: " .. vtf)
            isSubVTF = true
        elseif string_endsWith(vtf,"_mrao") then
            local def_vtf = string_sub(vtf,1,-6)
            sortList[def_vtf] = sortList[def_vtf] or {}
            sortList[def_vtf].MRAO = vtf
            -- print("Found MRAO map: " .. vtf)
            isSubVTF = true
        elseif string_endsWith(vtf,"_e") or string_endsWith(vtf,"_g") or string_endsWith(vtf,"_i") or string_endsWith(vtf,"_glow") then
            local def_vtf = string_sub(vtf,1,-3)
            sortList[def_vtf] = sortList[def_vtf] or {}
            sortList[def_vtf].Illuminate = vtf
            -- print("Found illuminate map: " .. vtf)
            isSubVTF = true
        end

        if !isSubVTF then
            sortList[vtf] = sortList[vtf] or {}
            sortList[vtf].Diffuse = vtf
            -- print("Found diffuse map: " .. vtf)
        end
    end
    
    local gameID = nil
    for vmt,vtf in pairs(sortList) do
        local shaderType = "VertexLitGeneric"
        if !forceShader then
            if vtf.MRAO or vtf.Specular then
                shaderType = "PBR"
            end
        else
            shaderType = forceShader
        end
        local listID = #list +1
        list[listID] = {
            Shader = shaderType,
            Diffuse = vtf.Diffuse,
            Normal = vtf.Normal,
            Specular = vtf.Specular,
            Illuminate = vtf.Illuminate,
            MRAO = vtf.MRAO,
            Exponent = vtf.Exponent,
        }
        if tbValues then
            if tbValues.Translucent then
                list[listID].Translucent = 1
            end
            if tbValues.AlphaTest then
                list[listID].AlphaTest = 1
            end
            if tbValues.Model then
                list[listID].Model = 1
            end
            if tbValues.Additive then
                list[listID].Additive = 1
            end
            if tbValues.NoCull then
                list[listID].NoCull = 1
            end
            if tbValues.NoDecal then
                list[listID].NoDecal = 1
            end
            if tbValues.SurfaceProp then
                list[listID].SurfaceProp = tbValues.SurfaceProp
            end
            if tbValues.ENVMap then
                list[listID].SurfaceProp = tbValues.ENVMap or "env_cubemap"
            end
            if tbValues.GameID then
                gameID = tbValues.GameID
            end
        end
        if shaderType == "PBR" then
            list[listID].Model = 1
        end
    end

    if #list > 0 then
        Valve.GenerateVMT(dir,saveDir,list,gameID)
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Generates the VMT file in the form of a txt file (used internally)
		- dir = The directory of the textures
		- saveDir = The name of the directory where it will save the VMTs in the data/ folder
        - list = The table of data to create the VMT file, an internal table really
        - gameID = If a game ID is set and a logic is created for the said game, the VMT will be generated in a unique way that's built for that game

        Current gameID parameters:
            - "BW"
            - "Genshin"
    Example
        Valve.GenerateVMT("models/cpthazama/mgr/khamsin","khamsin",list)
-----------------------------------------------------------]]
Valve.GenerateVMT = function(dir,saveDir,list,gameID)
    file.CreateDir("valve/vmt")
    file.CreateDir("valve/vmt/" .. saveDir)

    local function AddLine(f,parameter,value,dir)
        // \t is doo-doo, use 	 instead
        f:Write("\n")
        if dir then
            f:Write('	"' .. parameter .. '" "' .. dir .. "/" .. value .. '"')
        else
            f:Write('	"' .. parameter .. '" "' .. value .. '"')
        end
    end

    if gameID == nil then
        for _,v in pairs(list) do
            file.Write("valve/smd/" .. saveDir .. "/" .. v.Diffuse .. ".txt","")
            print("Compiling " .. v.Shader .. " VMT file: " .. v.Diffuse .. ".txt")

            local f = file.Open("valve/vmt/" .. saveDir .. "/" .. v.Diffuse .. ".vmt","w","DATA")
                f:Write('"' .. v.Shader .. '"')
                f:Write("\n")
                f:Write('{')
                    AddLine(f,"$basetexture",v.Diffuse,dir)
                    AddLine(f,"$bumpmap",v.Normal or "dev/flat",v.Normal && dir or false)
                    if v.Shader == "PBR" then
                        if v.MRAO then
                            AddLine(f,"$mraotexture",v.MRAO,dir)
                        end
                        if v.Specular then
                            AddLine(f,"$speculartexture",v.Specular,dir)
                        end
                    end
                    if v.Illuminate then
                        if v.Shader == "PBR" then
                            AddLine(f,"$emissiontexture",v.Illuminate,dir)
                        else
                            AddLine(f,"$selfillum",1)
                            AddLine(f,"$selfillummask",v.Illuminate,dir)
                        end
                    end
                    if v.Shader == "VertexLitGeneric" then
                        if v.Exponent then
                            AddLine(f,"$phongexponenttexture",v.Exponent,dir)
                        end
                    end
                    -- f:Write("\n")
                    if v.NoCull then
                        AddLine(f,"$nocull",1)
                    end
                    if v.NoDecal then
                        AddLine(f,"$nodecal",1)
                    end
                    if v.Model then
                        AddLine(f,"$model",1)
                    end
                    if v.Additive then
                        AddLine(f,"$additive",1)
                    end
                    -- f:Write("\n")
                    if v.Translucent then
                        AddLine(f,"$translucent",1)
                    end
                    if v.AlphaTest then
                        AddLine(f,"$alphatest",1)
                    end
                    -- f:Write("\n")
                    if v.SurfaceProp then
                        AddLine(f,"$surfaceprop",v.SurfaceProp)
                    end
                    -- f:Write("\n")
                    if v.ENVMap then
                        AddLine(f,"$envmap",v.ENVMap)
                    end
                f:Write("\n")
                f:Write('}')
            f:Close()
            print("VMT file compiled: " .. v.Diffuse .. ".txt")
        end
    elseif gameID == "BW" then
        for _,v in pairs(list) do
            file.Write("valve/smd/" .. saveDir .. "/" .. string.upper(v.Diffuse) .. ".txt","")
            print("Compiling " .. v.Shader .. " VMT file: " .. v.Diffuse .. ".txt")

            local f = file.Open("valve/vmt/" .. saveDir .. "/" .. v.Diffuse .. ".vmt","w","DATA")
                f:Write('"' .. v.Shader .. '"')
                f:Write("\n")
                f:Write('{')
                    AddLine(f,"$basetexture",v.Diffuse,dir)
                    AddLine(f,"$bumpmap",v.Normal or "dev/flat",v.Normal && dir or false)
                    AddLine(f,"$phongexponenttexture",v.Exponent or "vj_base/exponent",dir)
                    if v.Illuminate then
                        f:Write("\n")
                        AddLine(f,"$detail",v.Illuminate,dir)
                        AddLine(f,"$detailscale",1)
                        AddLine(f,"$detailblendfactor",1)
                        AddLine(f,"$detailblendmode",5)
                    end
                    f:Write("\n")
                    AddLine(f,"$nocull",1)
                    AddLine(f,"$nodecal",1)
                    AddLine(f,"$model",1)
                    f:Write("\n")
                    f:Write('	// "$alphatest" "1"')
                    f:Write("\n")
                    AddLine(f,"$ambientocclusion",1)
                    AddLine(f,"$phong",1)
                    AddLine(f,"$phongboost",1)
                    AddLine(f,"$phongfresnelranges","[1 1 1]")
                    AddLine(f,"$phongalbedotint",1)
                    f:Write("\n")
                    AddLine(f,"$envmap","models/cpthazama/battalion_wars_2/vwfrefmap2")
                    AddLine(f,"$envmapfresnel",1)
                    AddLine(f,"$envmaptint","[0.01 0.01 0.01]")
                    AddLine(f,"$normalmapalphaenvmapmask",1)
                f:Write("\n")
                f:Write('}')
            f:Close()
            print("VMT file compiled: " .. v.Diffuse .. ".txt")
        end
    elseif gameID == "Genshin" then
        for _,v in pairs(list) do
            file.Write("valve/smd/" .. saveDir .. "/" .. string.upper(v.Diffuse) .. ".txt","")
            print("Compiling " .. v.Shader .. " VMT file: " .. v.Diffuse .. ".txt")

            local f = file.Open("valve/vmt/" .. saveDir .. "/" .. v.Diffuse .. ".vmt","w","DATA")
                f:Write('"VertexlitGeneric"')
                f:Write("\n")
                f:Write('{')
                    AddLine(f,"$basetexture",v.Diffuse,dir)
                    AddLine(f,"$bumpmap",v.Normal or "models/cpthazama/genshin_impact/flat",v.Normal && dir or false)
                    AddLine(f,"$phongexponenttexture",v.Exponent or "models/cpthazama/genshin_impact/exponent",dir)
                    f:Write("\n")
                    AddLine(f,"$nocull",1)
                    AddLine(f,"$nodecal",1)
                    if v.Illuminate then
                        f:Write("\n")
                        AddLine(f,"$selfillum",1)
                        AddLine(f,"$selfillummask",v.Illuminate,dir)
                        AddLine(f,"$selfillumtint","[1 1 1]")
                    end
                    f:Write("\n")
                    AddLine(f,"$ambientocclusion",1)
                    AddLine(f,"$phong",1)
                    AddLine(f,"$phongboost",25)
                    AddLine(f,"$phongfresnelranges","[0.035 0.2 1]")
                    AddLine(f,"$phongalbedotint",1)
                    AddLine(f,"$normalmapalphaenvmapmask",1)
                    f:Write("\n")
                    AddLine(f,"$lightwarptexture","models/cpthazama/genshin_impact/shader6")
                f:Write("\n")
                f:Write('}')
            f:Close()
            print("VMT file compiled: " .. v.Diffuse .. ".txt")
        end
    end
end
--
-- if SERVER then -- Testing center
    -- print("-----------------------------------------------------")
    -- Valve.SetupVMT("models/cpthazama/mgr/khamsin","khamsin",false,nil)
-- end