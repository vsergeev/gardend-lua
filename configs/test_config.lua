configuration = {
    timestep = 3.0,
    dbfile = 'test.db',
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
        timer = {
            driver = "timer",
            variables = {"qux"},
            time_on = {hour = 19, min = 20, sec = 10},
            time_off = {hour = 19, min = 20, sec = 40},
        },
    },
    outputs = {
    },
    postprocessors = {
        textstats = {
            driver = "textstats",
            variables = {{name = "foo", units = "°C"}, {name = "hyst", units=""}, {name = "bar", units = "(on/off)"}, {name = "qux", units = ""}},
            file = nil,
        },
        webstats = {
            -- Driver name
            driver = "webstats",
            -- Block-specific configuration
            wwwdir = "./misc",
            blogfile = "postprocessors/webstats-microblog.lua.example",
            stats_variables = {
                {name = "foo", units = "C", description = "Tray Temperature"},
                {name = "hyst", units = "%", description = "Tray Humidity"},
                {name = "bar", units = "(on/off)", description = "Heatmat State"},
                {name = "qux", units = "(on/off)", description = "Growlight State"},
            },
            plot_utc_offset = -8,
            plot_width = 600,
            plot_height = 600,
            plot_variables = {
                {name = "foo", duration = 60*60},
                {name = "bar", duration = 60*60},
                {name = "qux", duration = 60*60},
            },
        }
    },
}
