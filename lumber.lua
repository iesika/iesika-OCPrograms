--[[
@file lumber.lua
@brief 高信頼な松の木用木こりプログラム
@detail 
  松の木をロボットで自動収穫するためのプログラム
  エネルギー供給が永続稼働の為には必要
  ic2のchainsawを使って高速化可能

  robotの必要最低限の構成
  :Hardware
    case(tier3)
    eeprom
    cpu(tier1↑)
    memory(tier1↑)
    HDD(tier1↑)
    screen(tier1↑)
    graphic card
    keyboard
    Inventory Controller Upgrade
    Inventory Upgrade
    Hover Upgrade(Tier2)
    geolyzer
    Tractor beam upgrade
  :SoftWare
    luaBIOS(eeprom)
    OpenOS
    oke libraly

  木こり場の構成(top view)
  
  ├─────────────────17────────────────┤
  ┌───────────────────────────────────┐ ┬
  │                         T         │ │
  │                         3         │ │
  │                         ┴         │ │
  │       D D               D D       │ │
  │ ├─3─┤ D D ├─────5─────┤ D D ├─3─┤ │ │
  │                         T         │ 17
  │                         5         │ │
  │                         ┴         │ │
  │       D D               D D       │ │
  │       D D ├─────5─────┤ D D       │ │
  │                         ┬         │ │
  │                         3         │ │
  │                         ┴         │ │
  ├───────7──────┤C R C├──────7───────┤ ┴
  ├────────8───────┤ ├────────8───────┤

  R : robot (y == 0), charger(y == -1)
  C : chest(inventory block) (y == -1)
  D : dirt (y == -2)
  17x17の空間(高さは2x2の松の木の高さ以上), dirtのｙ座標以下に床が必要

  --稼働条件
  robotの初期位置の下に電力を常に供給できるchargerを設置する
  robotの向きを木こり場に向ける
  robotのインベントリに16個以上の松の苗を入れる
  robotのtool slot又はinventoryにic2のchainsawを入れておく

  --稼働アルゴリズム
  基本的に以下を繰り返す
  1, robotのインベントリ中の苗の数が16個になるように，左チェストに苗を保管する
    余った分は投棄
  2, 4つの松の成長予定地点を周回しながら，落ちている苗木をtractor beamで回収する
    1, 松が育っていたなら伐採
    2, 訪れた成長予定地点に苗木が植わっておらず，十分な苗木があるならば植林
  3, 周回後右チェストに入るだけ木材，葉を入れる
  4, 初期地点で充電完了まで待機し，前回の周回で伐採できる木が一つでもあったならば
     充電完了後すぐに周回を再開し，そうでないならば
     前回の周回の開始時刻の3分後になるまで待機する

  --溢れた資材について
  チェストに入りきらなかった苗及び木材はワールドに投棄される

@usage
  lumber.lua [options]
  --useIC2chainsaw
    ic2のchainsawを使用する(高速に木こりができる)
  -q, --quite
    何ブロック収穫したか表示しなくなる
@author iesika
@date 2017/9/12
--]]

local oke = require("oke")
local component = require("component")
local sides = require("sides")

local filter = {}

--ic2のchainsaw
filter.chainsaw = function(stack)
  return stack and stack.name == "IC2:itemToolChainsaw"
end
--松の苗
filter.sapling = function(stack) 
  return stack and stack.name == "minecraft:sapling" and stack.damage == 1
end
--苗でないもの
filter.not_sap = function(stack) 
  return stack and stack.name ~= "minecraft:sapling" or stack.damage ~= 1
end
--原木ブロック
filter.log = function(stack) 
  return stack and stack.name == "minecraft:log"
end
--葉
filter.leaves = function(stack)
  return stack and stack.name == "minecraft:leaves"
end
--土ブロック
filter.dirt = function(stack)
  return stack and stack.name == "minecraft:dirt"
end

--木を収穫し元の位置に戻る
local function cutTree()
  oke.swing(sides.forward)
  oke.forward(1, true)
  oke.swing(sides.down)
  oke.down(1, true)
  oke.swing(sides.forward)
  --上(下)1マスとその隣の原木を収穫し1マス上昇（下降）する，下が土の場合は移動しない
  --返り値は収穫数(0-2)
  local function harvest2log(side)
    local count = 0
    if filter.log(oke.analyze(side)) then--上（下）が原木である
      count = count + 1
    elseif side == sides.down and filter.dirt(oke.analyze(side)) then
      return -1
    end
    if oke.detect(side) then
      oke.swing(side)--原木で無くても破壊し，上昇（下降）はする
    end
    oke.move(side, 1, true)
    if filter.log(oke.analyze(sides.forward)) then--前が原木である
      count = count + 1
      oke.swing(sides.forward)
    end
    return count
  end
  --下1マスとその隣の原木を収穫し1マス下降する
  --返り値は収穫数(0-2)
  while harvest2log(sides.up) > 0 do end
  oke.turnLeft()
  oke.swing(sides.forward)
  oke.forward(1, true)
  oke.turnRight()
  oke.swing(sides.forward)
  while harvest2log(sides.down) > -1 do end
  --横マスとも原木でない場合木こりが完了したとする
  oke.up(1, true)
  oke.turnRight()
  oke.forward(1, true)
  oke.turnLeft()
  oke.back(1, true)
end

local function placeSapling2x2()
  oke.forward(1, true)
  oke.turnLeft()
  for i = 1, 4 do
    oke.forward(1, true)
    oke.placeStack(sides.down, filter.sapling)
    oke.turn((i ~= 4) and true or false)
  end
  oke.forward(1, true)
end

--init
if (oke.countStack(filter.sapling) < 16) then
  error("More than 16 Spruce Sapling needed")
end
if (not component.isAvailable("inventory_controller")) then
  error("Missing inventory_controller")
end
if (not component.isAvailable("tractor_beam")) then
  error("Missing tractor_beam")
end
if (not component.isAvailable("geolyzer")) then
  error("Missing geolyzer")
end

--main
while true do
  --初期値点で充電
  oke.recharge()
  if filter.chainsaw(oke.getStackInInternalSlot(0)) then
    oke.rechargeTool(sides.down)
  end
  oke.turnLeft()
  oke.forward(1, true)
  --左側のチェストで苗木の数を調整
  local sap_count = oke.countStack(filter.sapling)
  if sap_count > 16 then
    oke.ejectStack(sides.down, filter.sapling, sap_count - 16)
  elseif sap_count < 16 then
    oke.pullStack(sides.down, filter.sapling, 16 - sap_count)
  end
  oke.turnAround()
  oke.forward(1, true)
  oke.turnLeft()
  --木こり，植林，苗木回収
  oke.forward(5, true)
  oke.suckAll()
  oke.turnLeft()
  oke.forward(2, true)

  local sleep = true
  for i = 1, 4 do
    oke.suckAll()
    if filter.log(oke.analyze(sides.forward)) then--木が成長している
      cutTree()
      sleep = false
    end
    oke.down(1, true)
    if (oke.analyze(sides.forward).name == "minecraft:air") then--苗が無い
      oke.up(1, true)
      placeSapling2x2()
    else--苗の上を移動しないように移動
      oke.up(1, true)
      oke.turnRight()
      oke.forward(1, true)
      oke.turnLeft()
      oke.forward(1, true)
      oke.turnRight()
    end
    oke.suckAll()
    oke.forward(i ~= 4 and 4 or 2, true)
    oke.suckAll()
  end
  oke.turnLeft()
  oke.forward(5, true)
  oke.turnLeft()
  oke.forward(1, true)
  --右側のチェストに収集品を入れる
  oke.ejectStack(sides.down, filter.not_sap, oke.countStack(filter.not_sap))
  --入り切らなかった分は投棄
  oke.ejectStack(sides.forward, filter.not_sap, oke.countStack(filter.not_sap))
  oke.turnAround()
  oke.forward(1, true)
  oke.turnRight()
  if sleep then
    os.sleep(150)
  end
end
