
-- game over state

state_death = {}

function state_death.init()
    
end

function state_death.deinit()
end

function state_death.keypressed(k)
    state_one.mouse = false
    state_death.restart()
end

function state_death.mousepressed(px, py, b)
    state_one.mouse = true
    state_death.restart()
end

function state_death.mousemoved(cpx, cpy, dpx, dpy)
    state_one.mouse = true
end

function state_death.restart()
    state_death.deinit()
    table.remove(states)
    state_one.deinit()
    table.remove(states)
end

function state_death.update(t)
    state_one.animate(t)
end

function state_death.draw()
    local highlight = function (space, bcolor, color, character)
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
        return bcolor, color, character
    end
    state_one.draw_map(highlight)
    state_one.draw_notes()
    state_one.draw_sidebar()
end

