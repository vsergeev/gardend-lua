# gardend design

## Basic Operation

`gardend` is a discrete-time control daemon with a lightweight framework for managing system state and implementing processing blocks. System state is maintained in a flat associative array, mapping variable names to values that may be inputs, intermediate computations, or outputs. Processing blocks are drivers, controllers, and post-processing routines that read sensors, compute output states, drive outputs, compute statistics or generate visualizations, respectively, and may access or populate variables in the system state. All system state is maintained in one time-indexed structure that is stored persistently, so that the daemon may recover from a crash or reboot to resume system control with past state left in-tact.

The main job of the daemon is executing processing blocks in four stages on every time step: `inputs`, `controllers`, `outputs`, and `postprocessors`. The `inputs` stage runs all input processing blocks to introduce input variables into the system state for the current time step, from hardware sensors or other data sources. The `controllers` stage runs all controller processing blocks to produce output variables from current and past system state variables. The `outputs` stage runs all output processing blocks to apply output variables to hardware or other external agents. Finally, the `postprocessors` stage runs all post-processing blocks to carry out arbitrary post-processing of the current and past system state variables, such as updating visualizations or statistics. The four categories of processing stages ensure that all input and output dependencies between processing blocks are accounted for during their construction.

The daemon runs in a single thread and assumes the time step is relatively long (e.g. 1 minute) compared to the execution time of the processing blocks. The daemon executes every processing block on each time step.

Daemon main loop pseudocode:

```
while true do
    state:stamp()

    for _, block in ipairs(InputBlocks) do
        block.object:process(state)
    done
    for _, block in ipairs(ControllerBlocks) do
        block.object:process(state)
    done
    for _, block in ipairs(OutputBlocks) do
        block.object:process(state)
    done
    for _, block in ipairs(PostprocessorBlocks) do
        block.object:process(state)
    done

    state:record()

    sleep(timestep)
end
```

## System State

The system state for a particular time step is stored in a simple table containing the timestamp, input data, intermediate computations, and outputs. Input blocks should populate variables in the system state with sampled data. Controller blocks should populate variables in the system state with computed outputs and any intermediate computations, if necessary. Output blocks should access variables in the system state to drive outputs. Postprocessor blocks should access variables in the system state to generate visualizations or statistics. In general, processing blocks should not maintain their own state and should keep all required state in the system state structure.

System state table example:

``` lua
{
        timestamp = 1420022112.0,
        ambient_temperature = 25.0,
        tray_temperature = 27.6,
        tray_humidity = 70.0,
        growlight_state = true,
        heatmat_state = true,
}
```

Processing blocks may access past system state by indexing the state structure with a negative index -- e.g. `state[-1]` refers to the system state one time step ago. If the system state does not exist for a given time index, it will be the empty table `{}`.

``` lua
state[-1] ->
{
        timestamp = 1420022052.0,
        ambient_temperature = 24.9,
        tray_temperature = 27.5,
        tray_humidity = 71.0,
        growlight_state = true,
        heatmat_state = true,
}

state[-2] ->
{
        timestamp = 1420021992.0,
        ambient_temperature = 24.8,
        tray_temperature = 27.5,
        tray_humidity = 70.0,
        growlight_state = true,
        heatmat_state = true,
}

state[-3] -> {}

state[-500] -> {}
```

## Configuration

The configuration structure for `gardend` specifies the processing blocks to be instantiated in the system, the variable names the processing blocks will look up or populate in the system state, and other block-specific configuration. The configuration is stored as a table with `inputs`, `controllers`, `outputs`, `postprocessors` subtables that contain the configuration of processing blocks belonging to those processing stages.

Configuration format:

``` lua
configuration = {
    timestep = <time step in seconds>,
    dbfile = <database file path>,
    logfile = <log file path>,
    inputs = {
        <instance name> = {
            -- Driver name
            driver = <driver name>,
            -- State variables configuration
            variables = {<state variable name>, ...},
            -- Block-specific configuration
            ...
        },
        ...
    },
    controllers = {
        ...
    },
    outputs = {
        ...
    },
    postprocessors = {
        ...
    },
}
```

The `driver` string specifies the driver filename to load. The `variables` array specifies which state variables the block may populate or access in a driver-specific order.

Configuration example:

``` lua
configuration = {
    timestep = 60.0,
    dbfile = "/var/gardend/gardend.db",
    logfile = "/var/gardend/gardend.log",
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
        tray_light_sensor = {
            -- Driver name
            driver = "tsl2561",
            -- State configuration
            variables = {"tray_light"},
            -- Block-specific configuration
            i2c_devpath = "/dev/i2c-0",
            i2c_address = 0x39,
        },
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
            -- Block-specific configuration
            variables = {
                {name = "tray_temperature", units = "°C"},
                {name = "tray_humidity", units = "%"},
                {name = "tray_light", units = "lux"},
                {name = "heatmat_state", units = "(on/off)"},
                {name = "growlight_state", units = "(on/off)"},
            },
            file = nil,
        },
        webstats = {
            -- Driver name
            driver = "webstats",
            -- Block-specific configuration
            wwwdir = '/var/www',
            blogfile = '/var/gardend/microblog.lua',
            stats_variables = {
                {name = "tray_temperature", units = "°C", description = "Tray Temperature"},
                {name = "tray_humidity", units = "%", description = "Tray Humidity"},
                {name = "tray_light", units = "lux", description = "Tray Light"},
                {name = "heatmat_state", units = "(on/off)", description = "Heatmat State"},
                {name = "growlight_state", units = "(on/off)", description = "Growlight State"},
            },
            plot_utc_offset = -8,
            plot_width = 640,
            plot_height = 240,
            plot_variables = {
                {name = "tray_temperature", duration = 8*60*60},
                {name = "tray_humidity", duration = 8*60*60},
                {name = "tray_light", duration = 8*60*60},
                {name = "heatmat_state", duration = 8*60*60},
                {name = "growlight_state", duration = 8*60*60},
            },
        }
    },
}
```

## Processing Blocks

Processing blocks live in the `inputs/`, `controllers/`, `outputs/`, `postprocessors/` folders and are named by their driver name. An imported processing block should be a callable constructor that takes a configuration table as its first argument and returns an instance of the block. The object is required to implement the `process(state <table>)` method.

For example, input processing block `foo` would live at `inputs/foo.lua`, and can be instantiated and configured with:

``` lua
local foo = require("inputs.foo")
foo_instance = foo(foo_configuration)
```

The configuration structure passed to the block is a block subtable from the configuration structure above.

All processing blocks must implement the `process(state <table>)` method, which will be called by gardend on each time step to execute the processing block. The processing block may look up and/or populate keys in the state table.

``` lua
foo_instance:process(state)
```

## System State Persistence

At the end of each time step, the system state is serialized into a JSON object and inserted as a row into the SQLite database specified by the configuration variable `dbfile`. Look-ups into past system state by processing blocks are made by fetching the row corresponding to the time index to look up and deserializing the JSON object stored there into a system state table. SQLite provides durable storage and efficient random access into past system state and JSON fulfills the need for serializing and deserializing the system state to/from storage.

The SQLite database schema is:

```
CREATE TABLE GardenState(timestamp INTEGER, state TEXT);
```

