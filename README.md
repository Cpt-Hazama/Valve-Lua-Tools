# Valve-Lua-Tools

A collection of lua based tools to help with creating Source related projects

## VMT Generation Functions

### Valve.SetupVMT(dir,saveDir,forceShader,tbValues)
	Generates necessary data to create a VMT file
		- dir = The directory of the textures
		- saveDir = The name of the directory where it will save the VMTs in the data/ folder
        - forceShader = Set the shader type manually, or set to false to automatically detect it
        - tbValues = A table of values to set in the VMT file
    Example
        local tbl = {Translucent = true, NoDecal = true}
        Valve.SetupVMT("models/cpthazama/mgr/khamsin","khamsin",false,tbl)

### Valve.GenerateVMT(dir,saveDir,list)
	Generates the VMT file in the form of a txt file (used internally, wouldn't recommend touching this)
		- dir = The directory of the textures
		- saveDir = The name of the directory where it will save the VMTs in the data/ folder
        - list = The table of data to create the VMT file, an internal table really
    Example
        Valve.GenerateVMT("models/cpthazama/mgr/khamsin","khamsin",list)

## $Sequence/SMD Helper Functions

### Valve.GenerateSMDFile(fileName, tbl)
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
        
### Valve.CreateSMDTable(name,tbl)
	Generates a SMD txt file from a list of animation names (use 'dir /s /b /o:gn' to get the list via cmd)
		- name = The generated file name
		- tbl = The list of animation names
    Example
        local tbl = { "anim1", "anim2", "anim3" }
        Valve.GenerateSMD( "anims", tbl )
        
### Valve.ReadSMDs(fileName)
	Reads the SMD txt file and returns a table of animation names
        - fileName = The generated file name
    Example
        local tbl = Valve.ReadSMDTable( "anims" )
	Returns
		- nil, couldn't find the file
		- table, the list of animation names
        
### Valve.CreateSequences(smds,defArgs,fileName,findInDir)
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
