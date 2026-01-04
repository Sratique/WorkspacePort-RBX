local RunService = game:GetService("RunService")

local HandleAdornment = require("./Capabilities/HandleAdornment")
local Movement = require("./Capabilities/Movement")
local PositionTracker = require("./Capabilities/PositionTracker")
local ReplicationService = require("./ReplicationService")

local Assets = script.Parent.Assets
local Skybox = Assets.Skybox
local Overlay = Assets.Overlay
local LayerBtn = Assets.LayerLabel

local VirtualWorkspace = {}
VirtualWorkspace.__index = VirtualWorkspace

VirtualWorkspace.Capabilities = {

	["Movement"] = {
		["CapabilityName"] = "MovementController",
		["Description"] = "Imports premade freecamera modules for Roblox Studio like behavior.",
		["Capability"] = Movement.New,
	},
	["HandleAdornment"] = {

		["CapabilityName"] = "HandleAdornmentController",
		["Description"] = "Handles creation of UI instances. (3D UI instances like PV Adornments)",
		["Capability"] = HandleAdornment.New,
	},
	["PositionalBaseplate"] = {

		["CapabilityName"] = "PositionalBaseplate",
		["Description"] = "Default baseplate that helps with orientation in the viewport.",
		["Capability"] = PositionTracker.NewBaseplate,
	},
}

local DefaultCapabilities = {}

function VirtualWorkspace.New(
	ExistingViewport: ViewportFrame,
	Capabilities: { [number]: { CapabilityName: string, Capability: (any) -> any } }?
)
	ExistingViewport = ExistingViewport or Instance.new("ViewportFrame")

	local WorkspaceCamera = ExistingViewport:FindFirstChildOfClass("Camera") or Instance.new("Camera")
	WorkspaceCamera.Parent = ExistingViewport
	ExistingViewport.CurrentCamera = WorkspaceCamera
	local WorkspaceWorldModel = ExistingViewport:FindFirstAncestorOfClass("WorldModel") or Instance.new("WorldModel")
	WorkspaceWorldModel.Parent = ExistingViewport

	local NewVirtualWorkspace = setmetatable({}, VirtualWorkspace)

	--Meant only for the package to function correctly and not interfere with other code
	NewVirtualWorkspace.ViewportFrame = ExistingViewport
	NewVirtualWorkspace.UserCamera = workspace.CurrentCamera
	NewVirtualWorkspace.WorldModel = WorkspaceWorldModel
	NewVirtualWorkspace.Layers = {}

	--Apply all object capabilities
	for _, CapabilityStruct in pairs(Capabilities or DefaultCapabilities) do
		NewVirtualWorkspace[CapabilityStruct.CapabilityName] = CapabilityStruct.Capability(NewVirtualWorkspace)
	end

	--Add skybox
	local NewSkybox = Skybox:Clone()
	NewSkybox.Parent = ExistingViewport
	--     Skybox Behavior
	RunService.Heartbeat:Connect(function()
		NewSkybox:PivotTo(CFrame.new(WorkspaceCamera.CFrame.Position) * CFrame.Angles(math.rad(90), 0, 0))
	end)

	--Add Overlay
	local NewOverlay = Overlay:Clone()
	NewOverlay.Parent = ExistingViewport

	local OverlayStatusBar = NewOverlay.StatusBar
	local LayersFrame = NewOverlay.Layers

	--Make the overlay interactive

	OverlayStatusBar.Layers.Activated:Connect(function()
		LayersFrame.Visible = not LayersFrame.Visible
		for _, v in pairs(LayersFrame:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
		for LayerName: string, v in pairs(NewVirtualWorkspace.Layers) do
			if not v.Instance then
				continue
			end

			local newbtn = LayerBtn:Clone()
			newbtn.Active = true
			newbtn.Interactable = true
			newbtn.Parent = LayersFrame
			newbtn.Text = LayerName

			local DefaultColor = newbtn.BackgroundColor3
			local DisabledColor = Color3.fromRGB(129, 129, 129)

			if not v.Enabled then
				newbtn.BackgroundColor3 = DisabledColor
			end

			newbtn.Activated:Connect(function()
				if v.Enabled then
					v.Enabled = false
					v.Instance.Parent = nil
					newbtn.BackgroundColor3 = DisabledColor
				else
					v.Enabled = true
					v.Instance.Parent = ExistingViewport
					newbtn.BackgroundColor3 = DefaultColor
				end
			end)
		end
	end)

	--The focus label behavior
	if ExistingViewport.Parent and ExistingViewport.Parent:IsA("DockWidgetPluginGui") then
		local Dock = ExistingViewport.Parent

		Dock.WindowFocused:Connect(function()
			OverlayStatusBar.IsFocused.Text = "This window is currently focused"
		end)

		Dock.WindowFocusReleased:Connect(function()
			OverlayStatusBar.IsFocused.Text = "This window is currently unfocused"
		end)
	else
		OverlayStatusBar.IsFocused.Visible = false
	end

	--Modify the current behavior of the existing ViewportFrame
	ExistingViewport.ChildAdded:Connect(function(Child: Instance)
		if Child:IsA("GuiBase2d") then
			return
		end
		Child.Parent = WorkspaceWorldModel
	end)

	return NewVirtualWorkspace
end

function VirtualWorkspace:NewWorkspaceLayer(LayerName: string)
	if self.Layers[LayerName] then
		return self.Layers[LayerName].Instance
	end

	local newWorkspace = Instance.new("WorldModel")
	newWorkspace.Parent = self.ViewportFrame

	newWorkspace.Name = LayerName

	self.Layers[LayerName] = { ["Instance"] = newWorkspace, ["Enabled"] = true }

	return newWorkspace
end

function VirtualWorkspace:AddInstance(ToAdd: Instance)
	ToAdd.Parent = self.WorldModel
end

function VirtualWorkspace:ReplicateInstance(Any: Instance, BothWays: boolean?)
	if not Any then
		return
	end

	local NewAny = Any:Clone()

	self.ReplicatedInstances = self.ReplicatedInstances or {}
	self.ReplicatedInstances[Any] = ReplicationService.New(Any, NewAny, BothWays)
end

return VirtualWorkspace
