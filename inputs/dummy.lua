local dummy = {}
dummy.__index = dummy

setmetatable(dummy, {__call = function(self, ...) return self.new(...) end})

function dummy.new(configuration)
    local self = setmetatable({}, dummy)
    return self
end

function dummy:process(state)
    if state[-1] == nil then
        state.i = 0
    else
        state.i = state[-1].i + 1
    end
end

return dummy
