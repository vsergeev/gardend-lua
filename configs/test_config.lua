configuration = {
    name = "dummy test",
    timestep = 5.0,
    dbfile = "test.db",
    logfile = nil,
    inputs = {
        tray_temperature = {
            driver = "dummy",
            variables = {"tray_temperature"},
            values = {65.0, 66.0, 67.0, 68.0, 69.0, 70.0, 71.0, 72.0, 73.0, 74.0, 75.0, 76.0, 77.0, 78.0, 79.0, 80.0, 79.0, 78.0, 77.0, 76.0, 75.0, 74.0, 73.0, 72.0, 71.0, 70.0, 69.0, 68.0, 67.0, 66.0},
        },
        tray_humidity = {
            driver = "dummy",
            variables = {"tray_humidity"},
            values = {70.0, 71.0, 71.0, 70.5, 70.0, 70.5, 71.0},
        },
        webcam = {
            driver = "webcam",
            variables = {"webcam_file"},
            interval = 5,
            archivedir = "./misc/",
            wwwdir = "./misc/",
        },
    },
    controllers = {
        growlight_timer = {
            driver = "timer",
            variables = {"growlight_state"},
            time_on = {hour = 6, min = 0, sec = 0},
            time_off = {hour = 15, min = 0, sec = 0},
        },
        heatmat_controller = {
            driver = "heatmat",
            variables = {"tray_temperature", "heatmat_hysteresis", "heatmat_state"},
            temperature_target = 75.0,
            temperature_threshold_high = 1.5,
            temperature_threshold_low = 3.0,
        }
    },
    outputs = {
    },
    postprocessors = {
        textstats = {
            driver = "textstats",
            variables = {
                {name = "tray_temperature", units = "°C"},
                {name = "tray_humidity", units = "%"},
                --{name = "tray_light", units = "lux"},
                {name = "heatmat_state", units = "(on/off)"},
                {name = "growlight_state", units = "(on/off)"},
            },
            file = nil,
        },
        webstats = {
            driver = "webstats",
            wwwdir = "./misc",
            blogfile = "postprocessors/webstats/microblog.lua.example",
            stats_variables = {
                {name = "tray_temperature", units = "C", description = "Tray Temperature"},
                {name = "tray_humidity", units = "%", description = "Tray Humidity"},
                --{name = "tray_light", units = "lux", description = "Tray Light"},
                {name = "heatmat_state", units = "(on/off)", description = "Heatmat State"},
                {name = "growlight_state", units = "(on/off)", description = "Growlight State"},
            },
            plot_utc_offset = -8,
            plot_width = 600,
            plot_height = 800,
            plot_variables = {
                {name = "tray_temperature", duration = 3*60*60},
                {name = "tray_humidity", duration = 3*60*60},
                --{name = "tray_light", duration = 3*60*60},
                {name = "heatmat_state", duration = 3*60*60},
                {name = "growlight_state", duration = 3*60*60},
            },
        }
    },
}
