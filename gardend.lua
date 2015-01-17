local state = require('state')
local periphery = require('periphery')

-- Version constant
GARDEND_VERSION = "1.0.0"

-- Usage
if #arg < 1 then
    io.stderr:write(string.format('Usage: %s %s <configuration file>\n\n', arg[-1], arg[0]))
    io.stderr:write(string.format('gardend version %s\n', GARDEND_VERSION))
    os.exit(-1)
end

-- Load configuration
local function loadconfig(path)
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
    io.stderr:write(tostring(gardenConfig) .. "\n")
    os.exit(-1)
end

-- Open Log file
if gardenConfig.logfile == nil then
    logfile = io.stdout
else
    logfile = assert(io.open(gardenConfig.logfile, "a"))
end

function log(fmt, ...)
    logfile:write(os.date("[%c] ") .. string.format(fmt, unpack({...})) .. "\n")
    logfile:flush()
end

-- Load blocks
local function loadblocks(configuration)
    local blkobjects = {}

    for _, blktype in ipairs({"inputs", "controllers", "outputs", "postprocessors"}) do
        if configuration[blktype] == nil then
            error("Invalid configuration: missing '" .. blktype .. "' subtable.")
        end

        for blkinstance, blkconfig in pairs(configuration[blktype]) do
            if blkconfig.driver == nil then
                error("Invalid configuration: instance '" .. blkinstance .. "' missing 'driver' in configuration")
            end

            local blkpath = blktype .. "." .. blkconfig.driver
            log("Loading %s block '%s' (%s)", blktype, blkinstance, blkpath)

            local ok, object = pcall(require(blkpath), blkconfig)
            if not ok then
                error(string.format("configuring block '%s' (%s): %s", blkinstance, blkpath, tostring(object)))
            end

            blkobjects[#blkobjects+1] = {instance = blkinstance, type = blktype, path = blkpath, object = object}
        end
    end

    return blkobjects
end

local ok, gardenBlocks = pcall(loadblocks, gardenConfig)
if not ok then
    io.stderr:write(tostring(gardenBlocks) .. "\n")
    os.exit(-1)
end

-- Create state structure
local gardenState = state.new(gardenConfig.dbfile)

-- Run system loop
while true do
    local timestamp = gardenState:stamp()

    for _, block in ipairs(gardenBlocks) do
        log("Processing %s block instance '%s' (%s)", block.type, block.instance, block.path)

        local ok, err = pcall(function () block.object:process(gardenState) end)
        if not ok then
            log("Error processing %s block instance '%s' (%s): %s", block.type, block.instance, block.path, tostring(err))
        end
    end

    log("Recording state...")
    gardenState:record()

    log("Sleeping...")
    periphery.sleep_ms(math.max((timestamp + gardenConfig.timestep - os.time())*1000, 0.0))
end

