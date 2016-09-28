
-- functions for altering game state

game = {}

-- create a game
function game.init()
    seed = SEED or os.time()
    print(string.format("seed: %d", seed))
    
    _state = {}
    
    _state.rand1 = love.math.newRandomGenerator(seed)
    _state.rand2 = love.math.newRandomGenerator(seed)
    _state.past_branchs = {}
    _state.present_notes = {}
    _state.past_notes = {}
    _state.events = {}
    _state.turn = 0

    game.print("(press [?] for controls, hints)")
    
    -- create hero
    _state.hero = game.data_init("hero")

    -- enter branch zero
    game.branch_enter({ name = "branch_zero", depth = 1 })
end

-- rng for level generation
function game.rand1(n)
    return _state.rand1:random(n)
end

-- rng for non-level generation
function game.rand2(n)
    return _state.rand2:random(n)
end

-- push a game message
function game.print(str)
    table.insert(_state.present_notes, str)
    print(str)
end

-- flush game messages (show in state_one)
function game.flush()
    _state.past_notes = List.copy(_state.present_notes)
    _state.present_notes = {}
end

-- get a game object's parent
function game.data(object)
    return _database[object.id]
end

-- create a game object
function game.data_init(id)
    assert(_database[id])
    local o = {}
    -- store database key of the parent
    o.id = id
    -- call parent's init
    local f = game.data(o).init
    if f then
        f(o)
    end
    return o
end

-- go to a branch
function game.branch_descend(branch)
    game.branch_exit()
    game.branch_enter(branch)
end

-- enter a branch
function game.branch_enter(branch)
    local prev = _state.branch
    _state.branch = branch

    local path = string.format(
        "%s-%d",
        branch.name, branch.depth
    )
    if _state.past_branchs[path] then
        -- restore the branch
        game.branch_restore(branch)
        
        -- place hero on stairs
        local f = function (space)
            return
                space.dst and
                space.dst.name == prev.name and
                space.dst.depth == prev.depth
        end
        local stairs = List.filter(_state.spaces, f)[1]
        game.person_enter(_state.hero, stairs)
    else
        -- hearts +1
        game.person_damage(_state.hero, -1)
        -- generate the branch
        game.branch_generate(branch)
    end
    -- preact
    List.delete(_state.events, _state.hero)
    game.preact()
end

-- exit and store the branch
function game.branch_exit()
    game.person_exit(_state.hero)
    game.branch_store()
end

-- store the branch
function game.branch_store()
    -- generate a path
    local path = string.format(
        "%s-%d", _state.branch.name, _state.branch.depth
    )
    -- write branch data to the path
    local data = {
        spaces = _state.spaces,
        spaces2d = _state.spaces2d,
        visited = _state.visited,
        events = _state.events,
        persons = _state.persons,
        objects = _state.objects
    }
    love.filesystem.write(path, binser.serialize(data))
    _state.past_branchs[path] = true
end

-- restore the branch
function game.branch_restore(branch)
    -- generate a path
    local path = string.format(
        "%s-%d", branch.name, branch.depth
    )
    -- read branch data
    local data = binser.deserialize(love.filesystem.read(path))[1]
    _state.spaces = data.spaces
    _state.spaces2d = data.spaces2d
    _state.visited = data.visited
    _state.events = data.events
    _state.persons = data.persons
    _state.objects = data.objects
end

-- generate the branch
function game.branch_generate(branch)
    _state.spaces = {}
    _state.spaces2d = {}
    _state.visited = {}
    _state.events = {}
    _state.persons = {}
    _state.objects = {}
    _database[branch.name].init(branch.depth)
end

-- create a (blank) hexagonal map
function game.spaces_init(size)
    local center = { x = size, y = size, z = 0 - size - size }
    for x = 1, 2 * size - 1 do
        _state.spaces2d[x] = {}
        for y = 1, 2 * size - 1 do
            local space = { x = x, y = y, z = 0 - x - y }
            if Hex.dist(space, center) < size then
                table.insert(_state.spaces, space)
                _state.spaces2d[x][y] = space
            end
        end
    end
end

-- pass the turn
function game.rotate()
    game.postact()
    while not _state.hero.dead do
        -- dequeue an event
        local event = table.remove(_state.events, 1)
        if event == _state.hero then
            break
        else
            game.data(event).act(event)
        end
    end
    game.preact()
end

-- hero's turn starts
function game.preact()
    _state.turn = _state.turn + 1
    game.person_preact(_state.hero)
    game.flush()
end

--[[
-- print discoveries
function game.print_discoveries(discoveries)
    assert(discoveries)
    if discoveries[1] == nil then
        return
    end
    local f = function (a, b)
        return
            Hex.dist(_state.hero.space, a.space) <
            Hex.dist(_state.hero.space, b.space)
    end
    table.sort(discoveries, f)
    local ids = {}
    local count = {}
    for _, discovery in ipairs(discoveries) do
        if count[discovery.id] then
            count[discovery.id] = count[discovery.id] + 1
        else
            table.insert(ids, discovery.id)
            count[discovery.id] = 1
        end
    end
    local str = "You see"
    local f = function (id)
        if count[id] == 1 then
            return grammar.a(_database[id].name)
        else
            return string.format(
                "%d %s",
                count[id],
                _database[id].plural_name or _database[id].name .. "s"
            )
        end
    end
    local strs = List.map(f, ids)
    if #strs == 1 then
        str = string.format("%s %s.", str, strs[1])
    elseif #strs == 2 then
        str = string.format("%s %s and %s.", str, strs[1], strs[2])
    else
        for i = 1, #strs - 1 do
            str = string.format("%s %s,", str, strs[i])
        end
        str = string.format("%s and %s.", str, strs[#strs])
    end
    game.print(str)
end
]]

-- hero's turn ends
function game.postact()
    game.person_postact(_state.hero)
end

-- return true if a person can stand here
function game.space_stand(space)
    return game.data(space.terrain).stand
end

-- return true if a person can stand here now
function game.space_vacant(space)
    return game.data(space.terrain).stand and not space.person
end

-- return the first obstructing space of an axis-bound path
function game.obstructed(src, dst, valid_f)
    if 2 <= Hex.dist(src, dst) then
        local spaces = Hex.line(src, dst)
        for i = 1 + 1, #spaces - 1 do
            local space = spaces[i]
            if not valid_f(space) then
                return space
            end
        end
    end
end

-- get a space w/ x and y coordinates
function game.get_space(x, y)
    return _state.spaces2d[x] and _state.spaces2d[x][y]
end

-- bootstrap a person
function game.person_setup(person)
    person.hp = 1
    person.damage = 0
    person.actions = {}
    person.statuss = {}
    person.objects = {}
    person.friends = {}
    person.sense = {}
end

-- get a person's decorations
function game.person_decorations(person)
    local decorations = {}
    if person.statuss then
        List.extend(decorations, person.statuss)
    end
    if person.objects then
        List.extend(decorations, person.objects)
    end
    return decorations
end

-- put person on space
function game.person_enter(person, space)
    table.insert(_state.persons, person)
    table.insert(person.friends, person)
    person.space, space.person = space, person
    person.here = 0 -- # of turns stuck
    local f = game.data(person).person_enter
    if f then
        f(person)
    end
    game.person_postact(person)
end

-- delete person
function game.person_exit(person)
    List.delete(person.friends, person)
    List.delete(_state.persons, person)
    person.space, person.space.person = nil, nil
    person.here = nil
end

-- person's turn
function game.person_act(person)
    game.person_preact(person)
    if person.space then
        if person.skip then
        
        else
            local f = game.data(person).person_act
            if f then
                f(person, cost)
            end
        end
    end
    game.person_postact(person)
end

-- person's turn starts
function game.person_preact(person)
    if person.space then
        local decorations = game.person_decorations(person)
        for _, decoration in ipairs(decorations) do
            local f = game.data(decoration).person_preact
            if f then
                f(person, object)
            end
        end
    end
end

-- person's turn ends
function game.person_postact(person)
    if person.space then
        -- person's terrain
        local f = game.data(person.space.terrain).person_terrain_postact
        if f then
            f(person, person.space.terrain)
        end
    end
    if person.space then
        -- person's decorations
        local decorations = game.person_decorations(person)
        for _, decoration in ipairs(decorations) do
            local f = game.data(decoration).person_postact
            if f then
                f(person, decoration)
            end
        end
    end
    if person.space then
        -- update sense connections
        game.person_scan(person)
        game.person_expose(person)

        person.here = person.here + 1
        -- enqueue
        if game.data(person).act then
            table.insert(_state.events, person)
        end
    end
end

-- person relocates
function game.person_relocate(person, space)
    assert(space.person == nil)
    local src = person.space
    if person.space then
        person.space.person = nil
    end
    person.space, space.person = space, person
    person.here = 0
    local decorations = game.person_decorations(person)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).person_relocate
        if f then
            f(person, decoration, src)
        end
    end
end

-- person passes turn, return success
function game.person_rest(person)
    return true
end

-- person steps, return success
function game.person_step(person, space)
    if game.data(space.terrain).stand and not space.person then
        local src = person.space
        game.person_relocate(person, space)
        if person.space then
            local f = game.data(person).person_step
            if f then
                f(person, src)
            end
        end
        if person.space then
            local decorations = game.person_decorations(person)
            for _, decoration in ipairs(decorations) do
                local f = game.data(decoration).person_poststep
                if f then
                    f(person, decoration, src)
                end
            end
        end
        return true
    end
end

-- person updates senses
function game.person_scan(person)
    for _, p in ipairs(_state.persons) do
        game.person_person_check(person, p)
    end
    for _, o in ipairs(_state.objects) do
        game.person_object_check(person, o)
    end
end

-- person updates others' senses
function game.person_expose(person)
    for _, p in ipairs(_state.persons) do
        game.person_person_check(p, person)
    end
end

-- return true if person sees the space
function game.person_space_sense(person, space)
    local sense = not game.obstructed(
        person.space,
        space,
        game.person_space_sense_aux
    )
    local decorations = game.person_decorations(person)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).person_space_sense1
        if f then
            sense = sense and f(person, decoration, space)
        end
    end
    sense = sense or Hex.dist(person.space, space) <= 1
    local decorations = game.person_decorations(person)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).person_space_sense2
        if f then
            sense = sense or f(person, decoration, space)
        end
    end
    return sense
end

function game.person_space_sense_aux(space)
    return game.data(space.terrain).sense
end

-- return true if person senses the person or object
function game.person_sense(person, person_or_object)
    if person and person.space then
        for _, friend in ipairs(person.friends) do
            local space = friend.sense[person_or_object]
            if space then
                return space
            end
        end
    end
end

-- update person-to-person sense relation
function game.person_person_check(attacker, defender)
    if game.person_space_sense(attacker, defender.space) then
        local dist = game.person_person_per_dist(attacker, defender)
        if Hex.dist(attacker.space, defender.space) <= dist then
            attacker.sense[defender] = defender.space
            return defender.space
        end
    end
    attacker.sense[defender] = nil
end

-- person-to-person sense range
function game.person_person_per_dist(attacker, defender)
    local con = 20
    -- get base conspicuousness
    local decorations = game.person_decorations(defender)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).con
        if f then
            con = math.min(f(defender, attacker, decoration), con)
        end
    end
    -- factor bonuses
    local decorations = game.person_decorations(attacker)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).per_addend
        if f then
            con = con + f(attacker, defender, decoration)
        end
    end
    local decorations = game.person_decorations(defender)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).con_addend
        if f then
            con = con + f(defender, attacker, decoration)
        end
    end
    return math.max(con, 1)
end

-- update person-to-object sense relation
function game.person_object_check(attacker, defender)
    if game.person_space_sense(attacker, defender.space) then
        local dist = game.person_object_per_dist(attacker, defender)
        if Hex.dist(attacker.space, defender.space) <= dist then
            attacker.sense[defender] = defender.space
            return defender.space
        end
    end
    attacker.sense[defender] = nil
end

-- person-to-object sense range
function game.person_object_per_dist(attacker, defender)
    local con = 20
    -- get base conspicuousness
    local decorations = game.object_decorations(defender)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).con
        if f then
            con = math.min(f(defender, attacker, decoration), con)
        end
    end
    -- factor bonuses
    local decorations = game.person_decorations(attacker)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).per_addend
        if f then
            con = con + f(attacker, defender, decoration)
        end
    end
    local decorations = game.object_decorations(defender)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).con_addend
        if f then
            con = con + f(defender, attacker, decoration)
        end
    end
    return math.max(con, 1)
end

-- person attacks
function game.person_attack(person, space)
    -- use object in hand or person's default attack
    local decoration = person.hand or person
    local verb = game.data(decoration).attack
    assert(verb)
    assert(verb.range(person, decoration, space))
    verb.execute(person, decoration, space)
    return true
end

-- person gets displaced (relocated nearby)
function game.person_displace(person)
    assert(person.space)
    local dst_f = function (space)
        return
            space ~= person.space and
            game.data(space.terrain).stand and
            not space.person
    end
    local spaces = List.filter(_state.spaces, f)
    local path = Path.dijk(person.space, dst_f, game.space_stand)
    if path then
        for i = #path, 2 do
            local dst = path[i]
            local src = path[i - 1]
            game.person_relocate(src.person, dst)
        end
        return true
    else
        print("didn\'t displace")
        game.person_exit(person)
    end
end

-- person gets damaged
function game.person_damage(person, points)
    person.damage = math.max(person.damage + points, 0)
    if person.damage >= person.hp then
        game.person_die(person)
    end
end

-- 2 persons relocate
function game.person_transpose(person1, person2)
    local space1 = person1.space
    local space2 = person2.space
    person1.space, space2.person = space2, person1
    person2.space, space1.person = space1, person2
    local decorations = game.object_decorations(person1)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).person_relocate
        if f then
            f(person1, decoration, src)
        end
    end
    local decorations = game.object_decorations(person2)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).person_relocate
        if f then
            f(person2, decoration, src)
        end
    end
end

-- person teleports
function game.person_teleport(person)
    if game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s teleport." or
                "%s teleports.",
            grammar.cap(grammar.the(game.data(person).name))
        )
        game.print(str)
    end
    local f = function (space)
        return
            game.data(space.terrain).stand and
            not space.dst and
            not space.person
    end
    local dst = List.filter(_state.spaces, f)[1]
    game.person_relocate(person, dst)
end

-- person dies
function game.person_die(person)
    if game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s die." or
                "%s dies.",
            grammar.cap(grammar.the(game.data(person).name))
        )
        game.print(str)
    end
    local f = game.data(person).person_die
    if f then
        f(person)
    end
    for _, decoration in ipairs(game.person_decorations(person)) do
        local f = game.data(decoration).person_die
        if f then
            f(person, decoration)
        end
    end
    if person == _state.hero then
        -- _state.hero dies later (update the map first)
        person.dead = true
    else
        game.person_exit(person)
    end
end

-- person1 friends person2
function game.person_add_friend(person, friend)
    friend.faction = person.faction
    friend.friends = person.friends
    table.insert(friend.friends, friend)
end

-- shorthand for person's perceived range of projectile
function game.person_space_proj(person, space)
    local d = Hex.dist(person.space, space)
    return
        1 <= d and d <= 4 and
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
end

-- shorthand for first obstructed space w/ simple obstruction rules
function game.person_space_proj_obstruction(person, space)
    local f = function (space)
        return
            game.data(space.terrain).stand and
            not space.person
    end
    return game.obstructed(person.space, space, f) or space
end

-- shorthand for slash attacks
function game.person_poststep_attack2(person, src)
    local spaces = List.intersection(
        Hex.adjacent(src),
        Hex.adjacent(person.space)
    )
    for _, space in ipairs(spaces) do
        if space.person and space.person.faction ~= person.faction then
            game.person_attack(person, space)
        end
    end
end

-- shorthand for lunge attacks
function game.person_poststep_attack3(person, src)
    local dx = math.max(math.min(person.space.x - src.x, 1), -1)
    local dy = math.max(math.min(person.space.y - src.y, 1), -1)
    local space = game.get_space(
        person.space.x + dx,
        person.space.y + dy
    )
    if space then
        if space.person and space.person.faction ~= person.faction then
            game.person_attack(person, space)
        end
    end
end

-- get hostile persons visible to the person
function game.person_get_defenders(attacker)
    local f = function (defender)
        return
            defender.faction ~= attacker.faction and
            game.person_sense(attacker, defender)
    end
    return List.filter(_state.persons, f)
end

-- get objects visible to the person
function game.person_get_objects(attacker)
    local f = function (defender)
        return game.person_sense(attacker, defender)
    end
    return List.filter(_state.objects, f)
end

-- person steps on a path to a space, return success
function game.person_step_to(person, dst_f, valid_f, cost_f, stop)
    local path = Path.dijk(
        person.space,
        dst_f,
        valid_f,
        cost_f,
        stop
    )
    local space = path and path[2]
    if space and game.space_vacant(space) then
        return game.person_step(person, space)
    end
end

-- person does a preferred action
function game.person_preferred_action(person, space_fs)
    for _, space_f in ipairs(space_fs) do
        local f = space_f(person.space)
        if f then
            return f()
        end
    end
end

-- person steps on a path to a position for a preferred action
function game.person_preferred_action_step(person, space_fs, cost_f)
    local dst_f = function (space)
        for _, space_f in ipairs(space_fs) do
            if space_f(space) then
                return true
            end
        end
    end
    return game.person_step_to(person, dst_f, game.space_stand, cost_f)
end

-- person does a preferred action or steps to pos
function game.person_do_or_step(person, pos_f, cost_f)
    local f = pos_f(person.space)
    if f then
        return f()
    else
        return game.person_step_to(
            person,
            pos_f,
            game.space_stand,
            cost_f
        )
    end
end

-- get the person's leader
function game.person_top(person)
    return person.friends[1]
end

-- person steps on a path to the leader
function game.person_step_to_friend(person, cost_f)
    local dst_f = function (space)
        return Hex.dist(space, person.friends[1].space) <= 1
    end
    return game.person_step_to(person, dst_f, game.space_stand, cost_f)
end

-- person stores the positions of reachable enemies
function game.person_store_defender_positions(person, cost_f, defenders)
    person.interests = {}
    for _, defender in ipairs(defenders) do
        local path = Path.astar(
            person.space,
            defender.space,
            game.space_stand,
            cost_f
        )
        if path then
            person.interests[defender.space] = true
        end
    end
end

-- person stores a random reachable space to wander to
function game.person_store_wherever(person, cost_f)
    local map = Path.dist(
        { person.space },
        game.space_stand,
        cost_f,
        8 -- cost to dst < 8
    )
    local f = function (space)
        local d = map[space]
        return 0 < d and d < math.huge
    end
    local spaces = List.filter(_state.spaces, f)
    local dst = spaces[game.rand2(#spaces)]
    person.interests = {}
    person.interests[dst] = true
end

-- person steps on a path to past-stored spaces
function game.person_step_to_dsts(person, cost_f)
    local dst_f = function (space)
        return person.interests[space]
    end
    return game.person_step_to(person, dst_f, game.space_stand, cost_f)
end

-- place a status on a person
function game.person_status_enter(person, status)
    table.insert(person.statuss, status)
    local f = game.data(status).person_status_enter
    if f then
        f(person, status)
    end
end

-- delete a status on a person
function game.person_status_exit(person, status)
    List.delete(person.statuss, status)
    local f = game.data(status).person_status_exit
    if f then
        f(person, status)
    end
end

-- decrement a status on a person
function game.person_status_decrement(person, status)
    assert(status.counters)
    if status.counters then
        status.counters = status.counters - 1
        if status.counters == 0 then
            game.person_status_exit(person, status)
        end
    end
end

-- place an object on a person
function game.person_object_enter(person, object)
    table.insert(person.objects, object)
    object.person = person
    local f = game.data(object).person_object_enter
    if f then
        f(person, object)
    end
end

-- delete an object on a person
function game.person_object_exit(person, object)
    if game.person_object_equipped(person, object) then
        game.person_object_unequip(person, object, true)
    end
    List.delete(person.objects, object)
    object.person = nil
end

-- print "<person> uses <object>."
function game.person_object_use(person, object)
    if game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s use %s." or
                "%s uses %s.",
            grammar.cap(grammar.the(game.data(person).name)),
            grammar.the(game.data(object).name)
        )
        game.print(str)
    end
end

-- print "<person> throws <object>."
function game.person_object_throw(person, object)
    if game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s throw %s." or
                "%s throws %s.",
            grammar.cap(grammar.the(game.data(person).name)),
            grammar.the(game.data(object).name)
        )
        game.print(str)
    end
end

-- print "<person> equips <object>."
function game.person_object_equip(person, object)
    assert(not game.person_object_equipped(person, object))
    local part = game.data(object).part
    if person[part] then
        game.person_object_unequip(person, person[part], true)
    end
    if game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s equip %s." or
                "%s equips %s.",
            grammar.cap(grammar.the(game.data(person).name)),
            grammar.the(game.data(object).name)
        )
        game.print(str)
    end
    person[part] = object
end

-- print "<person> unequips <object>."
function game.person_object_unequip(person, object, quiet)
    assert(game.person_object_equipped(person, object))
    if not quiet and game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s unequip %s." or
                "%s unequips %s.",
            grammar.cap(grammar.the(game.data(person).name)),
            grammar.the(game.data(object).name)
        )
        game.print(str)
    end
    local part = game.data(object).part
    person[part] = nil
end

-- returns true if person has object equipped
function game.person_object_equipped(person, object)
    return person[game.data(object).part] == object
end

-- person picks up an object
function game.person_object_pickup(person, object)
    assert(object.space)
    game.object_exit(object)
    if game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s pick up %s." or
                "%s picks up %s.",
            grammar.cap(grammar.the(game.data(person).name)),
            grammar.the(game.data(object).name)
        )
        game.print(str)
    end
    game.person_object_enter(person, object)
end

-- person drops an object
function game.person_object_drop(person, object)
    if game.person_sense(_state.hero, person) then
        local str = string.format(
            game.data(person).plural and
                "%s drop %s." or
                "%s drops %s.",
            grammar.cap(grammar.the(game.data(person).name)),
            grammar.the(game.data(object).name)
        )
        game.print(str)
    end
    game.person_object_exit(person, object)
    game.object_enter(object, person.space)

    -- don't autopickup this object
    object.dropped = true
end

-- bootstrap an object
function game.object_setup(object)
    object.statuss = {}
end

-- get object's decorations
function game.object_decorations(object)
    local decorations = {}
    if object.statuss then
        List.extend(decorations, object.statuss)
    end
    return decorations
end

-- place an object
function game.object_enter(object, space)
    table.insert(_state.objects, object)
    if space.object then
        game.object_displace(space.object)
    end
    object.space, space.object = space, object
    game.object_postact(object)
end

-- delete an object
function game.object_exit(object)
    List.delete(_state.objects, object)
    object.space, object.space.object = nil, nil
end

-- place a status on an object
function game.object_status_enter(object, status)
    table.insert(object.statuss, status)
    local f = game.data(status).object_status_enter
    if f then
        f(object, status)
    end
end

-- delete a status on an object
function game.object_status_exit(object, status)
    List.delete(object.statuss, status)
    local f = game.data(status).object_status_exit
    if f then
        f(object, status)
    end
end

-- decrement a status on an object
function game.object_status_decrement(object, status)
    assert(status.counters)
    if status.counters then
        status.counters = status.counters - 1
        if status.counters == 0 then
            game.object_status_exit(object, status)
        end
    end
end

-- object's turn
function game.object_act(object)
    if object.space then
        local f = game.data(object).object_act
        if f then
            f(object)
        end
    end
    game.object_postact(object)
end

-- object's turn ends
function game.object_postact(object)
    if object.space then
        local f = game.data(object.space.terrain).object_terrain_postact
        if f then
            f(object, object.space.terrain)
        end
    end
    if object.space then
        local decorations = game.object_decorations(object)
        for _, decoration in ipairs(decorations) do
            local f = game.data(decoration).object_postact
            if f then
                f(object, decoration)
            end
        end
    end
    if object.space then
        game.object_expose(object)
        if game.data(object).act then
            table.insert(_state.events, object)
        end
    end
end

-- object updates others' sense relations
function game.object_expose(object)
    for _, p in ipairs(_state.persons) do
        game.person_object_check(p, object)
    end
end

-- object relocates
function game.object_relocate(object, space)
    assert(space.object == nil)
    local src = object.space
    if object.space then
        object.space.object = nil
    end
    object.space, space.object = space, object
    local decorations = game.object_decorations(object)
    for _, decoration in ipairs(decorations) do
        local f = game.data(decoration).object_relocate
        if f then
            f(object, decoration, src)
        end
    end
end

-- object gets displaced (relocated nearby)
function game.object_displace(object)
    local f = function (space)
        return
            space ~= object.space and
            game.data(space.terrain).stand and
            not space.object
    end
    local spaces = List.filter(_state.spaces, f)
    local path = Path.astar(object.space, spaces, game.space_stand)
    if path then
        for i = #path, 2 do
            local dst = path[i]
            local src = path[i - 1]
            game.object_relocate(src.object, dst)
        end
        return true
    else
        print("didn\'t displace")
        game.object_exit(object)
    end
end

-- puts the status "charging" on object
function game.object_discharge(object, counters)
    local status = game.data_init("status_charging")
    status.counters = counters
    game.object_status_enter(object, status)
end

-- puts terrain on space
function game.terrain_enter(terrain, space)
    terrain.space, space.terrain = space, terrain
    game.terrain_postact(terrain)
end

-- deletes terrain
function game.terrain_exit(terrain)
    terrain.space, terrain.space.terrain = nil, nil
end

-- terrain's turn ends
function game.terrain_postact(terrain)
    if game.data(terrain).act then
        table.insert(_state.events, terrain)
    end
end

