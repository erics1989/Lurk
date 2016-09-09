
-- title screen state

state_start = {}

function state_start.init()

end

function state_start.deinit()
end

function state_start.keypressed(k)
    state_start.game_init()
end

function state_start.mousepressed(px, py, b)
    state_start.game_init()
end

function state_start.game_init()
    game.init()
    state_one.init()
    table.insert(states, state_one)
end

function state_start.draw()
    love.graphics.setFont(fonts.header)
    love.graphics.setColor(131, 148, 150)
    local str = "Lurker"
    love.graphics.print(
        str,
        1280 / 2 - fonts.header:getWidth(str) / 2,
        720 / 3 - fonts.header:getHeight() / 2
    )
    love.graphics.setFont(fonts.monospace)
    local str = "(press any key to continue)"
    love.graphics.print(
        str,
        1280 / 2 - fonts.monospace:getWidth(str) / 2,
        720 * 2/3 - fonts.monospace:getHeight() / 2
    )
end

