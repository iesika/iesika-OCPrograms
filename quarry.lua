--[[
 Quaryy プログラム　by iesika
 必要なmod:ic2 1.10.2
 必要なliblary:oke liblary
 ロボットの下にcharger(opencomputers),その右に蓄電池, 
 左側にチェストをおいて起動する
--]]

local oke = require("oke")
local sides = require("sides")
local shell = require("shell")
local component = require("component")
local computer = require("computer")

local cfg = {
  drill_name = {
    --1.10.2用名前
    "ic2:drill",
    "ic2:diamond_drill",
    "ic2:iridium_drill"
  }
}

local args, options = shell.parse(...)
local diameter, length = args[1] or 5, args[2] or math.huge
local recharge_point = {0, 0, 0}
local export_point = {-1, 0, 0}
local recharge_tool_point = {1, 0, 0}

local function isDrillName(stack)
  for i, name in ipairs(cfg.drill_name) do
    if stack.name == name then
      return true
    end
  end
  return false
end

local filter = {
  drill = function(stack)
    --1.10.2用名前
    return isDrillName(stack)
  end,
  drill_lowcharge = function(stack)
    if not isDrillName(stack) then
      return false
    else
      return (stack.charge / stack.maxCharge) < 0.1
    end
  end,
  all = function(stack)
    return true
  end
}

local function digLayer()
  local success = true
  for w = 1, diameter do
    for h = 1, diameter do
      if component.robot.detect(sides.down) then
        if not component.robot.swing(sides.down) then
          success = false
        end
      end
      if h ~= diameter then
        oke.forward()
      end
    end
    if w ~= diameter then
      oke.turn(w%2 == 1)
      oke.forward()
      oke.turn(w%2 == 1)
    end
  end
  oke.turnAround()
  oke.forward(diameter - 1)
  oke.turn(true)
  oke.forward(diameter - 1)
  oke.turn(true)
  return success
end

local function recharge()
  oke.compass.moveTo(table.unpack(recharge_point))
  oke.recharge()
  --if oke.countToolStack(filter.drill_lowcharge) >= 1 then
    oke.compass.moveTo(table.unpack(recharge_tool_point))
    oke.rechargeTool(sides.down)
  --end
end

local function maintenance()
  oke.compass.moveTo(0, 0, 0)
  recharge()
  oke.compass.moveTo(table.unpack(export_point))
  oke.ejectStack(sides.down, filter.all, math.huge)
end

local function needsMaintenance()
  local need = false
  if oke.countToolStack(filter.drill_lowcharge) >= 1 then
    return true
  end
  if (computer.energy() / computer.maxEnergy()) < 0.5 then
    return true
  end
  for slot = 1, component.robot.inventorySize() do
    if component.robot.count(slot) == 0 then
      return false
    end
  end
  return true
end

local function init()
  if oke.countToolStack(filter.drill) < 1 then
    error("need ic2 drill in tool slot\n")
  end
  if diameter % 2 == 0 then
    error("diameter must be odd\n")
  end
  if component.isAvailable("chunkloader") then
    component.chunkloader.setActive(true)
    io.write("chunkloader activated\n")
  else
    io.write("chunkloader not found\n")
    io.write("make sure chunk loading\n")
  end
end

--main
do
  init()
  oke.compass.init()
  maintenance()
  oke.compass.moveTo(0, 0, 0)
  for no = 0, length do
    io.write("digging hole #"..no)
    local quarry_pos = {-((diameter - 1) / 2), 0, -1 - diameter * no}
    --quarryへ
    oke.compass.moveTo(table.unpack(quarry_pos))
    oke.compass.turnTo(oke.dir.forward)
    local depth = 0
    while digLayer() do      
      if needsMaintenance() then
        oke.compass.moveTo(table.unpack(quarry_pos))
        maintenance()
        oke.compass.moveTo(table.unpack(quarry_pos))
        oke.down(depth)
      end
      depth = depth + 1
      oke.down()
    end
    oke.compass.moveTo(table.unpack(quarry_pos))
  end
end
