--require oke lib
local oke = require("oke")
local sides = require("sides")

local cfg = {
    build_material = 
        function(stack)
            return stack.name == "chisel:tyrian" and stack.damage == 1
        end
}
--[[
           ←length→ 
    S → → → → → → → → → → → 
S地点から開始し, 
lengthの長さだけrobotの下にブロックを設置しながら移動する
--]]
local function line(length, material)
    for i = 1, length do
        oke.placeStack(sides.down, material, true)
        if i ~= length then
            oke.forward(1, true)
        end
    end
end

--[[
                  ←col→ 
        → → → → → → → → → → → → ↓
        ↑                       ↓
        ↑                       ↓
        ↑                       ↓
        ↑                       ↓  ↑
        ↑                       ↓ row
        ↑                       ↓  ↓
        ↑                       ↓
        ↑                       ↓
        ↑                       ↓
        ↑                       ↓
        S ← ← ← ← ← ← ← ← ← ← ← ←
上記のs地点から開始し，
robotの下にブロックを設置しながらs地点まで周回した後，上（前）向きに戻る
--]]
local function frame(col, row, material)
    line(row, material)
    oke.turn(true)
    line(col, material)
    oke.turn(true)
    line(row, material)
    oke.turn(true)
    line(col, material)
    oke.turn(true)
end

local function make_farm_frame()
    for i = 1, 3 do
        for j = 1, 5 do
            frame(13, 13, cfg.build_material)
            oke.forward(12, true)
        end
        if i ~= 3 then
            frame(13, 5, cfg.build_material)
            oke.forward(4, true)
        end
    end
    oke.back(188, true)
end

local function make_farm_scaffold()
    for i = 1, 3 do
        for j = 1, 5 do
            frame(5, 13, cfg.build_material)
            oke.forward(12, true)
        end
        if i ~= 3 then
            frame(5, 5, cfg.build_material)
            oke.forward(4, true)
        end
    end
    oke.back(188, true)
end

local function go_next_frameline(distance)
    oke.turn(true)
    oke.forward(distance, true)
    oke.turn(false)
end

local function main()
    for i = 1, 3 do
        make_farm_scaffold()
        go_next_frameline(4)
        make_farm_frame()
        if not i ~= 3 then
            go_next_frameline(12)
        end
    end
end

main()