local posix = require('posix')
local periphery = require('periphery')
local GPIO = periphery.GPIO

local gpiopulse = {}
gpiopulse.__index = gpiopulse
setmetatable(gpiopulse, {__call = function(self, ...) return self.new(...) end})

-- xor for boolean type
local function xor(a, b)
    return (a and not b) or (not a and b)
end

function gpiopulse.new(configuration)
    local self = setmetatable({}, gpiopulse)

    if #configuration.variables ~= 1 then
        error("invalid number of state variables in configuration. expected 1")
    elseif configuration.gpio_number == nil then
        error("missing gpio_number in configuration")
    elseif configuration.active_low == nil then
        error("missing active_low boolean in configuration")
    elseif configuration.initial_value == nil then
        error("missing initial_value boolean in configuration")
    elseif configuration.duration == nil then
        error("missing duration integer in configuration")
    end

    self.variable = configuration.variables[1]
    self.active_low = configuration.active_low
    self.duration = configuration.duration

    -- Open GPIO with initial value
    local dir = {[false] = "low", [true] = "high"}
    self.gpio = GPIO(configuration.gpio_number, dir[xor(configuration.initial_value, self.active_low)])

    return self
end

function gpiopulse:process(state)
    if state[self.variable] then
        if posix.fork() == 0 then
            -- Enable
            self.gpio:write(xor(true, self.active_low))
            -- Sleep
            periphery.sleep(self.duration)
            -- Disable
            self.gpio:write(xor(false, self.active_low))

            os.exit()
        end
    end
end

return gpiopulse
