local dummy = {}
dummy.__index = dummy
setmetatable(dummy, {__call = function(self, ...) return self.new(...) end})

function dummy.new(configuration)
    local self = setmetatable({}, dummy)

    if #configuration.variables ~= 1 then
        error("invalid number of state variables in configuration. expected 1")
    elseif configuration.values == nil then
        error("missing values array in configuration.")
    end

    self.variable = configuration.variables[1]
    self.values = configuration.values
    self.i = 0

    return self
end

function dummy:process(state)
    state[self.variable] = self.values[self.i+1]
    self.i = (self.i + 1) % #self.values
end

return dummy
