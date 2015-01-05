local config = require('config')
local blocks = require('blocks')
local state = require('state')
local periphery = require('periphery')

-- Usage
if #arg < 1 then
    io.stderr:write(string.format('Usage: %s %s <configuration file>\n', arg[-1], arg[0]))
    os.exit(-1)
end

-- Load configuration
local ok, gardenConfig = pcall(config.load, arg[1])
if not ok then
    io.stderr:write(gardenConfig .. "\n")
    os.exit(-1)
end

-- Load blocks
local ok, gardenBlocks = pcall(blocks.load, gardenConfig)
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
    print(tostring(gardenState))
    gardenState:record()

    periphery.sleep_ms(gardenConfig.timestep*1000)
end

