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
--      wwwdir/style.css (external)
--      wwwdir/webcam.png (external)
--      wwwdir/plots/plot1.png
--      wwwdir/plots/plot2.png
--      wwwdir/plots/plot3.png
--      wwwdir/plots/...
--

function webstats.new(configuration)
    local self = setmetatable({}, webstats)

    if configuration.wwwdir == nil then
        error("missing wwwdir in configuration")
    elseif configuration.blogfile == nil then
        error("missing blogfile in configuration")
    elseif configuration.stats_variables == nil then
        error("missing stats_variables in configuration")
    elseif configuration.plot_width == nil then
        error("missing plot_width in configuration")
    elseif configuration.plot_height == nil then
        error("missing plot_height in configuration")
    elseif configuration.plot_utc_offset == nil then
        error("missing plot_utc_offset in configuration")
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
    self.templatefile, _ = debug.getinfo(1, "S").source:sub(2):gsub("lua","html")
    self.blogfile = configuration.blogfile
    self.stats_variables = configuration.stats_variables
    self.plot_width = configuration.plot_width
    self.plot_height = configuration.plot_height
    self.plot_utc_offset = configuration.plot_utc_offset
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

function webstats:utc_adjust(t)
    return t + self.plot_utc_offset*60*60
end

function webstats:process(state)
    -- Load blog
    local blog = loadblog(self.blogfile)

    -- Render plots
    -- FIXME

    -- Render template
    self.template.render(self.templatefile, {blog = blog, stats_variables = self.stats_variables, plot_variables = self.plot_variables, state = state})
end

return webstats
