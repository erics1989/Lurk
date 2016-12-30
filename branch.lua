
-- branch data

_database = _database or {}

function get_dnstairs()
    local f = function (space)
        return space.terrain.id == "terrain_stairs_dn"
    end
    local spaces = List.filter(_state.map.spaces, f)
    print(pp(spaces))
    return spaces[1]
end

local function valid_f(space)
    return
        game.data(space.terrain).stand and
        not game.data(space.terrain).water and
        not game.data(space.terrain).chasm
end

local function dist_f(src, dst)
    return 1
end

local function get_distant_space(src)
    --[[
    local dist = Path.dist(
        { src },
        valid_f,
        dist_f
    )
    local f = function (space)
        local d = dist[space]
        return 8 < d and d < math.huge
    end
    local spaces = List.filter(_state.map.spaces, f)
    local dst = spaces[game.rand1(#spaces)]
    return dst
    ]]
    return _state.map.spaces[game.rand1(#_state.map.spaces)]
end

local function generate_map2(depth)
    if not _state.map.spaces then
        _state.map.spaces = {}
    end
    local prev_dnstairs = get_dnstairs()
    if not prev_dnstairs then
        print("no dnstairs")
        prev_dnstairs = { x = 10, y = 10 }
    end
    local up = { name = "branch_zero", depth = depth - 1 }
    local dn = { name = "branch_zero", depth = depth + 1 }
    _state.map = {}
    _state.map.spaces = {}
    _state.map.spaces2d = {}
    _state.map.visited = {}
    _state.map.events = {}
    _state.map.persons = {}
    _state.map.objects = {}
    game.spaces_init(BOARD_SIZE)
    while true do
        -- place dots
        automata(
            function (space)
                return game.rand1(100) <= 65
            end,
            function (space)
                local terrain = game.data_init("terrain_dot")
                game.terrain_enter(terrain, space)
            end,
            function (space)
                local terrain = game.data_init("terrain_stone")
                game.terrain_enter(terrain, space)
            end,
            2
        )

        --[[
        -- place water
        automata(
            function (space)
                return
                    space.terrain.id == "terrain_dot" and
                    game.rand1(100) <= 47.5
            end,
            function (space)
                local terrain =
                    game.rand1(100) <= 90 and
                    game.data_init("terrain_water") or
                    game.data_init("terrain_water2")
                game.terrain_enter(terrain, space)
            end,
            nil,
            8
        )
        ]]

        -- place chasms 
        automata(
            function (space)
                return
                    space.terrain.id == "terrain_dot" and
                    game.rand1(100) <= 47.5
            end,
            function (space)
                local terrain = game.data_init("terrain_chasm")
                terrain.dst = dn
                game.terrain_enter(terrain, space)
            end,
            nil,
            8
        )

        -- create connectedness (considering water)
        connect1(
            function (space)
                return
                    game.data(space.terrain).stand and
                    not game.data(space.terrain).water and
                    not game.data(space.terrain).chasm
            end,
            function (space)
                local terrain = game.data_init("terrain_dot")
                game.terrain_enter(terrain, space)
            end
        )

        -- create loops (considering water)
        connect2(
            function (space)
                return
                    game.data(space.terrain).stand and
                    not game.data(space.terrain).water and
                    not game.data(space.terrain).chasm
            end,
            function (space)
                local terrain = game.data_init("terrain_dot")
                game.terrain_enter(terrain, space)
            end,
            2
        )

        -- place foliage
        automata(
            function (space)
                return game.rand1(100) <= 50
            end,
            function (space)
                if space.terrain.id == "terrain_dot" then
                    local terrain = game.data_init("terrain_foliage")
                    game.terrain_enter(terrain, space)
                end
            end
        )

        -- place dense foliage
        automata(
            function (space)
                return game.rand1(100) <= 50
            end,
            function (space)
                if game.data(space.terrain).plant then
                    local terrain = game.data_init("terrain_dense_foliage")
                    game.terrain_enter(terrain, space)
                end
            end
        )

        -- place trees
        local f = function (space)
            return
                game.data(space.terrain).plant and
                game.rand1(100) <= 25
        end
        for _, space in ipairs(List.filter(_state.map.spaces, f)) do
            local terrain = game.data_init("terrain_tree")
            game.terrain_enter(terrain, space)
        end
        
        --[[
        -- standards check
        local f = function (space)
            return
                game.data(space.terrain).stand and
                not game.data(space.terrain).water
        end
        local spaces1 = List.filter(_state.map.spaces, f)
        local f = function (space)
            return game.data(space.terrain).water
        end
        local spaces2 = List.filter(_state.map.spaces, f)
        local spaces3 = _state.map.spaces
        if  0.40 <= #spaces1 / #_state.map.spaces and
            0.02 <= #spaces2 / #_state.map.spaces
        then
            break
        else
            print("standards check failed: regenerating map")
        end
        ]]
        break
    end

    -- place stairs
    local space = game.get_space(prev_dnstairs.x, prev_dnstairs.y)
    assert(space)
    local upstairs = game.nearest_space(space)
    assert(upstairs)
    local dnstairs = get_distant_space(upstairs)
    assert(dnstairs)

    -- place upstairs
    if depth == 1 then
        local terrain = game.data_init("terrain_stairs_up")
        terrain.dst = { name = "END", depth = 1 }
        game.terrain_enter(terrain, upstairs)
    else
        local terrain = game.data_init("terrain_stairs_up")
        terrain.dst = up
        game.terrain_enter(terrain, upstairs)
    end

    -- place dnstairs
    if depth == 4 then
        local object = game.data_init("object_orb")
        game.object_enter(object, dnstairs)
    else
        local terrain = game.data_init("terrain_stairs_dn")
        terrain.dst = dn
        game.terrain_enter(terrain, dnstairs)
    end

    -- place encounters (water)
    local f = function (space)
        return
            game.data(space.terrain).water and
            game.rand1(100) <= 10
    end
    for _, space in ipairs(List.filter(_state.map.spaces, f)) do
        local person = game.data_init("person_pirahna")
        game.person_enter(person, space)
    end

    -- place encounters
    local encounters = _database.branch_zero[depth].encounters
    for i = 1, _database.branch_zero[depth].encounter_count do
        local str = encounters[game.rand1(#encounters)]
        local encounter = _database[str]
        local spaces = List.filter(_state.map.spaces, encounter.valid)
        if spaces[1] then
            local space = spaces[game.rand1(#spaces)]
            encounter.init(space)
        end
    end

    -- place treasures
    local treasures = _database.branch_zero[depth].treasures
    for i = 1, 4 do
        local str = treasures[game.rand1(#treasures)]
        local spaces = List.filter(
            _state.map.spaces,
            function (space) 
                return
                    game.data(space.terrain).stand and
                    not game.data(space.terrain).water and
                    not space.dst and
                    not space.object
            end
        )
        local space = spaces[game.rand1(#spaces)]
        game.object_enter(game.data_init(str), space)
    end
end

_database.branch_zero = {
    [1] = {
        encounter_count = 4,
        encounters = {
            "encounter_person_ooze",
            "encounter_person_kobold_warrior",
            "encounter_person_kobold_piker",
        },
        treasures = {
            "object_sword",
            "object_axe",
            "object_spear",
            "object_hammer",
            "object_feather",
            "object_sprinting_shoes",
            "object_bear_totem",
            "object_fire_staff",
            "object_regeneration_charm",
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_charm_of_passage",
            "object_staff_of_distortion",
            "object_staff_of_suggestion",
        }
    },
    [2] = {
        encounter_count = 8,
        encounters = {
            "encounter_person_kobold_warrior",
            "encounter_person_kobold_piker",
            "encounter_person_kobold_archer"
        },
        treasures = {
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_staff_of_incineration",
            "object_charm_of_passage",
            "object_staff_of_distortion",
            "object_staff_of_suggestion",
        }
    },
    [3] = {
        encounter_count = 12,
        encounters = {
            "encounter_person_kobold_warrior",
            "encounter_person_kobold_piker",
            "encounter_person_kobold_archer",
            "encounter_person_ooze",
        },
        treasures = {
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_staff_of_incineration",
            "object_charm_of_passage",
            "object_staff_of_distortion",
            "object_staff_of_suggestion",
        }
    },
    [4] = {
        encounter_count = 16,
        encounters = {
            "encounter_person_kobold_warrior",
            "encounter_person_kobold_piker",
            "encounter_person_kobold_archer",
            "encounter_person_ooze",
            "encounter_person_bear",
        },
        treasures = {
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_potion_of_health",
            "object_potion_of_distortion",
            "object_potion_of_blindness",
            "object_potion_of_invisibility",
            "object_potion_of_incineration",
            "object_staff_of_incineration",
            "object_charm_of_passage",
            "object_staff_of_distortion",
            "object_staff_of_suggestion",
        }
    }
}

