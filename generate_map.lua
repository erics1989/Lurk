
local generate_aux = require("generate_aux")

local function generate_area_pond()
    
end

local function generate_map_cave(prev, name, n)
    generate_aux.init(name, n)
    for _, space in ipairs(_state.map.spaces) do
        local terrain = game.data_init("terrain_stone")
        game.terrain_enter(terrain, space)
    end
    local area = generate_aux.get_blobs(
        function (space) return game.rand1(100) <= 60 end,
        1
    )
    for _, space in ipairs(area) do
        local terrain = game.data_init("terrain_dot")
        game.terrain_enter(terrain, space)
    end

    local area = generate_aux.get_blobs(
        function (space) return game.rand1(100) <= 40 end,
        4
    )
    for _, space in ipairs(area) do
        local terrain = game.data_init("terrain_water")
        game.terrain_enter(terrain, space)
    end

    local area = generate_aux.get_blobs(
        function (space) return game.rand1(100) <= 50 end,
        1
    )
    for _, space in ipairs(area) do
        if space.terrain.id == "terrain_dot" then
            local terrain = game.data_init("terrain_foliage")
            game.terrain_enter(terrain, space)
        end
    end



    -- post-processing
    local vf = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            space.terrain.id ~= "terrain_chasm"
    end
    local conn1 = generate_aux.get_connections1(vf)
    for _, space in ipairs(conn1) do
        if not vf(space) then
            local terrain = game.data_init("terrain_dot")
            game.terrain_enter(terrain, space)
        end
    end
    local conn2 = generate_aux.get_connections2(vf)
    for _, space in ipairs(conn2) do
        if not vf(space) then
            local terrain = game.data_init("terrain_dot")
            game.terrain_enter(terrain, space)
        end
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

local function generate_map_cave1(prev, name, n)
    generate_aux.init(name, n)
    for _, space in ipairs(_state.map.spaces) do
        local terrain = game.data_init("terrain_water")
        game.terrain_enter(terrain, space)
    end
    local area1 = generate_aux.get_blobs(
        function (space) return game.rand1(100) <= 55 end
    )
    for _, space in ipairs(area1) do
        local terrain = game.data_init("terrain_dot")
        game.terrain_enter(terrain, space)
    end
    local vf = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water
    end
    local conn1 = generate_aux.get_connections1(vf)
    for _, space in ipairs(conn1) do
        if space.terrain.id == "terrain_water" then
            local terrain = game.data_init("terrain_dot")
            game.terrain_enter(terrain, space)
        end
    end
    local conn2 = generate_aux.get_connections2(vf)
    for _, space in ipairs(conn2) do
        if space.terrain.id == "terrain_water" then
            local terrain = game.data_init("terrain_dot")
            game.terrain_enter(terrain, space)
        end
    end
end

local function generate_map(prev, name, n)
    generate_map_cave(prev, name, n)
end

return generate_map

