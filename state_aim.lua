
-- state for choosing a target for a verb

state_aim = {}

function state_aim.init(verb, object)
    state_aim.verb = verb
    state_aim.object = object
    state_aim.cursor = _state.hero.space
    -- create a set of valid spaces
    state_aim.valid = {}
    local spaces = List.filter(
        _state.spaces,
        function (space)
            return
                state_one.fov[space] and
                verb.range(_state.hero, state_aim.object, space)

        end
    )
    for _, space in ipairs(spaces) do
        state_aim.valid[space] = true
    end
end

function state_aim.deinit()
    state_aim.verb = nil
    state_aim.object = nil
    state_aim.cursor = nil
    state_aim.valid = nil
end

function state_aim.keypressed(k)
    state_one.mouse = false
    -- step the cursor
    if k == "h" or k == "kp4" then state_aim.step(-1, 0)
    elseif k == "l" or k == "kp6" then state_aim.step(1, 0)
    elseif k == "k" or k == "kp8" then state_aim.step(0, -1)
    elseif k == "j" or k == "kp2" then state_aim.step(0, 1) 
    elseif k == "y" or k == "kp7" then state_aim.step(0, -1)
    elseif k == "n" or k == "kp3" then state_aim.step(0, 1)
    elseif k == "b" or k == "kp1" then state_aim.step(-1, 1)
    elseif k == "u" or k == "kp9" then state_aim.step(1, -1)
    -- execute the verb
    elseif k == "space" or k == "kp5" then
        local space = state_aim.cursor
        if space and state_aim.valid[space] then
            state_aim.execute(space)
        end
    -- cancel
    elseif k == "escape" then
        state_aim.deinit()
        table.remove(states)
    end
end

-- step the cursor
function state_aim.step(dx, dy)
    local dst = game.get_space(
        state_aim.cursor.x + dx,
        state_aim.cursor.y + dy
    )
    if dst then
        state_aim.cursor = dst
    end
end

function state_aim.mousepressed(cpx, cpy, b)
    state_one.mouse = true
    if b == 1 then
        -- execute the verb
        local space = Hex.at_pos(
            cpx + state_one.camera.px,
            cpy + state_one.camera.py, 
            HS
        )
        if space and state_aim.valid[space] then
            state_aim.execute(space)
        end
    elseif b == 2 then
        -- cancel
        state_aim.deinit()
        table.remove(states)
    end
end

function state_aim.mousemoved(px, py, dpx, dpy)
    state_one.mouse = true
    -- move the cursor
    local space = Hex.at_pos(
        px + state_one.camera.px,
        py + state_one.camera.py, 
        HS
    )
    if space then
        state_aim.cursor = space
    end
end

-- execute the verb
function state_aim.execute(space)
    local verb, object = state_aim.verb, state_aim.object
    state_aim.deinit()
    table.remove(states)
    verb.execute(_state.hero, object, space)
    state_one.postact()
end

function state_aim.update(t)
    state_one.animate(t)
end

function state_aim.draw()
    local f = function (space, bcolor, color, character)
        -- perception range
        if state_one.perception[space] then
            bcolor = { bcolor[1], bcolor[2] + 64, bcolor[3] }
            color = { color[1], color[2] + 64, color[3] }
        end
        -- attack range
        if state_one.threaten[space] then
            bcolor = { bcolor[1] + 64, bcolor[2], bcolor[3] }
            color = { color[1] + 64, color[2], color[3] }
        end
        -- valid targets
        if state_aim.valid[space] then
            bcolor = { bcolor[1] + 64, bcolor[2] + 64, bcolor[3] + 64 }
            color = { color[1] + 64, color[2] + 64, color[3] + 64}
        end
        -- cursor
        local circle = space == state_aim.cursor
        return bcolor, color, character, circle
    end
    state_one.draw_map(f)
    state_one.draw_sidebar()
end

