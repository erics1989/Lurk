
-- object data

_database = _database or {}

_database.object_orb = {
    name = "The Seed of Despair",
    color = color_constants.red,
    character = "*",
    sprite = { file = "resource/sprite/Items.png", x = 16, y = 3 },
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    person_poststep = function (person, object, src)
        person.seed = true
    end
}

_database.object_shortsword = {
    name = "shortsword",
    color = color_constants.base3,
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 0 },
    character = ")",
    description =
        "A 2\' shortsword. Range: 1.\n" ..
        "• Lunge (when there's one space between you and an enemy and you step directly\n" ..
        "  towards him/her, you get a free attack)\n" ..
        "• Strafe (when you step between spaces adjacent to an enemy, you get a free\n" ..
        "  attack)"
    ,
    part = "hand", pickup = true,
    init = function (object)
        game.object_setup(object)
        object.enchant = 2
    end,
    person_poststep = function (person, object, src)
        if  game.person_object_equipped(person, object) and
            game.person_can_attack(person)
        then
            game.person_poststep_attack2(person, src)
            game.person_poststep_attack3(person, src)
        end
    end,
    attack = {
        range = function (person, object, space)
            return Hex.dist(person.space, space) == 1
        end,
        execute = function (person, object, space)
            local defender = space.person
            if defender then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s stab %s." or
                            "%s stabs %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    equip = {
        valid = function (person, object, space)
            return not game.person_object_equipped(person, object)
        end,
        execute = function (person, object, space)
            if game.person_object_equipped(person, object) then
                game.person_object_unequip(person, object)
            else
                game.person_object_equip(person, object)
            end
        end
    }

}

_database.object_machete = {
    name = "machete",
    color = { 255, 255, 255 }, character = ")",
    part = "hand", pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    attack = {
        range = function (person, object, space)
            return Hex.dist(person.space, space) == 1
        end,
        execute = function (person, object, space)
            local defender = space.person
            if defender then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s hack %s." or
                            "%s hacks %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    equip = {
        valid = function (person, object, space)
            return not game.person_object_equipped(person, object)
        end,
        execute = function (person, object, space)
            if game.person_object_equipped(person, object) then
                game.person_object_unequip(person, object)
            else
                game.person_object_equip(person, object)
            end
        end
    },
    person_poststep = function (person, object, src)
        if  game.person_object_equipped(person, object) and
            game.person_can_attack(person)
        then
            game.person_poststep_attack2(person, src)
        end
    end
}

_database.object_spear = {
    name = "spear",
    color = { 255, 255, 255 }, character = ")",
    part = "hand", pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    attack = {
        range = function (person, object, space)
            return Hex.dist(person.space, space) == 1
        end,
        execute = function (person, object, space)
            local defender = space.person
            if defender then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s skewer %s." or
                            "%s skewers %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    equip = {
        valid = function (person, object, space)
            return not game.person_object_equipped(person, object)              end,
        execute = function (person, object, space)
            if game.person_object_equipped(person, object) then
                game.person_object_unequip(person, object)
            else
                game.person_object_equip(person, object)
            end
        end
    },
    init = function (object)
    
    end,
    person_poststep = function (person, object, src)
        if  game.person_object_equipped(person, object) and
            game.person_can_attack(person)
        then
            game.person_poststep_attack3(person, src)
        end
    end
}

_database.object_shortbow = {
    name = "shortbow",
    color = { 255, 255, 255 }, character = ")",
    part = "hand", pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    attack = {
        range = function (person, object, space)
            local d = Hex.dist(person.space, space)
            return
                2 <= d and d <= 4 and
                Hex.axis(person.space, space) and
                not game.obstructed(
                    person.space,
                    space,
                    function (space)
                        return
                            game.data(space.terrain).stand and
                            (
                                not space.person or 
                                not person.sense[space.person] or
                                person == space.person
                            )
                    end
                )
        end,
        execute = function (person, object, space)
            space = game.obstructed(
                person.space, space, game.space_vacant
            ) or space
            local defender = space.person
            if defender then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s shoot an arrow at %s." or
                            "%s shoots an arrow at %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    equip = {
        valid = function (person, object, space)
            return not game.person_object_equipped(person, object)
        end,
        execute = function (person, object, space)
            if game.person_object_equipped(person, object) then
                game.person_object_unequip(person, object)
            else
                game.person_object_equip(person, object)
            end
        end
    },
}

_database.object_ring_of_stealth = {
    name = "ring of stealth",
    plural_name = "rings of stealth",
    color = color_constants.base3,
    sprite = { file = "resource/sprite/Items.png", x = 8, y = 11 },
    character = "o",
    description = "stealth = 2",
    part = "ring", pickup = true,
    init = function (object)
        game.object_setup(object)
        object.enchant = 2
    end,
    con = function (person, attacker, object)
        if game.person_object_equipped(person, object) then
            return 2
        end
    end,
    equip = {
        valid = function (person, object, space)
            return not game.person_object_equipped(person, object)
        end,
        execute = function (person, object, space)
            if game.person_object_equipped(person, object) then
                game.person_object_unequip(person, object)
            else
                game.person_object_equip(person, object)
            end
        end
    }
}

_database.object_ring_of_clairvoyance = {
    name = "ring of clairvoyance",
    plural_name = "rings of clairvoyance",
    color = color_constants.base3,
    sprite = { file = "resource/sprite/Items.png", x = 8, y = 11 },
    character = "o", pickup = true,
    description = "stealth = 2",
    part = "ring",
    init = function (object)
        game.object_setup(object)
        object.enchant = 2
    end,
    person_space_sense2 = function (person, object, space)
        if game.person_object_equipped(person, object) then
            return Hex.dist(person.space, space) <= 2
        end
    end,
    equip = {
        valid = function (person, object, space)
            return not game.person_object_equipped(person, object)
        end,
        execute = function (person, object, space)
            if game.person_object_equipped(person, object) then
                game.person_object_unequip(person, object)
            else
                game.person_object_equip(person, object)
            end
        end
    }
}

_database.object_staff_of_incineration = {
    name = "staff of incineration",
    color = { 255, 255, 255 },
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 1 },
    character = "/",
    description = "Upon use, the user shoots a firebolt, which damages the target and sets plants on fire. Recharges in 8 turns.",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end,
    person_postact = function (person, object)
        local status = object.status_charging
        if status then
            game.object_status_decrement(object, status)
        end
    end,
    use = {
        valid = function (person, object)
            return not object.status_charging
        end,
        range = function (person, object, space)
            return game.person_space_proj(person, space)
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.object_discharge(object, 8)
            local space = game.person_space_proj_obstruction(person, space)
            local defender = space.person
            if defender then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s incinerate %s." or
                            "%s incinerates %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
            if game.data(space.terrain).burn then
                game.terrain_exit(space.terrain)
                game.terrain_enter(game.data_init("terrain_fire"), space)
            end
        end
    }
}

_database.object_staff_of_distortion = {
    name = "staff of distortion",
    color = { 255, 255, 255 },
    character = "/",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 1 },
    description = "Upon use, the user shoots a splash of unstable energies, which teleports the target to a random space. Recharges in 8 turns.",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end,
    person_postact = function (person, object)
        local status = object.status_charging
        if status then
            game.object_status_decrement(object, status)
        end
    end,
    use = {
        valid = function (person, object)
            return not object.status_charging
        end,
        range = function (person, object, space)
            return game.person_space_proj(person, space)
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.object_discharge(object, 8)
            local space = game.person_space_proj_obstruction(person, space)
            local defender = space.person
            if defender then
                game.person_teleport(defender)
            end
        end
    }
}

_database.object_staff_of_suggestion = {
    name = "staff of suggestion",
    color = { 255, 255, 255 },
    character = "/",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 1 },
    description = "Upon use, the user sends a suggestion, which causes the target to act as an ally for one turn. Recharges in 8 turns.",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end,
    person_postact = function (person, object)
        local status = object.status_charging
        if status then
            game.object_status_decrement(object, status)
        end
    end,
    use = {
        valid = function (person, object)
            return not object.status_charging
        end,
        range = function (person, object, space)
            return game.person_space_proj(person, space)
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.object_discharge(object, 8)
            local space = game.person_space_proj_obstruction(person, space)
            local defender = space.person
            if defender then
                local status = game.data_init("status_charmed")
                status.charmer = person
                status.counters = 1
                game.person_status_enter(defender, status)
            end
        end
    }
}

_database.object_staff_of_substitution = {
    name = "staff of substitution",
    color = { 255, 255, 255 },
    character = "/",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 1 },
    description = "change places",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end,
    person_postact = function (person, object)
        local status = object.status_charging
        if status then
            game.object_status_decrement(object, status)
        end
    end,
    use = {
        valid = function (person, object)
            return not object.status_charging
        end,
        range = function (person, object, space)
            return game.person_space_proj(person, space)
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.object_discharge(object, 8)
            local space = game.person_space_proj_obstruction(person, space)
            local defender = space.person
            if defender then
                game.person_transpose(person, defender)
            end
        end
    }
}

_database.object_charm_of_passage = {
    name = "charm of passage",
    color = { 255, 255, 255 },
    character = "~",
    sprite = { file = "resource/sprite/Items.png", x = 15, y = 3 },
    description = "Upon use, the user teleports to a space of his/her choice, up to 4 spaces away. Recharges in 8 turns.",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end,
    person_postact = function (person, object)
        local status = object.status_charging
        if status then
            game.object_status_decrement(object, status)
        end
    end,
    use = {
        valid = function (person, object)
            return not object.status_charging
        end,
        range = function (person, object, space)
            local d = Hex.dist(person.space, space)
            return
                d <= 4 and
                game.data(space.terrain).stand and
                space.person == nil
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.object_discharge(object, 8)
            game.person_relocate(person, space)
        end
    }
}

_database.object_charm_of_verdure = {
    name = "charm of verdure",
    color = { 255, 255, 255 },
    character = "~",
    sprite = { file = "resource/sprite/Items.png", x = 15, y = 3 },
    description = "Lots of trees.",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end,
    person_postact = function (person, object)
        local status = object.status_charging
        if status then
            game.object_status_decrement(object, status)
        end
    end,
    use = {
        valid = function (person, object)
            return not object.status_charging
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.object_discharge(object, 8)
            local f = function (space)
                return
                    Hex.dist(person.space, space) <= 2 and
                    game.data(space.terrain).stand and
                    not game.data(space.terrain).water
            end
            local spaces = List.filter(_state.spaces, f)
            for _, space in ipairs(spaces) do
                game.terrain_exit(space.terrain)
                local terrain = game.data_init("terrain_tree")
                game.terrain_enter(terrain, space)
            end
        end
    }
}

_database.object_potion_of_health = {
    name = "potion of health",
    plural_name = "potions of health",
    color = { 255, 255, 255 },
    character = "!",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 3 },
    description = "An herbal tonic. Upon use, the user recovers 4 hearts.",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    use = {
        valid = function (person, object)
            return true
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                game.person_damage(defender, -4)
            end
        end
    },
    throw = {
        valid = function (person, object)
            return not person.restricted
        end,
        range = function (person, object, space)
            return Hex.dist(person.space, space) <= 4
        end,
        execute = function (person, object, space)
            game.person_object_throw(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                game.person_damage(defender, -16)
            end        
        end
    }
}

_database.object_potion_of_distortion = {
    name = "potion of distortion",
    plural_name = "potions of distortion",
    description = "A potion of unstable energies. Upon use, the user teleports to a random space.",
    color = { 255, 255, 255 }, character = "!",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 3 },
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    use = {
        valid = function (person, object)
            return true
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                game.person_teleport(defender)
            end        
        end
    },
    throw = {
        valid = function (person, object)
            return not person.restricted
        end,
        range = function (person, object, space)
            return Hex.dist(person.space, space) <= 4
        end,
        execute = function (person, object, space)
            game.person_object_throw(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                game.person_teleport(defender)
            end        
        end
    }
}

_database.object_potion_of_blindness = {
    name = "potion of blindness",
    plural_name = "potions of blindness",
    description = "A potion of cursed dust. Upon use, the user goes blind.",
    color = { 255, 255, 255 },
    character = "!",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 3 },
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    use = {
        valid = function (person, object)
            return true
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                local status = game.data_init("status_blind")
                status.counters = 16
                game.person_status_enter(defender, status)
            end
        end
    },
    throw = {
        valid = function (person, object)
            return true
        end,
        range = function (person, object, space)
            return Hex.dist(person.space, space) <= 4
        end,
        execute = function (person, object, space)
            game.person_object_throw(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                local status = game.data_init("status_blind")
                status.counters = 16
                game.person_status_enter(defender, status)
            end
        end
    }
}

_database.object_potion_of_invisibility = {
    name = "potion of invisibility",
    plural_name = "potions of invisibility",
    description = "A potion of clear, viscous fluid. Upon use, the user vanishes from the visible world for 16 turns.",
    color = { 255, 255, 255 },
    character = "!",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 3 },
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,

    use = {
        valid = function (person, object)
            return true
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                local status = game.data_init("status_invisible")
                status.counters = 16
                game.person_status_enter(defender, status)
            end
        end
    },
    throw = {
        valid = function (person, object)
            return true
        end,
        range = function (person, object, space)
            return Hex.dist(person.space, space) <= 4
        end,
        execute = function (person, object, space)
            game.person_object_throw(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                local status = game.data_init("status_invisible")
                status.counters = 16
                game.person_status_enter(defender, status)
            end
        end
    }
}

_database.object_potion_of_incineration = {
    name = "potion of incineration",
    plural_name = "potions of incineration",
    description = "A flask of dancing sparks. Upon use, the user starts a fire.",
    color = { 255, 255, 255 },
    character = "!",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 3 },
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    use = {
        valid = function (person, object)
            return true
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                if game.person_sense(_state.hero, defender) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s burn." or
                            "%s burns.",
                        grammar.cap(grammar.the(game.data(person).name))
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
            if game.data(space.terrain).burn then
                game.terrain_exit(space.terrain)
                local fire = game.data_init("terrain_fire")
                game.terrain_enter(fire, space)
            end
        end
    },
    throw = {
        valid = function (person, object)
            return true
        end,
        range = function (person, object, space)
            return Hex.dist(person.space, space) <= 4
        end,
        execute = function (person, object, space)
            game.person_object_throw(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                if game.person_sense(_state.hero, defender) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s burn." or
                            "%s burns.",
                        grammar.cap(grammar.the(game.data(person).name))
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
            if game.data(space.terrain).burn then
                game.terrain_exit(space.terrain)
                local fire = game.data_init("terrain_fire")
                game.terrain_enter(fire, space)
            end
        end
    }
}

_database.object_potion_of_domination = {
    name = "potion of domination",
    plural_name = "potions of domination",
    color = { 255, 255, 255 },
    character = "!",
    sprite = { file = "resource/sprite/Items.png", x = 0, y = 3 },
    description = "Upon use, the user joins your party.",
    pickup = true,
    init = function (object)
        game.object_setup(object)
    end,
    use = {
        valid = function (person, object)
            return true
        end,
        execute = function (person, object, space)
            game.person_object_use(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                local status = game.data_init("status_charmed")
                status.charmer = person
                game.person_status_enter(defender, status)
            end
        end
    },
    throw = {
        valid = function (person, object)
            return true
        end,
        range = function (person, object, space)
            return Hex.dist(person.space, space) <= 4
        end,
        execute = function (person, object, space)
            game.person_object_throw(person, object)
            game.person_object_exit(person, object)
            local defender = space.person
            if defender then
                local status = game.data_init("status_charmed")
                status.charmer = person
                game.person_status_enter(defender, status)
            end    
        end
    }
}

_database.object_bones = {
    name = "a pile of bones",
    plural_name = "piles of bones",
    color = { 255, 255, 255 },
    character = "%",
    sprite = { file = "resource/sprite/Terrain_Objects.png", x = 1, y = 4 },
    description = "bones",
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end
}

_database.object_blood = {
    name = "a puddle of blood",
    plural_name = "puddles of blood",
    color = color_constants.red,
    character = "%",
    sprite = { file = "resource/sprite/FX_Blood.png", x = 9, y = 0 },
    description = "blood",
    init = function (object)
        game.object_setup(object)
    end,
    act = function (object)
        game.object_act(object)
    end
}

