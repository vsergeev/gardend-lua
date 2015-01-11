-- Unit test for timer controller
local timer = require('controllers.timer')

describe("behavior", function ()
    local timer_obj = timer{variables = {"foo"}, time_on = {hour = 14, min = 15, sec = 12}, time_off = {hour = 17, min = 11, sec = 40}}

    it("checks time", function ()
        local t = os.date("*t")

        local state = {}

        -- time from 00:00:00 to 14:15:11, should be off
        for s = 0, 51311 do
            t.hour = math.floor(s/3600)
            t.min = math.floor((s - t.hour*3600)/60)
            t.sec = math.floor((s - t.hour*3600 - t.min*60))
            state.timestamp = os.time(t)
            timer_obj:process(state)
            assert.are.equal(state.foo, false)
        end
        -- time from 14:15:12 to 17:11:40, should be on
        for s = 51312, 61900 do
            t.hour = math.floor(s/3600)
            t.min = math.floor((s - t.hour*3600)/60)
            t.sec = math.floor((s - t.hour*3600 - t.min*60))
            state.timestamp = os.time(t)
            timer_obj:process(state)
            assert.are.equal(state.foo, true)
        end
        -- time from 17:11:41 to 23:59:59, should be off
        for s = 61901, 86399 do
            t.hour = math.floor(s/3600)
            t.min = math.floor((s - t.hour*3600)/60)
            t.sec = math.floor((s - t.hour*3600 - t.min*60))
            state.timestamp = os.time(t)
            timer_obj:process(state)
            assert.are.equal(state.foo, false)
        end
    end)
end)

