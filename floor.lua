local component = require ("component")
local sides = require("sides")
local shell = require("shell")
local robot = require("robot")

local args, option = shell.parse(...)

local width = tonumber(args[1]) or 4
local height = tonumber(args[2]) or 4

local function selectNotEmptySlot()
  if robot.count() > 0 then
    return true
  end
  for i = 1, robot.inventorySize() do
    if robot.count(i) > 0 then
      robot.select(i)
      return true
    end
  end
  return false
end

for i = 1, width do
  for j = 1, height do
    if option.f and component.robot.detect(sides.down) then
      component.robot.swing(sides.down)
    end
    selectNotEmptySlot()
    component.robot.place(sides.down)
    if j == height then--奥までいったらUターンする
      component.robot.turn(i%2 == 1)
      repeat until component.robot.move(sides.forward)
      component.robot.turn(i%2 == 1)
    else
      repeat until component.robot.move(sides.forward)
    end
  end
end
