local unicode = require("unicode")
local component = require("component")
local gpu = component.gpu

local bigfont = {}
local font_data = {}

function bigfont.load(size)
    local filename = "bigfont-size" .. tostring(size)
    local file = io.open("/lib/"..filename, "r")
    font_data[size] = {}

    for line in file:lines() do
        local code = tonumber(line:sub(1,4),16)
        font_data[size][code] = {}
        local data = line:sub(6)
        for i = 1, data:len(), 4 do
            table.insert(font_data[size][code], tonumber(data:sub(i, i + 3), 16))
        end
    end
end

local function load_letter(letter,size)
    local code = string.byte(letter)
    if code < 0x0020 or code > 0x007E then
        error("char '"..letter.."' is not supported")
    end
    local glyph = font_data[size][string.byte(letter)]
    local t = 1;
    local temp = {}
    for j = 1, size do
        for i = 1, size do
            table.insert(temp, unicode.char(glyph[t]))
            --gpu.set(x + i - 1, y + j - 1 , unicode.char(glyph[t]));
            t = t + 1
        end
    end
    return temp
end

function bigfont.set(x,y,sentence,size)
    local glyphs = {}
    local lines = {}
    for i = 1, size do
        lines[i] = ""
    end
    for i = 1, sentence:len() do
       table.insert(glyphs, load_letter(sentence:sub(i, i), size))
    end
    for i, glyph in ipairs(glyphs) do
        for j = 1, size do
            for k = 1, size do
                lines[j] = lines[j]..glyph[k + (j-1)*size]
            end
        end
    end
    for i, v in ipairs(lines) do
        gpu.set(x, y - 1 + i, lines[i])
    end
end

return bigfont