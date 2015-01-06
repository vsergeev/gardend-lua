# gardend design

## Basic Operation

`gardend` is a discrete-time control daemon with a lightweight framework for managing system state and implementing processing blocks. System state is maintained in a flat associative array, mapping unique variable names to values for inputs, intermediate computations, and outputs, which can be populated by and accessed from different processing blocks. All state is maintained in this structure and it is stored persistently so that the daemon may recover from a crash or reboot to resume system control with past state left in-tact. The processing blocks are comprised of drivers, controllers, and post-processing routines to read sensors, compute output states, drive outputs, compute statitistics and generate visualizations.

The main job of the daemon is four stages of processing on every time step: `inputs`, `controllers`, `outputs`, and `posts`. The `inputs` stage runs all input processing blocks to introduce input variables into the system state for the current time step, from hardware sensors or other data sources. The `controllers` stage runs all controller processing blocks to produce output variables from current and past system state. The `outputs` stage runs all output processing blocks to apply output variables to hardware or other external agents. Finally, the `posts` stage runs all post processing blocks to carry out arbitrary post-processing of the current and past states, such as updating visualizations or statistics. The four categories of processing stages ensure that all input and output dependencies between processing blocks are accounted for during their construction.

The daemon runs in a single thread and assumes the time step is relatively slow (e.g. 1 minute) compared to the execution time of the processing blocks. For the time being, the daemon executes every processing block on each time step.

Daemon main loop pseudocode:

```
while true do
    state:initialize()

    for _, block in ipairs(InputBlocks) do
        block:process(state)
    done
    for _, block in ipairs(ControllerBlocks) do
        block:process(state)
    done
    for _, block in ipairs(OutputBlocks) do
        block:process(state)
    done
    for _, block in ipairs(PostBlocks) do
        block:process(state)
    done

    state:record()

    sleep_until_next_timestep()
end
```

## System State

The system state for a particular time step is stored in a simple table key/value pairs for the timestamp, input data, intermediate computations, and outputs. Input blocks should populate the system state with the key/value pair(s) containing sampled data. Controller blocks should populate the system state with key/value pair(s) containing computed outputs and intermediate computations (if necessary). Output blocks should use the system state to drive outputs. Posts blocks should use system state to generate visualiaztions or statistics. In general, processing blocks should not maintain their own state and should keep all required state in the system state structure.

``` lua
{
        timestamp = 1420022112.0,
        ambient_temperature = 25.0,
        tray_temperature = 27.6,
        tray_humidity = 0.70,
        growlight_state = true,
        heatmat_state = true,
}
```

Processing blocks may access past system state by indexing the state structure with a negative index -- e.g. `state[-1]` refers to the system state one time step ago. If the system state does not exist for a given time index, it will be `nil`.

``` lua
state[-1] ->
{
        timestamp = 1420022052.0,
        ambient_temperature = 24.9,
        tray_temperature = 27.5,
        tray_humidity = 0.71,
        growlight_state = true,
        heatmat_state = true,
}

state[-2] ->
{
        timestamp = 1420021992.0,
        ambient_temperature = 24.8,
        tray_temperature = 27.5,
        tray_humidity = 0.70,
        growlight_state = true,
        heatmat_state = true,
}

state[-500] -> nil
```

## Configuration

The configuration structure for `gardend` specifies the processing blocks to be instantiated in the system, the variable names the processing blocks will look up or populate in the system state, and other block-specific configuration. The configuration is stored as a table with `inputs`, `controllers`, `outputs`, `posts` subtables that contain the configuration of processing blocks belonging to those processing stages.

Configuration format:

``` lua
configuration = {
    timestep = <time step in seconds>
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
    posts = {
        ...
    },
}
```

The `driver` string specifies the driver filename to load. The `variables` array specifies which state variables the block may populate or access in a driver-specific order. The variable names referenced in the `variables` table must be unique names.

Example:

``` lua
configuration = {
    timestep = 60.0,
    inputs = {
        ambient_temperature_sensor = {
            -- Driver name
            driver = "tmp102",
            -- State configuration
            variables = {"ambient_temperature"},
            -- Block-specific configuration
            i2c_devpath = "/dev/i2c-0",
            i2c_address = 0x20,
        },
        tray_temperature_and_humidity_sensor = {
            -- Driver name
            driver = "htu21d",
            -- State configuration
            variables = {"tray_temperature", "tray_humidity"},
            -- Block-specific configuration
            i2c_devpath = "/dev/i2c-0",
            i2c_address = 0x21,
        },
    },
    controllers = {
        growlight = {
            -- Driver name
            driver = "timer",
            -- State configuration
            variables = {"growlight_state"},
            -- Block-specific configuration
            time_on = "6:00am",
            time_off = "8:00pm",
        },
        heatmat = {
            -- Driver name
            driver = "heatmat",
            -- State configuration
            variables = {"tray_temperature", "heatmat_state"},
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
        },
        heatmat_switch = {
            -- Driver name
            driver = "gpioswitch",
            -- State configuration
            variables = {"heatmat_state"},
            -- Block-specific configuration
            gpio_number = 125,
        },
    },
    posts = {
        console = {
            -- Driver name
            driver = "consolestats",
            -- Block-specific configuration
        },
    },
}
```

## Processing Blocks

Processing blocks are code files named by their driver name and live in `inputs/`, `controllers/`, `outputs/`, `posts/` folders. The imported block module should be a callable constructor for the block that takes a configuration table as its first argument and returns an instance of that block.

For example, input processing block `foo` would live in `inputs/foo.lua`, and can be instantiated and configured with:

``` lua
local foo = require("inputs.foo")
foo_instance = foo(foo_configuration)
```

The configuration structure passed to the block is the corresponding subtable from the configuration structure above.

All processing blocks objects should provide a `process(state <table>)` method that take the system state as an argument. This method should look up and/or populate keys in the passed in system state table.

``` lua
foo_instance:process(state)
```

## System State Persistence and Recovery

The system states are stored persistently in database. Database is TBD.

