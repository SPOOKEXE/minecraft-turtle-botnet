
local settings

-- // Module // --
local Module = {}

function Module.SaveSettings( path )
	settings.save( path )
end

function Module.LoadSettings( path )
	settings.load( path )
end

function Module.GetState( stateName )
	return settings.get( stateName )
end

function Module.SetState( stateName, stateValue )
	settings.set( stateName, stateValue )
end

function Module.CreateState( stateName, stateData )
	settings.define( stateName, stateData )
end

function Module.StateArrayAppend( stateName, value )
	local concurrent = Module.GetState( stateName )
	table.insert( concurrent, value )
	Module.SetState( stateName, concurrent )
end

function Module.StateDictionaryUpdate( stateName, dictionary )
	local concurrent = Module.GetState( stateName )
	for index, value in pairs( dictionary ) do
		concurrent[index] = value
	end
	Module.SetState( stateName, concurrent )
end

function Module.UnsetState( stateName )
	settings.unset( stateName )
end

return Module
