local blocks = {}

function blocks.load(configuration)
    local blkobjects = {}

    if configuration.inputs == nil then
        error("Invalid configuration: missing 'inputs' subtable.")
    elseif configuration.algorithms == nil then
        error("Invalid configuration: missing 'algorithms' subtable.")
    elseif configuration.outputs == nil then
        error("Invalid configuration: missing 'outputs' subtable.")
    elseif configuration.posts == nil then
        error("Invalid configuration: missing 'posts' subtable.")
    end

    function loadblock(instance, blktype, config)
        if config.driver == nil then
            error("Invalid configuration: instance '" .. instance .. "' missing 'driver' in configuration")
        end

        path = blktype .. "." .. config.driver
        print("Loading " .. blktype .. " block '" .. instance .. "' (" .. path .. ")")
        return {instance = instance, type = blktype, config = config, path = path, object = require(path)(config)}
    end

    for blkinstance,blkconfig in pairs(configuration.inputs) do
        blkobjects[#blkobjects+1] = loadblock(blkinstance, "inputs", blkconfig)
    end
    for blkinstance,blkconfig in pairs(configuration.algorithms) do
        blkobjects[#blkobjects+1] = loadblock(blkinstance, "algorithms", blkconfig)
    end
    for blkinstance,blkconfig in pairs(configuration.outputs) do
        blkobjects[#blkobjects+1] = loadblock(blkinstance, "outputs", blkconfig)
    end
    for blkinstance,blkconfig in pairs(configuration.posts) do
        blkobjects[#blkobjects+1] = loadblock(blkinstance, "posts", blkconfig)
    end

    return blkobjects
end

return blocks
