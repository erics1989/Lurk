
binser = require("lib/binser")
inspect = require("lib/inspect")

List = require("List")
Path = require("Path")
Hex = require("Hex")
grammar = require("Grammar")
require("color_constants")
require("game")
require("generate")
require("branch")
require("encounter")
require("terrain")
require("person")
require("object")
require("status")
require("state_start")
require("state_one")
require("state_menu")
require("state_aim")
require("state_death")
require("state_victory")

FONT_HEADER = { file = "resource/font/Eczar-Regular.ttf", size = 200 }
FONT_MONOSPACE = { file = "resource/font/6x12.bdf", size = 12 }
--FONT_MONOSPACE = { file = "resource/font/Inconsolata.otf", size = 23 }
BOARD_SIZE = 12
SPRITES = {
    "resource/sprite/Avatar.png",
    "resource/sprite/FX_Blood.png",
    "resource/sprite/FX_General.png",
    "resource/sprite/Interface.png",
    "resource/sprite/Items.png",
    "resource/sprite/Monsters.png",
    "resource/sprite/Terrain.png",
    "resource/sprite/Terrain_Objects.png"
}

function love.load()
    love.window.setMode(1280, 720)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- resources
    init_fonts()
    init_sprites()

    -- state stack
    states = {}
    table.insert(states, state_start)
    state_start.init()
end

-- load fonts
function init_fonts()
    fonts = {}
    fonts.header = love.graphics.newFont(
        FONT_HEADER.file,
        FONT_HEADER.size
    )
    fonts.monospace = love.graphics.newFont(
        FONT_MONOSPACE.file,
        FONT_MONOSPACE.size
    )
    print(fonts.monospace:getWidth("@"))
    print(fonts.monospace:getHeight())
end

-- load and cut sprite sheets
function init_sprites()
    sprites = {}
    for _, file in ipairs(SPRITES) do
        local sheet = love.graphics.newImage(file)
        sheet:setFilter("nearest", "nearest")
        sprites[file] = {}
        sprites[file].sheet = sheet
        local w = sheet:getWidth()
        local h = sheet:getHeight()
        for x = 0, math.floor(w / 16) - 1 do
            sprites[file][x] = {}
            for y = 0, math.floor(h / 24) - 1 do
                sprites[file][x][y] = 
                    love.graphics.newQuad(x * 16, y * 24, 16, 24, w, h)
            end
        end
    end
end

function love.keypressed(_, k)
    local f = states[#states].keypressed
    if f then
        f(k)
    end
end

function love.mousepressed(px, py, b)
    local f = states[#states].mousepressed
    if f then
        f(px, py, b)
    end
end

function love.mousemoved(px, py, dpx, dpy)
    local f = states[#states].mousemoved
    if f then
        f(px, py, dpx, dpy)
    end
end

function love.update(t)
    local f = states[#states].update
    if f then
        f(t)
    end
end

function love.draw()
    local f = states[#states].draw
    if f then
        f()
    end
end

abstraction = {}

function abstraction.print(str, x, y)
    love.graphics.print(str, x, y, 0, 2, 2)
end

function abstraction.font_w(font, str)
    return font:getWidth(str or "a") * 2
end

function abstraction.font_h(font)
    return font:getHeight() * 2
end

