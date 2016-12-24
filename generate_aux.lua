
local generate_aux = {}

local function rng(a, b)
    return game.rand1(a, b)
end

function generate_aux.init(name, n, size)
    size = size or BOARD_SIZE
    _state.map = {}
    _state.map.name = name
    _state.map.n = n
    _state.map.spaces = {}
    _state.map.spaces2d = {}
    local center = { x = 0, y = 0, z = 0 }
    for x = -size, size do
        _state.map.spaces2d[x] = {}
        for y = -size, size do
            local space = { x = x, y = y, z = 0 - x - y }
            if Hex.dist(center, space) < size then
                table.insert(_state.map.spaces, space)
                _state.map.spaces2d[x][y] = space
            end
        end
    end
    _state.map.visited = {}
    _state.map.events = {}
    _state.map.persons = {}
    _state.map.objects = {}
end

function generate_aux.get_area(ax, bx, ay, by, az, bz)
    local spaces = {}
    for x = ax, bx do
        for y = ay, by do
            local z = 0 - x - y
            if az <= z and z <= bz then
                local space = game.get_space(x, y)
                if space then
                    table.insert(spaces, space)
                end
            end
        end
    end
    return spaces
end

function generate_aux.get_rng_area1(space, r1, r2)
    r1 = r1 or 1
    r2 = r2 or 4
    assert(space)
    local ax = space.x - rng(r1, r2)
    local bx = space.x + rng(r1, r2)
    local ay = space.y - rng(r1, r2)
    local by = space.y + rng(r1, r2)
    local az = space.z - rng(r1, r2)
    local bz = space.z + rng(r1, r2)
    return generate_aux.get_area(ax, bx, ay, by, az, bz)
end

function generate_aux.get_rng_area2(space1)
    local spaces1 = generate_aux.get_rng_area1(space1)
    local space2 = spaces1[rng(#spaces1)]
    local spaces2 = generate_aux.get_rng_area1(space2)
    return List.unique(List.concat(spaces1, spaces2))
end

function generate_aux.get_blobs(start_f, n)
    n = n or 1
    local generation1 = {}
    for _, space in ipairs(_state.map.spaces) do
        generation1[space] = start_f(space)
    end
    for i = 1, n do
        local generation2 = {}
        for _, space1 in ipairs(_state.map.spaces) do
            local x = 0
            if generation1[space1] then
                x = x + 1
            end
            for _, space2 in ipairs(Hex.adjacent(space1)) do
                if generation1[space2] then
                    x = x + 1
                end
            end
            generation2[space1] = x > 3
        end
        generation1 = generation2
    end
    local f = function (space)
        return generation1[space]
    end
    return List.filter(_state.map.spaces, f)
end

function generate_aux.get_drunk_path(src, valid_f, n)
    assert(n >= 2)
    local max = 1000
    local set = {}
    local j = 0
    local curr = src
    set[curr] = true
    j = j + 1
    for i = 1, max do
        local spaces = List.filter(Hex.adjacent(curr), valid_f)
        local space = spaces[rng(#spaces)]
        curr = space
        if not set[curr] then
            set[curr] = true
            j = j + 1
            if j >= n then
                break
            end
        end
    end
    
    local f = function (space)
        return set[space]
    end
    return List.filter(_state.map.spaces, f)
end

function generate_aux.get_border(spaces1)
    local dist = Path.dist(spaces1, nil, nil, 1)
    local f = function (space)
        return dist[space] == 1
    end
    return List.filter(_state.map.spaces, f)
end

function generate_aux.get_connection1(spaces1, spaces2)
    local pairs_of_spaces = {}
    for _, a in ipairs(spaces1) do
        for _, b in ipairs(spaces2) do
            if a.x == b.x or a.y == b.y or a.z == b.z then
                table.insert(pairs_of_spaces, { a, b })
            end
        end
    end
    if next(pairs_of_spaces) then
        local f = function (a, b)
            return Hex.dist(a[1], a[2]) < Hex.dist(b[1], b[2])
        end
        local pair_of_spaces = List.min(pairs_of_spaces, f)
        return Hex.line1(pair_of_spaces[1], pair_of_spaces[2])
    end
end

function generate_aux.get_connection2(spaces1, spaces2)
    local set = List.set(spaces2)
    local f1 = function (space)
        return set[space]
    end
    return Path.dijk(spaces1, f1)
end

function generate_aux.get_connections1(valid_f)
    local set = {}
    local f = function (space)
        return set[space] or valid_f(space)
    end
    local spaces = List.filter(_state.map.spaces, valid_f)
    assert(next(spaces))
    local src = spaces[rng(#spaces)]
    local curr = { src }
    while true do
        local dist = Path.dist(curr, f)
        curr = {}
        outside = {}
        for _, space in ipairs(_state.map.spaces) do
            if f(space) then
                if dist[space] < math.huge then
                    table.insert(curr, space)
                else
                    table.insert(outside, space)
                end
            end
        end
        if next(outside) then
            local path =
                generate_aux.get_connection1(curr, outside) or
                generate_aux.get_connection2(curr, outside)
            assert(path)
            for _, space in ipairs(path) do
                set[space] = true
            end
        else
            break
        end
    end
    local f = function (space)
        return set[space]
    end
    return List.filter(_state.map.spaces, f)
end

function generate_aux.get_distant_spaces(valid_f, dist_f)
    local spaces = List.filter(_state.map.spaces, valid_f)
    assert(next(spaces))
    local src = spaces[rng(#spaces)]
    local dist = Path.dist({ src }, valid_f, dist_f)
    local f = function (a, b)
        return dist[a] < dist[b]
    end
    local space1 = List.max(spaces, f)
    local dist = Path.dist({ space1 }, valid_f, dist_f)
    local f = function (a, b)
        return dist[a] < dist[b]
    end
    local space2 = List.max(spaces, f)
    return space1, space2
end

function generate_aux.get_connections2(valid_f, dist_f, n)
    n = n or 1
    local set = {}
    local f = function (space)
        return valid_f(space) or set[space]
    end
    for i = 1, n do
        local src, dst = generate_aux.get_distant_spaces(valid_f, dist_f)
        local dist_src = Path.dist({ src }, valid_f, dist_f, 2)
        local dist_dst = Path.dist({ dst }, valid_f, dist_f, 2)
        local area_src = List.filter(
            _state.map.spaces,
            function (space) return dist_src[space] < math.huge end
        )
        local area_dst = List.filter(
            _state.map.spaces,
            function (space) return dist_dst[space] < math.huge end
        )
        local path =
            generate_aux.get_connection1(area_src, area_dst) or
            generate_aux.get_connection2(area_src, area_dst)
        assert(path)
        for _, space in ipairs(path) do
            set[space] = true
        end
    end
    local f = function (space)
        return set[space]
    end
    return List.filter(_state.map.spaces, f)
end

function generate_aux.get_distant_space(space, valid_f, dist_f)
    local dist = Path.dist({ space }, valid_f, dist_f)
    local f1 = function (space)
        local d = dist[space]
        return 8 < d and d < math.huge
    end
    local spaces1 = List.filter(_state.map.spaces, f1)
    if next(spaces1) then
        return spaces1[game.rand1(#spaces1)]
    else
        local f2 = function (space)
            local d = dist[space]
            return 0 < d and d < math.huge
        end
        local spaces2 = List.filter(_state.map.spaces, f2)
        assert(next(spaces2))
        return spaces2[game.rand1(#spaces2)]
    end
end

function generate_aux.disjoint(spaces1, spaces2)
    local spaces1_s = List.set(spaces1)
    for _, space in ipairs(spaces2) do
        if spaces1_s[space] then
            return false
        end
    end
    return true
end

return generate_aux

