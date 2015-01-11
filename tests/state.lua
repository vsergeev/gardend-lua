-- Unit test for state management code
local state = require("state")

describe("basic usage", function ()
    local s = state.new()

    s:stamp()
    s.abc = 123
    s.bar = "hello world"
    s:record()

    s:stamp()
    s.def = 100
    s:record()

    assert.are.equal(type(s[0]), "table")
    assert.are.equal(type(s[-1]), "table")
    assert.are.equal(type(s[-2]), "table")
    assert.are.equal(type(s[-3]), "table")
end)

describe("basic history usage", function ()
    local s = state.new()

    s.timestamp = 5
    s.foo = 123
    s.bar = "hello world"
    s:record()

    s.timestamp = 6
    s.foo = 456
    s.bar = "bananas"
    s:record()

    s.timestamp = 7
    s.foo = 789
    s.bar = "coffee"
    s:record()

    s.timestamp = 3

    assert.are.same({timestamp = 3}, s[0])
    assert.are.same({timestamp = 7, foo = 789, bar = "coffee"}, s[-1])
    assert.are.same({timestamp = 6, foo = 456, bar = "bananas"}, s[-2])
    assert.are.same({timestamp = 5, foo = 123, bar = "hello world"}, s[-3])
    assert.are.same({}, s[-4])
    assert.are.same({}, s[-5])
end)

describe("errors", function ()
    it("checks we cannot timestamp state twice", function ()
        local s = state.new()
        s:stamp()
        assert.has_error(function () s:stamp() end)
    end)

    it("checks we cannot assign a key twice", function ()
        local s = state.new()
        s.foo = 123
        assert.has_error(function () s.foo = 456 end)
    end)

    it("checks we cannot assign numeric keys", function ()
        local s = state.new()
        assert.has_error(function () s[123] = "foo" end)
    end)

    it("checks we cannot positive index into history", function ()
        local s = state.new()
        assert.has_error(function () x = s[1] end)
    end)

    it("checks we cannot modify current state", function ()
        local s = state.new()
        s:stamp()
        assert.has_error(function () s[0].timestamp = 4 end)
    end)

    it("checks we cannot assign to past state", function ()
        local s = state.new()

        s.timestamp = 5
        s.foo = 123
        s.bar = "hello world"
        s:record()

        assert.has_error(function () s[-1].foo = 5 end)
    end)
end)

describe("tostring", function ()
    local s = state.new()

    s:stamp()
    s.foo = 456
    s.bar = "bananas"

    assert.are.equal(type(tostring(s)), "string")
end)
