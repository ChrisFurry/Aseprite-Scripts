-- Script by ChrisFurry, version 1.6
-- Discord: chrisfurry
-- Revolt: ChrisFurry#1081
-- Im stupid and i should have added credits, sorry normally im good about this stuff.
--[[ CREDITS
Partially based on "Palette Police" object from Sonic Mania Addendum, made by LittlePlanetCD and KiaraGale.
Ported from Sonic 1 Forever (Originally by ElspethThePict)
]]--

if app.apiVersion < 1 then
	return app.alert("This script requires version v1.2.10-beta3 or greater")
end

local function round(a)
	return ((a % 1) > 0.5) and math.ceil(a) or math.floor(a)
end

-- Color math
---ALL FUNCTIONS IN THIS TABLE MUST HAVE THESE PARAMS AND RETURN
---@param r number From 0-255
---@param g number From 0-255
---@param b number From 0-255
---@param e string Modifier
---@return table{r,g,b}
local fix_color = {
	["15-Bit"] = function(r,g,b)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			local roundUp = col % 8 > 4
			if(roundUp)then 
				col = col + (8 - col % 8)
				if(col > 0xFF)then
					col = 255 
					col = col >> 3
					col = col << 3
				end
			else
				col = col >> 3
				col = col << 3
			end
			color[i] = col
		end
		return color
	end;
	["12-Bit"] = function(r,g,b)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			col = col >> 4
			col = col << 4
			color[i] = col
		end
		return color
	end;
	["9-Bit"] = function(r,g,b,e)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			col = col >> 5
			if(e == "Retro Engine")then
				col = col << 5
			else
				col = col * 0x24
				if(col >= 0xFC and e == "Default")then col = 0xFF end
			end
			color[i] = col
		end
		return color
	end;
	["6-Bit"] = function(r,g,b)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			color[i] = math.min(round(col/85)*85,0xFF)
		end
		return color
	end;
	["3-Bit"] = function(r,g,b)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			color[i] = round(col/256)*255
		end
		return color
	end;
}
-- Execution
local function execute_script(type,game,extra,ignore_idx0)
	-- Setup
	local cel,img,spr,shiftamm
	if(type == "Image")then
		cel = app.cel
		if(not cel)then
			return app.alert("There is no active image!")
		end
		img = cel.image:clone()
		if(img.colorMode ~= ColorMode.RGB)then
			return app.alert("Image must be in RGB mode! For palettes, use the palette script!")
		end
	else
		trans_string = "Palette"
		spr = app.sprite
		if(not spr)then
			return app.alert("There is no active image!")
		end
	end
	trans_string = type.." to "..game.." Colorspace"
	-- Transaction
	app.transaction(trans_string,
	function()
		if(type == "Image")then
			local rgba = app.pixelColor.rgba
			local rgbaA = app.pixelColor.rgbaA
			for it in img:pixels() do
				local pixelValue = it()
				local color = fix_color[game](app.pixelColor.rgbaR(pixelValue),app.pixelColor.rgbaG(pixelValue),app.pixelColor.rgbaB(pixelValue),extra)

				it(rgba(color.r,
						color.g,
						color.b, rgbaA(it())))
			end
			cel.image = img

			app.refresh()
		else
			local pal = spr.palettes[1]
			for i = ignore_idx0 and 1 or 0,#pal-1 do
				local slotcolor = pal:getColor(i)
				local color = fix_color[game](slotcolor.red,slotcolor.green,slotcolor.blue,extra)
				
				pal:setColor(i,Color(color))
			end
		end
	end)
end

local dee,consoleSupport

-- List defining all of the supported consoles/games
consoleSupport = {
	["15-Bit"]	= "SNES, GBC, GBA, DS, Neo Geo AES/CD, Sega 32x, PSX (Textures), Sonic Mania",
	["12-Bit"]	= "Game Gear, Neo Geo Pocket Color (There are many more I didn't list)",
	["9-Bit"]	= "Sega Genesis/Mega Drive, Sega Pico",
	["6-Bit"]	= "Master System, EGA for IBM PC/AT (Already a palette but why not)",
	["3-Bit"]	= "Text Terminals",
	["1-Bit"]	= "Half-Bit"
}

local function on_game_change()
	local new_list = {"Default"}
	if(dee.data.game == "9-Bit")then
		new_list = {"Default","Rendered","Retro Engine"}
	end
	dee:modify{id="support",text=consoleSupport[dee.data.game]}
	dee:modify{id="extra",option="Default",options=new_list}
end

dee = Dialog("ColorSpace Converter"):combobox{id="type",label="Type",
	option="Image",options={
		"Image","Palette"}}
:label{id="support",label="Console/Game Support: ",text="haha you wont see this unless you're looking for it :3"}
:combobox{id="game",label="Game",
	option="15-Bit",options={
	"15-Bit",
	"12-Bit",
	"9-Bit",
	"6-Bit",
	"3-Bit"},onchange=on_game_change}
:combobox{id="extra",label="Modifier",option="Default",options={"Default"}}
:check{id="idx0",label="Ignore Index 0",selected=true}
:separator{id="nah"}
-- Final 3 buttons
:button{id="executeandclose", text="Done",onclick=function()
	execute_script(dee.data.type,dee.data.game,dee.data.extra,dee.data.idx0)
	dee:close()
end}
:button{id="execute", text="Apply",onclick=function()
	execute_script(dee.data.type,dee.data.game,dee.data.extra,dee.data.idx0)
end}
:button{id="cancel", text="Cancel",onclick=function()
	dee:close()
end}

on_game_change()

dee:show()