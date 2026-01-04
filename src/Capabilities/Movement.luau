local RunService = game:GetService("RunService")
local MovementController = {}
MovementController.__index = MovementController

type VirtualWorkspace = {

	ViewportFrame: ViewportFrame,
	UserCamera: Camera,
	Speed: number?,
}

local KeyToMovement = {

	["W"] = Vector3.new(0, 0, -1),
	["A"] = Vector3.new(-1, 0, 0),
	["S"] = Vector3.new(0, 0, 1),
	["D"] = Vector3.new(1, 0, 0),
	["Q"] = Vector3.new(0, -1, 0),
	["E"] = Vector3.new(0, 1, 0),
}

function MovementController.New(VirtualWorkspace: VirtualWorkspace)
	if not VirtualWorkspace then
		return
	end

	local NewMovementController = setmetatable({}, MovementController)

	local ViewportCamera = VirtualWorkspace.ViewportFrame.CurrentCamera

	local DirectionCFrame = CFrame.new(0, 0, 0)
	local DefaultSpeed = VirtualWorkspace.Speed or 0.75

	local IsGyrating: boolean = false
	local LastMousePosition: Vector3

	VirtualWorkspace.ViewportFrame.InputBegan:Connect(function(key)
		if key.KeyCode and KeyToMovement[string.upper(key.KeyCode.Name)] then
			DirectionCFrame += (KeyToMovement[string.upper(key.KeyCode.Name)] * DefaultSpeed)
		elseif key.UserInputType == Enum.UserInputType.MouseButton2 then
			LastMousePosition = key.Position
			IsGyrating = true
		end
	end)

	VirtualWorkspace.ViewportFrame.InputEnded:Connect(function(key)
		if key.KeyCode and KeyToMovement[string.upper(key.KeyCode.Name)] then
			if DirectionCFrame ~= Vector3.new(0, 0, 0) then
				DirectionCFrame -= (KeyToMovement[string.upper(key.KeyCode.Name)] * DefaultSpeed)
			end
		elseif key.UserInputType == Enum.UserInputType.MouseButton2 then
			IsGyrating = false
		end
	end)

	VirtualWorkspace.ViewportFrame.InputChanged:Connect(function(key)
		if key and key.UserInputType == Enum.UserInputType.MouseMovement and IsGyrating then
			local xorient, yorient, _ = ViewportCamera.CFrame:ToOrientation()

			local mousepos = key.Position - LastMousePosition

			ViewportCamera.CFrame = CFrame.new(ViewportCamera.CFrame.Position)
				* CFrame.Angles(0, math.rad(-mousepos.X) + yorient, 0)
				* CFrame.Angles(math.clamp(math.rad(-mousepos.Y) + xorient, math.rad(-81), math.rad(81)), 0, 0)

			LastMousePosition = key.Position
		end
	end)

	VirtualWorkspace.UserCamera:GetPropertyChangedSignal("CFrame"):Connect(function()
		VirtualWorkspace.ViewportFrame.CurrentCamera.CFrame = VirtualWorkspace.UserCamera.CFrame
	end)

	local FrameStep: RBXScriptConnection = RunService.PreRender:Connect(function()
		VirtualWorkspace.ViewportFrame.CurrentCamera.CFrame *= DirectionCFrame
	end)

	VirtualWorkspace.ViewportFrame.Destroying:Connect(function()
		FrameStep:Disconnect()
	end)

	return NewMovementController
end

return MovementController
