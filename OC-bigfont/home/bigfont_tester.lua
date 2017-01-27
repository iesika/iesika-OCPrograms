local bigfont = require("bigfont")
local component = require("component")
local gpu = component.gpu
local w, h = gpu.getResolution()
local args = {...}

gpu.fill(1,1,w,h," ")

for size = 2, 8 do
    bigfont.load(size)
end

local y = 1

for size = 2, 8 do
    bigfont.set(1, y, args[1] or "size"..tostring(size), size)
    y = y + size
end
