
-- root game state (playing)

state_one = {}

HS = 24
SIDEBAR_X = 960
ANIMATE_LEN = 10/60


function state_one.init()
    state_one.sprites = true
    local px, py = Hex.pos({ x = 0, y = 0 }, HS)
    state_one.camera = { px = px - 480, py = py - 360 }
    state_one.notes = {}
    state_one.terrains = {}
    state_one.terrains2 = {}
    state_one.objects = {}
    state_one.objects2 = {}
    
    state_one.persons = {}
    state_one.person_prev = {}

    state_one.fov = {}
    state_one.fov2 = {}
    state_one.perception = {}
    state_one.check = {}
    state_one.check2 = {}
    state_one.path = nil
    state_one.path_set = {}
    state_one.describe = nil
    state_one.timer = 0
    state_one.mouse = false
    state_one.animate = 0
    state_one.records = {}
    state_one.animations = {}

    state_one.process_map()
    state_one.flush()
end

function state_one.deinit()
    state_one.sprites = nil
    state_one.camera = nil
    state_one.fov = nil
    state_one.perception = nil
    state_one.check = nil
    state_one.path = nil
    state_one.path_set = nil
    state_one.describe = nil
    state_one.timer = nil
    state_one.mouse = nil
end

function state_one.keypressed(k)
    state_one.mouse = false
    state_one.path = nil
    state_one.path_set = {}
    if k == "1" then
        print(pp(_state.branch))
    elseif k == "2" then
        for _, space in ipairs(_state.map.spaces) do
            _state.map.visited[space] = true
        end
    end
    if k == "space" or k == "kp5" then
        state_one.rest()
    elseif k == "h" or k == "kp4" then
        state_one.step(-1, 0)
    elseif k == "l" or k == "kp6" then
        state_one.step(1, 0)
    elseif k == "k" or k == "kp8" then
        state_one.step(0, -1)
    elseif k == "j" or k == "kp2" then
        state_one.step(0, 1) 
    elseif k == "y" or k == "kp7" then
        state_one.step(0, -1)
    elseif k == "n" or k == "kp3" then
        state_one.step(0, 1) 
    elseif k == "b" or k == "kp1" then
        state_one.step(-1, 1)
    elseif k == "u" or k == "kp9" then
        state_one.step(1, -1)
    elseif k == "g" then
        state_one.pickup()
    elseif k == "i" then
        state_one.rucksack()
    elseif k == "q" then
        state_one.use()
    elseif k == "w" then
        state_one.throw()
    elseif k == "e" then
        state_one.equip()
    elseif k == "r" then
        state_one.drop()
    elseif k == "z" then
        state_one.descend()
    elseif k == "/" then
        state_one.help()
    elseif k == "=" then
        -- toggle sprite mode
        state_one.sprites = not state_one.sprites
    end
end

-- open rucksack menu
function state_one.rucksack()
    local data = {}
    data.sprite = { file = "resource/sprite/Items.png", x = 14, y = 3 }
    data.character = "!"
    data.header = "rucksack"
    data.options = {}
    for _, object in ipairs(_state.hero.objects) do
        local verb = game.data(object).use
        local option = { valid = true }
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = state_one.get_object_str(object)
        option.execute = function ()
            state_one.check_object(object)
        end
        table.insert(data.options, option)
    end
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- open rucksack and use menu
function state_one.use()
    local data = {}
    data.sprite = { file = "resource/sprite/Items.png", x = 14, y = 3 }
    data.character = "!"
    data.header = "use what?"
    data.options = {}
    for _, object in ipairs(_state.hero.objects) do
        local verb = game.data(object).use
        local option = {}
        option.valid =
            verb and
            (verb.valid == nil or verb.valid(_state.hero, object))
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = state_one.get_object_str(object)
        option.execute = function ()
            state_one.verb_execute(verb, object)
        end
        table.insert(data.options, option)
    end
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- open rucksack and throw menu
function state_one.throw()
    local data = {}
    data.sprite = { file = "resource/sprite/Items.png", x = 14, y = 3 }
    data.character = "!"
    data.header = "throw what?"
    data.options = {}
    for _, object in ipairs(_state.hero.objects) do
        local verb = game.data(object).throw
        local option = {}
        option.valid =
            verb and
            (verb.valid == nil or verb.valid(_state.hero, object))
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = state_one.get_object_str(object)
        option.execute = function ()
            state_one.verb_execute(verb, object)
        end
        table.insert(data.options, option)
    end
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- open rucksack and equip menu
function state_one.equip()
    local data = {}
    data.sprite = { file = "resource/sprite/Items.png", x = 14, y = 3 }
    data.character = "!"
    data.header = "equip what?"
    data.options = {}
    for _, object in ipairs(_state.hero.objects) do
        local verb = game.data(object).equip
        local option = {}
        option.valid =
            verb and
            (verb.valid == nil or verb.valid(_state.hero, object))
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = state_one.get_object_str(object)
        option.execute = function ()
            state_one.verb_execute(verb, object)
        end
        table.insert(data.options, option)
    end
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- open rucksack and drop menu
function state_one.drop()
    if _state.hero.space.object then
        game.print("You can't drop an item here.")
        state_one.flush()
        return
    end
    local data = {}
    data.sprite = { file = "resource/sprite/Items.png", x = 14, y = 3 }
    data.character = "!"
    data.header = "drop what?"
    data.options = {}
    for _, object in ipairs(_state.hero.objects) do
        local option = {}
        option.valid = true
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = state_one.get_object_str(object)
        option.execute = function ()
            game.person_object_drop(_state.hero, object)
            state_one.process_map()
            state_one.flush()
        end
        table.insert(data.options, option)
    end
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- examine a person or object from afar menu
function state_one.check_from_afar(person_or_object)
    local data = {}
    data.sprite = game.data(person_or_object).sprite
    data.character = game.data(person_or_object).character
    data.header = game.data(person_or_object).name
    data.paragraph = game.data(person_or_object).description
    data.options = {}
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- examine an object menu
function state_one.check_object(object)
    local data = {}
    data.sprite = game.data(object).sprite
    data.character = game.data(object).character
    data.header = state_one.get_object_str(object)
    data.paragraph = game.data(object).description
    data.options = {}
    local verb = game.data(object).use
    if verb then
        local option = {}
        option.valid =
            not verb.valid or
            verb.valid(_state.hero, object)
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = "use"
        option.execute = function ()
            state_one.verb_execute(verb, object)
        end
        table.insert(data.options, option)
    end
    local verb = game.data(object).throw
    if verb then
        local option = {}
        option.valid =
            not verb.valid or
            verb.valid(_state.hero, object)
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = "throw"
        option.execute = function ()
            state_one.verb_execute(verb, object)
        end
        table.insert(data.options, option)
    end
    local verb = game.data(object).equip
    if verb then
        local option = {}
        option.valid =
            not verb.valid or
            verb.valid(_state.hero, object)
        option.sprite = game.data(object).sprite
        option.character = game.data(object).character
        option.str = "equip"
        option.execute = function ()
            state_one.verb_execute(verb, object)
        end
        table.insert(data.options, option)
    end
    local option = { valid = true }
    option.sprite = game.data(object).sprite
    option.character = game.data(object).character
    option.str = "drop"
    option.execute = function ()
        game.person_object_drop(_state.hero, object)
        state_one.flush()
    end
    table.insert(data.options, option)
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- help menu
function state_one.help()
    local data = {}
    data.sprite = { file = "resource/sprite/Interface.png", x = 2, y = 3 }
    data.character = "?"

    data.header = "controls"
    data.paragraph =
        "[12346789/vi keys] step, attack\n" ..
        "[5/space] pass the turn\n" ..
        "[i] open rucksack\n" ..
        "[q] open rucksack and use\n" ..
        "[w] open rucksack and throw\n" ..
        "[e] open rucksack and equip\n" ..
        "[r] open rucksack and drop\n" ..
        "[g] pick up an object\n"
    data.options = {}
    state_menu.init(data)
    table.insert(states, state_menu)
end

-- generate an object description
function state_one.get_object_str(object)
    local str = game.data(object).name
    local enchant = object.enchant or 0
    if 0 < enchant then
        str = string.format("%s +%d", str, enchant)
    end
    if object.status_charging then
        str = string.format(
            "%s - charging (%d)",
            str,
            object.status_charging.counters
        )
    end
    if object == _state.hero.hand then
        string.format("%s (hand)", str)
    end
    return str
end

-- execute a verb
function state_one.verb_execute(verb, object)
    if verb.range then
        state_aim.init(verb, object)
        table.insert(states, state_aim)
    else
        state_one.preact()
        verb.execute(_state.hero, object, _state.hero.space)
        state_one.postact()
    end
end

function state_one.mousepressed(cpx, cpy, b)
    state_one.mouse = true
    local space = state_one.get_space(cpx, cpy)
    if b == 1 then
        if space then
            state_one.path_init(space)
            if state_one.path then
                local dst = state_one.path[2]
                if dst then
                    local dx = dst.x - _state.hero.space.x
                    local dy = dst.y - _state.hero.space.y
                    state_one.step(dx, dy)
                    if _state.hero.space then
                        state_one.path_init(space)
                    end
                else
                    state_one.rest()
                end
            end
        else
            local h = abstraction.font_h(fonts.monospace)
            local px = 960 + 12
            local py = 720 - 12 - h
            local str = "[i] open rucksack"
            if  px <= cpx and cpx < px + abstraction.font_w(fonts.monospace, str) and
                py <= cpy and cpy < py + h
            then
                state_one.rucksack()
            end
        end
    elseif b == 2 then
        if space then
            local person_or_object = space.person or space.object
            if  person_or_object and
                game.data(person_or_object).description then
                state_one.check_from_afar(person_or_object)
            end
        end
    elseif b == 3 then
        if space then
            print(space.x, space.y, space.z)
        end
    end
end

function state_one.mousemoved(px, py, dpx, dpy)
    state_one.mouse = true
    state_one.describe = nil
    local space = state_one.get_space(px, py)
    if space and _state.map.visited[space] then
        state_one.path_init(space)
        if
            space.person and
            game.person_sense(_state.hero, space.person)
        then
            state_one.describe = space.person
        elseif
            space.object and 
            game.person_sense(_state.hero, space.object)
        then
            state_one.describe = space.object
        elseif space.terrain then
            state_one.describe = space.terrain
        end
    else
        state_one.path_deinit()
    end
end

-- delete path data
function state_one.path_deinit()
    state_one.path = nil
    state_one.path_set = {}
end

-- get a space at a pixel position
function state_one.get_space(px, py)
    return Hex.at_pos(
        state_one.camera.px + px,
        state_one.camera.py + py,
        HS
    )
end

-- create a path
function state_one.path_init(dst)
    assert(_state.hero.space)
    assert(dst)
    local valid_f = function (space)
        return _state.map.visited[space] and game.space_stand(space)
    end
    state_one.path = Path.astar({ _state.hero.space }, dst, valid_f)
    if state_one.path then
        state_one.path_set = List.set(state_one.path)
    else
        state_one.path_deinit()
    end
end

-- step, attack
function state_one.step(dx, dy)
    local space = game.get_space(
        _state.hero.space.x + dx, _state.hero.space.y + dy
    )
    if space then
        if game.space_stand(space) then
            if space.person then
                if space.person.faction ~= _state.hero.faction then
                    if game.person_can_attack(_state.hero) then
                        state_one.preact()
                        game.person_attack(_state.hero, space)
                        state_one.postact()
                    else
                        game.print("You can't attack.")
                        state_one.flush()
                    end
                else
                    if game.person_can_step(_state.hero) then 
                        state_one.preact()
                        game.person_transpose(_state.hero, space.person)
                        state_one.postact()
                    else
                        game.print("You can't step.")
                        state_one.flush()
                    end
                end
            else
                if game.person_can_step(_state.hero) then
                    state_one.preact()
                    game.person_step(_state.hero, space)
                    state_one.postact()
                else
                    game.print("You can't step.")
                    state_one.flush()
                end
            end
        end
    end
end

-- pass the turn
function state_one.rest()
    local str = "You wait."
    game.print(str)
    state_one.preact()
    game.person_rest(_state.hero)
    state_one.postact()
end

-- pick up an object
function state_one.pickup()
    local object = _state.hero.space.object
    if object and game.data(object).pickup then
        game.person_object_pickup(_state.hero, object)
    end
    state_one.process_map()
    state_one.flush()
end

function state_one.preact()
    state_one.store()
end

function state_one.store()
    state_one.store_fov()
    state_one.store_terrains()
    state_one.store_objects()
    state_one.store_state()
end

function state_one.store_terrains()
    state_one.terrains2 = state_one.terrains
end

function state_one.store_objects()
    state_one.objects2 = state_one.objects
end


function state_one.store_state()
    state_one.persons = {}
    state_one.person_prev = {}
    for _, person in ipairs(_state.map.persons) do
        if state_one.sense[person] then
            table.insert(state_one.persons, person)
            state_one.person_prev[person] = person.space
        end
    end
end

function state_one.store_fov()
    state_one.fov2 = state_one.fov
    state_one.check2 = state_one.check
end

function state_one.descend()
    local space = _state.hero.space
    if space.terrain.door then
        if space.terrain.door.n == 0 then
            if _state.hero.seed then
                state_victory.init()
                table.insert(states, state_victory)
            else
                game.print("You can't ascend.")
                state_one.flush()
            end
        else
            state_one.store()
            game.descend(space)
            state_one.process_map()
            state_one.flush()
            state_one.timer = 0
            state_one.animate = 0
        end
    end
end

-- end the turn
function state_one.postact()    
    game.rotate()
    
    state_one.process_map()

    if _state.hero.dead then
        state_one.die()
    else
        state_one.auto_pickup()
    end
    
    state_one.flush()

    state_one.records = List.copy(_state.records)
    _state.records = {}

    state_one.animations = {}
    state_one.push_animations()
    
    state_one.animate = 0
end

function state_one.flush()
    state_one.notes = List.copy(_state.notes)
    _state.notes = {}
end

function state_one.auto_pickup()
    local object = _state.hero.space.object
    if object then
        local proto = game.data(object)
        if  proto.pickup and
            not object.dropped and
            #_state.hero.objects <= OBJECT_LIMIT
        then
            game.person_object_pickup(_state.hero, object)
            state_one.process_map()
        end
    end
end

function state_one.die()
    game.person_exit(_state.hero)
    state_death.init()
    table.insert(states, state_death)
end

function state_one.push_animations()
    local damage = false
    for _, record in ipairs(state_one.records) do
        if record.name == "attack" then
            local animation = game.data_init("animation_attack")
            animation.space = record.space
            table.insert(state_one.animations, animation)
        elseif record.name == "damage" then
            local animation = game.data_init("animation_damage")
            table.insert(state_one.animations, animation)
        end
    end
    state_one.records = {}
end

-- process the map
function state_one.process_map()
    state_one.process_fov()
    state_one.process_terrains()
    state_one.process_objects()
    state_one.opponents = game.person_get_opponents(_state.hero)
    state_one.process_con_map()
    state_one.process_check_map()
end

-- process the field of vision
function state_one.process_fov()
    state_one.fov = {}
    state_one.sense = {}
    for _, friend in ipairs(_state.hero.friends) do
        for _, space in ipairs(_state.map.spaces) do
            if  not state_one.fov[space] and
                game.person_space_sense(friend, space)
            then
                _state.map.visited[space] = true
                state_one.fov[space] = true
                if  space.person and
                    game.person_sense(_state.hero, space.person)
                then
                    state_one.sense[space.person] = true
                end
                if  space.object and
                    game.person_sense(_state.hero, space.object)
                then
                    state_one.sense[space.object] = true
                end
            end
        end
    end
end

function state_one.process_terrains()
    state_one.terrains = {}
    for _, terrain in ipairs(_state.map.terrains) do
        if _state.map.visited[terrain.space] then
            state_one.terrains[terrain.space] = terrain
        end
    end
end

function state_one.process_objects()
    state_one.objects = {}
    for _, object in ipairs(_state.map.objects) do
        if state_one.sense[object] then
            state_one.objects[object.space] = object
        end
    end
end

-- process perception ranges
function state_one.process_con_map()
    state_one.perception = {}
    local f = function (person)
        return
            state_one.sense[person] and
            not game.person_sense(person, _state.hero) and
            person.faction ~= _state.hero.faction
    end
    local persons = List.filter(_state.map.persons, f)
    for _, person in ipairs(persons) do
        local dist = game.person_person_per_dist(person, _state.hero)
        local spaces = Hex.range(person.space, dist)
        for _, space in ipairs(spaces) do
            if  _state.map.visited[space] and
                game.person_space_sense(person, space)
            then
                state_one.perception[space] = true
            end
        end
    end
end

-- process enemy attack ranges
function state_one.process_check_map()
    state_one.check = {}
    local opponents = game.person_get_opponents(_state.hero)
    local f = function (opponent)
        return state_one.sense[opponent]
    end
    opponents = List.filter(opponents, f)
    local f = function (space)
        return
            game.space_stand(space) and
            _state.map.visited[space]
    end
    local spaces = List.filter(_state.map.spaces, f)
    for _, opponent in ipairs(opponents) do
        for _, space in ipairs(spaces) do
            if game.person_space_check(opponent, space) then
                state_one.check[space] = true
            end
        end
    end
end

function state_one.update(t)
    state_one.timer = state_one.timer + t
    state_one.animate = state_one.animate + t / ANIMATE_LEN
end

function state_one.draw()
    local highlight = function (space, bcolor, color, character)
        -- path
        if state_one.mouse and state_one.path_set[space] then
            bcolor = { bcolor[1] + 32, bcolor[2] + 32, bcolor[3] + 32 }
            color = { color[1] + 32, color[2] + 32, color[3] + 32 }
        end
        -- perception range
        if state_one.perception[space] then
            bcolor = { bcolor[1], bcolor[2] + 64, bcolor[3] }
            color = { color[1], color[2] + 64, color[3] }
        end
        -- attack range
        if state_one.check[space] then
            bcolor = { bcolor[1] + 64, bcolor[2], bcolor[3] }
            color = { color[1] + 64, color[2], color[3] }
        end
        -- person destinations
        for _, person in ipairs(_state.map.persons) do
            if person.dsts then
                if List.contains(person.dsts, space) then
                    bcolor = { bcolor[1] + 64, bcolor[2], bcolor[3] }
                end
            end
        end
        return bcolor, color, character
    end
    -- state_one.set_camera()
    state_one.draw_map(highlight)
    state_one.draw_notes()
    state_one.draw_sidebar()
end

function state_one.set_camera()
    if state_one.animate < 1 then
        local prev = state_one.person_prev[_state.hero]
        if prev then
            local ax, ay = Hex.pos(prev, HS)
            local bx, by = Hex.pos(_state.hero.space, HS)
            local px = glue.lerp(ax, bx, state_one.animate)
            local py = glue.lerp(ay, by, state_one.animate)
            state_one.camera = { px = px - 480, py = py - 360 }
        else
            local px, py = Hex.pos(_state.hero.space, HS)
            state_one.camera = { px = px - 480, py = py - 360 }
        end
    else
        local px, py = Hex.pos(_state.hero.space, HS)
        state_one.camera = { px = px - 480, py = py - 360 }
    end
end

function state_one.draw_map(highlight)
    state_one.draw_terrains()
    state_one.draw_fov()
    state_one.draw_check()
    state_one.draw_objects()
    state_one.draw_persons()
    state_one.draw_animations()
end

-- draw terrains
function state_one.draw_terrains()
    if state_one.animate < 1 then
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = state_one.terrains[space]
            local prev = state_one.terrains2[space]
            if curr and curr == prev then
                local proto = game.data(curr)
                local bc = proto.bcolor
                local c = proto.color
                local s = proto.sprite
                abstraction.set_color(bc)
                state_one.draw_hex(px, py)
                abstraction.set_color(c)
                abstraction.draw_sprite(s, px - 8, py - 12)
            else
                if curr then
                    local proto = game.data(curr)
                    local bc = List.copy(proto.bcolor)
                    local c = List.copy(proto.color)
                    local s = proto.sprite
                    bc[4] = glue.lerp(0, 255, state_one.animate)
                    c[4] = glue.lerp(0, 255, state_one.animate)
                    abstraction.set_color(bc)
                    state_one.draw_hex(px, py)
                    abstraction.set_color(c)
                    abstraction.draw_sprite(s, px - 8, py - 12)
                end
                if prev then
                    print("hello")
                    local proto = game.data(prev)
                    local bc = List.copy(proto.bcolor)
                    local c = List.copy(proto.color)
                    local s = proto.sprite
                    bc[4] = glue.lerp(255, 0, state_one.animate)
                    c[4] = glue.lerp(255, 0, state_one.animate)
                    abstraction.set_color(bc)
                    state_one.draw_hex(px, py)
                    abstraction.set_color(c)
                    abstraction.draw_sprite(s, px - 8, py - 12)
                end
            end
        end
    else
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = state_one.terrains[space]
            if curr then
                local proto = game.data(curr)
                local bc = proto.bcolor
                local c = proto.color
                local s = proto.sprite
                abstraction.set_color(bc)
                state_one.draw_hex(px, py)
                abstraction.set_color(c)
                abstraction.draw_sprite(s, px - 8, py - 12)
            end
        end
    end
end

function state_one.draw_fov()
    if state_one.animate < 1 then
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = not state_one.fov[space]
            local prev = not state_one.fov2[space]
            if curr and prev then
                abstraction.set_color(color_constants.fov)
                state_one.draw_hex(px, py)
            else
                if curr then
                    local c = List.copy(color_constants.fov)
                    c[4] = glue.lerp(0, 127, state_one.animate)
                    abstraction.set_color(c)
                    state_one.draw_hex(px, py)
                end
                if prev then
                    local c = List.copy(color_constants.fov)
                    c[4] = glue.lerp(127, 0, state_one.animate)
                    abstraction.set_color(c)
                    state_one.draw_hex(px, py)
                end
            end
        end
    else
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = not state_one.fov[space]
            if curr then
                abstraction.set_color(color_constants.fov)
                state_one.draw_hex(px, py)
            end
        end
    end
end

function state_one.draw_check()
    if state_one.animate < 1 then
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = state_one.check[space]
            local prev = state_one.check2[space]
            if curr and prev then
                abstraction.set_color(color_constants.check)
                state_one.draw_hex(px, py)
            else
                if curr then
                    local c = List.copy(color_constants.check)
                    c[4] = glue.lerp(0, 127, state_one.animate)
                    abstraction.set_color(c)
                    state_one.draw_hex(px, py)
                end
                if prev then
                    local c = List.copy(color_constants.check)
                    c[4] = glue.lerp(127, 0, state_one.animate)
                    abstraction.set_color(c)
                    state_one.draw_hex(px, py)
                end
            end
        end
    else
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = state_one.check[space]
            if curr then
                abstraction.set_color(color_constants.check)
                state_one.draw_hex(px, py)
            end
        end
    end
end

function state_one.draw_objects()
    if state_one.animate < 1 then
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = state_one.objects[space]
            local prev = state_one.objects2[space]
            if curr and curr == prev then
                local proto = game.data(curr)
                local c = proto.color
                local s = proto.sprite
                abstraction.set_color(c)
                abstraction.draw_sprite(s, px - 8, py - 12)
            else
                if curr then
                    local proto = game.data(curr)
                    local c = List.copy(proto.color)
                    local s = proto.sprite
                    c[4] = glue.lerp(0, 255, state_one.animate)
                    abstraction.set_color(c)
                    abstraction.draw_sprite(s, px - 8, py - 12)
                end
                if prev then
                    local proto = game.data(prev)
                    local c = List.copy(proto.color)
                    local s = proto.sprite
                    c[4] = glue.lerp(255, 0, state_one.animate)
                    abstraction.set_color(c)
                    abstraction.draw_sprite(s, px - 8, py - 12)
                end
            end
        end
    else
        for _, space in ipairs(_state.map.spaces) do
            local px, py = state_one.get_px(space)
            local curr = state_one.objects[space]
            if curr then
                local proto = game.data(curr)
                local c = proto.color
                local s = proto.sprite
                abstraction.set_color(c)
                abstraction.draw_sprite(s, px - 8, py - 12)
            end
        end
    end
end

function state_one.draw_objectsasdf()
    if state_one.animate < 1 then
        local objects = List.filter(
            _state.map.objects,
            function (object) return state_one.sense[object] end
        )
        for _, object in ipairs(objects) do
            local proto = game.data(object)
            local s = proto.sprite
            local prev = state_one.object_prev[object]
            if prev then
                abstraction.set_color(proto.color)
                local ax, ay = state_one.get_px(prev)
                local bx, by = state_one.get_px(object.space)
                local px = glue.lerp(ax, bx, state_one.animate)
                local py = glue.lerp(ay, by, state_one.animate)
                abstraction.draw(
                    sprites[s.file].sheet,
                    sprites[s.file][s.x][s.y],
                    px - 8, py - 12
                )
            else
                local c = List.copy(proto.color)
                c[4] = glue.lerp(0, 255, state_one.animate)
                abstraction.set_color(c)
                local px, py = state_one.get_px(object.space)
                abstraction.draw(
                    sprites[s.file].sheet,
                    sprites[s.file][s.x][s.y],
                    px - 8, py - 12
                )
            end
        end
        local objects = List.filter(
            state_one.objects,
            function (object)
                return not object.space or not state_one.sense[object]
            end
        )
        for _, object in ipairs(objects) do
            local proto = game.data(object)
            local c = List.copy(proto.color)
            local s = proto.sprite
            local prev = state_one.object_prev[object]
            c[4] = glue.lerp(255, 0, state_one.animate)
            abstraction.set_color(c)
            local px, py = state_one.get_px(prev)
            abstraction.draw(
                sprites[s.file].sheet,
                sprites[s.file][s.x][s.y],
                px - 8, py - 12
            )
        end
    else
        local objects = List.filter(
            _state.map.objects,
            function (object) return state_one.sense[object] end
        )
        for _, object in ipairs(objects) do
            local proto = game.data(object)
            local s = proto.sprite
            abstraction.set_color(proto.color)
            local px, py = state_one.get_px(object.space)
            abstraction.draw(
                sprites[s.file].sheet,
                sprites[s.file][s.x][s.y],
                px - 8, py - 12
            )
        end
    end
end

function state_one.draw_persons()
    if state_one.animate < 1 then
        local persons = List.filter(
            _state.map.persons,
            function (person) return state_one.sense[person] end
        )
        for _, person in ipairs(persons) do
            local proto = game.data(person)
            local s = proto.sprite
            local prev = state_one.person_prev[person]
            if prev then
                abstraction.set_color(proto.color)
                local ax, ay = state_one.get_px(prev)
                local bx, by = state_one.get_px(person.space)
                local px = glue.lerp(ax, bx, state_one.animate)
                local py = glue.lerp(ay, by, state_one.animate)
                abstraction.draw(
                    sprites[s.file].sheet,
                    sprites[s.file][s.x][s.y],
                    px - 8, py - 12
                )
            else
                local c = List.copy(proto.color)
                c[4] = glue.lerp(0, 255, state_one.animate)
                abstraction.set_color(c)
                local px, py = state_one.get_px(person.space)
                abstraction.draw(
                    sprites[s.file].sheet,
                    sprites[s.file][s.x][s.y],
                    px - 8, py - 12
                )
            end
        end
        local persons = List.filter(
            state_one.persons,
            function (person)
                return not person.space or not state_one.sense[person]
            end
        )
        for _, person in ipairs(persons) do
            local proto = game.data(person)
            local c = List.copy(proto.color)
            local s = proto.sprite
            local prev = state_one.person_prev[person]
            c[4] = glue.lerp(255, 0, state_one.animate)
            abstraction.set_color(c)
            local px, py = state_one.get_px(prev)
            abstraction.draw(
                sprites[s.file].sheet,
                sprites[s.file][s.x][s.y],
                px - 8, py - 12
            )
        end
    else
        local persons = List.filter(
            _state.map.persons,
            function (person) return state_one.sense[person] end
        )
        for _, person in ipairs(persons) do
            local proto = game.data(person)
            local s = proto.sprite
            abstraction.set_color(proto.color)
            local px, py = state_one.get_px(person.space)
            abstraction.draw(
                sprites[s.file].sheet,
                sprites[s.file][s.x][s.y],
                px - 8, py - 12
            )
        end
    end
end

function state_one.get_px(space)
    local px, py = Hex.pos(space, HS)
    px = px - state_one.camera.px
    py = py - state_one.camera.py
    return px, py
end

function state_one.draw_animations()
    if state_one.animate < 1 then
        for _, animation in ipairs(state_one.animations) do
            local proto = game.data(animation)
            proto.draw(animation)
        end
    end
end

-- draw the map
--[[
function state_one.draw_map(highlightF)
    local anim = state_one.timer % 1 <= 0.5 and 1 or 2
    love.graphics.setFont(fonts.monospace)
    for _, space in ipairs(_state.map.spaces) do        
        local px, py = Hex.pos(space, HS)
        px = px - state_one.camera.px
        py = py - state_one.camera.py
        local bcolor, color, character, sprite, circle =
            state_one.space_representation(space, anim)
        if highlightF then
            bcolor, color, character, circle =
                highlightF(space, bcolor, color, character)
        end
        love.graphics.setColor(bcolor)
        state_one.draw_hex(px, py)
        if circle then
            state_one.draw_hex_outline(px, py)
        end
        if state_one.sprites and sprite then
            love.graphics.setColor(color)
            love.graphics.draw(
                sprites[sprite.file].sheet,
                sprites[sprite.file][sprite.x][sprite.y],
                px - 8, py - 12
            )
        else
            love.graphics.setColor(color)
            local dx = px - 6
            local dy = py - 12
            abstraction.print(character, dx, dy)
        end
    end
end
]]

-- get the representation of a space for printing
--[[
function state_one.space_representation(space, anim)
    local bcolor, color, character, sprite
    if _state.map.visited[space] then
        bcolor = game.data(space.terrain).bcolor
        if game.data(space.terrain).water then
            local v = love.math.noise(
                state_one.timer * 0.5 + space.x * 0.5,
                space.y * 0.5
            ) * 2 - 1
            bcolor = {
                bcolor[1] + 16 * v,
                bcolor[2] + 16 * v,
                bcolor[3] + 16 * v
            }
        end
        color = game.data(space.terrain).color
        character = game.data(space.terrain).character
        sprite =
            anim == 2 and game.data(space.terrain).sprite2 or
            game.data(space.terrain).sprite
        if state_one.fov[space] then
            if  space.person and
                state_one.sense[space.person]
            then
                color = game.data(space.person).color
                character = game.data(space.person).character
                sprite =
                    anim == 2 and game.data(space.person).sprite2 or
                    game.data(space.person).sprite
            elseif
            if
                space.object and
                state_one.sense[space.object]
            then
                color = game.data(space.object).color
                character = game.data(space.object).character
                sprite = game.data(space.object).sprite
            end
        else
            bcolor = { bcolor[1] * .5, bcolor[2] * .5, bcolor[3] * .5 }
            color = { color[1] * .5, color[2] * .5, color[3] * .5 }
        end
    else
        bcolor = _database.terrain_question.bcolor
        color = _database.terrain_question.color
        character = _database.terrain_question.character
        sprite = _database.terrain_question.sprite
    end
    return bcolor, color, character, sprite
end
]]

-- draw a hex
function state_one.draw_hex(px, py)
    love.graphics.polygon(
        "fill",
        px + HS * math.cos(math.pi * 1/6),
        py + HS * math.sin(math.pi * 1/6),
        px + HS * math.cos(math.pi * 1/2),
        py + HS * math.sin(math.pi * 1/2),
        px + HS * math.cos(math.pi * 5/6),
        py + HS * math.sin(math.pi * 5/6),
        px + HS * math.cos(math.pi * 7/6),
        py + HS * math.sin(math.pi * 7/6),
        px + HS * math.cos(math.pi * 3/2),
        py + HS * math.sin(math.pi * 3/2),
        px + HS * math.cos(math.pi * 11/6),
        py + HS * math.sin(math.pi * 11/6)
    )
    --[[
    love.graphics.setLineWidth(2)
    love.graphics.polygon(
        "line",
        px + (HS - 1) * math.cos(math.pi * 1/6),
        py + (HS - 1) * math.sin(math.pi * 1/6),
        px + (HS - 1) * math.cos(math.pi * 1/2),
        py + (HS - 1) * math.sin(math.pi * 1/2),
        px + (HS - 1) * math.cos(math.pi * 5/6),
        py + (HS - 1) * math.sin(math.pi * 5/6),
        px + (HS - 1) * math.cos(math.pi * 7/6),
        py + (HS - 1) * math.sin(math.pi * 7/6),
        px + (HS - 1) * math.cos(math.pi * 3/2),
        py + (HS - 1) * math.sin(math.pi * 3/2),
        px + (HS - 1) * math.cos(math.pi * 11/6),
        py + (HS - 1) * math.sin(math.pi * 11/6)
    )
    love.graphics.setLineWidth(1)
    ]]
end

--[[
function state_one.draw_hex(px, py)
    love.graphics.polygon(
        "fill",
        px + (HS - 1) * math.cos(math.pi * 0/6),
        py + (HS - 1) * math.sin(math.pi * 0/6),
        px + (HS - 1) * math.cos(math.pi * 2/6),
        py + (HS - 1) * math.sin(math.pi * 2/6),
        px + (HS - 1) * math.cos(math.pi * 4/6),
        py + (HS - 1) * math.sin(math.pi * 4/6),
        px + (HS - 1) * math.cos(math.pi * 6/6),
        py + (HS - 1) * math.sin(math.pi * 6/6),
        px + (HS - 1) * math.cos(math.pi * 8/6),
        py + (HS - 1) * math.sin(math.pi * 8/6),
        px + (HS - 1) * math.cos(math.pi * 10/6),
        py + (HS - 1) * math.sin(math.pi * 10/6)
    )
    love.graphics.setLineWidth(2)
    love.graphics.polygon(
        "line",
        px + (HS - 1) * math.cos(math.pi * 0/6),
        py + (HS - 1) * math.sin(math.pi * 0/6),
        px + (HS - 1) * math.cos(math.pi * 2/6),
        py + (HS - 1) * math.sin(math.pi * 2/6),
        px + (HS - 1) * math.cos(math.pi * 4/6),
        py + (HS - 1) * math.sin(math.pi * 4/6),
        px + (HS - 1) * math.cos(math.pi * 6/6),
        py + (HS - 1) * math.sin(math.pi * 6/6),
        px + (HS - 1) * math.cos(math.pi * 8/6),
        py + (HS - 1) * math.sin(math.pi * 8/6),
        px + (HS - 1) * math.cos(math.pi * 10/6),
        py + (HS - 1) * math.sin(math.pi * 10/6)
    )
    love.graphics.setLineWidth(1)
end
]]
-- draw a hex outline

function state_one.draw_hex_outline(px, py)
    love.graphics.setColor(color_constants.base3)
    love.graphics.setLineWidth(2)
    love.graphics.polygon(
        "line",
        px + (HS - 2) * math.cos(math.pi * 1/6),
        py + (HS - 2) * math.sin(math.pi * 1/6),
        px + (HS - 2) * math.cos(math.pi * 1/2),
        py + (HS - 2) * math.sin(math.pi * 1/2),
        px + (HS - 2) * math.cos(math.pi * 5/6),
        py + (HS - 2) * math.sin(math.pi * 5/6),
        px + (HS - 2) * math.cos(math.pi * 7/6),
        py + (HS - 2) * math.sin(math.pi * 7/6),
        px + (HS - 2) * math.cos(math.pi * 3/2),
        py + (HS - 2) * math.sin(math.pi * 3/2),
        px + (HS - 2) * math.cos(math.pi * 11/6),
        py + (HS - 2) * math.sin(math.pi * 11/6)
    )
end

--[[
function state_one.draw_hex_outline(px, py)
    love.graphics.setColor(color_constants.base3)
    love.graphics.setLineWidth(2)
    love.graphics.polygon(
        "line",
        px + (HS - 1) * math.cos(math.pi * 0/6),
        py + (HS - 1) * math.sin(math.pi * 0/6),
        px + (HS - 1) * math.cos(math.pi * 2/6),
        py + (HS - 1) * math.sin(math.pi * 2/6),
        px + (HS - 1) * math.cos(math.pi * 4/6),
        py + (HS - 1) * math.sin(math.pi * 4/6),
        px + (HS - 1) * math.cos(math.pi * 6/6),
        py + (HS - 1) * math.sin(math.pi * 6/6),
        px + (HS - 1) * math.cos(math.pi * 8/6),
        py + (HS - 1) * math.sin(math.pi * 8/6),
        px + (HS - 1) * math.cos(math.pi * 10/6),
        py + (HS - 1) * math.sin(math.pi * 10/6)

    )
end
]]

-- draw the game messages
function state_one.draw_notes()
    love.graphics.setFont(fonts.monospace)
    if next(state_one.notes) then
        local concat = table.concat(state_one.notes, " ")
        local _, strs = fonts.monospace:getWrap(concat, 960 - 24)
        for i, str in ipairs(strs) do
            local px = 12
            local py = 12 + (i - 1) * fonts.monospace:getHeight()
            state_one.print(
                color_constants.highlight,
                color_constants.base3,
                str,
                px,
                py
            )
        end
    end
end

-- draw the sidebar
function state_one.draw_sidebar()
    love.graphics.setFont(fonts.monospace)
    
    local px = SIDEBAR_X + 12
    local py = 12
    local w = abstraction.font_w(fonts.monospace)
    local h = abstraction.font_h(fonts.monospace)

    -- hearts
    love.graphics.setColor(color_constants.red)
    for i = 1, _state.hero.hp - _state.hero.damage do
        if state_one.sprites then
            love.graphics.draw(
                sprites["resource/sprite/Interface.png"].sheet,
                sprites["resource/sprite/Interface.png"][3][3],
                px - 2, py
            )
        else
            abstraction.print("❤", px, py)
        end
        px = px + 2 * w
    end
    for i = _state.hero.hp - _state.hero.damage + 1, _state.hero.hp do
        if state_one.sprites then
            love.graphics.draw(
                sprites["resource/sprite/Interface.png"].sheet,
                sprites["resource/sprite/Interface.png"][4][3],
                px - 2, py
            )
        else
            abstraction.print("_", px, py)
        end
        px = px + 2 * w
    end
    px = SIDEBAR_X + 12
    py = py + 1 * h

    love.graphics.setColor(color_constants.base1)

    -- equipment
    if _state.hero.hand then
        local object = _state.hero.hand
        local sprite = game.data(object).sprite
        local character = game.data(object).character
        local str = string.format(
            "  %s",
            state_one.get_object_str(object)
        )
        abstraction.print(str, px, py)
        if state_one.sprites and sprite then
            love.graphics.draw(
                sprites[sprite.file].sheet,
                sprites[sprite.file][sprite.x][sprite.y],
                px - 2, py
            )
        elseif character then
            abstraction.print(character, px, py)
        end
        py = py + 1 * h
    end
    if _state.hero.ring then
        local object = _state.hero.ring
        local sprite = game.data(object).sprite
        local character = game.data(object).character
        local str = string.format(
            "  %s",
            state_one.get_object_str(object)
        )
        abstraction.print(str, px, py)
        if state_one.sprites and sprite then
            love.graphics.draw(
                sprites[sprite.file].sheet,
                sprites[sprite.file][sprite.x][sprite.y],
                px - 2, py
            )
        elseif character then
            abstraction.print(character, px, py)
        end
        py = py + 1 * h
    end


    -- statuses
    local f = function (status)
        return not game.data(status).hide
    end
    local statuss = List.filter(_state.hero.statuss, f)
    for i, status in ipairs(statuss) do
        local sprite = game.data(status).sprite
        local character = game.data(status).character
        local str = string.format("  %s", game.data(status).name)
        if status.counters then
            str = string.format("%s (%d turns)", str, status.counters)
        end
        abstraction.print(str, px, py)
        if state_one.sprites and sprite then
            love.graphics.draw(
                sprites[sprite.file].sheet,
                sprites[sprite.file][sprite.x][sprite.y],
                px - 2, py
            )
        elseif character then
            abstraction.print(character, px, py)
        end
        py = py + 1 * h
    end
    py = py + 1 * h


    -- state_one.draw_sidebar_objects()
    
    -- opponents
    --[[
    local opponents = List.concat(
        state_one.opponents,
        game.person_get_objects(_state.hero)
    )
    for i, opponent in ipairs(opponents) do
        local sprite = game.data(opponent).sprite
        local character = game.data(opponent).character
        local str = string.format("  %s", game.data(opponent).name)
        abstraction.print(str, px, py)
        if state_one.sprites and sprite then
            love.graphics.draw(
                sprites[sprite.file].sheet,
                sprites[sprite.file][sprite.x][sprite.y],
                px - 2, py
            )
        elseif character then
            abstraction.print(character, px, py)
        end
        py = py + 1 * h
    end
    py = py + 1 * h
    ]]

    -- turn
    --[[
    local str = string.format("turn %d", _state.turn)
    abstraction.print(str, px, py)
    py = py + 1 * h
    ]]--

    -- open rucksack
    --[[
    px = 960 + 12
    py = 720 - 12 - h
    local str = "[i]   open rucksack"
    local cpx, cpy = love.mouse.getPosition()
    local bcolor, color
    if states[#states] == state_one then
        if  px <= cpx and cpx < px + abstraction.font_w(fonts.monospace, str) and
            py <= cpy and cpy < py + h
        then
            bcolor = color_constants.base3
            color = color_constants.highlight
        else
            bcolor = color_constants.highlight
            color = color_constants.base3
        end
    else
        bcolor = color_constants.highlight
        color = color_constants.base01
    end

    state_one.print(bcolor, color, str, px, py)
    local sprite = { file = "resource/sprite/Items.png", x = 14, y = 3 }
    local character = "!"
    if state_one.sprites and sprite then
        love.graphics.draw(
            sprites[sprite.file].sheet,
            sprites[sprite.file][sprite.x][sprite.y],
            px + 4*w - 2, py
        )
    elseif character then
        abstraction.print(character, px + 4*w, py)
    end
    ]]

end

function state_one.draw_sidebar_objects()
    local px = SIDEBAR_X + 12

    for i, object in ipairs(_state.hero.objects) do
        local py = 200 + 24 * (i - 1)
        local str = string.format(
            "[%s]   %s",
            LETTERS[i],
            game.data(object).name
        )
        abstraction.print(str, px, py)
        local sprite = game.data(object).sprite
        abstraction.draw(
            sprites[sprite.file].sheet,
            sprites[sprite.file][sprite.x][sprite.y],
            px + 4 * 12,
            py
        )
    end
end

-- print highlighted text
function state_one.print(bcolor, color, str, px, py)
    local font = love.graphics.getFont()
    local w = abstraction.font_w(font, str)
    local h = abstraction.font_h(font)
    love.graphics.setColor(bcolor)
    love.graphics.rectangle("fill", px, py, w, h)
    love.graphics.setColor(color)
    abstraction.print(str, px, py)
end

