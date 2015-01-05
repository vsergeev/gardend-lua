local config = {}

function config.load(path)
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

return config
