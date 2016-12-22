
local prev1 = { name = "dungeon", n = 0 }
local door1 = {
    id = "terrain_stairs_dn",
    space = { x = 12, y = 12 }
}

local function get_spaces(ax, ay, az, bx, by, bz)
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

local function get_distant_space(space, valid_f, dist_f)
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
        if next(spaces2) then
            return spaces2[game.rand1(#spaces2)]
        end
    end
end

local function get_dnstairs(map)
    local f = function (space)
        return space.terrain.id == "terrain_stairs_dn"
    end
    return List.filter(map.spaces, f)
end

local function init_map(name, n, size)
    size = size or BOARD_SIZE
    local map = {}
    map.name = name
    map.n = n
    map.spaces = {}
    map.spaces2d = {}
    local center = { x = size, y = size, z = 0 - size - size }
    for x = 1, 2 * size - 1 do
        map.spaces2d[x] = {}
        for y = 1, 2 * size - 1 do
            local space = { x = x, y = y, z = 0 - x - y }
            if Hex.dist(center, space) < size then
                table.insert(map.spaces, space)
                map.spaces2d[x][y] = space
            end
        end
    end
    map.visited = {}
    map.events = {}
    map.persons = {}
    map.objects = {}
    return map
end

local function prefab_entrance1()
    local space = game.get_space(9, 17)
    local terrain = game.data_init("terrain_dot")
    game.terrain_enter(terrain, space)
    return space
end

local function paint(id, space)
    game.terrain_enter(game.data_init(id), space)
end

local function prefab_upstairs(space1, prev)
    for _, space2 in ipairs(Hex.adjacent(space1)) do
        local terrain = game.data_init("terrain_dot")
        game.terrain_enter(terrain, space2)
    end
    local terrain = game.data_init("terrain_stairs_up")
    terrain.door = { name = prev.name, n = prev.n }
    game.terrain_enter(terrain, space1)
end

local function generate_map_cave(prev, name, n)
    _state.map = init_map(name, n)
    while true do
        for _, space in ipairs(_state.map.spaces) do
            local terrain = game.data_init("terrain_stone")
            game.terrain_enter(terrain, space)
        end

        local upstairs
        if prev then
            local dnstairs = get_dnstairs(prev)[1]
            assert(dnstairs)
            upstairs = game.get_space(dnstairs.x, dnstairs.y)
            prefab_upstairs(upstairs, prev)
        else
            upstairs = prefab_entrance1()
        end

        local dnstairs = get_distant_space(
            upstairs,
            glue.true_f,
            function () return 1 end
        )
        assert(dnstairs)
        local terrain = game.data_init("terrain_stairs_dn")
        terrain.door = { name = _state.map.name, n = _state.map.n + 1 }
        game.terrain_enter(terrain, dnstairs)

        -- dots
        local f1 = function (space)
            return
                space.terrain.id ~= "terrain_stone"
                or game.rand1(100) <= 65
        end
        local f2 = function (space)
            if space.terrain.id == "terrain_stone" then
                local terrain = game.data_init("terrain_dot")
                game.terrain_enter(terrain, space)
            end
        end
        automata(f1, f2, nil, 2)

        -- chasms
        local f1 = function (space)
            return game.rand1(100) <= 50
        end
        local f2 = function (space)
            if space.terrain.id == "terrain_dot" then
                local terrain = game.data_init("terrain_chasm")
                terrain.door = { name = name, n = n + 1 }
                game.terrain_enter(terrain, space)
            end
        end
        automata(f1, f2, nil, 2)

        -- connect
        local f1 = function (space)
            return
                game.data(space.terrain).stand and
                space.terrain.id ~= "terrain_chasm"
        end
        local f2 = function (space)
            local terrain = game.data_init("terrain_dot")
            game.terrain_enter(terrain, space)
        end
        connect1(f1, f2)
        break
    end

    -- place encounters
    local encounters = _database.branch_zero[n].encounters
    for i = 1, _database.branch_zero[n].encounter_count do
        local str = encounters[game.rand1(#encounters)]
        local encounter = _database[str]
        local spaces = List.filter(_state.map.spaces, encounter.valid)
        if spaces[1] then
            local space = spaces[game.rand1(#spaces)]
            encounter.init(space)
        end
    end

end

local function generate_map(prev, name, n)
    generate_map_cave(prev, name, n)
end

return generate_map

