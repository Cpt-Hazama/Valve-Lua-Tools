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

        if string_endsWith(vtf,"_n") then
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
        elseif string_endsWith(vtf,"_mrao") then
            local def_vtf = string_sub(vtf,1,-6)
            sortList[def_vtf] = sortList[def_vtf] or {}
            sortList[def_vtf].MRAO = vtf
            -- print("Found MRAO map: " .. vtf)
            isSubVTF = true
        elseif string_endsWith(vtf,"_e") or string_endsWith(vtf,"_g") or string_endsWith(vtf,"_i") then
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
        end
        if shaderType == "PBR" then
            list[listID].Model = 1
        end
    end

    if #list > 0 then
        Valve.GenerateVMT(dir,saveDir,list)
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Generates the VMT file in the form of a txt file (used internally)
		- dir = The directory of the textures
		- saveDir = The name of the directory where it will save the VMTs in the data/ folder
        - list = The table of data to create the VMT file, an internal table really
    Example
        Valve.GenerateVMT("models/cpthazama/mgr/khamsin","khamsin",list)
-----------------------------------------------------------]]
Valve.GenerateVMT = function(dir,saveDir,list)
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
end
--
-- if SERVER then -- Testing center
    -- print("-----------------------------------------------------")
    -- Valve.SetupVMT("models/cpthazama/mgr/khamsin","khamsin",false,nil)
-- end