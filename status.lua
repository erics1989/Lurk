
-- status data

_database = _database or {}

_database.status_stunned = {
    name = "stunned",
    character = "-",
    person_status_enter = function (person, status)
        person.status_stunned = status
    end,
    person_status_exit = function (person, status)
        person.status_stunned = nil
    end,
    person_postact = function (person, status)
        game.person_status_decrement(person, status)
    end
}

_database.status_charmed = {
    name = "charmed",
    character = "-",
    person_status_enter = function (person, status)
        if game.person_sense(_state.hero, person) then
            local str = string.format(
                game.data(person).plural and
                    "%s are charmed." or
                    "%s is charmed.",
                grammar.cap(grammar.the(game.data(person).name))
            )
            game.print(str)
        end
        List.delete(person.friends, person)
        status.prev_faction = person.faction
        status.prev_friends = person.friends
        game.person_add_friend(status.charmer, person)
        person.status_charmed = status
    end,
    person_status_exit = function (person, status)
        if game.person_sense(_state.hero, person) then
            local str = string.format(
                game.data(person).plural and
                    "%s are no longer charmed." or
                    "%s is no longer charmed.",
                grammar.cap(grammar.the(game.data(person).name))
            )
            game.print(str)
        end
        List.delete(person.friends, person)
        person.faction = status.prev_faction
        person.friends = status.prev_friends
        table.insert(person.friends, person)
        person.status_charmed = nil
    end,
    person_postact = function (person, status)
        if status.counters then
            game.person_status_decrement(person, status)
        end
    end
}

_database.status_blind = {
    name = "blind",
    character = "-",
    init = function (status) end,
    person_status_enter = function (person, status)
        if game.person_sense(_state.hero, person) then
            local str = string.format(
                game.data(person).plural and
                    "%s are blind." or
                    "%s is blind.",
                grammar.cap(grammar.the(game.data(person).name))
            )
            game.print(str)
        end
    end,
    person_space_sense1 = function (person, status, space)
        return false
    end,
    person_postact = function (person, status)
        game.person_status_decrement(person, status)
    end
}

_database.status_acute_senses = {
    name = "acute senses",
    character = "+",
    per_addend = function (attacker, defender, decoration)
        return 2
    end,
}

_database.status_invisible = {
    name = "invisible",
    character = "+",
    sprite = { file = "resource/sprite/Items.png", x = 9, y = 8 },
    init = function (status) end,
    person_status_enter = function (person, status)
        if game.person_sense(_state.hero, person) then
            local str = string.format(
                game.data(person).plural and
                    "%s are invisible." or
                    "%s is invisible.",
                grammar.cap(grammar.the(game.data(person).name))
            )
            game.print(str)
        end
    end,
    person_status_exit = function (person, status)
        if game.person_sense(_state.hero, person) then
            local str = string.format(
                game.data(person).plural and
                    "%s are no longer invisible." or
                    "%s is no longer invisible.",
                grammar.cap(grammar.the(game.data(person).name))
            )
            game.print(str)
        end
    end,
    con = function (person, attacker, status)
        return 1
    end,
    person_postact = function (person, status)
        game.person_status_decrement(person, status)
    end
}

_database.status_cover_foliage = {
    name = "cover (dense foliage)",
    character = ";",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 1, y = 10 },
    init = function (status) end,
    person_status_enter = function (person, status)
        person.status_cover_foliage = status
    end,
    object_status_enter = function (object, status)
        object.status_cover_foliage = status
    end,
    con = function (person, attacker, status)
        return 3
    end,
    person_postact = function (person, status)
        if person.space.terrain.id ~= "terrain_dense_foliage" then
            game.person_status_exit(person, status)
        end
    end,
    person_status_exit = function (person, status)
        person.status_cover_foliage = nil
    end,
    object_status_exit = function (object, status)
        object.status_cover_foliage = nil
    end
}

_database.status_cover_tree = {
    name = "cover (tree)",
    character = "&",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 3, y = 10 },
    init = function (status) end,
    person_status_enter = function (person, status)
        person.status_cover_tree = status
    end,
    object_status_enter = function (object, status)
        object.status_cover_tree = status
    end,
    con = function (person, attacker, status)
        return 2
    end,
    person_postact = function (person, status)
        if person.space.terrain.id ~= "terrain_tree" then
            game.person_status_exit(person, status)
        end
    end,
    person_status_exit = function (person, status)
        person.status_cover_tree = nil
    end,
    object_status_exit = function (object, status)
        object.status_cover_tree = nil
    end
}

_database.status_underwater = {
    name = "underwater",
    character = "~",
    sprite = { file = "resource/sprite/FX_General.png", x = 13, y = 2 },
    init = function (status) end,
    person_status_enter = function (person, status)
        --[[
        if game.person_sense(_state.hero, person) then
            local str = string.format(
                game.data(person).plural and
                    "%s are underwater." or
                    "%s is underwater.",
                grammar.cap(grammar.the(game.data(person).name))
            )
            game.print(str)
        end
        ]]--
        person.status_underwater = status
    end,
    object_status_enter = function (object, status)
        --[[
        if game.person_sense(_state.hero, object) then
            local str = string.format(
                game.data(object).plural and
                    "%s are underwater." or
                    "%s is underwater.",
                grammar.cap(grammar.the(game.data(object).name))
            )
            game.print(str)
        end
        ]]--
        object.status_underwater = status
    end,
    person_space_sense1 = function (person, status, space)
        local f = function (space)
            return game.data(space.terrain).water
        end
        return not game.obstructed(person.space, space, f)
    end,
    con = function (person, attacker, status)
        return attacker.status_underwater and 20 or 1
    end,
    person_postact = function (person, status)
        if game.data(person.space.terrain).water == nil then
            game.person_status_exit(person, status)
        end
    end,
    person_status_exit = function (person, status)
        person.status_underwater = nil
    end,
    object_status_exit = function (object, status)
        object.status_underwater = nil
    end
}

_database.status_charging = {
    name = "charging",
    object_status_enter = function (object, status)
        object.status_charging = status
    end,
    object_status_exit = function (object, status)
        object.status_charging = nil
    end,
    object_postact = function (object, status)
        game.object_status_decrement(object, status)
    end
}

_database.status_regenerating = {
    name = "regenerating",
    object_status_enter = function (object, status)
        object.status_regenerating = status
    end,
    object_status_exit = function (object, status)  
        object.status_regenerating = nil
        local space = object.space
        game.object_exit(object)
        local person = game.data_init(status.person_id)
        game.person_enter(person, space)
    end,
    object_postact = function (object, status)
        if not object.space.person then
            game.object_status_decrement(object, status)
        end
    end
}

