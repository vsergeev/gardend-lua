local periphery = require('periphery')
local I2C = periphery.I2C

local htu21d = {}
htu21d.__index = htu21d
setmetatable(htu21d, {__call = function(self, ...) return self.new(...) end})

function htu21d.new(configuration)
    local self = setmetatable({}, htu21d)

    if #configuration.variables ~= 2 then
        error("invalid number of state variables in configuration. expected 2, {temperature var, humidity var}")
    elseif configuration.i2c_devpath == nil then
        error("missing i2c_devpath in configuration")
    elseif configuration.i2c_address == nil then
        error("missing i2c_address in configuration")
    end

    self.temperature_variable, self.humidity_variable = unpack(configuration.variables)
    self.i2c_address = configuration.i2c_address

    -- Open I2C
    self.i2c = I2C(configuration.i2c_devpath)

    return self
end

function htu21d:process(state)
    -- Measurement procedure
    -- 1. <Address | W> ACK 0xf3/0xf5 ACK
    -- 2. Sleep 60 ms
    -- 3. <Address | R> ACK <MSB> ACK <LSB> ACK <Checksum> ACK
    -- see htu21d datasheet, pg. 12

    local msgs

    -- Trigger temperature measurement
    msgs = {{0xf3}}
    self.i2c:transfer(self.i2c_address, msgs)
    -- Sleep for conversion time
    periphery.sleep_ms(60)
    -- Read measurement
    msgs = {{0x00, 0x00, 0x00, flags = I2C.I2C_M_RD}}
    self.i2c:transfer(self.i2c_address, msgs)

    local temperature = bit32.band(bit32.bor(bit32.lshift(msgs[1][1], 8), msgs[1][2]), 0xfffc)
    -- htu21d datasheet, pg. 15
    temperature = -46.85 + 175.72*(temperature/2^16)

    -- Trigger humidity measurement
    msgs = {{0xf5}}
    self.i2c:transfer(self.i2c_address, msgs)
    -- Sleep for conversion time
    periphery.sleep_ms(60)
    -- Read measurement
    msgs = {{0x00, 0x00, 0x00, flags = I2C.I2C_M_RD}}
    self.i2c:transfer(self.i2c_address, msgs)

    local humidity = bit32.band(bit32.bor(bit32.lshift(msgs[1][1], 8), msgs[1][2]), 0xfffc)
    -- htu21d datasheet, pg. 15
    humidity = -6.0 + 125.0*(humidity/2^16)

    state[self.temperature_variable] = temperature
    state[self.humidity_variable] = humidity
end

return htu21d
