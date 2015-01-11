configuration = {
    timestep = 2.0,
    dbfile = nil,
    logfile = nil,
    inputs = {
        bar = {
            driver = "dummy",
            variables = {"foo"},
            values = {1234, 4567, 100, 200, 300}
        },
    },
    controllers = {
    },
    outputs = {
    },
    postprocessors = {
        textstats = {
            driver = "textstats",
            variables = { {name = "foo", units = "°C"} },
            file = nil,
        },
    },
}
