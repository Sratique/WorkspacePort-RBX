local Assets = script.Parent.Parent.Assets
local Baseplate = Assets.Baseplate

local PositionTracker = {}

type VirtualWorkspace = {

	ViewportFrame: ViewportFrame,
	UserCamera: Camera,
	Speed: number?,
	NewWorkspaceLayer: (VirtualWorkspace, string) -> (),
}

function PositionTracker.NewBaseplate(VirtualWorkspace: VirtualWorkspace)
	local RootLayer = VirtualWorkspace:NewWorkspaceLayer("OrientationHelper")

	local newBaseplate = Baseplate:Clone()
	newBaseplate.Parent = RootLayer
end

return PositionTracker
