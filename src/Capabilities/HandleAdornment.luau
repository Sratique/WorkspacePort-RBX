local HandleAdornmentController = {}
HandleAdornmentController.__index = HandleAdornmentController

local Emulation = {

	["BoxHandleAdornment"] = {},
}

function HandleAdornmentController.New(VirtualWorkspace: any)
	if not VirtualWorkspace then
		return
	end

	local NewHandleAdornmentController = setmetatable({}, HandleAdornmentController)

	local ViewportFrame: ViewportFrame = VirtualWorkspace.ViewportFrame

	ViewportFrame.DescendantAdded:Connect(function(Descendant: Instance)
		if not Descendant:IsA("HandleAdornment") then
			return
		end
	end)

	return NewHandleAdornmentController
end

return HandleAdornmentController
