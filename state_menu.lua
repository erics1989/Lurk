
-- state for menus

LETTERS = {
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
    "k", "l", "m", "n", "o", "p", "q", "r", "s", "t",
    "u", "v", "w", "x", "y", "z"
}

LETTERS_R = {}

for i, character in ipairs(LETTERS) do
    LETTERS_R[character] = i
end

state_menu = {}

-- "[escape] return" option
state_menu.option_escape = {
    k = "escape",
    valid = true,
    sprite = { file = "resource/sprite/Interface.png", x = 0, y = 3 },
    character = "x",
    str = "return",
    execute = function ()
        -- pass
    end
}

function state_menu.init(data)
    state_menu.sprite = data.sprite
    state_menu.character = data.character
    state_menu.header = data.header
    state_menu.paragraph = data.paragraph
    state_menu.options = data.options
    -- add escape option
    table.insert(data.options, state_menu.option_escape)
end

function state_menu.deinit()
    state_menu.header = nil
    state_menu.options = nil
end

function state_menu.keypressed(k)
    state_one.mouse = false
    local i = LETTERS_R[k]
    local option = state_menu.options[i]
    if option and option.valid then
        state_menu.execute(option)
    elseif k == "escape" then
        state_menu.deinit()
        table.remove(states)
    elseif not state_menu.options[1] then
        state_menu.deinit()
        table.remove(states)
    end
end

function state_menu.mousepressed(px, py, b)
    state_one.mouse = true
    if b == 1 then
        if state_menu.cursor then
            local option = state_menu.options[state_menu.cursor]
            state_menu.execute(option)
        elseif not state_menu.options[1] then
            state_menu.deinit()
            table.remove(states)
        end
    elseif b == 2 then
        state_menu.deinit()
        table.remove(states)
    end
end

function state_menu.mousemoved(cpx, cpy, dpx, dpy)
    state_one.mouse = true
end

-- execute the option
function state_menu.execute(option)
    state_menu.deinit()
    table.remove(states)
    option.execute()
end

function state_menu.update(t)
    local cpx, cpy = love.mouse.getPosition()
    local h = abstraction.font_h(fonts.monospace)
    local px = 12
    local py = 12 + 2 * h
    if state_menu.paragraph then
        local _, strs = fonts.monospace:getWrap(
            state_menu.paragraph,
            960 - 24
        )
        py = py + h * (#strs + 1)
    end 
    -- store option under the cursor
    state_menu.cursor = nil
    for i, option in ipairs(state_menu.options) do
        local str = string.format(
            "[%s]   %s",
            option.k or LETTERS[i],
            option.str
        )
        local w = abstraction.font_w(fonts.monospace, str)
        if  option.valid and
            px <= cpx and cpx < px + w and
            py <= cpy and cpy < py + h
        then
            state_menu.cursor = i
        end
        py = py + h
    end
    state_one.update(t)
end

function state_menu.draw()
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
        return bcolor, color, character
    end
    state_one.draw_map()

    local w = abstraction.font_w(fonts.monospace)
    local h = abstraction.font_h(fonts.monospace)
    local px = 12
    local py = 12
    love.graphics.setFont(fonts.monospace)

    -- draw header
    local str = string.format("  %s", state_menu.header)
    state_one.print(
        color_constants.highlight,
        color_constants.base3,
        str,
        px,
        py
    )
    local sprite, character = state_menu.sprite, state_menu.character
    if state_one.sprites and sprite then
        love.graphics.draw(
            sprites[sprite.file].sheet,
            sprites[sprite.file][sprite.x][sprite.y],
            px + math.floor((w - 16) / 2),
            py + math.floor((h - 24) / 2)
        )
    elseif state_menu.character then
        abstraction.print(state_menu.character, px, py)
    end
    py = py + 2 * h

    -- draw paragraph
    if state_menu.paragraph then
        local _, strs = fonts.monospace:getWrap(
            state_menu.paragraph,
            960 - 24
        )
        for i, str in ipairs(strs) do
            state_one.print(
                color_constants.highlight,
                color_constants.base1,
                str,
                px,
                py
            )
            py = py + h
        end
        py = py + h
    end 

    -- draw options
    for i, option in ipairs(state_menu.options) do
        local bcolor, color, str
        if option.valid then
            if state_menu.cursor and i == state_menu.cursor then
                bcolor = color_constants.base3
                color = color_constants.base00
            else
                bcolor = color_constants.highlight
                color = color_constants.base3
            end
        else
            bcolor = color_constants.highlight
            color = color_constants.base01
        end
        local str = string.format(
            "[%s]   %s",
            option.k or LETTERS[i],
            option.str
        )
        state_one.print(bcolor, color, str, px, py)
        local offset = abstraction.font_w(
            fonts.monospace,
            string.format("[%s] ", option.k or " ")
        )
        
        love.graphics.setColor(color)
        local sprite, character = option.sprite, option.character
        if state_one.sprites and sprite then
            love.graphics.draw(
                sprites[sprite.file].sheet,
                sprites[sprite.file][sprite.x][sprite.y],
                px + offset + math.floor((w - 16) / 2),
                py + math.floor((h - 24) / 2)
            )
        elseif character then
            abstraction.print(character, px + offset, py)
        end
        py = py + h
    end
    state_one.draw_sidebar()
end

