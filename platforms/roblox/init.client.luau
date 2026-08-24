--!strict
local doom = require("../src")
local keys = require("@self/keyinput")
local engineStart = 0

-- Configure platform-specific interface
local ScreenGui = Instance.new("ScreenGui", assert(game.Players.LocalPlayer).PlayerGui)
ScreenGui.IgnoreGuiInset = true
local ImageLabel = Instance.new("ImageLabel")
ImageLabel.Size = UDim2.new(1.333, 0, 1, 0)
ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
ImageLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY
ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
ImageLabel.Parent = ScreenGui
local outputImageSize = Vector2.new(doom.doomtype.DOOMGENERIC_RESX, doom.doomtype.DOOMGENERIC_RESY)
local outputImage = game:GetService("AssetService"):CreateEditableImage({Size = outputImageSize})
ImageLabel.ImageContent = Content.fromObject(outputImage)

-- Assign platform-specific functions into platform.luau
doom.platform.GetTicksMs = function()
	return (os.clock() - engineStart) // 0.001
end
doom.platform.GetKey = function(isPressed, Key)
	local key = keys[1]
	if key then
		table.remove(keys, 1)
		return key[1] == 1, key[2]
	end
	-- No keys in queue
	return false, 0
end

-- Create, run & loop
doom.doomgeneric.SetWAD(require('../res/doom1.wad'))
engineStart = os.clock()
doom.doomgeneric.Create({ "DoomGeneric" })
while task.wait(1/35) do
	doom.doomgeneric.Tick()
	outputImage:WritePixelsBuffer(
		Vector2.zero,
		outputImageSize,
		doom.doomgeneric.DG_ScreenBuffer
	)
end