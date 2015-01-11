local dummy = {}
dummy.__index = dummy
setmetatable(dummy, {__call = function(self, ...) return self.new(...) end})

function dummy.new(configuration)
    local self = setmetatable({}, dummy)
    self.var = configuration.variables[1]
    self.values = configuration.values
    self.i = 0
    return self
end

function dummy:process(state)
    state[self.var] = self.values[self.i+1]
    self.i = (self.i + 1) % #self.values
end

return dummy
