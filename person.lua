
-- person data

_database = _database or {}

_database.hero = {
    name = "you",
    plural = true,
    color = { 255, 255, 255 },
    character = "@",
    sprite = { file = "resource/sprite/Avatar.png", x = 1, y = 0 },
    sprite2 = { file = "resource/sprite/Avatar.png", x = 1, y = 1 },
    init = function (person)
        game.person_setup(person)
        person.faction = "hero"
        person.hp = 4
        local object = game.data_init("object_shortsword")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)
        local object = game.data_init("object_ring_of_clairvoyance")
        game.person_object_enter(person, object)

    end,
    act = function (person)
        
    end,
    person_die = function (person)
        local object = game.data_init("object_blood")
        game.object_enter(object, person.space)
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
                            "%s punch %s." or
                            "%s punches %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    }
}

_database.person_kobold_warrior = {
    name = "kobold warrior",
    description = "A kobold w/ a machete. When it steps between spaces adjacent to an enemy, it gets a free attack.",
    color = { 255, 255, 255 },
    character = "w",
    sprite = { file = "resource/sprite/Monsters.png", x = 5, y = 10 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 5, y = 11 },
    init = function (person)
        game.person_setup(person)
        person.hp = 1
        person.perception = 9
        person.conspic = 9
        local object = game.data_init("object_machete")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)
        person.dsts = {}
    end,
    threaten = function (person, space)
        return Hex.dist(person.space, space) <= 1
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water
            then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[src.person]
            then
                cost = cost + dst.person.here
            end

            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local spaceF = function (space)
                for _, defender in ipairs(defenders) do
                    if Hex.dist(space, defender.space) == 1 then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { spaceF }) or
                game.person_preferred_action_step(person, { spaceF }, cost_f)
            then
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            return
        end
        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) or
            game.person_rest(person)
        then
            return
        end
    end
}

_database.person_kobold_piker = {
    name = "kobold piker",
    description = "A kobold w/ a spear. When there's one space between it and an enemy and it steps directly towards the enemy, it gets a free attack.",
    color = { 255, 255, 255 },
    character = "p",
    sprite = { file = "resource/sprite/Monsters.png", x = 8, y = 10 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 8, y = 11 },
    init = function (person)
        game.person_setup(person)
        local object = game.data_init("object_spear")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)
        person.dsts = {}
    end,
    threaten = function (person, space)
        return
            Hex.dist(person.space, space) <= 1 or
            (
                Hex.dist(person.space, space) == 2 and
                Hex.axis(person.space, space) and
                not game.obstructed(
                    person.space,
                    space,
                    function (space)
                        return
                            game.data(space.terrain).stand and
                            not space.person
                    end
                )
            )
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water
            then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[src.person]
            then
                cost = cost + dst.person.here
            end

            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local f1 = function (space)
                for _, defender in ipairs(defenders) do
                    if  Hex.dist(space, defender.space) == 2 and
                        Hex.axis(space, defender.space) and
                        not game.obstructed(
                            space,
                            defender.space,
                            function (space)
                                return
                                    game.data(space.terrain).stand and
                                    not game.data(space.terrain).water and
                                    (
                                        not space.person or
                                        not person.sense[space.person] or
                                        person == space.person
                                    )
                            end
                        )
                    then
                        return function ()
                            local dx = defender.space.x - person.space.x
                            local dy = defender.space.y - person.space.y
                            return game.person_step(
                                person,
                                game.get_space(
                                    person.space.x + dx / 2,
                                    person.space.y + dy / 2
                                )
                            )
                        end
                    end
                end
            end
            local f2 = function (space)
                for _, defender in ipairs(defenders) do
                    if Hex.dist(space, defender.space) == 1 then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { f1, f2 }) or
                game.person_preferred_action_step(person, { f1, f2 }, cost_f)
            then
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            return
        end
        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) or
            game.person_rest(person)
        then
            return
        end
    end
}

_database.person_skeleton_warrior = {
    name = "skeleton",
    description = "a skeleton",
    color = { 255, 255, 255 },
    character = "s",
    sprite = { file = "resource/sprite/Monsters.png", x = 1, y = 12 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 1, y = 13 },
    init = function (person)
        game.person_setup(person)
        local object = game.data_init("object_machete")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)
        person.dsts = {}
    end,
    threaten = function (person, space)
        return Hex.dist(person.space, space) <= 1
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water
            then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[src.person]
            then
                cost = cost + dst.person.here
            end
            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local spaceF = function (space)
                for _, defender in ipairs(defenders) do
                    if Hex.dist(space, defender.space) == 1 then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { spaceF }) then
                print("preferred_action")
                return
            end
            if game.person_preferred_action_step(person, { spaceF }, cost_f) then
                print("preferred_action_step")
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            print("step_to_friend")
            return
        end

        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) then
            print("step_to_dsts")
            return

        elseif game.person_step_to_preferred_terrain(person, cost_f) then
            print("step_to_preferred_terrain")
            return

        elseif game.person_rest(person) then
            print("rest")
            return
        end
    end,
    person_die = function (person)
        local object = game.data_init("object_bones")
        local status = game.data_init("status_regenerating")
        status.person_id = "person_skeleton_warrior"
        status.counters = 8
        game.object_status_enter(object, status)
        game.object_enter(object, person.space)
    end
}

_database.person_ooze = {
    name = "ooze",
    description = "An ooze. Upon getting hit, it splits into two.",
    color = { 255, 255, 255 },
    character = "o",
    sprite = { file = "resource/sprite/Monsters.png", x = 2, y = 18 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 2, y = 19 },
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
                            "%s attack %s." or
                            "%s attacks %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        person.size = 2
        person.dsts = {}
    end,
    threaten = function (person, space)
        return Hex.dist(person.space, space) <= 1
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        if _state.turn % 2 == 1 then
            return game.person_rest(person)
        end
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water
            then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + 2*dst.person.here
            end
            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local f = function (space)
                for _, defender in ipairs(defenders) do
                    if Hex.dist(space, defender.space) == 1 then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { f }) or
                game.person_preferred_action_step(person, { f }, cost_f)
            then
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            return
        end
        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) or
            game.person_rest(person)
        then
            return
        end
    end,
    person_die = function (person)
        if 2 <= person.size then
            if game.person_sense(_state.hero, person) then
                local str = string.format(
                    game.data(person).plural and
                        "%s split in half." or
                        "%s splits in half.",
                    grammar.cap(grammar.the(game.data(person).name))
                )
                game.print(str)
            end
            local space = person.space
            game.person_displace(person)
            local p1 = game.data_init("person_ooze")
            p1.size = person.size / 2
            game.person_enter(p1, space)
            if p1.space then
                game.person_displace(p1)
            end
            local p2 = game.data_init("person_ooze")
            p2.size = person.size / 2
            game.person_enter(p2, space)
        end
    end
}

_database.person_kobold_archer = {
    name = "kobold archer",
    description = "A kobold w/ a shortbow. Can attack enemies 2 spaces away in a straight line, but can't attack enemies up close.",
    color = { 255, 255, 255 },
    character = "a",
    sprite = { file = "resource/sprite/Monsters.png", x = 6, y = 10 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 6, y = 11 },
    init = function (person)
        game.person_setup(person)
        person.hp = 1
        person.perception = 9
        person.conspic = 9
        local object = game.data_init("object_shortbow")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)
        person.dsts = {}
    end,
    act = function (person)
        game.person_act(person)
    end,
    threaten = function (person, space)
        if person.space == space then
            return true
        end
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
                            not _state.hero.sense[space.person] or
                            person == space.person
                        )
                end
            )
    end,
    person_act = function (person)
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water
            then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + 2*dst.person.here                
            end
            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local spaceF = function (space)
                for _, defender in ipairs(defenders) do
                    local d = Hex.dist(space, defender.space)
                    if  2 <= d and d <= 4 and
                        Hex.axis(space, defender.space) and
                        not game.obstructed(
                            space,
                            defender.space,
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
                    then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { spaceF }) or
                game.person_preferred_action_step(person, { spaceF }, cost_f)
            then
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            return
        end
        
        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) or
            game.person_rest(person)
        then
            return
        end
    end
}

_database.person_dhole = {
    name = "dhole",
    description = "a dhole",
    color = color_constants.max,
    character = "d",
    sprite = { file = "resource/sprite/Monsters.png", x = 3, y = 4 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 3, y = 5 },
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
                            "%s bite %s." or
                            "%s bites %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        local status = game.data_init("status_acute_senses")
        game.person_status_enter(person, status)
        person.dsts = {}
    end,
    threaten = function (person, space)
        return Hex.dist(person.space, space) <= 1
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water
            then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[src.person]
            then
                cost = cost + dst.person.here
            end

            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local spaceF = function (space)
                for _, defender in ipairs(defenders) do
                    if Hex.dist(space, defender.space) == 1 then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { spaceF }) or
                game.person_preferred_action_step(person, { spaceF }, cost_f)
            then
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            return
        end
        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) or
            game.person_rest(person)
        then
            return
        end
    end
}

_database.person_pirahna = {
    name = "pirahna",
    description = "A pirahna. Can't leave the water.",
    color = { 255, 255, 255 },
    character = "f",
    sprite = { file = "resource/sprite/Monsters.png", x = 1, y = 6 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 1, y = 7 },
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
                            "%s bite %s." or
                            "%s bites %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        person.dsts = {}
    end,
    threaten = function (person, space)
        return Hex.dist(person.space, space) <= 1
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if not game.data(dst.terrain).water then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + 2*dst.person.here
            end
            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local spaceF = function (space)
                for _, defender in ipairs(defenders) do
                    if Hex.dist(space, defender.space) == 1 then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { spaceF }) or
                game.person_preferred_action_step(person, { spaceF }, cost_f)
            then
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            return
        end
        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) or
            game.person_rest(person)
        then
            return
        end
    end
}

_database.person_bear = {
    name = "bear",
    description = "4 HP",
    color = { 255, 255, 255 },
    character = "B",
    sprite = { file = "resource/sprite/Monsters.png", x = 13, y = 6 },
    sprite2 = { file = "resource/sprite/Monsters.png", x = 13, y = 7 },
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
                            "%s slash %s." or
                            "%s slashes %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(defender).name)
                    )
                    game.print(str)
                end
                game.person_damage(defender, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        person.hp = 4
        person.dsts = {}
    end,
    threaten = function (person, space)
        return Hex.dist(person.space, space) <= 1
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local defenders = game.person_get_defenders(person)
        local cost_f = function (src, dst)
            if  game.data(dst.terrain).fire then
                return math.huge
            end
            local cost = 1
            if  dst.person and
                dst.person ~= person and
                person.sense[src.person]
            then
                cost = cost + dst.person.here
            end

            for _, defender in ipairs(defenders) do
                if Hex.dist(dst, defender.space) == 1 then
                    cost = cost + 4
                end
            end
            if game.data(dst.terrain).water then
                cost = cost * 2
            end
            return cost
        end
        if defenders[1] then
            game.person_store_defender_positions(person, cost_f, defenders)
            local spaceF = function (space)
                for _, defender in ipairs(defenders) do
                    if Hex.dist(space, defender.space) == 1 then
                        return function ()
                            return game.person_attack(person, defender.space)
                        end
                    end
                end
            end
            if  game.person_preferred_action(person, { spaceF }) or
                game.person_preferred_action_step(person, { spaceF }, cost_f)
            then
                return
            end
        end
        if  person ~= game.person_top(person) and
            game.person_step_to_friend(person, cost_f)
        then
            return
        end
        List.delete(person.dsts, person.space)
        if  person == game.person_top(person) and
            not person.dsts[1]
        then
            game.person_store_wherever(person, cost_f)
        end

        if  game.person_step_to_dsts(person, cost_f) or
            game.person_rest(person)
        then
            return
        end
    end
}

