local heatmat = {}
heatmat.__index = heatmat
setmetatable(heatmat, {__call = function(self, ...) return self.new(...) end})

function heatmat.new(configuration)
    local self = setmetatable({}, heatmat)

    if #configuration.variables ~= 3 then
        error("invalid number of state variables in configuration. expected 3, {temperature, hysteresis, heatmat}")
    elseif configuration.temperature_target == nil then
        error("missing temperature target in configuration")
    elseif configuration.temperature_threshold_high == nil then
        error("missing temperature threshold high in configuration")
    elseif configuration.temperature_threshold_low == nil then
        error("missing temperature threshold low in configuration")
    end

    self.temperature_variable, self.hysteresis_variable, self.heatmat_variable = unpack(configuration.variables)
    self.target = configuration.temperature_target
    self.threshold_high = configuration.temperature_threshold_high
    self.threshold_low = configuration.temperature_threshold_low

    return self
end

--
--                   cooling           cooling
--                 /--\              /--\
-- T + th_hi      /    \            /    \
--               /      \          /      \
-- Target       /        \        /        \
--             /          \      /          ...
-- T - th_lo  /            \    /
--         --/              \--/
--          warming           warming
--
function heatmat:process(state)
    local temperature = state[self.temperature_variable]
    local hysteresis = state[-1][self.hysteresis_variable] or "warming"

    if hysteresis == "warming" and temperature < (self.target + self.threshold_high) then
        state[self.heatmat_variable] = true
        state[self.hysteresis_variable] = "warming"
    elseif hysteresis == "warming" then
        state[self.heatmat_variable] = false
        state[self.hysteresis_variable] = "cooling"
    elseif hysteresis == "cooling" and temperature > (self.target - self.threshold_low) then
        state[self.heatmat_variable] = false
        state[self.hysteresis_variable] = "cooling"
    elseif hysteresis == "cooling" then
        state[self.heatmat_variable] = true
        state[self.hysteresis_variable] = "warming"
    end
end

return heatmat
