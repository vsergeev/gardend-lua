-- Unit test for heatmat controller
local heatmat = require('controllers.heatmat')

describe("behavior", function ()
    local heatmat_obj = heatmat{variables = {"temperature", "hysteresis", "output"}, temperature_target=75.0, temperature_window=3.0}

    it("checks hysteresis behavior", function ()
        local state

        -- Initialize to warming state
        state = {[-1] = {}, temperature = 68.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "warming")
        assert.are.equal(state.output, true)

        -- Warm up to upper threshold
        state = {[-1] = {hysteresis = "warming"}, temperature = 69.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "warming")
        assert.are.equal(state.output, true)

        state = {[-1] = {hysteresis = "warming"}, temperature = 75.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "warming")
        assert.are.equal(state.output, true)

        -- Cross upper threshold, 75.0+3.0=78.0
        state = {[-1] = {hysteresis = "warming"}, temperature = 79.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "cooling")
        assert.are.equal(state.output, false)

        -- Cool down to lower threshold
        state = {[-1] = {hysteresis = "cooling"}, temperature = 78.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "cooling")
        assert.are.equal(state.output, false)

        state = {[-1] = {hysteresis = "cooling"}, temperature = 75.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "cooling")
        assert.are.equal(state.output, false)

        -- Cross lower threshold, temperature < 75.0-3.0=72.0
        state = {[-1] = {hysteresis = "cooling"}, temperature = 71.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "warming")
        assert.are.equal(state.output, true)

        -- Warm up towards upper threshold
        state = {[-1] = {hysteresis = "warming"}, temperature = 69.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "warming")
        assert.are.equal(state.output, true)

        state = {[-1] = {hysteresis = "warming"}, temperature = 75.0}
        heatmat_obj:process(state)
        assert.are.equal(state.hysteresis, "warming")
        assert.are.equal(state.output, true)
    end)
end)

