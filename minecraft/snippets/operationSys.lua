
local currentOperationId = nil
local operationIdQueue = {}

local function tableFind( array, value )
	for index, item in ipairs(array) do
		if item == value then
			return index
		end
	end
	return nil
end

-- returns 1 if is the current operation, 2 if in the queue, 3 if non-existent
local function GetOperationStatus( operationId )
	if operationId == currentOperationId then
		return 1
	elseif tableFind( operationIdQueue, operationId ) then
		return 2
	end
	return 3
end

local function IsOperationCompleted( operationId )
	return (currentOperationId ~= operationId) and not tableFind( operationIdQueue, operationId )
end

-- return -1 if non-existent, 1 if is current operation, 2 if was in queue
local function PopOperationFromQueue( operationId )
	local index = tableFind( operationIdQueue, operationId )
	if index then
		table.remove( operationIdQueue, index )
	end
	return (index ~= nil)
end
