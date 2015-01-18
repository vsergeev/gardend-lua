local textstats = {}
textstats.__index = textstats
setmetatable(textstats, {__call = function(self, ...) return self.new(...) end})

function textstats.new(configuration)
    local self = setmetatable({}, textstats)

    self.variables = configuration.variables

    if configuration.file ~= nil then
        self.file = assert(io.open(configuration.file, "a"))
    else
        self.file = io.stdout
    end

    return self
end

function textstats:process(state)
    local s = {}
    s[1] = string.format("\ttimestamp: %s", tostring(state.timestamp))
    for _,variable in ipairs(self.variables) do
        local name, units = variable.name, variable.units
        s[#s+1] = string.format("\t%s: %s %s", name, tostring(state[name]), units)
    end
    s = table.concat(s, "\n")

    self.file:write(os.date("[%c]") .. "\n" .. s .. "\n\n")
    self.file:flush()
end

return textstats
