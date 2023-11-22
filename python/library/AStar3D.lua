
export type Node = {
	x : number,
	y : number,
	z : number,

	cost : number,
	non_traversible : boolean
}

export type VisualNode = {
	x : number,
	z : number,
	y  : number,
	part : BasePart
}

export type Path = {
	start : Node,
	finish : Node,
	waypoints : { Node },
	total_cost : number,
}

export type GridClass = {
	Grid : boolean | { { { { [string] : Node } } } },
	_ComputeCache : { [string] : Path },
	_ComputeCacheLength : number,
}

local function CreateNode(x : number, y : number, z : number, cost : number, non_traversible : boolean) : Node
	return { x = x, y = y, z = z, cost = cost, non_traversible = non_traversible }
end

local function Compute3dArray( x_len, y_len, z_len, callback )
	local array3d = {}
	for x = 1, x_len do
		if not array3d[x] then
			array3d[x] = { }
		end
		for z = 1, z_len do
			if not array3d[x][z] then
				array3d[x][z] = { }
			end
			for y = 1, y_len do
				table.insert(array3d[x][z], callback(x,y,z))
			end
		end
	end
	return array3d
end

-- // Class // --
local AStarGridClass = {}
AStarGridClass.__index = AStarGridClass

function AStarGridClass.New()
	local self = setmetatable({
		Grid = {}, -- actual map grid is stored here

		_ComputeCache = { }, -- past computations are stored here
		_ComputeCacheLength = 0,
	}, AStarGridClass)

	return self
end

function AStarGridClass:HashNodePair(start : Node, finish : Node)
	return string.format(
		"(%s_%s_%s)_(%s_%s_%s)",
		start.x, start.y, start.z,
		finish.x, finish.y, finish.z
	)
end

function AStarGridClass:ClearComputeCache()
	self._ComputeCache = { }
end

function AStarGridClass:Empty( x_len, z_len, y_len )
	self.Grid = Compute3dArray(x_len, y_len, z_len, function(x,y,z)
		return CreateNode(x, y, z, 1, false)
	end)
end

function AStarGridClass:RandomizeWall( x_len, z_len, y_len, wall_chance_of_hundred )
	self.Grid = Compute3dArray(x_len, y_len, z_len, function(x,y,z)
		return CreateNode(x, y, z, 1, math.random(1, 100) < wall_chance_of_hundred)
	end)
end

function AStarGridClass:RandomizeCost( x_len, z_len, y_len, cost_min, cost_max )
	self.Grid = Compute3dArray(x_len, y_len, z_len, function(x,y,z)
		return CreateNode(x, y, z, math.random(cost_min, cost_max), false)
	end)
end

function AStarGridClass:RandomizeCostAndWall( x_len, z_len, y_len, cost_min, cost_max, wall_chance_of_hundred )
	self.Grid = Compute3dArray(x_len, y_len, z_len, function(x,y,z)
		return CreateNode(x, y, z, math.random(cost_min, cost_max), math.random(1, 100) < wall_chance_of_hundred)
	end)
end

function AStarGridClass:ComputeNodeCallback( x_len, z_len, y_len, callback )
	self.Grid = Compute3dArray(x_len, y_len, z_len, function(x, y, z)
		local Data = CreateNode(x, y, z, 1, false)
		callback(x, y, z, Data)
		return Data
	end)
end

function AStarGridClass:FindNext( condition : (Node) -> Node ) : Node?
	for x, ztab in self.Grid do
		for z, ytab in ztab do
			for y, node in ytab do
				if condition(node) then
					return node
				end
			end
		end
	end
	return nil
end

function AStarGridClass:Get3DNeighbors( source : Node, disallow_diagonals : boolean?, filter_traversible : boolean? ) : { Node }

	-- find all neighbour nodes (assume empty columns/rows/depth to be nil, are filtered)
	local LeftPlane = source.x - 1
	local RightPlane = source.x + 1
	local ForwardPlane = source.z + 1
	local BackwardPlane = source.z - 1
	local Up = source.y + 1
	local Down = source.y - 1
	
	local function CheckNodePath( x, z, y )
		if self.Grid[ x ] then
			if self.Grid[ x ][ z ] then
				return self.Grid[ x ][ z ][ y ] or false
			end
		end
		return false
	end
	
	-- 9 + 9 + 8 = 27 points
	local neighbour_across = {
		CheckNodePath( LeftPlane, source.z, source.y ), -- left-middle-middle
		CheckNodePath( RightPlane, source.z, source.y ), -- right-middle-middle
		CheckNodePath( source.x, source.z, Up ), -- top-middle
		CheckNodePath( source.x, source.z, Down ), -- bottom-middle
		CheckNodePath( source.x, ForwardPlane, source.y ), -- middle-forward-middle
		CheckNodePath( source.x, BackwardPlane, source.y ), -- middle-forward
	}
	
	if not disallow_diagonals then
		
		local neighbour_diagonal = {
			-- left plane
			CheckNodePath(LeftPlane, ForwardPlane, Up),
			CheckNodePath(LeftPlane, ForwardPlane, source.y),
			CheckNodePath(LeftPlane, ForwardPlane, Down),
			CheckNodePath(LeftPlane, source.z, Up),
			CheckNodePath(LeftPlane, source.z, Down),
			CheckNodePath(LeftPlane, BackwardPlane, Up),
			CheckNodePath(LeftPlane, BackwardPlane, source.y),
			CheckNodePath(LeftPlane, BackwardPlane, Down),
			-- right plane
			CheckNodePath(RightPlane, ForwardPlane, Up),
			CheckNodePath(RightPlane, ForwardPlane, source.y),
			CheckNodePath(RightPlane, ForwardPlane, Down),
			CheckNodePath(RightPlane, source.z, Up),
			CheckNodePath(RightPlane, source.z, Down),
			CheckNodePath(RightPlane, BackwardPlane, Up),
			CheckNodePath(RightPlane, BackwardPlane, source.y),
			CheckNodePath(RightPlane, BackwardPlane, Down),
			-- around
			CheckNodePath(source.x, ForwardPlane, Up),
			CheckNodePath(source.x, ForwardPlane, Down),
			CheckNodePath(source.x, BackwardPlane, Up),
			CheckNodePath(source.x, BackwardPlane, Down),
		}
		
		table.move(neighbour_diagonal, 1, #neighbour_diagonal, #neighbour_across + 1, neighbour_across)
	end
	
	-- filter out non-traversible nodes
	local reverse = (source.x + source.z + source.y) % 2 == 0
	
	local neighbours = { }
	for _, p in ipairs(neighbour_across) do
		if (not p) or (filter_traversible and p.non_traversible) then
			continue
		end
		if reverse then
			table.insert(neighbours, 1, p)
		else
			table.insert(neighbours, p)
		end
	end
	
	return neighbours
end

function AStarGridClass:FloodFillNodesCallback( source : Node, callback : (Node) -> boolean, disallow_diagonals : boolean? )
	local Frontier = { source }
	local Visited = { source }

	while #Frontier > 0 do
		local source = table.remove(Frontier, 1)
		local neighbours = self:Get3DNeighbors( source, disallow_diagonals )
		for _, neighbour in ipairs(neighbours) do
			local sayYesPlz = (not callback) or callback(neighbour)
			if not table.find(Visited, neighbour) and sayYesPlz then
				table.insert(Visited, neighbour) 
				table.insert(Frontier, neighbour)
			end
		end
	end

	return Visited
end

function AStarGridClass:FloodFillNonTraversible( source : Node, disallow_diagonal : boolean? ) : { Node }
	return self:FloodFillNodesCallback( source, function( node : Node )
		return node.non_traversible
	end, disallow_diagonal, false)
end

function AStarGridClass:RandomPoint() : Node
	local x = math.random(#self.Grid)
	local z = math.random(#self.Grid[x])
	local y = math.random(#self.Grid[x][z])
	return self.Grid[x][z][y]
end

function AStarGridClass:GetNodeDistance( A : Node, B : Node ) : number
	return (Vector3.new( A.x, A.y, A.z ) - Vector3.new( B.x, B.y, B.z )).Magnitude
end

function AStarGridClass:GetCost(current : Node, currentCost : number, start : Node, goal : Node)
	return currentCost + self:GetNodeDistance(current, start) + self:GetNodeDistance(current, goal)
end

function AStarGridClass:PathfindTo( start : Node, goal : Node )
	local frontier = { start }
	local cameFrom = { [start] = false }
	local costTable = { [start] = 1 }
	local activePoint = nil

	start.non_traversible = false
	goal.non_traversible = false

	while #frontier > 0 do 
		activePoint = frontier[1]
		table.remove(frontier, 1)

		if activePoint == goal then
			break
		end

		for _, point in ipairs( self:Get3DNeighbors( activePoint ) ) do 
			local cost = self:GetCost(point, costTable[point] or 1, start, goal )
			if cameFrom[point] then 
				if cost < costTable[point] then
					costTable[point] = cost
					cameFrom[point] = activePoint
					table.insert(frontier, 1, point)
				end
			else
				costTable[point] = cost
				cameFrom[point] = activePoint
				table.insert(frontier, point)
			end
		end

		table.sort(frontier, function(pointA, pointB)
			return costTable[pointA] < costTable[pointB]
		end)
	end
	
	if activePoint == goal then 
		local path = {}
		while activePoint and activePoint ~= start do
			table.insert(path, activePoint)
			activePoint = cameFrom[activePoint]
		end
		return path
	end

	return nil
	
end

-- // Wrapper // --
local SizeMultiplier = 2
local CurrentCamera = workspace.CurrentCamera

local BaseVisualPart = Instance.new('Part')
BaseVisualPart.CastShadow = false
BaseVisualPart.Anchored = true
BaseVisualPart.CanQuery = false
BaseVisualPart.CanTouch = false
BaseVisualPart.CanCollide = false
BaseVisualPart.Massless = true
BaseVisualPart.TopSurface = Enum.SurfaceType.Smooth
BaseVisualPart.BottomSurface = Enum.SurfaceType.Smooth
BaseVisualPart.Size = Vector3.new(SizeMultiplier, SizeMultiplier, SizeMultiplier)

local WHITE_COLOR = Color3.new(1,1,1)
local RED_COLOR = Color3.new(1,0,0)

local Module = { AStarGridClass = AStarGridClass }

function Module.Visualize( Grid : GridClass ) : { VisualNode }
	local VisualNodeArray = {}
	local XYZCache = {}

	local function CheckXYZ(node)
		if not XYZCache[node.x] then
			XYZCache[node.x] = {}
		end
		if not XYZCache[node.x][node.z] then
			XYZCache[node.x][node.z] = {}
		end
		if not XYZCache[node.x][node.z][node.y] then
			XYZCache[node.x][node.z][node.y] = node
		end
	end

	for x, ztab in Grid.Grid do
		for z, ytab in ztab do
			for y, node in ytab do
				
				local NewPart = BaseVisualPart:Clone()
				NewPart.Name = x..'_'..y..'_'..z
				NewPart.Position = Vector3.new(x, y, z) * SizeMultiplier
				NewPart.Transparency = node.non_traversible and 0.95 or 1
				NewPart.Color = node.non_traversible and RED_COLOR or WHITE_COLOR
				NewPart.Parent = CurrentCamera

				local node = {x=x, z=z, y=y, part=NewPart}
				CheckXYZ(node)
				table.insert(VisualNodeArray, node)
			end
		end
	end

	return VisualNodeArray, XYZCache
end

return Module
