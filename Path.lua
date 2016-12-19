
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
    local processed = {}
    local cf = function (space1, space2)
        return dist[space1] < dist[space2]
    end
    for _, src in ipairs(srcs) do
        if valid_f(src) then
            dist[src] = 0
            List.p_enqueue(q, src, cf)
        end
    end
    while q[1] do
        local space1 = List.p_dequeue(q, cf)
        processed[space1] = true
        for _, space2 in ipairs(adjacent(space1)) do
            if not processed[space2] and valid_f(space2) then
                local d = dist[space1] + cost_f(space1, space2)
                if d < dist[space2] and d <= stop then
                    dist[space2] = d
                    prev[space2] = space1
                    List.p_enqueue(q, space2, cf)
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
    local processed = {}
    local cf = function (space1, space2)
        return dist[space1] < dist[space2]
    end
    if valid_f(src) then
        dist[src] = 0
        List.p_enqueue(q, src, cf)
    end
    while next(q) do
        local space1 = List.p_dequeue(q, cf)
        processed[space1] = true
        if dst_f(space1) then
            return Path.reverse(space1, prev)
        else
            for _, space2 in ipairs(adjacent(space1)) do
                if not processed[space2] and valid_f(space2) then
                    local d = dist[space1] + cost_f(space1, space2)
                    if d < dist[space2] and d <= stop then
                        dist[space2] = d
                        prev[space2] = space1
                        List.p_enqueue(q, space2, cf)
                    end
                end
            end
        end
    end
end

-- dijkstra
function Path.dijk(src, dst_f, valid_f, cost_f, stop)
    cost_f = cost_f or d_cost_f
    stop = stop or math.huge
    local dist = {}
    local prev = {}
    local cf = function (space1, space2)
        return dist[space1] < dist[space2]
    end
    local q = {}
    local outside = {}
    for i, space in ipairs(_state.spaces) do
        dist[space] = math.huge
        q[i] = space
        outside[space] = true
    end
    if valid_f(src) then
        dist[src] = 0
        List.heap(q, cf)
    end
    while next(q) do
        local space1 = List.p_dequeue(q, cf)
        outside[space1] = false
        if dst_f(space1) then
            return Path.reverse(space1, prev)
        else
            for _, space2 in ipairs(adjacent(space1)) do
                if outside[space2] and valid_f(space2) then
                    local d = dist[space1] + cost_f(space1, space2)
                    if d < dist[space2] and d <= stop then
                        dist[space2] = d
                        prev[space2] = space1
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
    local cf = function (space1, space2)
        return dist_heuristic[space1] < dist_heuristic[space2]
    end
    if valid_f(src) then
        dist[src] = 0
        dist_heuristic[src] = astar_heuristic(src, dst)
        List.p_enqueue(q, src, cf)
    end
    while q[1] do
        local space1 = List.p_dequeue(q, cf)
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
                        List.p_enqueue(q, space2, cf)
                    end
                end
            end
        end
    end
end

function Path.reverse(dst, prev)
    local path = {}
    while dst do
        table.insert(path, 1, dst)
        dst = prev[dst]
    end
    return path
end

return Path

