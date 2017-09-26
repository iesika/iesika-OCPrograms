--[[
@file oke.lua
@brief libray for OpenComputers robot, Over Kill Engine (Carnage Heart)
@author iesika
@date 2017/9/12~
@detail
  主にcomponent.robot, component.inventory_controllerのwrapperを提供する
--]]

local oke = {}

local component = require("component")
local computer = require("computer")
local sides = require("sides")

--[[ init ]]--
--robot専用ライブラリであるから，robot内環境以外では使えなくする．
if not component.isAvailable("robot") then
  return nil
end

oke.version = 1

--[[ Constants ]]--

local CONSTANTS = {}
--充電待機時に，充電状態を再確認するまでの長さ
CONSTANTS.CHARGE_INTERVAL = 5
--移動失敗した際に、再度移動を試みるまでのwait時間
CONSTANTS.MOVE_FAILINTERVAL = 0
--ブロック設置失敗した際に、再度ブロック設置を試みるまでのwait時間
CONSTANTS.PLACE_INTERVAL = 5
--インベントリコントローラーがない場合のエラー表示
CONSTANTS.IC_ERROR = "require inventory controller."
CONSTANTS.NOEQUIP_ERROR = "robot does not equip tool"
CONSTANTS.NOIC2EQUIP_ERROR = "robot does not have valid ic2 tool"
CONSTANTS.NOCHARGEBOX_ERROR = "robot can't insert ic2 tool to charge box"
--tractor beamがない場合のエラー表示
CONSTANTS.TB_ERROR = "require tractor beam."
--geolyzerがない場合のエラー
CONSTANTS.GEO_ERROR = "require geolyzer."

--ロボットのツールスロットにアイテムがない場合のエラー表示

--[[ States ]]--

local state = {}
--インベントリ操作高速化の為、前回使ったスロットを記憶しておく
state.slot = 1

--[[ Utility ]]--


--[[ API ]]--

--[[ API - utility ]]--

--[[
@fn
ロボット使用者に許可を求める
@brief robotのスクリーンに実行許可を得られるかの質問を表示する
@param (message : string) 表示するメッセージ
@return 許可が得られたらtrue，そうでなければfalse
--]]
function oke.prompt(message)
  io.write(message .. " [Y/n] ")
  local result = io.read()
  return result and (result == "" or result:lower() == "y")
end

--[[
@fn
エネルギー量の割合を調べる
@brief エネルギー量の割合を調べる
@return 貯蔵されているエネルギー量(0 ~ 1, 1が最大値)
--]]
function oke.getEnergyRatio()
  return (computer.energy() / computer.maxEnergy())
end

--[[ API - charge ]]--

--[[
@fn
ロボットを充電する
@brief ロボットが充電状態にあるとして，充電完了まで待つ
@return 充電完了したか
--]]
function oke.recharge()
  repeat
    computer.pullSignal(CONSTANTS.CHARGE_INTERVAL)
  until computer.energy() >= computer.maxEnergy() - 100
  return true
end

--[[
@fn
ロボットのツールを充電する
@brief ロボットのツールスロットのアイテムを充電する(ic2の装備を想定)
@param (side : number) 充電可能なブロックがある方向
@return 充電完了できたらtrue，できなければfalse, errmsg
--]]
function oke.rechargeTool(side)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  local ic = component.inventory_controller
  local slot = component.robot.select()
  --ツールスロットと選択されたスロットのアイテムを交換
  ic.equip()
  --stackは充電しようとしているツールアイテム
  local stack = ic.getStackInInternalSlot(slot)
  if not stack then
    return false, CONSTANTS.NOEQUIP_ERROR
  end
  if not stack.charge or not stack.maxCharge then
    return false, CONSTANTS.NOIC2EQUIP_ERROR
  end
  if not ic.dropIntoSlot(side, 1) then
    return false, CONSTANTS.NOCHARGEBOX_ERROR
  end
  repeat 
    local tool = ic.getStackInSlot(sides.down, 1)
  until tool.charge >= tool.maxCharge
  ic.suckFromSlot(side, 1)
  --充電したアイテムをツールスロットに戻す
  ic.equip()
  return true
end

--[[----------------------------------------------------------------------------
  API - robot - wrapeer

  component.robotをokeの名前空間で使えるようにするだけ
  TODO fluid関連
  TODO inventory関連
----------------------------------------------------------------------------]]--

--[[
@fn
robot.compareのwrapper
@param (side : number) 確認するブロックの方向
@return boolean[, string] 現在選択されているスロットとブロックが一致するか
--]]
function oke.compare(side, fuzzy)
  return component.robot.compare(side, fuzzy)
end

--[[
@fn
robot.detectのwrapper
@param (side : number) 確認するブロックの方向
@return boolean[, string]
--]]
function oke.detect(side)
  return component.robot.detect(side)
end

--robot.moveはアレンジ版のみ使用可能

--[[
@fn
robot.turnのwrapper
@param (clockwise : boolean) trueで右回り，nil, falseで左回り
@return boolean[, string] 回転できたか
--]]
function oke.turn(clockwise)
  return component.robot.turn(clockwise)
end

--[[
@fn
robot.useのwrapper
@param (side : number) ツールを使う方向
@param (sneaky : boolean) sneak状態での右クリック扱いにするか
@param (duration : number) 右クリックしている時間の長さ
@return boolean[, string]
--]]
function oke.use(side, sneaky, duration)
  return component.robot.use(side, sneaky, duration)
end

--[[
@fn
robot.swingのwrapper
@param (side : number) ツールを使って左クリックする方向
@return boolean[, string]
--]]
function oke.swing(side)
  return component.robot.swing(side)
end

--[[----------------------------------------------------------------------------
  API - robot - addon

  component.robotを便利に扱えるようにするAPI群
  TODO fluid関連
  TODO inventory関連
----------------------------------------------------------------------------]]--

--[[
@fn
ロボットの移動を司るコア部分
@brief side方向にdistance
@param (side : number) 移動する向き(前，後ろ，上，下のみ)
@param (distance : number) 移動距離
@param (destory : boolean) 移動方向に障害物があった場合，除去を試みるか
@return 
@detail 移動成功するか，除去に失敗するまで制御は帰ってこない
        side == sides.back and destroyの場合ブロック破壊はできない
--]]
function oke.move(side, distance, destory)
  local function tryMove()
    local flag, reason = component.robot.move(side)
    if not flag and destory and side ~= sides.back then
      component.robot.swing(side)
      flag = component.robot.move(side)
    end
    return flag
  end
  for d = 1, distance do
    while not tryMove() do
      os.sleep(CONSTANTS.MOVEFAIE_INTERVAL)
    end
  end
end

function oke.forward(distance, destory)
  distance = distance or 1
  oke.move(sides.forward, distance, destory)
end

function oke.back(distance, destory)
  distance = distance or 1
  oke.move(sides.back, distance, destory)
end

function oke.up(distance, destory)
  distance = distance or 1
  oke.move(sides.up, distance, destory)
end

function oke.down(distance, destory)
  distance = distance or 1
  oke.move(sides.down, distance, destory)
end

function oke.turnRight()
  return oke.turn(true)
end

function oke.turnLeft()
  return oke.turn(false)
end

function oke.turnAround(clockwise)
  if clockwise == nil then
    clockwise = false
  end
  return component.robot.turn(clockwise) and component.robot.turn(clockwise)
end

--[[
@fn
robot.placeのオリジナル実装
@brief side方向にdistance
@param (side : number) ブロックを設置する向き(前，上，下のみ)
@param (slot : number) 置くブロックのスロット番号
@param (destory : boolean) 移動方向に障害物があった場合，除去を試みるか
@return 
@detail 設置成功するか，除去に失敗するまで制御は帰ってこない
        side == sides.back and destroyの場合ブロック破壊はできない
--]]
function oke.place(side, slot, replace)
  side = side or sides.forward
  local before = component.robot.select()--選択前のスロットを記憶
  component.robot.select(slot)
  local function tryPlace()
    local flag = component.robot.place(side)
    if not flag and replace then
      component.robot.swing(side)
      tryPlace()
    end
    component.robot.select(before)
    return true
  end
  if not component.robot.compare(side, true) then--同じブロックなら配置しない
    while not tryPlace() do
      os.sleep(CONSTANTS.PLACE_INTERVAL)
    end
  end
  component.robot.select(before)
  return true
end

--[[----------------------------------------------------------------------------
  API - inventory_controller - wrapeer

  inventory_controllerをokeの名前空間で使えるようにするだけ
----------------------------------------------------------------------------]]--

--[[
@fn
inventory_controller.getInventorySize(side)のwrapper
@param (side : number) 確認するインベントリの方向
@return number[, string]
--]]
function oke.getInventorySize(side)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  return component.inventory_controller.getInventorySize(side)
end

--[[
@fn
inventory_controller.getStackInSlot(side, slot)のwrapper
@param (side : number) 確認するインベントリの方向
@param (slot : number) 確認するインベントリのスロット
@return number[, string]
--]]
function oke.getStackInSlot(side, slot)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  return component.inventory_controller.getStackInSlot(side, slot)
end

--[[
inventory_controller.getStackInInternalSlotはアレンジ版のみ使用可能
]]

--[[
@fn
inventory_controller.dropIntoSlot(side, slot[, count])のwrapper
@param (side : number) インベントリの方向
@param (slot : number) インベントリのスロット
@param (count : number) 入れるアイテムの数
@return boolean[, string]
--]]
function oke.dropIntoSlot(side, slot, count)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  return component.inventory_controller.dropIntoSlot(side, slot, count)
end

--[[
@fn
inventory_controller.suckFromSlot(side, slot[, count])のwrapper
@param (side : number) インベントリの方向
@param (slot : number) インベントリのスロット
@param (count : number) 取るアイテムの数
@return boolean[, string]
--]]
function oke.suckFromSlot(side, slot, count)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  return component.inventory_controller.suckFromSlot(side, slot, count)
end

--[[
@fn
inventory_controller.equip()と同じ
@return 移動したアイテムの数
--]]
function oke.equip()
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  return component.inventory_controller.equip()
end

--[[---------------------------------------------------------------------------
  API - inventory_controller - addon

  inventory_controllerを便利に扱える用にするapi群
---------------------------------------------------------------------------]]--

--[[
@fn
アレンジ版inventory_controller.getStackInInternalSlot()
@brief ツールスロット内のアイテムも参照可能
@param (slot : number) 確認するスロットの番号
@return 充電完了できたらtrue，できなければfalse, errmsg
@detail ロボットのインベントリは左上から1, 2...とスロット
        が割り当てられているがツールスロットは0としてアクセス可能．
        ただし，equip()関数を使うため通常の参照よりは遅い
--]]
function oke.getStackInInternalSlot(slot)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  if slot == 0 then
    --このスロットにツールスロットのアイテムが移動する
    local slot = component.robot.select()
    component.inventory_controller.equip()
    local stack = component.inventory_controller.getStackInInternalSlot(slot)
    component.inventory_controller.equip()
    return stack
  else
    return component.inventory_controller.getStackInInternalSlot(slot)
  end
end

--[[
@fn
インベントリ内を整理する
@brief インベントリ内の重複するアイテムをスタック限界まで重ねる
@return なし
--]]
function oke.merge()
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  local robot = component.robot
  local beforeSlot = robot.select()--選択前のスロットを記憶
  for fromSlot = robot.inventorySize(), 1, -1 do
    robot.select(fromSlot)
    for toSlot = 1, fromSlot - 1 do
      if robot.count(fromSlot) > 0 then 
        if robot.compareTo(toSlot) or robot.count(toSlot) == 0 then
          robot.transferTo(toSlot)
        end
      else
        break
      end
    end 
  end
  robot.select(beforeSlot)
end

--[[
@fn
filterに合致するアイテムを数える
@brief filterに合致するアイテムを数えるが，ツールスロットは無視する
@param (filter : function) 選別するアイテムのフィルタ
@return filterに合致するrobotインベントリ内のアイテムの数
--]]
function oke.countStack(filter)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  local size = 0
  for slot = 1, component.robot.inventorySize() do
    local stack = component.inventory_controller.getStackInInternalSlot(slot)
    if filter and stack and filter(stack) and stack.size then
      size = size + stack.size
    elseif not filter then
      size = size + component.robot.count(slot)
    end
  end
  return size
end

--[[
@fn
filterに合致するアイテムを数える
@brief filterに合致するアイテムを数えるが，ツールスロットのみ数える
@param (filter : function) 選別するアイテムのフィルタ
@return filterに合致するrobotツールスロット内のアイテムの数
--]]
function oke.countToolStack(filter)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  local size = 0
  local slot = component.robot.select()
  oke.equip()
  local stack = component.inventory_controller.getStackInInternalSlot(slot)
  if filter and stack and filter(stack) and stack.size then
    size = size + stack.size
  elseif not filter then
    size = size + component.robot.count(slot)
  end
  component.robot.select(slot)
  oke.equip()
  return size
end

--[[
@fn
インベントリからロボットにfilterに合致するアイテムを移動する
@brief side方向のインベントリからロボットにfilterに合致するアイテムをcount個移動する
@param (side : number) 搬入するインベントリの方向
@param (filter : function) 選別するアイテムのフィルタ
@param (count : number) 移動するアイテムの数
@return 移動したアイテムの数
--]]
function oke.pullStack(side, filter, count)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
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
  return count - remain
end

--[[
@fn
ロボットからインベントリにfilterに合致するアイテムを移動する
@brief side方向のインベントリにロボットからfilterに合致するアイテムをcount個移動する
@param (side : number) 搬出するインベントリの方向
@param (filter : function) 選別するアイテムのフィルタ
@param (count : number) 移動するアイテムの数
@return 移動したアイテムの数
@detail pullStack()はインベントリからでないといけないが，ejectの場合無くても
        空中にアイテムスタックを放り投げる,インベントリ後部から排出する
        ツールスロットは含まない
--]]
function oke.ejectStack(side, filter, count)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  local remain = count
  local preSlot = component.robot.select()
  for slot = component.robot.inventorySize(), 1, -1 do
    local stack = component.inventory_controller.getStackInInternalSlot(slot)
    if stack and filter and filter(stack) then
      component.robot.select(slot)
      component.robot.drop(side, remain)
      remain = remain - stack.size
      if remain <= 0 then
        break
      end
    end
  end
  component.robot.select(preSlot)
  return count - remain
end

--[[
@fn
ロボットのインベントリのfilterに合致するアイテムを設置する
@brief side方向にロボットのインベントリのfilterに合致するアイテムを設置する
@param (side : number) 搬出するインベントリの方向
@param (filter : function) 選別するアイテムのフィルタ
@param (count : number) 移動するアイテムの数
@return 移動したアイテムの数
@detail pullStack()はインベントリからでないといけないが，ejectの場合無くても
        空中にアイテムスタックを放り投げる
        ツールスロットは含まない
--]]
function oke.placeStack(side, filter, destory)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  --前回使ったスロットを先に調べる
  local bs = component.inventory_controller.getStackInInternalSlot(state.slot)
  if filter and bs and filter(bs) then
    return oke.place(side, state.slot, destory)
  else
    for slot = 1, component.robot.inventorySize() do
      stack = component.inventory_controller.getStackInInternalSlot(slot)
      if filter and stack and filter(stack) then
        state.slot = slot
        return oke.place(side, slot, destory)
      end
    end
    return false
  end
end

--[[
@fn
ロボットのインベントリのfilterに合致するアイテムを装備する
@param (filter : function) 選別するアイテムのフィルタ
@return アイテムを装備できたか
--]]
function oke.equipStack(filter)
  if not component.isAvailable("inventory_controller") then
    return false, CONSTANTS.IC_ERROR
  end
  local bs = component.robot.select()
  --robotのインベントリで合致するスロットを探す
  for slot = 0, component.robot.inventorySize() do
    local stack = oke.getStackInInternalSlot(slot)
    if stack and filter(stack) then
      if slot == 0 then--ツールスロットが合致した
        return true
      else
        component.robot.select(slot)
        component.inventory_controller.equip()
      end
    end
  end
  component.robot.select(bs)
end

-- function oke.useStack(side, filter, sneaky, duration)
--   --まずツールスロットをチェック
--   if oke.countToolStack() > 0 then
--     oke.use()
--   end
--   return component.robot.use(side, sneaky, duration)
-- end

--[[---------------------------------------------------------------------------
  API - tractor_beam - addon

  tractor_beamを扱いやすくする
---------------------------------------------------------------------------]]--
function oke.suckAll()
  if not component.isAvailable("tractor_beam") then
    return false, CONSTANTS.TB_ERROR
  end
  while component.tractor_beam.suck() do end
end

--[[---------------------------------------------------------------------------
  API - geolyzer - wrapper

  geolyzerのwrapper
---------------------------------------------------------------------------]]--
function oke.analyze(side)
  if not component.isAvailable("geolyzer") then
    return false, CONSTANTS.GEO_ERROR
  end
  side = side or sides.forward
  return component.geolyzer.analyze(side)
end

--[[---------------------------------------------------------------------------
  API - geolyzer - addon

  geolyzerを扱いやすくする
---------------------------------------------------------------------------]]--
function oke.analyzeUp()
  if not component.isAvailable("geolyzer") then
    return false, CONSTANTS.GEO_ERROR
  end
  return component.geolyzer.analyze(sides.up)
end

function oke.analyzeDown()
  if not component.isAvailable("geolyzer") then
    return false, CONSTANTS.GEO_ERROR
  end
  return component.geolyzer.analyze(sides.down)
end

return oke