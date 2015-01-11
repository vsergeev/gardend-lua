local timer = {}
timer.__index = timer
setmetatable(timer, {__call = function(self, ...) return self.new(...) end})

function timer.new(configuration)
    local self = setmetatable({}, timer)

    if #configuration.variables ~= 1 then
        error("invalid number of state variables in configuration. expected 1")
    elseif not (configuration.time_on and configuration.time_on.hour and configuration.time_on.min and configuration.time_on.sec) then
        error("invalid time_on in configuration. expected table with hour, min, sec.")
    elseif not (configuration.time_off and configuration.time_off.hour and configuration.time_off.min and configuration.time_off.sec) then
        error("invalid time_off in configuration. expected table with hour, min, sec.")
    end

    self.output_variable = configuration.variables[1]
    -- Convert time_on table to a seconds point in a day (0 - 86400)
    self.time_on = configuration.time_on.hour*3600 + configuration.time_on.min*60 + configuration.time_on.sec
    -- Convert time_off table to a seconds point in a day (0 - 86400)
    self.time_off = configuration.time_off.hour*3600 + configuration.time_off.min*60 + configuration.time_off.sec

    return self
end

function timer:process(state)
    local current_time = os.date("*t", state.timestamp)
    current_time = current_time.hour*3600 + current_time.min*60 + current_time.sec

    -- Turn on the output if we're between time_on and time_off
    if current_time >= self.time_on and current_time <= self.time_off then
        state[self.output_variable] = true
    else
        state[self.output_variable] = false
    end
end

return timer
