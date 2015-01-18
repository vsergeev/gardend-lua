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

    -- Take a picture
    log(read_process('/usr/bin/fswebcam -r 640x480 --no-shadow --banner-colour "#80000000" --line-colour "#FF000000" /tmp/gardend-webcam.jpg'))

    local filename = string.format("webcam-%d.jpg", state.timestamp)

    -- Copy image to archive directory
    assert(os.execute("cp /tmp/gardend-webcam.jpg " .. self.archivedir .. "/" .. filename))
    -- Copy image to www dir
    assert(os.execute("mv /tmp/gardend-webcam.jpg " .. self.wwwdir .. "/webcam.jpg"))

    -- Put filename into the state
    state[self.webcam_variable] = filename

    -- Reset count
    self.count = 1
end

return webcam
