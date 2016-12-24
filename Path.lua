
-- path functions

local Path = {}

-- get adjacent spaces
local function adjacent(space)
    return Hex.adjacent(space)
end

local function valid_f0(space)
    return true
end

-- default cost between adjacent spaces
local function d_dist_f(space1, space2)
    return 1
end

-- default A* heuristic
local function astar_heuristic(space1, space2)
    return Hex.dist(space1, space2)
end

-- distance map
function Path.dist(srcs, valid_f, dist_f, stop)
    valid_f = valid_f or valid_f0
    dist_f = dist_f or d_dist_f
    stop = stop or math.huge
    local dist = {}
    local prev = {}
    local cf = function (space1, space2)
        return dist[space1] < dist[space2]
    end
    local q = {}
    local i = 1
    local qset = {}
    for _, space in ipairs(_state.map.spaces) do
        dist[space] = math.huge
        if valid_f(space) then
            table.insert(q, space)
            qset[space] = true
        end
    end
    for _, src in ipairs(srcs) do
        if valid_f(src) then
            dist[src] = 0
        end
    end
    while next(q) do
        List.heap(q, cf)
        local space1 = List.p_dequeue(q, cf)
        qset[space1] = false
        for _, space2 in ipairs(adjacent(space1)) do
            if qset[space2] and valid_f(space2) then
                local d = dist[space1] + dist_f(space1, space2)
                if d < dist[space2] and d <= stop then
                    dist[space2] = d
                    prev[space2] = space1
                end
            end
        end
    end
    return dist, prev
end

-- dijkstra
function Path.dijk(srcs, dst_f, valid_f, dist_f, stop)
    valid_f = valid_f or valid_f0
    dist_f = dist_f or d_dist_f
    stop = stop or math.huge
    local dist = {}
    local prev = {}
    local cf = function (space1, space2)
        return dist[space1] < dist[space2]
    end
    local q = {}
    local i = 1
    local qset = {}
    for _, space in ipairs(_state.map.spaces) do
        dist[space] = math.huge
        if valid_f(space) then
            table.insert(q, space)
            qset[space] = true
        end
    end
    for _, src in ipairs(srcs) do
        if valid_f(src) then
            dist[src] = 0
        end
    end
    while next(q) do
        List.heap(q, cf)
        local space1 = List.p_dequeue(q, cf)
        qset[space1] = false
        if dst_f(space1) then
            return Path.reverse(space1, prev)
        end
        for _, space2 in ipairs(adjacent(space1)) do
            if qset[space2] and valid_f(space2) then
                local d = dist[space1] + dist_f(space1, space2)
                if d < dist[space2] and d <= stop then
                    dist[space2] = d
                    prev[space2] = space1
                end
            end
        end
    end
end

-- A*
function Path.astar(src, dst, valid_f, dist_f, stop, heuristic)
    valid_f = valid_f or valid_f0
    dist_f = dist_f or d_dist_f
    stop = stop or math.huge
    heuristic = heuristic or astar_heuristic
    local dist = {}
    local dist_heuristic = {}
    local prev = {}
    local cf = function (space1, space2)
        return dist_heuristic[space1] < dist_heuristic[space2]
    end
    local q = {}
    local qset = {}
    for _, space in ipairs(_state.map.spaces) do
        dist[space] = math.huge
        dist_heuristic[space] = math.huge
        if valid_f(space) then
            table.insert(q, space)
            qset[space] = true
        end
    end
    if valid_f(src) then
        dist[src] = 0
        dist_heuristic[src] = heuristic(src, dst)
    end
    while next(q) do
        List.heap(q, cf)
        local space1 = List.p_dequeue(q, cf)
        qset[space1] = false
        if space1 == dst then
            return Path.reverse(space1, prev)
        end
        for _, space2 in ipairs(adjacent(space1)) do
            if qset[space2] and valid_f(space2) then
                local d = dist[space1] + dist_f(space1, space2)
                if d < dist[space2] and d <= stop then
                    dist[space2] = d
                    dist_heuristic[space2] =
                        d + astar_heuristic(space2, dst)
                    prev[space2] = space1
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

