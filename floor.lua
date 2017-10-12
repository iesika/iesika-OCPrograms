--[[
@file floor.lua
@brief OpenComputersのロボットに床を作らせる
@detail
燃料は考慮しない, 貼るブロックはロボットのインベントリ内のものを使う,
貼り終えたら元の位置，向きに戻る

 robotの必要最低限の構成
  :Hardware
    case(tier1↑)
    eeprom
    cpu(tier1↑)
    memory(tier1↑)
    HDD(tier1↑)
    screen(tier1↑)
    graphic card
    keyboard
    Inventory Upgrade
  :SoftWare
    luaBIOS(eeprom)
    OpenOS

@args1 (width : number, nil) 横の長さ (defalt:4)
@args2 (height : number, nil) 縦の長さ (defalt:4)
@options
-e
  ロボットのツールスロットにextracell2のblockcontainerがあるものとして
  robotのインベントリ内の資材ではなく，これを用いることで床貼りを行う
-f
  ブロックを配置する場所に既にブロックがあった場合置き換えを行う
-r
  指定された場合元の位置に戻る
@author iesika
@date 2017/9/12~
--]]

local component = require ("component")
local sides = require("sides")
local shell = require("shell")
local robot = require("robot")

local args, options = shell.parse(...)

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

--床はりルーチン
for i = 1, width do
  for j = 1, height do
    if option.f and component.robot.detect(sides.down) then
      component.robot.swing(sides.down)
    end
    selectNotEmptySlot()
    if options["e"] then
      robot.useDown()
    else
      robot.placeDown()
    end
    if j == height then--奥までいったらUターンする
      component.robot.turn(i%2 == 1)
      repeat until component.robot.move(sides.forward)
      component.robot.turn(i%2 == 1)
    else
      repeat until component.robot.move(sides.forward)
    end
  end
end

--元の位置に戻る
if options["r"] then
  if width%2 == 0 then
    robot.turnLeft()
  else
    for i = 1, height - 1 do
      repeat until component.robot.move(sides.forward)
    end
    robot.turnRight()
  end
  for i = 1, width do
    repeat until component.robot.move(sides.forward)
  end
  robot.turnRight()
end

