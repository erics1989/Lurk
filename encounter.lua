
-- encounter data

_database = _database or {}

_database.encounter_person_kobold_warrior = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_kobold_warrior")
        game.person_enter(person, space)
    end
}

_database.encounter_person_kobold_piker = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_kobold_piker")
        game.person_enter(person, space)
    end
}

_database.encounter_person_kobold_archer = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_kobold_archer")
        game.person_enter(person, space)
    end
}

_database.encounter_person_skeleton_warrior = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_skeleton_warrior")
        game.person_enter(person, space)
    end
}

_database.encounter_person_ooze = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_ooze")
        game.person_enter(person, space)
    end
}

_database.encounter_person_dhole = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_dhole")
        game.person_enter(person, space)
    end
}

_database.encounter_person_bear = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            not game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_bear")
        game.person_enter(person, space)
    end
}

_database.encounter_person_pirahna = {
    valid = function (space)
        return
            game.data(space.terrain).stand and
            game.data(space.terrain).water and
            not space.dst and
            not space.person
    end,
    init = function (space)
        local person = game.data_init("person_pirahna")
        game.person_enter(person, space)
    end
}


