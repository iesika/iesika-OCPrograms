local args = {...}
local component = require("component")
local event = require("event")
local gpu = component.gpu
local unicode = require("unicode")
local computer = require("computer")
local term = require("term")
local os = require("os")

gpu.setBackground(0x000000, false)
gpu.setForeground(0xFFFFFF, false)
gpu.setResolution(160, 50)
gpu.fill(1, 1, 160, 50, " ")

local fps = 30
--一回のファイルアクセスで何byte読むか
local oneRead = 2048

function r8(file)
	local byte = file:read(1)
	if byte == nil then
		return 0
	else
		return string.byte(byte)
	end
end

function readData(file)
	local t = {["code"] = {},["dupe"] = {}}
	local data = file:read(oneRead)
	for i = 1, (oneRead/2) do
		t["code"][i] = data:byte(i*2-1) + 0x2800
		t["dupe"][i] = data:byte(i*2) + 1
		--print(string.format("%x, %x",t["code"][i], t["dupe"][i]))
		--event.pull("touch")
	end
	return t
end

local file = io.open(args[1],'rb')
local header = {0x6f, 0x63, 0x6d, 0x31, 0x00}
for i = 1, #header do
	if r8(file) ~= header[i] then
		print("Invalid header")
		os.exit()
	end
end

if component.tape_drive then
	if component.tape_drive.isReady() then
		component.tape_drive.seek(-math.huge)
		component.tape_drive.play()
	end
end

--音声を合わせるため決め打ち
os.sleep(1)

local framePos = 1
local starttime = computer.uptime() + framePos*(1/fps)
local load = 1
local stack = {["code"] = {} ,["dupe"]= {} }
local flag

while stack["code"] and stack["dupe"] do
	while starttime + framePos*(1/fps) > computer.uptime() do
		computer.pullSignal(0.001)
	end
	term.setCursor(1,1)
	local checksum = 0
	repeat
		local line = ""
		repeat
			if not stack["code"] or not stack["dupe"] then
				break
			end
			if not stack["code"][load] or not stack["dupe"][load] then
				load = 1
				flag, stack = pcall(readData,file)
			end
			if flag then
				line = line..string.rep(unicode.char(stack["code"][load]),stack["dupe"][load])
				checksum = checksum + stack["dupe"][load]
				load = load + 1
			end
		until checksum % 160 == 0 or not stack["code"]
		gpu.set(1,math.floor(checksum / 160),line)
	until checksum == 8000 or not stack["code"]
	framePos = framePos + 1
end

gpu.fill(1, 1, 160, 50, " ")

if component.tape_drive then
	component.tape_drive.stop()
	component.tape_drive.seek(-math.huge)
end
