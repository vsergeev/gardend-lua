local GPIO = require('periphery').GPIO

local gpioswitch = {}
gpioswitch.__index = gpioswitch
setmetatable(gpioswitch, {__call = function(self, ...) return self.new(...) end})

-- xor for boolean type
local function xor(a, b)
    return (a and not b) or (not a and b)
end

function gpioswitch.new(configuration)
    local self = setmetatable({}, gpioswitch)

    if #configuration.variables ~= 1 then
        error("invalid number of state variables in configuration. expected 1")
    elseif configuration.gpio_number == nil then
        error("missing gpio_number in configuration")
    elseif configuration.active_low == nil then
        error("missing active_low boolean in configuration")
    elseif configuration.initial_value == nil then
        error("missing initial_value boolean in configuration")
    end

    self.variable = configuration.variables[1]
    self.active_low = configuration.active_low

    -- Open GPIO with initial value
    local dir = {[false] = "low", [true] = "high"}
    self.gpio = GPIO(configuration.gpio_number, dir[xor(configuration.initial_value, self.active_low)])

    return self
end

function gpioswitch:process(state)
    -- Write GPIO
    self.gpio:write(xor(state[self.variable], self.active_low))
end

return gpioswitch
