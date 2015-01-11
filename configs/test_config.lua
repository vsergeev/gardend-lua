configuration = {
    timestep = 2.0,
    dbfile = nil,
    logfile = nil,
    inputs = {
        heatmat = {
            driver = "dummy",
            variables = {"foo"},
            values = {65.0, 66.0, 67.0, 68.0, 69.0, 70.0, 71.0, 72.0, 73.0, 74.0, 75.0, 76.0, 77.0, 78.0, 79.0, 80.0, 79.0, 78.0, 77.0, 76.0, 75.0, 74.0, 73.0, 72.0, 71.0, 70.0, 69.0, 68.0, 67.0, 66.0},
        },
    },
    controllers = {
        heatmat = {
            driver = "heatmat",
            variables = {"foo", "hyst", "bar"},
            temperature_target = 75.0,
            temperature_window = 3.0,
        },
    },
    outputs = {
    },
    postprocessors = {
        textstats = {
            driver = "textstats",
            variables = {{name = "foo", units = "°C"}, {name = "hyst", units=""}, {name = "bar", units = "(on/off)"}},
            file = nil,
        },
    },
}
