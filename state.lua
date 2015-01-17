local json = require('cjson')
local sqlite3 = require('lsqlite3')

local state = {}

-- Safe sql_execute() with parameter binding
local function sql_execute(db, sql, ...)
    -- Bind values to SQL statement
    local stmt = db:prepare(sql)
    stmt:bind_values(...)

    -- Collect results
    local results = {}
    for r in stmt:urows() do
        results[#results+1] = r
    end

    -- Finalize statement
    if stmt:finalize() ~= sqlite3.OK then
        error(string.format("executing statement on database: %s (%d)", db:errmsg(), db:errcode()))
    end

    return results
end

function state.new(dbpath)
    -- Open database handle
    local db = nil
    if dbpath == nil then
        db = sqlite3.open_memory()
    else
        db = sqlite3.open(dbpath)
    end

    -- Create state table if it doesn't exist
    if db:exec("CREATE TABLE IF NOT EXISTS GardenState(timestamp INTEGER, state TEXT);") ~= sqlite3.OK then
        error(string.format("creating table in database: %s (%d)", db:errmsg(), db:errcode()))
    end

    -- Create a new state object
    local self = setmetatable({_data = {}, _db = db}, state)
    return self
end

local function state_stamp(self)
    -- Timestamp state data
    self.timestamp = os.time()

    return self.timestamp
end

local function state_record(self)
    -- Record the state to the database
    local ok, results = pcall(sql_execute, self._db, "INSERT INTO GardenState Values(?,?);", tonumber(self._data.timestamp), json.encode(self._data))
    if not ok then
        error(string.format("recording state to database: %s", results))
    end
    -- Clear our data
    self._data = {}
end

local function state_count(self)
    -- Count the number of records in the database
    local ok, results = pcall(sql_execute, self._db, "SELECT COUNT(*) FROM GardenState;")
    if not ok then
        error(string.format("count records in database: %s", results))
    end

    return results[1]
end

function state:__tostring()
    s = {}
    for k,v in pairs(self._data) do
        s[#s+1] = tostring(k) .. ": " .. tostring(v)
    end
    return table.concat(s, "\n")
end

function state:__index(key)
    -- Interpret numeric index as access to past/current state
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
        local ok, results = pcall(sql_execute, self._db, "SELECT state FROM GardenState WHERE rowid=(SELECT MAX(rowid) FROM GardenState)+?;", tonumber(key)+1)
        if not ok then
            error(string.format("querying past state in database: %s", results))
        end
        local past_state
        if #results == 0 then
            past_state = {}
        else
            past_state = json.decode(results[1])
        end
        return setmetatable({}, {__index = past_state, __newindex = function (t, k, v) error("modifying past state") end})
    end

    -- Methods
    if key == "stamp" then
        return state_stamp
    elseif key == "record" then
        return state_record
    elseif key == "count" then
        return state_count
    end

    -- Normal state variable read
    return self._data[key]
end

function state:__newindex(key, value)
    -- Disallow numeric keys / time indexes
    if type(key) == "number" then
        error("invalid key, got type number", 2)
    end

    -- Disallow overwriting an existing key
    if self._data[key] ~= nil then
        error("key already exists in state", 2)
    end

    -- Normal state variable write
    self._data[key] = value
end

return state
