local ReplicationService = {}
ReplicationService.__index = ReplicationService

function ReplicationService.New(ReplicatedInstance: Instance, ReplicationTarget: Instance, BothWays: boolean?)
	if not ReplicatedInstance or not ReplicationTarget then
		return
	end

	local NewReplicationController = setmetatable({}, ReplicationService)

	local IsReplicating = false

	ReplicatedInstance.Changed:Connect(function(ChangedProperty: string)
		if IsReplicating then
			return
		end
		IsReplicating = true
		ReplicatedInstance[ChangedProperty] = ReplicationTarget[ChangedProperty]
		IsReplicating = false
	end)

	if BothWays then
		ReplicationTarget.Changed:Connect(function(ChangedProperty: string)
			if IsReplicating then
				return
			end
			IsReplicating = true
			ReplicationTarget[ChangedProperty] = ReplicatedInstance[ChangedProperty]
			IsReplicating = false
		end)
	end

	return NewReplicationController
end

return ReplicationService
