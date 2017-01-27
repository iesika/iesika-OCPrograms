--[[
----gui function---------------------------------------------------------------
	gui:newWindow(x,y,width,height,screen_address)
		return window
	gui:update()

----window function------------------------------------------------------------
	window:close()
		return nil
	window:setWindowName(name)
		return window
	window:setWindowNameColor(color)
		return window
	window:setCloseButtonColor(color)
		return window
	window:setFrameColor(color)
		return window
	window:setCloseButtonCallback(callback)
		return window
		--default callback is window:close()
	window:setMoveability(boolean)
		return window
	window:newTabBar()
		return tabBar
	window:newButton(x,y,width,height,callback)
		return button

----tabBar function------------------------------------------------------------

	tabBar:newTab(name)



--]]

local component = require("component")
local computer = require("computer")
local event = require("event")
local text = require("text")
local term = require("term")
local unicode = require("unicode")
local bigfont = require("bigfont")
local gpu = component.gpu

--公開するのはguiのみ
local gui = {}

local objects = {}
local render = {}
render.internal = {}
render.internal.cursor = {}
local event_handler = {}
local cfg = {}

--**cfg**----------------------------------------------------------------------

cfg.frame_char = {}
cfg.frame_char.window = {{"⣿","⣿","⣿"},{"⡇"," ","⢸"},{"⣇","⣀","⣸"}}
cfg.frame_char.close_button = "X"
cfg.frame_char.button = {{"⡏","⠉","⢹"},{"⡇"," ","⢸"},{"⣇","⣀","⣸"}}
cfg.frame_char.button2 = {{"┏","━","┓"},{"┃"," ","┃"},{"┗","━","┛"}}
cfg.frame_char.button3 = {{"⡤","⠤","⢤"},{"⡇"," ","⢸"},{"⠓","⠒","⠚"}}
cfg.frame_char.progress = {{"╒","═","╕"},{"│"," ","│"},{"╘","═","╛"}}
cfg.frame_char.list = {{"╓","─","╖"},{"║"," ","║"},{"╙","─","╜"}}
--cfg.frame_char.scrollBar = {"⇧","┃","⇩","⣿"}
--cfg.frame_char.scrollBar = {"↑","│","￬","⣿"}
cfg.frame_char.scrollBar = {"┬","│","┴","⣿"}
--cfg.frame_char.progress = {{"⢠","⣤","⡄"},{"⡇"," ","⡇"},{"⠘","⠛","⠃"}}
cfg.frame_char.bar = "▊"

cfg.color = {}
cfg.color.std = {}
cfg.color.std.foreground = 0xFFFFFF
cfg.color.std.background = 0x000000

cfg.color.gui = {}
cfg.color.gui.background = 0x000000

cfg.color.window = {}
cfg.color.window.frame = 0xFFFFFF
cfg.color.window.panel = 0xCCCCCC
cfg.color.window.name = 0x000000
cfg.color.window.close_button = 0x000000

cfg.color.tab = {}
cfg.color.tab.name = 0x000000

cfg.color.button = {}
cfg.color.button.frame = 0x4B4B4B
cfg.color.button.panel = 0xC3C3C3
cfg.color.button.text = 0x000000

cfg.color.switch = {}
cfg.color.switch.text = {}
cfg.color.switch.text.on = {}
cfg.color.switch.text.on.foreground = 0x000000
cfg.color.switch.text.on.background = 0xD2D2D2
cfg.color.switch.text.off = {}
cfg.color.switch.text.off.foreground = 0x000000
cfg.color.switch.text.off.background = 0xD2D2D2
cfg.color.switch.frame = {}
cfg.color.switch.frame.on = {}
cfg.color.switch.frame.on.foreground = 0x4B4B4B
cfg.color.switch.frame.on.background = 0xD2D2D2
cfg.color.switch.frame.off = {}
cfg.color.switch.frame.off.foreground = 0xFFFFFF
cfg.color.switch.frame.off.background = 0xD2D2D2
cfg.color.switch.panel = {}
cfg.color.switch.panel.on = {}
cfg.color.switch.panel.on.foreground = 0xFF0000--無意味
cfg.color.switch.panel.on.background = cfg.color.switch.frame.on.background
cfg.color.switch.panel.off = {}
cfg.color.switch.panel.off.foreground = 0xFF0000--無意味
cfg.color.switch.panel.off.background = cfg.color.switch.frame.off.background

cfg.color.label = {}
cfg.color.label.text = {}
cfg.color.label.text.foreground = 0x000000
cfg.color.label.text.background = cfg.color.window.panel
cfg.color.label.underline = {}
cfg.color.label.underline.foreground = 0xFF0000
cfg.color.label.underline.background = cfg.color.window.panel

cfg.color.textField = {}
cfg.color.textField.text = {}
cfg.color.textField.text.foreground = 0xFFFFFF
cfg.color.textField.text.background = 0x000000
cfg.color.textField.active = {}
cfg.color.textField.active.foreground = 0xFFFFFF
cfg.color.textField.active.background = 0xFFB600

cfg.color.list = {}
cfg.color.list.name = {}
cfg.color.list.element = {}
cfg.color.list.element.on = {}
cfg.color.list.element.on.foreground = 0x000000
cfg.color.list.element.on.background = 0xFFDB00
--cfg.color.list.element.on.background = 0xFFFFFF
cfg.color.list.element.off = {}
cfg.color.list.element.off.foreground = 0x0F0F0F
cfg.color.list.element.off.background = 0xB4B4B4
cfg.color.list.frame = {}
cfg.color.list.frame.foreground = 0x000000
cfg.color.list.frame.background = cfg.color.window.panel
cfg.color.list.panel = {}
cfg.color.list.panel.foreground = 0x000000
cfg.color.list.panel.background = 0xC3C3C3

cfg.color.progress = {}
cfg.color.progress.frame = {}
cfg.color.progress.frame.foreground = 0x000000
cfg.color.progress.frame.background = cfg.color.window.panel
cfg.color.progress.bar = {}
--cfg.color.progress.bar.foreground = 0x0000FF
cfg.color.progress.bar.foreground = 0x006DFF
cfg.color.progress.bar.background = 0x1E1E1E
cfg.color.progress.name = {}
cfg.color.progress.name.foreground = 0xFF0000
cfg.color.progress.name.background = cfg.color.window.panel


--tier3だと下設定がいいかも
-- cfg.color.window = {}
-- cfg.color.window.frame = 0xFFFFFF
-- cfg.color.window.panel = 0xCCCCCC
-- cfg.color.window.name = 0x000000
-- cfg.color.window.close_button = 0x000000

-- cfg.color.tab = {}
-- cfg.color.tab.name = 0x000000

-- cfg.color.button = {}
-- cfg.color.button.frame = 0xA5A5A5
-- cfg.color.button.panel = 0xC3C3C3
-- cfg.color.button.text = 0x000000

-- cfg.color.switch = {}
-- cfg.color.switch.text = {}
-- cfg.color.switch.text.on = {}
-- cfg.color.switch.text.on.foreground = 0x000000
-- cfg.color.switch.text.on.background = 0xF0F0F0
-- cfg.color.switch.text.off = {}
-- cfg.color.switch.text.off.foreground = 0xFFFFFF
-- cfg.color.switch.text.off.background = 0x969696
-- cfg.color.switch.frame = {}
-- cfg.color.switch.frame.on = {}
-- cfg.color.switch.frame.on.foreground = 0xFFFFFF
-- cfg.color.switch.frame.on.background = 0xF0F0F0
-- cfg.color.switch.frame.off = {}
-- cfg.color.switch.frame.off.foreground = 0xB4B4B4
-- cfg.color.switch.frame.off.background = 0x969696
-- cfg.color.switch.panel = {}
-- cfg.color.switch.panel.on = {}
-- cfg.color.switch.panel.on.foreground = 0xFF0000--無意味
-- cfg.color.switch.panel.on.background = cfg.color.switch.frame.on.background
-- cfg.color.switch.panel.off = {}
-- cfg.color.switch.panel.off.foreground = 0xFF0000--無意味
-- cfg.color.switch.panel.off.background = cfg.color.switch.frame.off.background

-- cfg.color.label = {}
-- cfg.color.label.text = {}
-- cfg.color.label.text.foreground = 0x000000
-- cfg.color.label.text.background = cfg.color.window.panel
-- cfg.color.label.underline = {}
-- cfg.color.label.underline.foreground = 0xFF0000
-- cfg.color.label.underline.background = cfg.color.window.panel

-- cfg.color.textField = {}
-- cfg.color.textField.text = {}
-- cfg.color.textField.text.foreground = 0xFFFFFF
-- cfg.color.textField.text.background = 0x000000
-- cfg.color.textField.active = {}
-- cfg.color.textField.active.foreground = 0xFFFFFF
-- cfg.color.textField.active.background = 0xFFB600

-- cfg.color.list = {}
-- cfg.color.list.name = {}
-- cfg.color.list.element = {}
-- cfg.color.list.element.on = {}
-- cfg.color.list.element.on.foreground = 0x000000
-- cfg.color.list.element.on.background = 0xFFDB00
-- --cfg.color.list.element.on.background = 0xFFFFFF
-- cfg.color.list.element.off = {}
-- cfg.color.list.element.off.foreground = 0x0F0F0F
-- cfg.color.list.element.off.background = 0xB4B4B4
-- cfg.color.list.frame = {}
-- cfg.color.list.frame.foreground = 0x000000
-- cfg.color.list.frame.background = cfg.color.window.panel
-- cfg.color.list.panel = {}
-- cfg.color.list.panel.foreground = 0x000000
-- cfg.color.list.panel.background = 0xC3C3C3

-- cfg.color.progress = {}
-- cfg.color.progress.frame = {}
-- cfg.color.progress.frame.foreground = 0x000000
-- cfg.color.progress.frame.background = cfg.color.window.panel
-- cfg.color.progress.bar = {}
-- --cfg.color.progress.bar.foreground = 0x0000FF
-- cfg.color.progress.bar.foreground = 0x006DFF
-- cfg.color.progress.bar.background = 0x1E1E1E
-- cfg.color.progress.name = {}
-- cfg.color.progress.name.foreground = 0xFF0000
-- cfg.color.progress.name.background = cfg.color.window.panel

cfg.default = {}
cfg.default.x = 1
cfg.default.y = 1
cfg.default.width = 32
cfg.default.height = 10

--**util functions**-----------------------------------------------------------
--点i,jが四角形に内在するか
local function isInsideRect(i, j, x, y, width, height)
	return x <= i and i <= x + width - 1 and y <= j and j <= y + height - 1
end

local function isExistActiveTextField(layerGroup)
	local flag = false
	for i, object in ipairs(layerGroup) do
		if object.type == "textField" and object.active then
			flag = true
		end
	end
	return flag
end

local function getTopLayer(layerGroup)
	return layerGroup[#layerGroup]
end

local function debug(msg,pause)
	local w, h = gpu.getResolution()
	render.setColor(cfg.color.std)
	msg = text.padRight(tostring(msg),w)
	gpu.set(1,h,msg)
	if pause then
		event.pull("touch")
	end
end

local function ripairs(t)
  local function ripairs_it(t,i)
    i = i - 1
    local v = t[i]
    if v == nil then
		return v 
	end
    return i,v
  end
  return ripairs_it, t, #t+1
end

--**eventhandler**-------------------------------------------------------------

function event_handler.event(event_name, screen_address, x , y, button)
	if event_name then
		--debug(event_name.." : "..tostring(button))
	end
	local isRightClick = (button == 1)
	if event_handler[event_name] then
		event_handler[event_name](screen_address, x, y, isRightClick)
	else
		--unknown event
	end
end

--反応しない？
function event_handler.interrupted(...)
	debug("interrupted")
	gui:exit()
end

function event_handler.touch(screen_address, x, y, isRightClick)
	if isRightClick or #gui.layer == 0 then
		return
	end
	
	do--クリックされたwindowをgui.layerの一番最後に持ってくる
		local window
		for i, w in ripairs(gui.layer) do
			if isInsideRect(x, y, w.x, w.y, w.width, w.height) then
				--既にgui上で最上段にあればスルー
				if i == #gui.layer then
					break
				end
				window = table.remove(gui.layer, i)
				break
			end
		end

		if window then
			window.dirty = true
			table.insert(gui.layer, window)
		end
	end

	local top = getTopLayer(gui.layer)

	if not top then
		return
	end
	--上部frameがクリックされたか
	if isInsideRect(x, y, top.x, top.y, top.width - 3, 1) then
		if top.moveability then
			top.move.moving = true
			top.move.position = x - top.x
		end
	--closebuttonがクリックされたか
	elseif isInsideRect(x, y, top.x + top.width - 2, top.y, 1, 1) then
		if not top.close_button_callback then
			top:close()
		else
			top.close_button_callback()
			top:close()
		end
	else
		--buttonが押されたか判断する
		for i, object in ripairs(top.layer) do
			if not object.visible then
				goto continue
			end
			local bx, by = object.x + top.x, object.y + top.y
			local w, h = object.width, object.height
			if object.type == "button" then
				--buttonのobjectが
				--debug(tostring(x)..":"..tostring(y))
				if isInsideRect(x, y, bx, by, w, h) then
					if object.callback then
						if object.args then
							object.callback(table.unpack(object.args))
						else
							object.callback()
						end	
					else
						--debug("function not be defined")
					end
				end
			elseif object.type == "switch" then
				if isInsideRect(x, y, bx, by, w, h) then
					--debug("switch")
					if object.state == "on" then
						object.state = "off"
					else
						object.state = "on"
					end
					object.dirty = true
					local onoff = object.state
					if object.callback[onoff] then
						if object.args[onoff] then
							object.callback[onoff](table.unpack(object.args[onoff]))
						else
							object.callback[onoff]()
						end
					end
				end
			elseif object.type == "textField" then
				if isInsideRect(x, y, bx, by, w, h) then
					--他のテキストフィールドを非アクティブに
					for j, o in ipairs(top.layer) do
						if o.type == "textField" and o.active and o ~= object then
							o.active = false
							o.dirty = true
						end
					end
					object.active = true
					local tx, ty = top.x + object.x, top.y + object.y
					local w = unicode.wlen(object.text)
					render.internal.cursor.blink = true
					render.internal.cursor.x = tx + w
					render.internal.cursor.y = ty
					object.dirty = true
				end
			elseif object.type == "list" then
				if isInsideRect(x, y, bx + 1, by + 1, w - 2, h - 2) then
					local pos = y - (object.y + top.y) + object.pos - 1
					if object.elements[pos].state == "on" then
						object.elements[pos].state = "off"
						object.dirty = true
					else
						for i, le in ipairs(object.elements) do
							le.state = "off"
						end
						object.dirty = true
						object.elements[pos].state = "on"
						if object.elements[pos].callback then
							if object.elements[pos].args then
								local args = object.elements[pos].args
								object.elements[pos].callback(table.unpack(args))
							else
								object.elements[pos].callback()
							end
						end
					end
				end
			end
			::continue::
		end
	end
end

function event_handler.drag(screen_address, x, y, isRightClick)
	local top = getTopLayer(gui.layer)
	if top.move.moving and top.moveability then
		--top:clear()
		top.x = x - top.move.position
		top.y = y
		top.dirty = true
		-- for i , window in ipairs(gui.layer) do
		-- 	window.dirty = true
		-- end
	end
end

function event_handler.drop(screen_address, x, y, isRightClick)
	local top = getTopLayer(gui.layer)
	if top.move.moving then
		top.move.moving = false
		top.move.position = 0
	end
end

function event_handler.scroll(screen_address, px, py, isUp)
	local top = getTopLayer(gui.layer)
	for i, o in ripairs(top.layer) do
		if o.type ~= "list" then
			goto continue
		end
		local x, y = o.x + top.x, o.y + top.y
		local width, height = o.width, o.height
		local ymax = #o.elements - (o.height - 3)
		if isInsideRect(px, py, x, y, width, height) then
			if isUp then
				if o.pos == 1 then
					goto continue
				end
				o.pos = o.pos - 1
				o.dirty = true
			else
				if o.pos == ymax then
					goto continue
				end			
				o.pos = o.pos + 1
				o.dirty = true
			end	
		end
		::continue::
	end
end

function event_handler.key_down(screen_address, ch, code)
	local top = getTopLayer(gui.layer)
	if not top then
		return
	end
	local activeTextField
	for i, object in ipairs(top.layer) do
		if object.type == "textField" and object.active then
			activeTextField = object
			break
		end
	end
	if not activeTextField then
		return
	end
	if code == 28 then --enter
		activeTextField.active = false
		activeTextField.dirty = true
		activeTextField.text_buf = activeTextField.text
	elseif code == 14 then --backspace
		if unicode.wlen(activeTextField.text) > 0 then
			activeTextField.text = string.sub(activeTextField.text ,1, #activeTextField.text - 1)
			activeTextField.dirty = true
		end
	elseif code ~= 0 and code ~= 42 then
		if unicode.wlen(activeTextField.text) < activeTextField.width then
			activeTextField.text = activeTextField.text..string.char(ch)
			activeTextField.dirty = true
		end
	end
end

function event_handler.register()
	event.listen("touch", event_handler.event)
	event.listen("drag", event_handler.event)
	event.listen("scroll", event_handler.event)
	event.listen("drop", event_handler.event)
	event.listen("key_down", event_handler.event)
	--event.listen("interrupted",event_handler.event)
end

function event_handler.ignore()
	event.ignore("touch" ,event_handler.event)
	event.ignore("drag", event_handler.event)
	event.ignore("scroll", event_handler.event)
	event.ignore("drop", event_handler.event)
	event.ignore("key_down", event_handler.event)
	--event.ignore("interrupted",event_handler.event)
end

--**render**-------------------------------------------------------------------

function render.setColor(f_color, b_color)
	if type(f_color) == "table" then
		gpu.setForeground(f_color.foreground or cfg.color.std.foreground)
		gpu.setBackground(f_color.background or cfg.color.std.background)
	else
		gpu.setForeground(f_color or cfg.color.std.foreground)
		gpu.setBackground(b_color or cfg.color.std.background)
	end
end

function render.drawFrame(x, y, width, height, char)
	gpu.set(x, y, char[1][1])
	gpu.set(x + width - 1, y, char[1][3])
	gpu.set(x, y + height - 1, char[3][1])
	gpu.set(x + width - 1, y + height - 1, char[3][3])
	gpu.set(x + 1, y, char[1][2]:rep(width - 2))
	gpu.set(x+1, y + height - 1, char[3][2]:rep(width - 2))
	gpu.set(x, y + 1, char[2][1]:rep(height-2), true)
	gpu.set(x + width - 1, y + 1, char[2][3]:rep(height-2), true)
end

function render.drawText(x, y, text, scale)
	if scale and scale ~= 1 then
		bigfont.set(x, y, text, scale)
	else
		if text and text ~= "" then
			gpu.set(x, y, text)
		end
	end
end

function render.drawBar(x, y, height)
	gpu.set(x, y, string.rep(cfg.frame_char.bar, height), true)
end

function render.drawScrollBar(list)
	local x, y = list.parent.x + list.x, list.parent.y + list.y
	local width, height = list.width, list.height
	x = x + width - 2
	gpu.set(x, y, cfg.frame_char.scrollBar[1])
	gpu.set(x, y + 1, cfg.frame_char.scrollBar[2]:rep(height - 2), true)
	gpu.set(x, y + height - 1, cfg.frame_char.scrollBar[3])
	local length, pos 
	local maxLength = height - 2
	if #list.elements <= maxLength then
		length = maxLength
		pos = y + 1
	elseif #list.elements > maxLength*2 then
		length = 1
		pos = (list.pos/(#list.elements - (maxLength - 2)))*maxLength
		pos = list.y + list.parent.y + math.floor(pos) + 1
	else
		length = maxLength - (#list.elements - maxLength)
		if length < 1 then
			length = 1
		end
		pos = list.y + list.parent.y + list.pos
	end
	gpu.set(x, pos, cfg.frame_char.scrollBar[4]:rep(length), true)
end

function render.clear(x, y, width, height, color)
	gpu.setBackground(color)
	gpu.fill(x, y, width, height, " ")
end

function render.guiClear()
	local width, height = gpu.getResolution()
	gpu.setBackground(gui.background_color)
	gpu.fill(1, 1, width, height, " ")
end

--**objects**------------------------------------------------------------------
--functionを毎回作るのはメモリ消費が重いのでprototypeっぽいの
objects.prototype = {}
objects.prototype.object = {}
objects.prototype.window = {}
objects.prototype.tabBar = {}
objects.prototype.tab    = {}
objects.prototype.button = {}
objects.prototype.switch = {}
objects.prototype.progress = {}
objects.prototype.label = {}
objects.prototype.textField = {}
objects.prototype.list = {}
--継承っぽいの
setmetatable(objects.prototype.window,{__index = objects.prototype.object})
setmetatable(objects.prototype.tabBar,{__index = objects.prototype.object})
setmetatable(objects.prototype.tab   ,{__index = objects.prototype.object})
setmetatable(objects.prototype.button,{__index = objects.prototype.object})
setmetatable(objects.prototype.switch,{__index = objects.prototype.object})
setmetatable(objects.prototype.progress, {__index = objects.prototype.object})
setmetatable(objects.prototype.label, {__index = objects.prototype.object})
setmetatable(objects.prototype.textField, {__index = objects.prototype.object})
setmetatable(objects.prototype.list, {__index = objects.prototype.object})

--**object.object**--------------------------------------------------

function objects.prototype.object:enable()
	if not self.visible then
		self.visible = true
		self.dirty = true
	end
	return self
end

function objects.prototype.object:disable()
	if self.visible then
		self.dirty = true
		self.visible = false
	end
	return self
end

function objects.prototype.object:draw()
	--this method need override
end

function objects.prototype.object:setPosition(x, y)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	self.x, self.y = x, y
	return self
end

function objects.prototype.object:getPosition()
	return self.x, self.y
end

function objects.prototype.object:setScale(width, height)
	checkArg(1, width, "number")
	checkArg(2, height, "number")
	self.width = width
	self.height = height
	return self
end

function objects.prototype.object:getScale()
	return self.width, self.height
end

function objects.prototype.object:getType()
	return self.type
end

--オブジェクトの雛形クラス
function objects.newObject(x,y,width,height)
	checkArg(1, x, "nil", "number")
	checkArg(2, y, "nil", "number")
	checkArg(3, width, "nil", "number")
	checkArg(4, height, "nil", "number")
	local object = {}
	object.x = x or cfg.default.x
	object.y = y or cfg.default.y
	object.width = width or cfg.default.width
	object.height = height or cfg.default.height
	object.visible = true
	object.dirty = true
	object.type = "object"
	return object
end

--**object.window**------------------------------------------------------------
--window自体の描画
function objects.prototype.window:draw()
	local x, y = self.x, self.y
	local width, height = self.width, self.height
	local frame_color = self.frame_color
	local panel_color = self.panel_color
	local name, name_color = self.name, self.name_color
	local close_button_color = self.close_button_color
	--drawFrame
	render.setColor(frame_color, panel_color)
	render.drawFrame(x, y, width, height, cfg.frame_char.window)
	--name
	if name and name_color then
		render.setColor(name_color, frame_color)
		render.drawText(x + 1, y, name)
	end
	--drawclosebutton
	render.setColor(close_button_color, frame_color)
	render.drawText(x + width - 2, y, cfg.frame_char.close_button)
	--fill margin
	render.clear(x + 1, y + 1, width - 2, height - 2, panel_color)
end

function objects.prototype.window:close()
	--closeされたwindow以外は再描画する
	local remove
	for i, window in ipairs(gui.layer) do
		window.dirty = true
		if window == self then
			remove = i
		end
	end
	table.remove(gui.layer, remove)
end

function objects.prototype.window:setWindowName(name)
	checkArg(1, name, "string")
	self.name = name
	self.dirty = true
	return self
end

function objects.prototype.window:setWindowNameColor(color)
	checkArg(1, color, "number")
	self.name_color = color
	self.dirty = true
	return self
end

function objects.prototype.window:setCloseButtonColor(color)
	checkArg(1, color, "number")
	self.close_button_color = color
	self.dirty = true
	return self
end

function objects.prototype.window:setFrameColor(color)
	checkArg(1, color, "number")
	self.frame_color = color
	self.dirty = true
	return self
end

function objects.prototype.window:setCloseButtonCallback(callback)
	checkArg(1, callback, "function", "nil")
	self.close_button_callback = callback
	return self
end

function objects.prototype.window:setMoveability(boolean)
	checkArg(1, boolean, "boolean")
	self.moveability = boolean
	return self
end

--window単位で描画したい時に
function objects.prototype.window:update()
	--レイヤー中で再描画すべきオブジェクトがあるなら全オブジェクトを再描画する
	local redraw = false
	if not self.layer or #self.layer == 0 then
		return
	end
	for i, object in ipairs(self.layer) do
		if object.visible then
			object:draw()
			object.dirty = false
		end
	end
end

function objects.prototype.window:newTabBar()
	local tabBar = objects.newTabBar(self)
	--barはwindow layerの二番目に挿入する
	if self.layer[2] and self.layer[2].type == "tabBar" then
		error("newTabBar")
	end
	table.insert(self.layer, 2, tabBar)
	return tabBar
end

function objects.prototype.window:newButton(x,y,width,height,callback)
	local button = objects.newButton(x,y,width,height,callback)
	button.parent = self
	button.callback = callback
	table.insert(self.layer, button)
	return button
end

function objects.prototype.window:newSwitch(x, y, width, height, on, off)
	local switch = objects.newSwitch(x, y, width, height, on, off)
	switch.parent = self
	table.insert(self.layer, switch)
	return switch
end

function objects.prototype.window:newLabel(x, y, text)
	local label = objects.newLabel(x, y, text)
	label.parent = self
	table.insert(self.layer, label)
	return label
end

function objects.prototype.window:newProgress(x,y,width,height)
	local progress = objects.newProgress(x, y, width, height)
	progress.parent = self
	table.insert(self.layer, progress)
	return progress
end

function objects.prototype.window:newTextField(x, y, width)
	local textField = objects.newTextField(x, y, width)
	textField.parent = self
	table.insert(self.layer, textField)
	return textField
end

function objects.prototype.window:newList(x, y, width, height)
	local list = objects.newList(x, y, width, height)
	list.parent = self
	table.insert(self.layer, list)
	return list
end

function objects.newWindow(x,y,width,height,screen_address)
	local window = objects.newObject(x,y,width,height)
	window.type = "window"
	window.moveability = true
	window.focus = false
	window.move = {}
	window.move.moving = false
	window.move.position = 0 
	window.screen_address = screen_address
	window.frame_color = cfg.color.window.frame
	window.panel_color = cfg.color.window.panel
	window.name_color = cfg.color.window.name
	window.close_button_color = cfg.color.window.close_button
	setmetatable(window,{__index = objects.prototype.window})
	--window内部のLayer添字が大きいほど優先される
	window.layer = {}
	table.insert(window.layer,window)
	table.insert(gui.layer,window)
	return window
	--[[
	window.screen_address
	window.x
	window.y
	window.width
	window.height
	window.enable
	window.moveability
	window.moving 
	object.dirty
	window.panel_color
	window.name_color
	window.close_button_color
	window.frame_f_color
	window.frame_b_color
	--追加可能
	window.name
 --]]
end

--**objects.tabBar**-----------------------------------------------------------

function objects.prototype.tabBar:draw()
	if not self.visible then
		return
	end
	--親windowの座標を
	local parent = self.window
	local x, y = parent.x, parent.y + 1
	local width, height = parent.width, 1
	--draw bar
	gpu.setBackground(parent.frame_color)
	gpu.fill(x, y, width, height, " ")
end

function objects.prototype.tabBar:newTab()
	local tab = objects.newTab(self.window)
end

function objects.newTabBar(window)
	local x, y = 0, 0
	local width, height = 0, 0
	local tabBar = objects.newObject(x, y, width, height)
	tabBar.type = "tabBar"
	--親windowへのポインタ的な
	tabBar.window = window
	--tabを格納する
	tabBar.tabs = {}
	setmetatable(tabBar,{__index = objects.prototype.tabBar})
	--objects.prototype.tabBar.__index = objects.prototype.tabBar
	return tabBar
	--[[
	tabBar.x
	tabBar.y
	tabBar.width
	tabBar.height
	tabBar.enable
	tabBar.dirty
	tabBar.name_color
	--]]
end

--**objects.tab**--------------------------------------------------------------

function objects.prototype.tab:setName()
	-- body
end

function objects.prototype.tab:draw()

end

function objects.newTab(window)
	local x, y = 0, 0
	local width, height = 0, 0
	local tab = objects.newObject(x, y, 0, 0)
	tab.type = "tab"
	tab.window = window
	tab.layer = {}
	setmetatable(tabBar, {__index = objects.prototype.tab})
	return tab
end

--**object.button**------------------------------------------------------------

function objects.prototype.button:draw()
	if not self.visible then
		return
	end
	local x, y = self.x + self.parent.x, self.y + self.parent.y
	local width, height = self.width, self.height
	local panel_color, frame_color = self.panel_color, self.frame_color
	--drawFrame
	if self.frame_type ~= "none" then
		render.setColor(frame_color, panel_color)
		render.drawFrame(x, y, width, height, cfg.frame_char[self.frame_type])
		render.clear(x + 1 , y + 1 , width - 2 , height - 2, panel_color)
	else
		render.clear(x , y, width, height, panel_color)		
	end
	--drawText
	if self.text and self.text ~= "" then
		local tx, ty = x + self.text_x - 1 , y + self.text_y - 1
		render.setColor(self.text_color, panel_color)
		render.drawText(tx , ty, self.text, self.text_scale)
	end
end

function objects.prototype.button:setCallback(callback, ...)
	checkArg(1, callback, "function", "nil")
	self.callback = callback
	self.args = table.pack(...)
	return self
end

--0でframeなし1でデフォルト
function objects.prototype.button:setFrameType(type)
	checkArg(1, type, "string")
	self.frame_type = type
	self.dirty = true
	return self
end

function objects.prototype.button:setText(text)
	checkArg(1, text, "string")
	self.text = text
	self.dirty = true
	return self
end

function objects.prototype.button:setTextPosition(x, y)
	local x, y = tonumber(x), tonumber(y)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	self.text_x, self.text_y = x, y
	self.dirty = true
	return self
end

function objects.prototype.button:setTextScale(scale)
	checkArg(1, scale, "number")
	if type(scale) ~= "number" or self.text_scale == scale then
		return self
	end
	self.text_scale = scale
	self.dirty = true
	return self
end

function objects.prototype.button:setTextColor(color)
	checkArg(1, color, "number")
	self.text_color = color
	self.dirty = true
	return self
end

function objects.prototype.button:setPanelColor(color)
	checkArg(1, color, "number")
	self.panel_color = color
	self.dirty = true
	return self
end

function objects.prototype.button:setFrameColor(color)
	checkArg(1, color, "number")
	self.frame_color = color
	self.dirty = true
	return self
end

function objects.newButton(x, y, width, height, callback)
	checkArg(1, x, "nil", "number")
	checkArg(2, y, "nil", "number")
	checkArg(3, width, "nil", "number")
	checkArg(4, height, "nil", "number")
	checkArg(5, callback, "nil", "function")
	local button = objects.newObject(x, y, width, height)
	button.type = "button"
	button.callback = callback
	button.frame_type = "button"
	button.text = ""
	button.text_scale = 1
	button.text_x, button.text_y = 2, 2
	button.text_color = cfg.color.button.text
	button.panel_color = cfg.color.button.panel
	button.frame_color = cfg.color.button.frame
	setmetatable(button, {__index = objects.prototype.button})
	--objects.prototype.button.__index = objects.prototype.button
	return button
end
--**object.switch**------------------------------------------------------------

function objects.prototype.switch:draw()
	local x, y = self.x + self.parent.x, self.y + self.parent.y
	local width, height = self.width, self.height
	local state = self.state
	--render.setColor(self.color.text[self.state])
	local panel_color = self.color.panel[state].background
	if self.frame_type ~= "none" then
		render.setColor(self.color.frame[state])
		if cfg.frame_char[self.frame_type] then
			render.drawFrame(x, y, width, height, cfg.frame_char[self.frame_type])
		else
			render.drawFrame(x, y, width, height, cfg.frame_char.button)
		end
		render.clear(x + 1 , y + 1 , width - 2 , height - 2, panel_color)
	else
		render.clear(x , y, width, height, panel_color)
	end
	--drawText
	if self.text and self.text ~= "" then
		local tx, ty = x + self.text_x - 1 , y + self.text_y - 1
		render.setColor(self.color.text[state])
		render.drawText(tx , ty, self.text[state], self.text_scale[state])
	end
end

function objects.prototype.switch:getState()
	return self.state
end

function objects.prototype.switch:setOnText(text)
	checkArg(1, text, "string")
	self.text.on = text
	self.dirty = true
	return self
end

function objects.prototype.switch:setOffText(text)
	checkArg(1, text, "string")
	self.text.off = text
	self.dirty = true
	return self
end

function objects.prototype.switch:setTextPosition(x, y)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	self.x, self.y = x, y
	self.dirty = true
	return self
end

function objects.prototype.switch:setTextOnColor(f_color, b_color)
	checkArg(1, f_color, "number")
	checkArg(2, b_color, "number")
	self.color.text.on.foreground = f_color
	self.color.text.on.background = b_color
	self.dirty = true
	return self
end

function objects.prototype.switch:setTextOffColor(f_color, b_color)
	checkArg(1, f_color, "number")
	checkArg(2, b_color, "number")
	self.color.text.off.foreground = f_color
	self.color.text.off.background = b_color
	self.dirty = true
	return self
end

function objects.prototype.switch:setPanelOnColor(f_color, b_color)
	checkArg(1, f_color, "number")
	checkArg(2, b_color, "number")
	self.color.panel.on.foreground = f_color
	self.color.panel.on.background = b_color
	self.dirty = true
	return self
end

function objects.prototype.switch:setPanelOffColor(f_color, b_color)
	checkArg(1, f_color, "number")
	checkArg(2, b_color, "number")
	self.color.panel.off.foreground = f_color
	self.color.panel.off.background = b_color
	self.dirty = true
	return self
end

function objects.prototype.switch:setFrameOnColor(f_color, b_color)
	checkArg(1, f_color, "number")
	checkArg(2, b_color, "number")
	self.color.frame.on.foreground = f_color
	self.color.frame.on.background = b_color
	self.dirty = true
	return self
end

function objects.prototype.switch:setFrameOffColor(f_color, b_color)
	checkArg(1, f_color, "number")
	checkArg(2, b_color, "number")
	self.color.frame.off.foreground = f_color
	self.color.frame.off.background = b_color
	self.dirty = true
	return self
end

function objects.prototype.switch:setOffCallback(func, ...)
	checkArg(1, func, "function")
	self.callback.off = func
	self.args.off = table.pack(...)
	return self
end

function objects.prototype.switch:setOnCallback(func, ...)
	checkArg(1, func, "function")
	self.callback.on = func
	self.args.on = table.pack(...)
	return self
end

function objects.prototype.switch:setOnTextScale(scale)
	checkArg(1, scale, "number")
	self.text_scale.on = scale
	self.dirty = true
	return self
end

function objects.prototype.switch:setOffTextScale(scale)
	checkArg(1, scale, "number")
	self.text_scale.off = scale
	self.dirty = true
	return self
end

function objects.prototype.switch:setFrameType(frame_type)
	checkArg(1, frame_type, "string")
	self.frame_type = frame_type
	self.dirty = true
	return self
end

function objects.newSwitch(x, y, width, height, onCallback, offCallback)
	checkArg(1, x, "nil", "number")
	checkArg(2, y, "nil", "number")
	checkArg(3, width, "nil", "number")
	checkArg(4, height, "nil", "number")
	checkArg(5, onCallback, "nil", "function")
	checkArg(6, offCallback, "nil", "function")
	local switch = objects.newObject(x, y, width, height)
	switch.type = "switch"
	switch.state = "off"
	switch.frame_type = "button"
	switch.text = {}
	switch.text_scale = {}
	switch.text_scale.on = 1
	switch.text_scale.off = 1
	switch.text_x, switch.text_y = 2, 2
	switch.callback = {}
	switch.callback.on = onCallback
	switch.callback.off = offCallback
	switch.args = {}
	switch.color = {}
	switch.color.text = {}
	switch.color.text.on = {}
	switch.color.text.on.foreground = cfg.color.switch.text.on.foreground
	switch.color.text.on.background = cfg.color.switch.text.on.background
	switch.color.text.off = {}
	switch.color.text.off.foreground = cfg.color.switch.text.off.foreground
	switch.color.text.off.background = cfg.color.switch.text.off.background
	switch.color.panel = {}
	switch.color.panel.on = {}
	switch.color.panel.on.foreground = cfg.color.switch.panel.on.foreground
	switch.color.panel.on.background = cfg.color.switch.panel.on.background
	switch.color.panel.off = {}
	switch.color.panel.off.foreground = cfg.color.switch.panel.off.foreground
	switch.color.panel.off.background = cfg.color.switch.panel.off.background
	switch.color.frame = {}
	switch.color.frame.on = {}
	switch.color.frame.on.foreground = cfg.color.switch.frame.on.foreground
	switch.color.frame.on.background = cfg.color.switch.frame.on.background
	switch.color.frame.off = {}
	switch.color.frame.off.foreground = cfg.color.switch.frame.off.foreground
	switch.color.frame.off.background = cfg.color.switch.frame.off.background
	setmetatable(switch,{__index = objects.prototype.switch})
	return switch
end

--**object.label**-------------------------------------------------------------

function objects.prototype.label:draw()
	if not self.visible or self.text == "" then
		return
	end
	local x, y = self.x + self.parent.x, self.y + self.parent.y
	render.setColor(self.color.text)
	render.drawText(x, y, self.text, self.scale)
	--underline
	if self.underline then
		render.setColor(self.color.underline)
		local text = string.rep("⠉", self.text:len() * self.scale)
		render.drawText(x, y + self.scale, text, 1)
	end
end

function objects.prototype.label:clear()

end

function objects.prototype.label:setUnderline(bool)
	checkArg(1, bool, "boolean", "nil")
	self.underline = bool
	self.dirty = true
	return self
end

function objects.prototype.label:setScale(scale)
	checkArg(1, scale, "number")
	self.scale = scale
	self.dirty = true
	return self
end

function objects.prototype.label:getScale()
	return self.scale
end

function objects.prototype.label:setTextColor(f_color, b_color)
	checkArg(1, f_color, "number", "nil")
	checkArg(2, b_color, "number", "nil")
	if f_color then
		self.color.text.foreground = f_color
	end
	if b_color then
		self.color.text.background = b_color
	end
	return self
end

function objects.prototype.label:setUnderlineColor(f_color, b_color)
	checkArg(1, f_color, "number", "nil")
	checkArg(2, b_color, "number", "nil")
	if f_color then
		self.color.underline.foreground = f_color
	end
	if b_color then
		self.color.underline.background = b_color
	end
	return self
end

function objects.prototype.label:setText(text)
	local s = tostring(text)
	checkArg(1, s, "string")
	if s and s ~= self.text and s ~= "" then
		self.text = s
		self.dirty = true
	end
	return self
end

function objects.prototype.label:getText()
	return self.text
end

function objects.newLabel(x, y, text)
	text = tostring(text)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	checkArg(3, text, "string", "nil")
	local label = objects.newObject(x, y, 1, 1)
	label.type = "text"
	label.text = text
	label.underline = false
	label.scale = 1
	label.color = {}
	label.color.text = {}
	label.color.underline = {}
	label.color.underline.foreground = cfg.color.label.underline.foreground
	label.color.underline.background = cfg.color.label.underline.background
	label.color.text.foreground = cfg.color.label.text.foreground
	label.color.text.background = cfg.color.label.text.background
	setmetatable(label, {__index = objects.prototype.label})
	return label
end

--**object.progress**----------------------------------------------------------

function objects.prototype.progress:draw()
	local x, y = self.x + self.parent.x, self.y + self.parent.y
	local width, height = self.width, self.height
	local bw = math.floor((self.percentage / 100) * (width - 2))
	local panel_color = self.color.bar.background
	if width > 2 and height > 2 then
		render.setColor(self.color.frame)
		render.drawFrame(x, y, width, height, cfg.frame_char.progress)
		render.setColor(self.color.bar)
		render.clear(x + 1, y + 1, width - 2, height - 2, panel_color)
		if bw > 0 then		
			for i = 1, bw do
				render.drawBar(x + i, y + 1, height - 2)
			end
		end
	end
	if self.name and self.name ~= "" then
		render.setColor(self.color.name)
		render.drawText(x + 2, y, self.name)
	end
end

function objects.prototype.progress:setProgress(percentage)
	checkArg(1, percentage, "number")
	if self.percentage ~= percentage then
		self.percentage = percentage
		self.dirty = true
	end
	return self
end

function objects.prototype.progress:setName(name)
	checkArg(1, name, "string")
	self.name = name
	self.dirty = true
	return self
end

function objects.prototype.progress:setNameColor(f_color, b_color)
	checkArg(1, f_color, "number", "nil")
	checkArg(2, b_color, "number", "nil")
	if f_color then
		self.color.name.foreground = f_color
	end
	if b_color then
		self.color.name.background = b_color
	end
end

function objects.newProgress(x, y, width, height)
	checkArg(1, x, "nil", "number")
	checkArg(2, y, "nil", "number")
	checkArg(3, width, "nil", "number")
	checkArg(4, height, "nil", "number")
	local progress = objects.newObject(x, y, width, height)
	progress.type = "progress"
	progress.name = ""
	progress.percentage = 0
	progress.color = {}
	progress.color.bar = {}
	progress.color.bar.foreground = cfg.color.progress.bar.foreground
	progress.color.bar.background = cfg.color.progress.bar.background
	progress.color.frame = {}
	progress.color.frame.foreground = cfg.color.progress.frame.foreground
	progress.color.frame.background = cfg.color.progress.frame.background
	progress.color.name = {}
	progress.color.name.foreground = cfg.color.progress.name.foreground
	progress.color.name.background = cfg.color.progress.name.background
	setmetatable(progress, {__index = objects.prototype.progress})
	return progress
end

--**object.textField**---------------------------------------------------------

--setScaleの上書き
function objects.prototype.textField:setScale(width)
	checkArg(1, width, "number")
	self.width = width
	return self
end

function objects.prototype.textField:draw()
	if not self.visible then
		return
	end
	local x, y = self.x + self.parent.x, self.y + self.parent.y
	local f_col, b_col = self.color.text.foreground, self.color.text.background
	if self.active then
		f_col, b_col = self.color.active.foreground, self.color.active.background
	end
	local internal_text
	if unicode.wlen(self.text) > self.width then
		internal_text = unicode.sub(1, self.width)
	else
		internal_text = text.padRight(self.text, self.width)
	end
	render.setColor(f_col, b_col)
	render.drawText(x, y, internal_text)
end

function objects.prototype.textField:setText(text)
	checkArg(1, text, "string")
	self.text = text
	self.dirty = true
	textField.text_buf = text
	return self
end

function objects.prototype.textField:getText()
	return self.text_buf
end

function objects.newTextField(x, y, width)
	checkArg(1, x, "nil", "number")
	checkArg(2, y, "nil", "number")
	checkArg(3, width, "nil", "number")
	local textField = objects.newObject(x, y, width, 1)
	textField.type = "textField"
	textField.text = ""
	textField.text_buf = ""
	textField.active = false
	textField.color = {}
	textField.color.text = {}
	textField.color.text.foreground = cfg.color.textField.text.foreground
	textField.color.text.background = cfg.color.textField.text.background
	textField.color.active = {}
	textField.color.active.foreground = cfg.color.textField.active.foreground
	textField.color.active.background = cfg.color.textField.active.background
	setmetatable(textField, {__index = objects.prototype.textField})
	return textField
end

--**object.list**--------------------------------------------------------------

function objects.prototype.list:draw()
	if not self.visible then
		return
	end
	--親windowの座標を
	local parent = self.parent
	local x, y = self.x + parent.x, self.y + parent.y
	local width, height = self.width, self.height
	--render.setColor()
	render.setColor(self.color.frame)
	render.drawFrame(x, y, width, height, cfg.frame_char.list)
	--drawScrollBar
	render.drawScrollBar(self)
	--drawName
	render.drawText(x + 1, y, self.name)
	--drawElements
	local pos = 1
	for i = self.pos, #self.elements do
		local element = self.elements[i]
		if not element or self.height - 2 < pos then
			break
		end
		local name = text.padRight(element.name, width - 3)
		name = name:sub(1, width - 3)
		render.setColor(element.color[element.state])
		render.drawText(x + 1, y + pos, name)
		pos = pos + 1
	end
end

function objects.prototype.list:setName(name)
	checkArg(1, name, "string")
	self.name = name
	self.dirty = true
	return self
end

function objects.prototype.list:clearAllElement()
	self.elements = {}
	self.dirty = true
	return self
end

function objects.prototype.list:getOnElementIndex()
	for i, el in ipairs(self.elements) do
		if el.state == "on" then
			return i
		end
	end
end

function objects.prototype.list:setOnElementColor(index, f_color, b_color)
	checkArg(1, index, "number")
	checkArg(2, f_color, "number", "nil")
	checkArg(3, b_color, "number", "nil")
	if not self.elements[index] then
		return
	end
	if f_color then
		self.elements[index].color.on.foreground = f_color
	end
	if b_color then
		self.elements[index].color.on.background = b_color
	end
end

function objects.prototype.list:setElementColor(index, state, f_color, b_color)
	checkArg(1, index, "number")
	checkArg(2, state, "string")
	checkArg(3, f_color, "number", "nil")
	checkArg(4, b_color, "number", "nil")
	if not self.elements[index] or (state ~= "on" and state ~= "off") then
		return
	end
	f_color = f_color or self.color.element[state].foreground
	b_color = b_color or self.color.element[state].background
	self.elements[index].color[state].foreground = f_color
	self.elements[index].color[state].background = b_color
	self.dirty = true
	return self
end

function objects.prototype.list:addElement(name, callback, ...)
	checkArg(1, name, "string")
	checkArg(2, callback, "function", "nil")
	local element = {}
	element.state = "off"
	element.name = name
	element.callback = callback
	element.color = {}
	element.color.on = {}
	element.color.on.foreground = self.color.element.on.foreground
	element.color.on.background = self.color.element.on.background
	element.color.off = {}
	element.color.off.foreground = self.color.element.off.foreground
	element.color.off.background = self.color.element.off.background
	element.args = table.pack(...)
	table.insert(self.elements, element)
	return self
end

function objects.newList(x, y, width, height)
	checkArg(1, x, "nil", "number")
	checkArg(2, y, "nil", "number")
	checkArg(3, width, "nil", "number")
	checkArg(4, height, "nil", "number")
	local list = objects.newObject(x, y, width, height)
	list.type = "list"
	list.name = ""
	list.pos = 1
	list.elements = {}
	list.color = {}
	list.color.element = {}
	list.color.element.on = {}
	list.color.element.on.foreground = cfg.color.list.element.on.foreground
	list.color.element.on.background = cfg.color.list.element.on.background
	list.color.element.off = {}
	list.color.element.off.foreground = cfg.color.list.element.off.foreground
	list.color.element.off.background = cfg.color.list.element.off.background
	list.color.frame = {}
	list.color.frame.foreground = cfg.color.list.frame.foreground
	list.color.frame.background = cfg.color.list.frame.background
	list.color.panel = {}
	list.color.panel.foreground = cfg.color.list.panel.foreground
	list.color.panel.background = cfg.color.list.panel.background
	setmetatable(list, {__index = objects.prototype.list})
	return list
end

--**gui**----------------------------------------------------------------------
--window単位でのlayer
gui.layer = {}
--
gui.background_color = cfg.color.gui.background

function gui:newWindow(x, y, width, height,screen_address)
	screen_address = screen_address or component.screen.address
	local newWindow = objects.newWindow(x, y, width, height, screen_address)
	event_handler.register()
	return newWindow
end

--全windowを描画しなおしたい時に呼ぶ
function gui:update()
	if not self.layer or #self.layer == 0 then
		gui:exit()
	end
	if render.internal.cursor.blink then
		local cx, cy = render.internal.cursor.x, render.internal.cursor.y
		render.setColor(0x000000, 0xFFFFFF)
		term.setCursorBlink(true)
		term.setCursor(cx, cy)
	else
		term.setCursorBlink(false)
	end
	local redraw = false
	for i, window in ipairs(self.layer) do
		for j, object in ipairs(window.layer) do
			if object.dirty then
				redraw = true
			end
		end
	end
	if not redraw then
		return
	end
	render.guiClear()
	for i, window in ipairs(self.layer) do
		window:update()
	end
end

function gui:setBackgroundColor(color)
	checkArg(1, color, "number")
	gui.background_color = color or gui.background_color
end

function gui:exit()
	gui.layer = {}
	event_handler.ignore()
	render.setColor(cfg.color.std)
	term.clear()
	os.exit()
end

function gui:init()
	gui.layer = {}
	event_handler.ignore()
	for size = 2, 4 do
    	bigfont.load(size)
	end
end

return gui