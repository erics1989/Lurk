
-- path functions

local Path = {}

-- get adjacent spaces
local function adjacent(space)
    return Hex.adjacent(space)
end

-- default cost between adjacent spaces
local function d_cost(space1, space2)
    return 1
end

-- default A* heuristic
local function astar_heuristic(space1, space2)
    return Hex.dist(space1, space2)
end

-- bfs distance map
function Path.dist(srcs, validF, costF, max)
    costF = costF or d_cost
    max = max or math.huge
    local dist = {}
    local prev = {}
    for _, space in ipairs(_state.spaces) do
        dist[space] = math.huge
    end
    local q = {}
    for _, space in ipairs(srcs) do
        if validF(space) then
            dist[space] = 0
            table.insert(q, space)
        end
    end
    while q[1] do
        local space1 = List.pop_top(
            q, 
            function (space1, space2)
                return dist[space1] < dist[space2]
            end
        )
        for _, space2 in ipairs(adjacent(space1)) do
            if validF(space2) then
                local d = dist[space1] + costF(space1, space2)
                if d < dist[space2] and d <= max then
                    dist[space2] = d
                    prev[space2] = space1
                    table.insert(q, space2)
                end
            end
        end
    end
    return dist, prev
end

-- Dijkstra's algorithm (backwards)
function Path.dijk(srcF, dsts, validF, costF, max)
    costF = costF or d_cost
    max = max or math.huge
    local dist = {}
    local prev = {}
    for _, space in ipairs(_state.spaces) do
        dist[space] = math.huge
    end
    local q = {}
    for _, space in ipairs(dsts) do
        if validF(space) then
            dist[space] = 0
            table.insert(q, space)
        end
    end
    while q[1] do
        local space1 = List.pop_top(
            q,
            function (space1, space2)
                return dist[space1] < dist[space2]
            end
        )
        if srcF(space1) then
            return Path.get_path(space1, prev)
        else
            for _, space2 in ipairs(adjacent(space1)) do
                if validF(space2) then
                    local d = dist[space1] + costF(space2, space1)
                    if d < dist[space2] and d <= max then
                        dist[space2] = d
                        prev[space2] = space1
                        table.insert(q, space2)
                    end
                end
            end
        end
    end
end

-- A* (backwards)
function Path.astar(src, dsts, validF, costF, max)
    costF = costF or d_cost
    max = max or math.huge
    local dist = {}
    local dist_heuristic = {}
    local prev = {}
    for _, space in ipairs(_state.spaces) do
        dist[space] = math.huge
        dist_heuristic[space] = math.huge
    end
    local q = {}
    for _, space in ipairs(dsts) do
        if validF(space) or space == src then
            dist[space] = 0
            dist_heuristic[space] =
                astar_heuristic(src, space)
            table.insert(q, space)
        end
    end
    while q[1] do
        local space1 = List.pop_top(
            q,
            function (space1, space2)
                return dist_heuristic[space1] < dist_heuristic[space2]
            end
        )
        if space1 == src then
            return Path.get_path(space1, prev)
        else
            for _, space2 in ipairs(adjacent(space1)) do
                if validF(space2) or space2 == src then
                    local d = dist[space1] + costF(space2, space1)
                    if d < dist[space2] and d <= max then
                        dist[space2] = d
                        dist_heuristic[space2] =
                            d + astar_heuristic(src, space2)
                        prev[space2] = space1
                        table.insert(q, space2)
                    end
                end
            end
        end
    end
end

-- generate a path w/ path data
function Path.get_path(space, prev)
    local spaces = {}
    while space do
        table.insert(spaces, space)
        space = prev[space]
    end
    return spaces
end

return Path

