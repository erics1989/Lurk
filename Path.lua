
-- path functions

local Path = {}

-- get adjacent spaces
local function adjacent(space)
    return Hex.adjacent(space)
end

-- default cost between adjacent spaces
local function d_cost_f(space1, space2)
    return 1
end

-- default A* heuristic
local function astar_heuristic(space1, space2)
    return Hex.dist(space1, space2)
end

-- bfs distance map
function Path.dist(srcs, valid_f, cost_f, stop)
    cost_f = cost_f or d_cost_f
    stop = stop or math.huge
    local dist = {}
    local prev = {}
    for _, space in ipairs(_state.spaces) do
        dist[space] = math.huge
    end
    local q = {}
    for _, space in ipairs(srcs) do
        if valid_f(space) then
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
            if valid_f(space2) then
                local d = dist[space1] + cost_f(space1, space2)
                if d < dist[space2] and d <= stop then
                    dist[space2] = d
                    prev[space2] = space1
                    table.insert(q, space2)
                end
            end
        end
    end
    return dist, prev
end

-- dijkstra's
function Path.dijk(src, dst_f, valid_f, cost_f, stop)
    cost_f = cost_f or d_cost_f
    stop = stop or math.huge
    local dist = {}
    local prev = {}
    for _, space in ipairs(_state.spaces) do
        dist[space] = math.huge
    end
    local q = {}
    if valid_f(src) then
        dist[src] = 0
        table.insert(q, src)
    end
    while q[1] do
        local space1 = List.pop_top(
            q,
            function (space1, space2)
                return dist[space1] < dist[space2]
            end
        )
        if dst_f(space1) then
            return Path.reverse(space1, prev)
        else
            for _, space2 in ipairs(adjacent(space1)) do
                if valid_f(space2) then
                    local d = dist[space1] + cost_f(space1, space2)
                    if d < dist[space2] and d <= stop then
                        dist[space2] = d
                        prev[space2] = space1
                        table.insert(q, space2)
                    end
                end
            end
        end
    end
end

-- A*
function Path.astar(src, dst, valid_f, cost_f, stop)
    cost_f = cost_f or d_cost_f
    stop = stop or math.huge
    local dist = {}
    local dist_heuristic = {}
    local prev = {}
    for _, space in ipairs(_state.spaces) do
        dist[space] = math.huge
        dist_heuristic[space] = math.huge
    end
    local q = {}
    if valid_f(src) then
        dist[src] = 0
        dist_heuristic[src] = astar_heuristic(src, dst)
        table.insert(q, src)
    end
    while q[1] do
        local space1 = List.pop_top(
            q,
            function (space1, space2)
                return dist_heuristic[space1] < dist_heuristic[space2]
            end
        )
        if space1 == dst then
            return Path.reverse(space1, prev)
        else
            for _, space2 in ipairs(adjacent(space1)) do
                if valid_f(space2) then
                    local d = dist[space1] + cost_f(space1, space2)
                    if d < dist[space2] and d <= stop then
                        dist[space2] = d
                        dist_heuristic[space2] =
                            d + astar_heuristic(space2, dst)
                        prev[space2] = space1
                        table.insert(q, space2)
                    end
                end
            end
        end
    end
end

-- generate a path w/ path data
-- deprecated
function Path.get_path(space, prev)
    local spaces = {}
    while space do
        table.insert(spaces, space)
        space = prev[space]
    end
    return spaces
end

-- TODO optimize: use dist to insert backwards
function Path.reverse(dst, prev)
    local path = {}
    while dst do
        table.insert(path, 1, dst)
        dst = prev[dst]
    end
    return path
end

function Path.print(path)
    local strs = {}
    if path[1] then
        for _, space in ipairs(path) do
            local str = string.format("(%d,%d)", space.x, space.y)
            table.insert(strs, str)
        end
        print(table.concat(strs, ","))
    else
        print("no spaces")
    end
end

return Path

