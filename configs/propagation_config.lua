configuration = {
    timestep = 60.0,
    dbfile = "gardend.db",
    logfile = "/var/log/gardend.log",
    inputs = {
        tray_temperature_and_humidity_sensor = {
            -- Driver name
            driver = "htu21d",
            -- State configuration
            variables = {"tray_temperature", "tray_humidity"},
            -- Block-specific configuration
            i2c_devpath = "/dev/i2c-0",
            i2c_address = 0x40,
        },
        --tray_light_sensor = {
        --    -- Driver name
        --    driver = "tsl2561",
        --    -- State configuration
        --    variables = {"tray_light"},
        --    -- Block-specific configuration
        --    i2c_devpath = "/dev/i2c-0",
        --    i2c_address = 0x39,
        --},
    },
    controllers = {
        growlight_timer = {
            -- Driver name
            driver = "timer",
            -- State configuration
            variables = {"growlight_state"},
            -- Block-specific configuration
            time_on = {hour = 6, min = 0, sec = 0},
            time_off = {hour = 20, min = 0, sec = 0},
        },
        heatmat_controller = {
            -- Driver name
            driver = "heatmat",
            -- State configuration
            variables = {"tray_temperature", "heatmat_hysteresis", "heatmat_state"},
            -- Block-specific configuration
            temperature_target = 80.0,
            temperature_window = 5.0,
        }
    },
    outputs = {
        growlight_switch = {
            -- Driver name
            driver = "gpioswitch",
            -- State configuration
            variables = {"growlight_state"},
            -- Block-specific configuration
            gpio_number = 123,
            active_low = false,
            initial_value = false,
        },
        heatmat_switch = {
            -- Driver name
            driver = "gpioswitch",
            -- State configuration
            variables = {"heatmat_state"},
            -- Block-specific configuration
            gpio_number = 125,
            active_low = false,
            initial_value = false,
        },
    },
    postprocessors = {
        textstats = {
            -- Driver name
            driver = "textstats",
            -- State configuration
            variables = {
                {name = "tray_temperature", units = "°C"},
                {name = "tray_humidity", units = "%"},
                --{name = "tray_light", units = "lux"},
                {name = "heatmat_state", units = "(on/off)"},
                {name = "growlight_state", units = "(on/off)"},
            },
            -- Block-specific configuration
            file = nil,
        },
    },
}
