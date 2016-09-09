
-- victory screen state

state_victory = {}

function state_victory.init()
end

function state_victory.deinit()
end

function state_victory.keypressed(k)

end

function state_victory.mousepressed(px, py, b)

end

function state_victory.quit()
    love.event.quit()
end

function state_victory.draw()
    love.graphics.setFont(fonts.header)
    love.graphics.setColor(131, 148, 150)
    local str = "Victory!"
    love.graphics.print(
        str,
        1280 / 2 - fonts.header:getWidth(str) / 2,
        720 / 3 - fonts.header:getHeight() / 2
    )
end

