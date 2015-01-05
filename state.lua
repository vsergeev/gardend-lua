local state = {}

function state.new()
    -- Create a new state object
    local self = setmetatable({_data = {}, _history = {}}, state)
    return self
end

function state_timestamp(self)
    -- Timestamp state data
    self.timestamp = os.time()
end

function state_record(self)
    -- Add the data to our history
    self._history[#self._history+1] = setmetatable({}, {__index = self._data, __newindex = function (t, k, v) error("modifying past state") end})
    -- Clear our data
    self._data = {}
end

function state:__tostring()
    s = {}
    for k,v in pairs(self._data) do
        s[#s+1] = tostring(k) .. ": " .. tostring(v)
    end
    return table.concat(s, "\n")
end

function state:__index(key)
    -- Interpret negative index as accesses to past state
    if type(key) == "number" then
        -- Future
        if key > 0 then
            error("invalid future time index " .. key, 2)
        end

        -- Current
        if key == 0 then
            return setmetatable({}, {__index = self._data, __newindex = function (t, k, v) error("modifying raw state") end})
        end

        -- Past
        return self._history[#self._history+key+1]
    end

    -- Methods
    if key == "timestamp" then
        return state_timestamp
    elseif key == "record" then
        return state_record
    end

    -- Normal state data read
    return self._data[key]
end

function state:__newindex(key, value)
    -- Disallow numeric keys / time indexes
    if type(key) == "number" then
        error("invalid key, got type number", 2)
    end

    -- Disallow overwriting data in an existing key
    if self._data[key] ~= nil then
        error("key already exists in state", 2)
    end

    -- Normal state data write
    self._data[key] = value
end

return state
