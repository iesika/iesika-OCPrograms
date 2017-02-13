-- libray for OpenComputers robot
-- over kill engine (Carnage Heart)
local oke = {}

local component = require("component")
local sides = require("sides")

local cfg = {
  interval = 1
}

--相対座標管理用
--turnやmoveした際に移動量, 回転数を記憶し, 相対位置に移動できるようにする
oke.compass = {}
oke.compass.x, oke.compass.y, oke.compass.z = 0, 0 ,0
oke.compass.facing = 0
--[[
      ↑0(-z)
3(-x)← →1(+x)
      ↓2(+z)
--]]

local save = {}
save.x, save.y, save.z = 0, 0, 0
save.facing = 0

--現在向いている方向, 位置を初期化する
function oke.compass.init()
  oke.compass.x, oke.compass.y, oke.compass.z = 0, 0 ,0
  oke.compass.facing = 0
end

function oke.compass.getPos()
  return oke.compass.x, oke.compass.y, oke.compass.z
end

--現在地と向いている方向をresumeを呼んだ時に戻れるように保存する
function oke.compass.save()
 save.x, save.y, save.z = oke.compass.x, oke.compass.y, oke.compass.z
 save.facing = oke.compass.facing
end

function oke.compass.resume()
  oke.compass.moveTo(save.x, save.y, save.z)
  while oke.compass.facing ~= save.facing do
    oke.turn(true)
  end
end

--移動した後の向きは不定
function oke.compass.moveTo(x, y, z)
  local function facing(face)
    while oke.compass.facing ~= face do
      oke.turn(true)
    end
  end
  if y < oke.compass.y then
    oke.down(oke.compass.y - y)
  elseif y > oke.compass.y then
    oke.up(y - oke.compass.y)
  end
  if x < oke.compass.x then
    facing(3)
    oke.forward(oke.compass.x - x)
  elseif x > oke.compass.x then
    facing(1)
    oke.forward(x - oke.compass.x)
  end
  if z < oke.compass.z then
    facing(0)
    oke.forward(oke.compass.z - z)
  elseif z > oke.compass.z then
    facing(2)
    oke.forward(z - oke.compass.z)
  end
end

local function checkComponent(componentName)
  if not component.isAvailable(componentName) then
    io.write("require " .. componentName .. "Aborting...")
    os.exit()
  end
end

function oke.prompt(message)
  io.write(message .. " [Y/n] ")
  local result = io.read()
  return result and (result == "" or result:lower() == "y")
end

--ロボット内にあるfilterに合致するアイテムの数を数える
function oke.countStack(filter)
  checkComponent("inventory_controller")
  checkComponent("robot")
  local size = 0
  for slot = 1, component.robot.inventorySize() do
    local stack = component.inventory_controller.getStackInInternalSlot(slot)
    if filter and filter(stack) and stack and stack.size then
      size = size + stack.size
    elseif not filter then
      size = size + component.robot.count(slot)
    end
  end
  return size
end

--side方向にインベントリがあればfilterに合致するアイテムがあればcountの数だけ取得する
function oke.pullStack(side, filter, count)
  checkComponent("inventory_controller")
  checkComponent("robot")
  local remain = count
  for slot = 1, component.inventory_controller.getInventorySize(side) do
    local stack = component.inventory_controller.getStackInSlot(side, slot)
    if stack and filter and filter(stack) then
      component.inventory_controller.suckFromSlot(side, slot, remain)
      remain = remain - stack.size
      if remain <= 0 then
        break
      end
    end
  end
end

--１つでもアイテムが移動すればtrueを返す
function oke.ejectStack(side, filter, count)
  checkComponent("inventory_controller")
  checkComponent("robot")
  local remain = count 
  local isEjected = false
  local preSlot = component.robot.select()
  for slot = component.robot.inventorySize(), 1, -1 do
    local stack = component.inventory_controller.getStackInInternalSlot(slot)
    if stack and filter and filter(stack) then
      component.robot.select(slot)
      isEjected = isEjected or component.robot.drop(side, remain)
      remain = remain - stack.size
      if remain <= 0 then
        break
      end
    end
  end
  component.robot.select(preSlot)
  return isEjected
end

function oke.merge()
  checkComponent("inventory_controller")
  checkComponent("robot")
  local beforeSlot = component.robot.select()--選択前のスロットを記憶
  for fromSlot = component.robot.inventorySize(), 1, -1 do
    component.robot.select(fromSlot)
    for toSlot = 1, fromSlot - 1 do
      if component.robot.count(fromSlot) > 0 then 
        if component.robot.compareTo(toSlot) or component.robot.count(toSlot) == 0 then
          component.robot.transferTo(toSlot)
        end
      else
        break
      end
    end 
  end
  component.robot.select(beforeSlot)
end

--if robot find obstacle, robot will try remove it.
function oke.move(side, distance, soft)
  checkComponent("robot")
  if side == sides.back then
    side = sides.forward
    oke.turnAround(true)
  elseif side == sides.right or side == sides.left then
    oke.turn(side == sides.right)
    side = sides.forward
  end
  side = side or sides.forward
  local function tryMove()
    local flag, reason = component.robot.move(side)
    if not flag and not soft then
      component.robot.swing(side)
      flag = component.robot.move(side)
    end
    if flag then--side方向に移動成功
      if side == sides.down  then
        oke.compass.y = oke.compass.y - 1
      elseif side == sides.up then
        oke.compass.y = oke.compass.y + 1
      elseif side == sides.forward then
        if oke.compass.facing == 0 then
          oke.compass.z = oke.compass.z - 1
        elseif oke.compass.facing == 1 then
          oke.compass.x = oke.compass.x + 1
        elseif oke.compass.facing == 2 then
          oke.compass.z = oke.compass.z + 1
        elseif oke.compass.facing == 3 then
          oke.compass.x = oke.compass.x - 1
        end
      end
    end
    return flag
  end
  for d = 1, distance do
    while not tryMove() do
      os.sleep(cfg.interval)
    end
  end
end

function oke.forward(distance, soft)
  distance = distance or 1
  oke.move(sides.forward, distance, soft)
end

function oke.up(distance, soft)
  distance = distance or 1
  oke.move(sides.up, distance, soft)
end

function oke.down(distance, soft)
  distance = distance or 1
  oke.move(sides.down, distance, soft)
end

--just readbilty
function oke.turn(clockwise)
  checkComponent("robot")
  local flag = component.robot.turn(clockwise)
  if flag then
    oke.compass.facing = (oke.compass.facing + (clockwise and 1 or -1)) % 4
  end
  return flag
end

function oke.turnAround(clockwise)
  checkComponent("robot")
  if clockwise == nil then
    clockwise = false
  end
  oke.compass.facing = (oke.compass.facing + 2) % 4
  return component.robot.turn(clockwise) and component.robot.turn(clockwise)
end

function oke.place(direction, slot, soft)
  checkComponent("robot")
  direction = direction or sides.forward
  slot = tonumber(slot)
  local before = component.robot.select()--選択前のスロットを記憶
  component.robot.select(slot)
  local function tryPlace()
    local flag = component.robot.place(direction)
    if not flag and not soft then
      component.robot.swing(direction)
      tryPlace()
    end
    component.robot.select(before)
    return true
  end
  if not component.robot.compare(direction, true) then--同じブロックなら配置しない
    while not tryPlace() do
      os.sleep(cfg.interval)
    end
  end
  component.robot.select(before)
  return true
end

--soft == trueで既にブロックがあった場合破壊を試みない
function oke.placeStack(direction, filter, soft)
  checkComponent("inventory_controller")
  checkComponent("robot")
  for slot = 1, component.robot.inventorySize() do
    stack = component.inventory_controller.getStackInInternalSlot(slot)
    if filter and filter(stack) then
       return oke.place(direction, slot, soft)
    end
  end
  return false
end

function oke.suckAll()
  checkComponent("tractor_beam")
  while component.tractor_beam.suck() do end
end

function oke.analyze(side)
  checkComponent("geolyzer")
  return component.geolyzer.analyze(side)
end

return oke