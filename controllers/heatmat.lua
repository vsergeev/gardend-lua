local heatmat = {}
heatmat.__index = heatmat
setmetatable(heatmat, {__call = function(self, ...) return self.new(...) end})

function heatmat.new(configuration)
    local self = setmetatable({}, heatmat)

    if #configuration.variables ~= 3 then
        error("insufficient number of variables. expected {temperature, hysteresis, heatmat}")
    elseif configuration.temperature_target == nil then
        error("missing temperature target in configuration")
    elseif configuration.temperature_window == nil then
        error("missing temperature window in configuration")
    end

    self.temperature_variable, self.hysteresis_variable, self.heatmat_variable = unpack(configuration.variables)
    self.target = configuration.temperature_target
    self.window = configuration.temperature_window

    return self
end

--
--                 cooling           cooling
--               /--\              /--\
-- T + W        /    \            /    \
--             /      \          /      \
-- Target     /        \        /        \
--           /          \      /          ...
-- T - W    /            \    /
--       --/              \--/
--        warming           warming
--
function heatmat:process(state)
    local temperature = state[self.temperature_variable]
    local hysteresis = state[-1][self.hysteresis_variable] or "warming"

    if hysteresis == "warming" and temperature < (self.target + self.window) then
        state[self.heatmat_variable] = true
        state[self.hysteresis_variable] = "warming"
    elseif hysteresis == "warming" then
        state[self.heatmat_variable] = false
        state[self.hysteresis_variable] = "cooling"
    elseif hysteresis == "cooling" and temperature > (self.target - self.window) then
        state[self.heatmat_variable] = false
        state[self.hysteresis_variable] = "cooling"
    elseif hysteresis == "cooling" then
        state[self.heatmat_variable] = true
        state[self.hysteresis_variable] = "warming"
    end
end

return heatmat
