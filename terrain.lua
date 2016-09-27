
-- terrain data

_database = _database or {}

_database.terrain_dot = {
    name = "dirt",
    bcolor = color_constants.base03,
    color = { 88, 110, 117 },
    character = ".",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 8, y = 0 },
    sense = true,
    stand = true
}

_database.terrain_foliage = {
    name = "foliage",
    bcolor = color_constants.base03,
    color = { 133, 153, 0 },
    character = ",",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 0, y = 10 },
    sense = true, stand = true, burn = true, plant = true,
}

_database.terrain_dense_foliage = {
    name = "dense foliage",
    bcolor = color_constants.base03,
    color = { 133, 153, 0 },
    character = ";",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 1, y = 10 },
    sense = true, stand = true, burn = true, plant = true,
    person_terrain_postact = function (person, terrain)
        if not person.status_cover_foliage then
            local status = game.data_init("status_cover_foliage")
            game.person_status_enter(person, status)
        end
    end,
    object_terrain_postact = function (object, terrain)
        if not object.status_cover_foliage then
            local status = game.data_init("status_cover_foliage")
            game.object_status_enter(object, status)
        end
    end
}

_database.terrain_tree = {
    name = "tree",
    bcolor = color_constants.base03,
    color = { 133, 153, 0 },
    character = "&",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 3, y = 10 },
    stand = true, burn = true, plant = true,
    person_terrain_postact = function (person, terrain)
        if not person.status_cover_tree then
            local status = game.data_init("status_cover_tree")
            game.person_status_enter(person, status)
        end
    end,
    object_terrain_postact = function (object, terrain)
        if not object.status_cover_tree then
            local status = game.data_init("status_cover_tree")
            game.object_status_enter(object, status)
        end
    end
}


_database.terrain_fire = {
    name = "fire",
    bcolor = color_constants.base03,
    color = { 203, 75, 22 },
    character = "^",
    sprite = { file = "resource/sprite/FX_General.png", x = 12, y = 1 },
    sprite2 = { file = "resource/sprite/FX_General.png", x = 13, y = 1 },
    sense = true, stand = true, fire = true,
    init = function (terrain)
        terrain.counters = 8
    end,
    act = function (terrain)
        if _state.turn % 2 == 0 then
            local f = function (space)
                return game.data(space.terrain).burn
            end
            spaces = List.filter(f, Hex.adjacent(terrain.space))
            for _, space in ipairs(spaces) do
                game.terrain_exit(space.terrain)
                game.terrain_enter(
                    game.data_init("terrain_fire"),
                    space
                )
            end
        end
        terrain.counters = terrain.counters - 1
        if terrain.counters == 0 then
            local space = terrain.space
            game.terrain_exit(terrain)
            game.terrain_enter(
                game.data_init("terrain_dot"),
                space
            )
        else
            table.insert(_state.events, terrain)
        end
    end,
    person_terrain_postact = function (person, terrain)
        if game.person_sense(_state.hero, person) then
            local str = string.format(
                game.data(person).plural and
                    "%s burn." or
                    "%s burns.",
                grammar.cap(grammar.the(game.data(person).name))
            )
            game.print(str)
        end
        game.person_damage(person, 1)
    end
}

_database.terrain_water = {
    name = "water",
    bcolor = color_constants.blue,
    color = { 88, 110, 117 },
    character = "~",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 8, y = 0 },
    sense = true, stand = true, water = true,
    person_terrain_postact = function (person, terrain)
        if not person.status_underwater then
            local status = game.data_init("status_underwater")
            game.person_status_enter(person, status)
        end
    end,
    object_terrain_postact = function (object, terrain)
        if not object.status_underwater then
            local status = game.data_init("status_underwater")
            game.object_status_enter(object, status)
        end
    end
}

_database.terrain_water2 = {
    name = "water",
    bcolor = color_constants.blue,
    color = color_constants.green,
    character = "~",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 0, y = 11 },
    sprite2 = { file = "resource/sprite/Terrain_Objects.png", x = 1, y = 11 },
    sense = true, stand = true, water = true,
    person_terrain_postact = function (person, terrain)
        if not person.status_underwater then
            local status = game.data_init("status_underwater")
            game.person_status_enter(person, status)
        end
    end,
    object_terrain_postact = function (object, terrain)
        if not object.status_underwater then
            local status = game.data_init("status_underwater")
            game.object_status_enter(object, status)
        end
    end
}

_database.terrain_stone = {
    name = "stone",
    bcolor = { 131, 148, 150 },
    color = { 88, 110, 117 },
    character = "#",
    sprite = { file = "resource/sprite/Terrain.png", x = 12, y = 0 },
}

_database.terrain_stairs_up = {
    name = "stairs",
    bcolor = { 0, 43, 54 },
    color = { 255, 255, 255 },
    character = "<",
    sprite = { file = "resource/sprite/Terrain.png", x = 15, y = 1 },
    sense = true,
    stand = true
}

_database.terrain_stairs_dn = {
    name = "stairs",
    bcolor = { 0, 43, 54 },
    color = { 255, 255, 255 },
    character = ">",
    sprite = { file = "resource/sprite/Terrain.png", x = 14, y = 1 },
    sense = true,
    stand = true
}

