
local os
-- ^ IGNORE FOR PRODUCTION

local utility = require("dev.utility")
local actions = require("dev.actions")
local state = require("dev.state")

local TURTLE_STATE_FILENAME = 'turtle_'.. os.getComputerID()

state.LoadSettings( TURTLE_STATE_FILENAME )

state.CreateState('active_tracker_id', {
	description='The current tracker id for the python backend.',
	default='none',
	type='string',
})

state.CreateState('active_jobs', {
	description = 'The current jobs that are being processed.',
	default={},
	type='table',
})

state.CreateState('active_results', {
	description = 'The results for all the current jobs.',
	default={},
	type='table',
})

state.CreateState('active_index', {
	description = 'The current job index that is being processed.',
	default={},
	type='table',
})

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

	state.SetState('active_tracker_id', tracker_id or 'none')
	state.SetState('active_jobs', jobs_list)
	state.SetState('active_index', 1)
	state.SaveSettings( TURTLE_STATE_FILENAME )

	-- execute and prepare results
	if not state.GetState('active_results') then
		state.SetState('active_results', {})
	end

	for index, jobEnum in ipairs( jobs_list ) do
		if index < #
		state.SetState('active_index', index)
		state.SaveSettings( TURTLE_STATE_FILENAME )
		local success, results = actions.parseEnum( table.unpack(jobEnum) ) -- job and arguments passed in
		state.StateArrayAppend( 'active_results', { success, results } )
		if not success then
			break -- if len(results) ~= len(jobs) -> something was not successful, end early.
		end
	end

	-- send back to the server
	local jobs_results = state.GetState('active_results')
	local _ = utility.ReturnJobResults(turtle_id, jobs_results, tracker_id)
	state.UnsetState('active_results')
end
