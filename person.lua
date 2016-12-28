
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
        person.hp = 4
        
        local status = game.data_init("status_terrestrial")
        game.person_status_enter(person, status)

        local object = game.data_init("object_shortsword")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)

        local object = game.data_init("object_staff_of_distortion")
        game.person_object_enter(person, object)
        local object = game.data_init("object_potion_of_health")
        game.person_object_enter(person, object)
        local object = game.data_init("object_potion_of_incineration")
        game.person_object_enter(person, object)
        local object = game.data_init("object_potion_of_invisibility")
        game.person_object_enter(person, object)
        local object = game.data_init("object_staff_of_suggestion")
        game.person_object_enter(person, object)
        local object = game.data_init("object_charm_of_passage")
        game.person_object_enter(person, object)
        local object = game.data_init("object_potion_of_blindness")
        game.person_object_enter(person, object)
        local object = game.data_init("object_staff_of_incineration")
        game.person_object_enter(person, object)

        person.faction = "hero"
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
            local opponent = space.person
            if opponent then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s punch %s." or
                            "%s punches %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(opponent).name)
                    )
                    game.print(str)
                end
                game.person_damage(opponent, 1)
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
        local object = game.data_init("object_machete")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)
        person.interests = {}
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local opponents = game.person_get_opponents(person)
        local dist_f = function (src, dst)
            local cost = 1
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water or
                dst.terrain.door
            then
                cost = cost + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end

        -- attack opponents
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local pos_f = function (space)
                for _, opponent in ipairs(opponents) do
                    if Hex.dist(space, opponent.space) == 1 then
                        return function ()
                            return game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
            if game.person_do_or_step(person, pos_f, dist_f) then
                return
            end
        end

        -- step to friend 1
        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end

        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end

        game.person_rest(person)
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
        person.interests = {}
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local opponents = game.person_get_opponents(person)
        local dist_f = function (src, dst)
            local cost = 1
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water or
                dst.terrain.door
            then
                cost = cost + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local space_stab_f = function (space)
                return
                    game.space_stand(space) and
                    not game.data(space.terrain).water and
                    (
                        not space.person or
                        not person.sense[space.person] or
                        person == space.person
                    )
            end
            local pos_f = function (space)
                for _, opponent in ipairs(opponents) do
                    if  Hex.dist(space, opponent.space) == 2 and
                        Hex.axis(space, opponent.space) and
                        not game.obstructed(
                            space,
                            opponent.space,
                            space_stab_f
                        )
                    then
                        return function ()
                            local dx = opponent.space.x - person.space.x
                            local dy = opponent.space.y - person.space.y
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
                for _, opponent in ipairs(opponents) do
                    if Hex.dist(space, opponent.space) == 1 then
                        return function ()
                            return game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
            if game.person_do_or_step(person, pos_f, dist_f) then
                return
            end
        end

        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end

        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end

        game.person_rest(person)
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
        person.interests = {}
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local opponents = game.person_get_opponents(person)
        local dist_f = function (src, dst)
            local cost = 1
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water
            then
                cost = cost + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local pos_f = function (space)
                for _, opponent in ipairs(opponents) do
                    if Hex.dist(space, opponent.space) == 1 then
                        return function ()
                            return game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
            if game.person_do_or_step(person, pos_f, dist_f) then
                return
            end
        end
        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end

        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end

        game.person_rest(person)
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
            local opponent = space.person
            if opponent then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s attack %s." or
                            "%s attacks %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(opponent).name)
                    )
                    game.print(str)
                end
                game.person_damage(opponent, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        person.size = 2
        person.interests = {}
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        if _state.turn % 2 == 1 then
            return game.person_rest(person)
        end
        local opponents = game.person_get_opponents(person)
        local dist_f = function (src, dst)
            local cost = 1
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water or
                dst.terrain.door
            then
                cost = cost + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local pos_f = function (space)
                for _, opponent in ipairs(opponents) do
                    if Hex.dist(space, opponent.space) == 1 then
                        return function ()
                            return game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
            if game.person_do_or_step(person, pos_f, dist_f) then
                return
            end
        end
        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end

        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end

        game.person_rest(person)
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
        local object = game.data_init("object_shortbow")
        game.person_object_enter(person, object)
        game.person_object_equip(person, object)
        person.interests = {}
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
        local opponents = game.person_get_opponents(person)
        local dist_f = function (src, dst)
            local cost = 1
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water or
                dst.terrain.door
            then
                cost = cost + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local pos_f = function (space)
                for _, opponent in ipairs(opponents) do
                    local d = Hex.dist(space, opponent.space)
                    if  2 <= d and d <= 4 and
                        Hex.axis(space, opponent.space) and
                        not game.obstructed(
                            space,
                            opponent.space,
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
                            return game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
            if game.person_do_or_step(person, pos_f, dist_f) then
                return
            end
        end
        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end

        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end

        game.person_rest(person)
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
            local opponent = space.person
            if opponent then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s bite %s." or
                            "%s bites %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(opponent).name)
                    )
                    game.print(str)
                end
                game.person_damage(opponent, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        local status = game.data_init("status_acute_senses")
        game.person_status_enter(person, status)
        person.interests = {}
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local opponents = game.person_get_opponents(person)
        local dist_f = function (src, dst)
            local cost = 1
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water or
                dst.terrain.door
            then
                cost = cost + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local pos_f = function (space)
                for _, opponent in ipairs(opponents) do
                    if Hex.dist(space, opponent.space) == 1 then
                        return function ()
                            return game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
            if game.person_do_or_step(person, pos_f, dist_f) then
                return
            end
        end
        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end

        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end

        game.person_rest(person)
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
            local opponent = space.person
            if opponent then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s bite %s." or
                            "%s bites %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(opponent).name)
                    )
                    game.print(str)
                end
                game.person_damage(opponent, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        local status = game.data_init("status_aquatic")
        game.person_status_enter(person, status)
        person.interests = {}
    end,
    person_check = function (person, space)
        if game.person_can_attack(person) then

        end
    end,

    act = function (person)
        game.person_act(person)
    end,
    person_dist_f = function (person, opponents)
        local f = function (src, dst)
            local dist = 1
            if not game.data(dst.terrain).water then
                dist = dist + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                dist = dist + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    dist = dist + 4
                end
            end
            return dist
        end
        return f
    end,
    person_post_f = function (person, opponents)
        local f = function (space)
            if game.person_can_attack(person) then
                for _, opponent in ipairs(opponents) do
                    if Hex.dist(space, opponent.space) == 1 then
                        return function ()
                            game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
        end
        return f
    end,
    person_act = function (person)
        local proto = game.data(person)
        local opponents = game.person_get_opponents(person)
        local dist_f = proto.person_dist_f(person, opponents)
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local post_f = proto.person_post_f(person, opponents)
            if game.person_do_or_step(person, post_f, dist_f) then
                return
            end
        end
        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end
        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end
        game.person_rest(person)
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
            local opponent = space.person
            if opponent then
                if game.person_sense(_state.hero, person) then
                    local str = string.format(
                        game.data(person).plural and
                            "%s slash %s." or
                            "%s slashes %s.",
                        grammar.cap(grammar.the(game.data(person).name)),
                        grammar.the(game.data(opponent).name)
                    )
                    game.print(str)
                end
                game.person_damage(opponent, 1)
            end
        end
    },
    init = function (person)
        game.person_setup(person)
        person.hp = 4
        person.interests = {}
    end,
    threaten = function (person, space)
        return Hex.dist(person.space, space) <= 1
    end,
    act = function (person)
        game.person_act(person)
    end,
    person_act = function (person)
        local opponents = game.person_get_opponents(person)
        local dist_f = function (src, dst)
            local cost = 1
            if  game.data(dst.terrain).fire or
                game.data(dst.terrain).water or
                dst.terrain.door
            then
                cost = cost + math.huge
            end
            if  dst.person and
                dst.person ~= person and
                person.sense[dst.person]
            then
                cost = cost + dst.person.here
            end
            for _, opponent in ipairs(opponents) do
                if Hex.dist(dst, opponent.space) == 1 then
                    cost = cost + 4
                end
            end
            return cost
        end
        if next(opponents) then
            game.person_store_opponent_positions(person, dist_f, opponents)
            local pos_f = function (space)
                for _, opponent in ipairs(opponents) do
                    if Hex.dist(space, opponent.space) == 1 then
                        return function ()
                            return game.person_attack(person, opponent.space)
                        end
                    end
                end
            end
            if game.person_do_or_step(person, pos_f, dist_f) then
                return
            end
        end
        if person ~= game.person_top(person) then
            if game.person_step_to_friend(person, dist_f) then
                return
            end
        end

        person.interests[person.space] = nil
        if next(person.interests) == nil then
            game.person_store_wherever(person, dist_f)
        end
        if game.person_step_to_dsts(person, dist_f) then
            return
        end

        game.person_rest(person)
    end
}

