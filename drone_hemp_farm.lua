--[[
@file drone_hemp_farm.lua
@brief OpenComputersのImmersive engineringの麻を自動収穫させる
@detail
燃料は太陽光で補う、動かない時間が長い為、日中に雨の日が続かない限り連続稼働できるはず

droneの必要最低限の構成
  :Hardware
    Case(tier2)
    CPU(tier1)
    memory(tier1)x1
    Inventory Upgrade
    Inventory Controller Upgrade
    Solar Generator Upgrade

必要環境
    農場の構成(top view)
    ・農場の周囲を壁で囲わないと収穫物が散乱してしまう
    ・農場は自前で先に耕しておく
    ・droneには自分の向きが無いため方角厳守
                  ↑（南）
  ├─────────────────11────────────────┤
  ┌───────────────────────────────────┐ ┬
  │                                   │ │
  │                                   │ │
  │                                   │ │
  │                                   │ │
  │                                   │ │
  │                                   │ 11
  │                 W                 │ │
  │                                   │ │
  │                                   │ │
  │                                   │ │
  │                                   │ │
  │                                   │ │
  │                                   │ │
  ├────────5───────┤C├────────5───────┤ ┴
  ├────────5───────┤D├────────5───────┤

  R : drone起動位置 (y == 0)
  C : chest(inventory block) (y == 0)
  W : 水(y == -1)
--]]

drone = component.proxy(component.list("drone")())
tractor_beam = component.proxy(component.list("tractor_beam")())

local px, py, pz = 5, 0, -1

local color_charing = 0xFFCC33
local color_harvesting = 0x66CC66

local function moveTo(x, y, z)
    local rx, ry, rz = x - px, y - py, z - pz
    drone.move(rx, ry, rz)
    while drone.getOffset() > 0.5 or drone.getVelocity() > 0.5 do
        computer.pullSignal(0.2)
    end
    px, py, pz = x, y, z
end

local function recharge(timeout)
    drone.setLightColor(color_charing)
    while computer.energy() < computer.maxEnergy() * 0.9 do
        computer.pullSignal(1)
    end
end

local function dropItem(name)
    for i = 1, drone.inventorySize() do
        drone.select(i)
        drone.drop(0)
    end
end

local function harvest()
    drone.setLightColor(color_harvesting)
    for i = 1, 9 do
        for j = 1, 9 do
            moveTo(i, 2, j)
            if drone.detect(0) then
                drone.swing(0)
            end
        end
    end
end

local function collect()
    for i = 2, 8, 3 do
        for j = 2, 8, 3 do
            moveTo(i, 2, j)
            repeat until not tractor_beam.suck()
        end
    end 
end

while true do
    harvest()
    collect()
    moveTo(5, 1, 0)
    dropItem()
    moveTo(5, 2, 5)
    recharge()
end
