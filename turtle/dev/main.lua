
local utility = require("dev.utility")
local actions = require("dev.actions")

local turtle_id = utility.InitializeTurtle()

while true do
	-- get queued jobs
	local queued_jobs = utility.GetQueuedJobs(turtle_id)
	if queued_jobs == nil or queued_jobs.success == false then
		print('Server errored - killed turtle.')
		break
	end

	local tracker_id = queued_jobs['tracker_id']
	local jobs_list = queued_jobs['data']
	--[[
		{ success : bool, data : dict | list | None, message : string?, tracker_id : string? }
	]]

	-- execute and prepare results
	local jobs_results = { }
	for _, jobEnum in ipairs( jobs_list ) do
		local success, results = actions.parseEnum( table.unpack(jobEnum) ) -- job and arguments passed in
		if not success then
			break -- if len(results) ~= len(jobs) -> something was not successful, end early.
		end
		table.insert(jobs_results, results)
	end

	-- send back to the server
	local _ = utility.ReturnJobResults(turtle_id, jobs_results, tracker_id)
end
