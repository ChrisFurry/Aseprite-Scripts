-- Script by ChrisFurry, version 1.4
-- Discord: chrisfurry

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
---@return table{r,g,b}
local fix_color = {
	["15-Bit (SNES, 32X, Sonic Mania)"] = function(r,g,b)
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
	["9-Bit (Retro Engine ColorSpace)"] = function(r,g,b)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			col = col >> 5
			col = col << 5
			color[i] = col
		end
		return color
	end;
	["9-Bit (Rendered, Sonic 3 Air)"] = function(r,g,b)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			col = col >> 5
			col = col * 0x24
			-- yes i just remove one line of code lol
			-- i dont know how to make dynamic options yet so this is the best you get.
			--if(col >= 0xFC)then col = 0xFF end
			color[i] = col
		end
		return color
	end;
	["9-Bit (Sega Geneis)"] = function(r,g,b)
		local color = {
			r=r,
			g=g,
			b=b
		}
		for i,col in pairs(color) do
			col = col >> 5
			col = col * 0x24
			if(col >= 0xFC)then col = 0xFF end
			color[i] = col
		end
		return color
	end;
	["6-Bit (Master System)"] = function(r,g,b)
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
local function execute_script(type,game,ignore_idx0)
	-- Setup
	local cel,img,spr,shiftamm
	if(type == "Image")then
		cel = app.activeCel
		if(not cel)then
			return app.alert("There is no active image!")
		end
		img = cel.image:clone()
		if(img.colorMode ~= ColorMode.RGB)then
			return app.alert("Image must be in RGB mode! For palettes, use the palette script!")
		end
	else
		trans_string = "Palette"
		spr = app.activeSprite
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
				local color = fix_color[game](app.pixelColor.rgbaR(pixelValue),app.pixelColor.rgbaG(pixelValue),app.pixelColor.rgbaB(pixelValue))

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
				local color = fix_color[game](slotcolor.red,slotcolor.green,slotcolor.blue)
				
				pal:setColor(i,Color(color))
			end
		end
	end)
end

local dee = Dialog("ColorSpace Converter"):combobox{id="type",label="Type",
	option="Image",options={
		"Image","Palette"}}
:combobox{id="game",label="Game",
	option="Mania",options={
	"15-Bit (SNES, 32X, Sonic Mania)",
	"9-Bit (Retro Engine ColorSpace)",
	"9-Bit (Rendered, Sonic 3 Air)",
	"9-Bit (Sega Geneis)",
	"6-Bit (Master System)",
	"3-Bit"}}
:check{id="idx0",label="Ignore Index 0",selected=true}
-- Final 3 buttons
dee:button{id="executeandclose", text="Done",onclick=function()
	execute_script(dee.data.type,dee.data.game,dee.data.idx0)
	dee:close()
end}
:button{id="execute", text="Apply",onclick=function()
	execute_script(dee.data.type,dee.data.game,dee.data.idx0)
end}
:button{id="cancel", text="Cancel",onclick=function()
	dee:close()
end}

dee:show()