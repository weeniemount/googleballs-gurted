-- Vector class for 3D positions
Vector = {}
Vector.__index = Vector

function Vector.new(x, y, z)
    local self = setmetatable({}, Vector)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    return self
end

function Vector:addX(x)
    self.x = self.x + x
end

function Vector:addY(y)
    self.y = self.y + y
end

function Vector:addZ(z)
    self.z = self.z + z
end

function Vector:set(x, y, z)
    self.x = x
    self.y = y or self.y
    self.z = z or self.z
end

-- Point class for individual animated points
Point = {}
Point.__index = Point

function Point.new(x, y, z, size, colour)
    local self = setmetatable({}, Point)
    self.colour = colour
    self.curPos = Vector.new(x, y, z)
    self.friction = 0.8
    self.originalPos = Vector.new(x, y, z)
    self.radius = size
    self.size = size
    self.springStrength = 0.1
    self.targetPos = Vector.new(x, y, z)
    self.velocity = Vector.new(0, 0, 0)
    return self
end

function Point:update()
    -- X axis spring physics
    local dx = self.targetPos.x - self.curPos.x
    local ax = dx * self.springStrength
    self.velocity.x = self.velocity.x + ax
    self.velocity.x = self.velocity.x * self.friction
    self.curPos.x = self.curPos.x + self.velocity.x

    -- Y axis spring physics
    local dy = self.targetPos.y - self.curPos.y
    local ay = dy * self.springStrength
    self.velocity.y = self.velocity.y + ay
    self.velocity.y = self.velocity.y * self.friction
    self.curPos.y = self.curPos.y + self.velocity.y

    -- Z axis for scaling effect
    local dox = self.originalPos.x - self.curPos.x
    local doy = self.originalPos.y - self.curPos.y
    local dd = (dox * dox) + (doy * doy)
    local d = math.sqrt(dd)

    self.targetPos.z = d / 100 + 1
    local dz = self.targetPos.z - self.curPos.z
    local az = dz * self.springStrength
    self.velocity.z = self.velocity.z + az
    self.velocity.z = self.velocity.z * self.friction
    self.curPos.z = self.curPos.z + self.velocity.z

    -- Update radius based on Z position
    self.radius = self.size * self.curPos.z
    if self.radius < 1 then
        self.radius = 1
    end
end

function Point:draw(ctx)
    ctx:setFillStyle(self.colour)
    ctx:beginPath()
    ctx:arc(self.curPos.x, self.curPos.y, self.radius, 0, 2 * math.pi, false)
    ctx:fill()
end

-- PointCollection class to manage all points
PointCollection = {}
PointCollection.__index = PointCollection

function PointCollection.new()
    local self = setmetatable({}, PointCollection)
    self.mousePos = Vector.new(0, 0, 0)
    self.points = {}
    return self
end

function PointCollection:addPoint(x, y, z, size, colour)
    local point = Point.new(x, y, z, size, colour)
    table.insert(self.points, point)
    return point
end

function PointCollection:update()
    for i, point in ipairs(self.points) do
        if point then
            local dx = self.mousePos.x - point.curPos.x
            local dy = self.mousePos.y - point.curPos.y
            local dd = (dx * dx) + (dy * dy)
            local d = math.sqrt(dd)

            if d < 150 then
                -- Mouse is close, repel the point
                point.targetPos.x = point.curPos.x - dx
                point.targetPos.y = point.curPos.y - dy
            else
                -- Mouse is far, return to original position
                point.targetPos.x = point.originalPos.x
                point.targetPos.y = point.originalPos.y
            end

            point:update()
        end
    end
end

function PointCollection:draw(ctx)
    for i, point in ipairs(self.points) do
        if point then
            point:draw(ctx)
        end
    end
end

function PointCollection:recenter(canvasWidth, canvasHeight)
    local offsetX = (canvasWidth / 2 - 180)
    local offsetY = (canvasHeight / 2 - 65)

    for i, point in ipairs(self.points) do
        -- Calculate relative position from original center
        local relX = point.originalPos.x - (canvasWidth / 2 - 180)
        local relY = point.originalPos.y - (canvasHeight / 2 - 65)

        -- Update positions
        point.originalPos.x = offsetX + relX
        point.originalPos.y = offsetY + relY
        point.curPos.x = point.originalPos.x
        point.curPos.y = point.originalPos.y
    end
end

-- Global variables
local canvas
local ctx
local pointCollection
local canvasWidth, canvasHeight
local reloadMsg

-- Initialize the application
function init()
    canvas = gurt.select('#canvas')
    ctx = canvas:withContext('2d')
    reloadMsg = gurt.select('#reload-msg')

    updateCanvasDimensions()
    createPoints()
    initEventListeners()
    showReloadMessage()
    
    -- Start animation loop
    gurt.timer.setInterval(30, function()
        draw()
        update()
    end)
end

function updateCanvasDimensions()
    canvasWidth = gurt.window.innerWidth
    canvasHeight = gurt.window.innerHeight
    canvas:attr('width', canvasWidth)
    canvas:attr('height', canvasHeight)
    
    if pointCollection then
        pointCollection:recenter(canvasWidth, canvasHeight)
    end
end

function createPoints()
    -- Original Google logo point data
    local pointData = {
        {202, 78, 0.0, 9, "#ed9d33"}, {348, 83, 0.0, 9, "#d44d61"}, {256, 69, 0.0, 9, "#4f7af2"},
        {214, 59, 0.0, 9, "#ef9a1e"}, {265, 36, 0.0, 9, "#4976f3"}, {300, 78, 0.0, 9, "#269230"},
        {294, 59, 0.0, 9, "#1f9e2c"}, {45, 88, 0.0, 9, "#1c48dd"}, {268, 52, 0.0, 9, "#2a56ea"},
        {73, 83, 0.0, 9, "#3355d8"}, {294, 6, 0.0, 9, "#36b641"}, {235, 62, 0.0, 9, "#2e5def"},
        {353, 42, 0.0, 8, "#d53747"}, {336, 52, 0.0, 8, "#eb676f"}, {208, 41, 0.0, 8, "#f9b125"},
        {321, 70, 0.0, 8, "#de3646"}, {8, 60, 0.0, 8, "#2a59f0"}, {180, 81, 0.0, 8, "#eb9c31"},
        {146, 65, 0.0, 8, "#c41731"}, {145, 49, 0.0, 8, "#d82038"}, {246, 34, 0.0, 8, "#5f8af8"},
        {169, 69, 0.0, 8, "#efa11e"}, {273, 99, 0.0, 8, "#2e55e2"}, {248, 120, 0.0, 8, "#4167e4"},
        {294, 41, 0.0, 8, "#0b991a"}, {267, 114, 0.0, 8, "#4869e3"}, {78, 67, 0.0, 8, "#3059e3"},
        {294, 23, 0.0, 8, "#10a11d"}, {117, 83, 0.0, 8, "#cf4055"}, {137, 80, 0.0, 8, "#cd4359"},
        {14, 71, 0.0, 8, "#2855ea"}, {331, 80, 0.0, 8, "#ca273c"}, {25, 82, 0.0, 8, "#2650e1"},
        {233, 46, 0.0, 8, "#4a7bf9"}, {73, 13, 0.0, 8, "#3d65e7"}, {327, 35, 0.0, 6, "#f47875"},
        {319, 46, 0.0, 6, "#f36764"}, {256, 81, 0.0, 6, "#1d4eeb"}, {244, 88, 0.0, 6, "#698bf1"},
        {194, 32, 0.0, 6, "#fac652"}, {97, 56, 0.0, 6, "#ee5257"}, {105, 75, 0.0, 6, "#cf2a3f"},
        {42, 4, 0.0, 6, "#5681f5"}, {10, 27, 0.0, 6, "#4577f6"}, {166, 55, 0.0, 6, "#f7b326"},
        {266, 88, 0.0, 6, "#2b58e8"}, {178, 34, 0.0, 6, "#facb5e"}, {100, 65, 0.0, 6, "#e02e3d"},
        {343, 32, 0.0, 6, "#f16d6f"}, {59, 5, 0.0, 6, "#507bf2"}, {27, 9, 0.0, 6, "#5683f7"},
        {233, 116, 0.0, 6, "#3158e2"}, {123, 32, 0.0, 6, "#f0696c"}, {6, 38, 0.0, 6, "#3769f6"},
        {63, 62, 0.0, 6, "#6084ef"}, {6, 49, 0.0, 6, "#2a5cf4"}, {108, 36, 0.0, 6, "#f4716e"},
        {169, 43, 0.0, 6, "#f8c247"}, {137, 37, 0.0, 6, "#e74653"}, {318, 58, 0.0, 6, "#ec4147"},
        {226, 100, 0.0, 5, "#4876f1"}, {101, 46, 0.0, 5, "#ef5c5c"}, {226, 108, 0.0, 5, "#2552ea"},
        {17, 17, 0.0, 5, "#4779f7"}, {232, 93, 0.0, 5, "#4b78f1"}
    }

    pointCollection = PointCollection.new()

    -- Create points with centered positioning
    for i, data in ipairs(pointData) do
        local x = (canvasWidth / 2 - 180) + data[1]
        local y = (canvasHeight / 2 - 65) + data[2]
        local z = data[3]
        local size = data[4]
        local color = data[5]
        
        pointCollection:addPoint(x, y, z, size, color)
    end
end

function initEventListeners()
    -- Mouse movement tracking
    gurt.body:on('mousemove', function(event)
        if pointCollection then
            pointCollection.mousePos:set(event.x, event.y, 0)
        end
    end)

    -- Window resize handling
    gurt.window:on('resize', function()
        updateCanvasDimensions()
    end)

    -- Keyboard shortcuts
    gurt.body:on('keydown', function(event)
        if event.ctrl and event.key == 'r' then
            -- Ctrl+R to reset points
            createPoints()
            trace.log('Points reset!')
        end
    end)
end

function showReloadMessage()
    reloadMsg:style('display', 'block')
    
    -- Fade out after 3 seconds
    gurt.timer.setTimeout(3000, function()
        reloadMsg:style('display', 'none')
    end)
end

function draw()
    -- Clear canvas
    ctx:clearRect(0, 0, canvasWidth, canvasHeight)
    
    -- Draw all points
    if pointCollection then
        pointCollection:draw(ctx)
    end
end

function update()
    -- Update all points
    if pointCollection then
        pointCollection:update()
    end
end
