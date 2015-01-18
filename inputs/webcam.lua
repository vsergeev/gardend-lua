local webcam = {}
webcam.__index = webcam
setmetatable(webcam, {__call = function(self, ...) return self.new(...) end})

function webcam.new(configuration)
    local self = setmetatable({}, webcam)

    if #configuration.variables ~= 1 then
        error("invalid number of state variables in configuration. expected 1")
    elseif configuration.interval == nil then
        error("missing interval in configuration")
    elseif configuration.archivedir == nil then
        error("missing archivedir in configuration")
    elseif configuration.wwwdir == nil then
        error("missing wwwdir in configuration")
    end

    self.webcam_variable = configuration.variables[1]
    self.interval = configuration.interval
    self.archivedir = configuration.archivedir
    self.wwwdir = configuration.wwwdir

    self.count = self.interval

    return self
end

local function read_process(cmd)
    local f = io.popen(cmd)
    local s = f:read("*a")
    assert(f:close())
    -- Trim trailing newline
    return s:sub(1, #s-1)
end

function webcam:process(state)
    if self.count ~= self.interval then
        self.count = self.count + 1
        return
    end

    -- Take a high-res picture for archiving
    log(read_process('/usr/bin/fswebcam -r 1920x1080 --no-banner /tmp/gardend-webcam-hi.jpg 2>&1'))
    -- Take a low-res picture for webstats
    log(read_process('/usr/bin/fswebcam -r 640x480 --no-banner /tmp/gardend-webcam-lo.jpg 2>&1'))

    -- Timestamp the low-res picture
    assert(os.execute("/usr/bin/convert -font Liberation-Mono -pointsize 12 -fill white -undercolor '#00000080' -gravity SouthEast -annotate +0+-2 '" .. os.date("%c", state.timestamp) .. "' /tmp/gardend-webcam-lo.jpg /tmp/gardend-webcam-lo.jpg"))

    local filename = string.format("webcam-%d.jpg", state.timestamp)

    -- Copy high-res image to archive directory
    assert(os.execute("cp /tmp/gardend-webcam-hi.jpg " .. self.archivedir .. "/" .. filename))
    -- Copy low-res image to www dir
    assert(os.execute("mv /tmp/gardend-webcam-lo.jpg " .. self.wwwdir .. "/webcam.jpg"))

    -- Store filename in state
    state[self.webcam_variable] = filename

    -- Reset count
    self.count = 1
end

return webcam
