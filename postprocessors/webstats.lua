local template = require("resty.template")

local webstats = {}
webstats.__index = webstats
setmetatable(webstats, {__call = function(self, ...) return self.new(...) end})

--
-- Configuration
--
--      webstats = {
--          driver = "webstats",
--          wwwdir = "/var/www",
--          blogfile = "/var/gardend/microblog.lua",
--          stats_variables = {
--              {name = "tray_temperature", units = "C", description = "Tray Temperature"},
--              {name = "tray_humidity", units = "%", description = "Tray Humidity"},
--              {name = "tray_light", units = "lux", description = "Tray Light"},
--              {name = "heatmat_state", units = "(on/off)", description = "Heatmat State"},
--              {name = "growlight_state", units = "(on/off)", description = "Growlight State"},
--          },
--          plot_utc_offset = -8,
--          plot_width = 600,
--          plot_height = 240,
--          plot_variables = {
--              {name = "tray_temperature", duration = 8*60*60},
--              {name = "tray_humidity", duration = 8*60*60},
--              {name = "tray_light", duration = 8*60*60},
--              {name = "heatmat_state", duration = 8*60*60},
--              {name = "growlight_state", duration = 8*60*60},
--          },
--      }
--
--
-- Output
--
--      wwwdir/index.html
--      wwwdir/plot.png
--      wwwdir/style.css (external)
--      wwwdir/webcam.png (external)
--

function webstats.new(configuration)
    local self = setmetatable({}, webstats)

    if configuration.wwwdir == nil then
        error("missing wwwdir in configuration")
    elseif configuration.blogfile == nil then
        error("missing blogfile in configuration")
    elseif configuration.stats_variables == nil then
        error("missing stats_variables in configuration")
    elseif configuration.plot_utc_offset == nil then
        error("missing plot_utc_offset in configuration")
    elseif configuration.plot_width == nil then
        error("missing plot_width in configuration")
    elseif configuration.plot_height == nil then
        error("missing plot_height in configuration")
    elseif configuration.plot_variables == nil then
        error("missing plot_variables in configuration")
    end

    self.template = require("resty.template")
    self.template.caching(false)
    self.template.print = function (s)
        local f = assert(io.open(self.wwwdir .. "/index.html", 'w'))
        f:write(s)
        f:close()
    end

    self.wwwdir = configuration.wwwdir
    self.templatefile = debug.getinfo(1, "S").source:sub(2):gsub("lua","html")
    self.blogfile = configuration.blogfile
    self.stats_variables = configuration.stats_variables
    self.plot_utc_seconds_offset = configuration.plot_utc_offset*60*60
    self.plot_width = configuration.plot_width
    self.plot_height = configuration.plot_height
    self.plot_variables = configuration.plot_variables

    return self
end

-- Load blog
local function loadblog(path)
    local f = assert(io.open(path, 'r'))
    local t = f:read('*all')
    f:close()
    local env = {}
    load(t, nil, 't', env)()

    return env.blog
end

function webstats:plot(state)
    -- Look up past data
    local xdatas = {}
    local ydatas = {}

    for plot_index, plot_variable in ipairs(self.plot_variables) do
        local xdata = {}
        local ydata = {}

        -- Collect current and past data
        local i = 0
        while state[i].timestamp ~= nil and (state.timestamp - state[i].timestamp) < plot_variable.duration do
            local value = state[i][plot_variable.name]

            -- Convert booleans to integers
            if type(value) == "boolean" then
                value = true and 1 or 0
            end

            table.insert(xdata, 1, state[i].timestamp + self.plot_utc_seconds_offset)
            table.insert(ydata, 1, value)
            i = i - 1
        end

        xdatas[#xdatas + 1] = xdata
        ydatas[#ydatas + 1] = ydata
    end

    -- Prepare script
    local script = {}

    local function append(setting)
        script[#script + 1] = setting
    end

    append(string.format('set terminal pngcairo transparent truecolor enhanced size %d, %d font "Arial,8"', self.plot_width, self.plot_height))
    -- Output
    append(string.format('set output "%s/plot.png"', self.wwwdir))
    -- Mulitplot Setup
    append(string.format('set multiplot layout %d, 1', #ydatas))
    -- X Input
    append('set timefmt "%s"')
    append('set xdata time')
    -- X Tick Format
    append('set format x "%H:%M"')
    -- Style
    append('set border lw 2 lc rgb "white"')
    append('set xtics textcolor rgb "white"')
    append('set ytics textcolor rgb "white"')
    append('set xlabel textcolor rgb "white"')
    append('set ylabel textcolor rgb "white"')
    append('set key textcolor rgb "white"')
    append('set title textcolor rgb "white"')
    append('set lmargin 6')
    -- Plot Commands
    for i = 1, #self.plot_variables do
        -- Plot title
        append(string.format('set title "%s"', self.plot_variables[i].name))
        -- X Axis Range
        append(string.format('set xrange ["%d":"%d"]', xdatas[i][1]-5, xdatas[i][#xdatas[i]]+5))
        -- Handle boolean values
        if type(state[self.plot_variables[i].name]) == "boolean" then
            append('set yrange [-0.5 : 1.5]')
            append('set ytics ("false" 0, "true" 1)')
        end
        -- No key
        append('unset key')
        -- Plot
        append(string.format('plot "/tmp/gardend_plot%d_data" using 1:2 with linespoints', i))
    end

    -- Write plot data
    for i = 1, #self.plot_variables do
        local f = assert(io.open(string.format("/tmp/gardend_plot%d_data", i), "w"))
        for j = 1, #xdatas[i] do
            f:write(xdatas[i][j] .. "\t" .. ydatas[i][j] .. "\n")
        end
        f:close()
    end

    -- Write plot script
    local f = assert(io.open("/tmp/gardend_plot_script", "w"))
    f:write(table.concat(script, "\n"))
    f:close()

    -- Execute gnuplot
    local result, exit, code = os.execute("gnuplot /tmp/gardend_plot_script")
end

function webstats:process(state)
    -- Load blog
    local blog = loadblog(self.blogfile)

    -- Render plots
    self:plot(state)

    -- Render template
    self.template.render(self.templatefile, {blog = blog, stats_variables = self.stats_variables, plot_variables = self.plot_variables, state = state})
end

return webstats
