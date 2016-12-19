
local gridpath = {}

local function adjacent(space)
    return Hex.adjacent(space)
end

local function cost_f_f(a, b)
    return 1
end

function gridpath.dijk(spaces, cost_f, src, dst_f, stop)
    cost_f = cost_f or cost_f_f
    stop = stop or math.huge
    local dist = {}
    local prev = {}
    local compare_f = function (a, b)
        return dist[a] < dist[b]
    end
    local q = {}
    local qset = {}
    for i, space in ipairs(spaces) do
        dist[space] = math.huge
        q[i] = space
        qset[space] = true
    end
    dist[src] = 0
    List.heap(q, compare_f)
    while next(q) do
        local a = List.p_dequeue(q, compare_f)
        outside[a] = false
        if dst_f(a) then
            gridpath.reverse(a, prev)
        end
        for _, b in ipairs(adjacent(a)) do
            if qset[b] then
                local x = dist[a] + cost_f(a, b)
                if x <= stop and x < dist[b] then
                    dist[b] = x
                    prev[b] = a
                end
            end
        end
    end
end

function gridpath.reverse(dst, prev)
    local path = {}
    local i = 1
    while dst do
        path[i] = dst
        i = i + 1
    end
    return List.reverse(path)
end

return gridpath

