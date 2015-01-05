local state = require('state')
local periphery = require('periphery')

-- Usage
if #arg < 1 then
    io.stderr:write(string.format('Usage: %s %s <configuration file>\n', arg[-1], arg[0]))
    os.exit(-1)
end

-- Load configuration
function loadconfig(path)
    local f = assert(io.open(path, 'r'))
    local t = f:read('*all')
    f:close()
    local env = {}
    load(t, nil, 't', env)()

    if env.configuration == nil then
        error("Invalid configuration: 'configuration' table missing.")
    end
    return env.configuration
end

local ok, gardenConfig = pcall(loadconfig, arg[1])
if not ok then
    io.stderr:write(gardenConfig .. "\n")
    os.exit(-1)
end

-- Load blocks
function loadblocks(configuration)
    local blkobjects = {}

    for _, blktype in ipairs({"inputs", "algorithms", "outputs", "posts"}) do
        if configuration[blktype] == nil then
            error("Invalid configuration: missing '" .. blktype .. "' subtable.")
        end

        for blkinstance, blkconfig in pairs(configuration[blktype]) do
            if blkconfig.driver == nil then
                error("Invalid configuration: instance '" .. blkinstance .. "' missing 'driver' in configuration")
            end

            path = blktype .. "." .. blkconfig.driver
            print("Loading " .. blktype .. " block '" .. blkinstance .. "' (" .. path .. ")")
            blkobject = {instance = blkinstance, type = blktype, path = path, object = require(path)(config)}

            blkobjects[#blkobjects+1] = blkobject
        end
    end

    return blkobjects
end

local ok, gardenBlocks = pcall(loadblocks, gardenConfig)
if not ok then
    io.stderr:write(gardenBlocks .. "\n")
    os.exit(-1)
end

-- Create state structure
local gardenState = state.new()

-- Run system loop
while true do
    gardenState:timestamp()

    for _, block in ipairs(gardenBlocks) do
        print(string.format("[%s] Processing %s block instance '%s' (%s)", os.date("%c"), block.type, block.instance, block.path))
        block.object:process(gardenState)
    end

    print(string.format("[%s] Recording state...", os.date("%c")))
    s, _ = ("\t" .. tostring(gardenState)):gsub("\n", "\n\t")
    print(s)
    gardenState:record()

    periphery.sleep_ms(gardenConfig.timestep*1000)
end

