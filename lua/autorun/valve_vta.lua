Valve = Valve or {}

local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat

local string_find = string.find
local string_lower = string.lower
local string_upper = string.upper
local string_sub = string.sub
local string_gsub = string.gsub
local string_Replace = string.Replace
local string_len = string.len
local string_endsWith = string.EndsWith
--------------------------------------------------------------------------------------------------------------------------------------------
--[[---------------------------------------------------------
	Generates the VTA file in the form of a txt file (used internally)
		- smd = The name of the model these VTA files are for
		- saveDir = The name of the directory where it will save the VTAs in the data/ folder
        - data = The table of data to create the VTA file, an internal table really
    Example
        local data = {}
        // data[VTA_FILENAME] = {FLEX_FRAME_NAME}
        data["default_upperface"] = {"lEyeLid","rEyeLid","blink","lWink","rWink","eyeDroop","eyeOpen","eyeSerious","eyeSad","eyeAnnoyed"}
        data["default_lowerface"] = {"smile_teeth","pucker","open_small","smile","open_happy","open_confused","neutral","sad","smile_big","annoyed"}
        data["default_brow"] = {"rBrowDown","lBrowUp","rBrowUp","lBrowIn","rBrowIn","browSpread","browUp","browAnger","browUpset","browAnnoyed"}
        data["default_eyes"] = {"eyeShrink","eyeWet","eyeSmall"}
        Valve.GenerateVTA("default_face","makoto",data)
-----------------------------------------------------------]]
Valve.GenerateVTA = function(smd,saveDir,data)
    file.CreateDir("valve/vta")
    file.CreateDir("valve/vta/" .. saveDir)

    local tab = "	"

    file.Write("valve/smd/" .. saveDir .. "/" .. smd .. ".txt","")
    print("Compiling  VTA QC file in directory: 'valve/smd/" .. saveDir .. "/" .. smd .. ".txt'")

    local function WriteLine(f,line,lineType)
        if lineType == 1 then
            f:Write("\n")
        end
        f:Write(line)
        if lineType == 2 then
            f:Write("\n")
        end
    end

    local f = file.Open("valve/vta/" .. saveDir .. "/" .. smd .. ".txt","w","DATA")
        WriteLine(f,'$model studio "' .. smd .. '.smd" {',2)
            for vta,s in pairs(data) do
                WriteLine(f,tab .. 'flexfile "vta/' .. vta .. '.vta" {',1)
                    WriteLine(f,tab .. tab .. 'defaultflex frame 0',1)
                    for index,flex in pairs(s) do
                        WriteLine(f,tab .. tab .. 'flex "' .. flex .. '" frame ' .. index,1)
                    end
                WriteLine(f,tab .. '}',1)
                
                f:Write("\n")
                local flexList = table_concat(s, " ")
                flexList = string_gsub(flexList, " ", "\" \"")
                flexList = "\"" .. flexList .. "\""

                WriteLine(f,tab .. 'flexcontroller ' .. vta .. ' ' .. flexList,1)
                for _,flex in pairs(s) do
                    WriteLine(f,tab .. tab .. '%' .. flex .. " = " .. flex,1)
                end
                f:Write("\n")
            end
            WriteLine(f,'}',1)
    f:Close()
    print("VTA QC file compiled: " .. smd .. ".txt")
end
--
if SERVER then -- Testing center
    print("-----------------------------------------------------")
    local data = {}
    data["default_upperface"] = {"lEyeLid","rEyeLid","blink","lWink","rWink","eyeDroop","eyeOpen","eyeSerious","eyeSad","eyeAnnoyed"}
    data["default_lowerface"] = {"smile_teeth","pucker","open_small","smile","open_happy","open_confused","neutral","sad","smile_big","annoyed"}
    data["default_brow"] = {"rBrowDown","lBrowUp","rBrowUp","lBrowIn","rBrowIn","browSpread","browUp","browAnger","browUpset","browAnnoyed"}
    data["default_eyes"] = {"eyeShrink","eyeWet","eyeSmall"}
    Valve.GenerateVTA("head_default","makoto",data)
end