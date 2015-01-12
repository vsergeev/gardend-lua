local I2C = require('periphery').I2C

local tsl2561 = {}
tsl2561.__index = tsl2561
setmetatable(tsl2561, {__call = function(self, ...) return self.new(...) end})

function tsl2561.new(configuration)
    local self = setmetatable({}, tsl2561)

    if #configuration.variables ~= 1 then
        error("invalid number of state variables in configuration. expected 1")
    elseif configuration.i2c_devpath == nil then
        error("missing i2c_devpath in configuration")
    elseif configuration.i2c_address == nil then
        error("missing i2c_address in configuration")
    end

    self.light_variable = configuration.variables[1]
    self.i2c_address = configuration.i2c_address

    -- Open I2C
    self.i2c = I2C(configuration.i2c_devpath)

    local msgs

    -- Check part ID
    msgs = {{0x8a}, {0x00, flags = I2C.I2C_M_RD}}
    self.i2c:transact(self.i2c_address, msgs)
    if bit32.band(msgs[2][1], 0xf0) ~= 0x10 then
        error(string.format("invalid tsl2561 device ID: expected 0x10, got 0x%02x", bit32.band(msgs[2][1], 0xf0)))
    end

    -- Power on the device and enable ALS
    msgs = {{0x80, 0x03}}
    self.i2c:transact(self.i2c_address, msgs)

    -- Set low gain and 402ms integration time
    msgs = {{0x81, 0x02}}
    self.i2c:transact(self.i2c_address, msgs)
    -- gain can be [1, 16]
    self.gain = 1
    -- integration_time can be [13.7, 101, 402]
    self.integration_time = 402

    return self
end

function tsl2561:process(state)
    local msgs

    -- Read CH0
    msgs = {{0xac}, {0x00, 0x00, flags = I2C.I2C_M_RD}}
    self.i2c:transact(self.i2c_address, msgs)
    local ch0 = bit32.bor(bit32.lshift(msgs[2][2], 8), msgs[2][1])

    -- Read CH1
    msgs = {{0xae}, {0x00, 0x00, flags = I2C.I2C_M_RD}}
    self.i2c:transact(self.i2c_address, msgs)
    local ch1 = bit32.bor(bit32.lshift(msgs[2][2], 8), msgs[2][1])

    -- Check for saturation
    if ch0 == 0xffff or ch1 == 0xffff then
        state[self.light_variable] = math.huge
        return
    end

    -- Calculate lux (tsl2561 datasheet TAOS059N, pg. 23-28)
    local ratio = ch1/ch0
    local lux

    -- Scale by integration time and gain
    ch0 = ch0*(402.0/self.integration_time)*(16.0/self.gain)
    ch1 = ch1*(402.0/self.integration_time)*(16.0/self.gain)

    if ratio <= 0.50 then
        lux = 0.0304*ch0 - 0.062*ch0*(ratio^1.4)
    elseif ratio <= 0.61 then
        lux = 0.0224*ch0 - 0.031*ch1
    elseif ratio <= 0.80 then
        lux = 0.0128*ch0 - 0.0153*ch1
    elseif ratio <= 1.30 then
        lux = 0.00146*ch0 - 0.00112*ch1
    else
        lux = 0.0
    end

    state[self.light_variable] = lux
end

return tsl2561
