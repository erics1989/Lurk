
_database.animation_attack = {
    sprites = {
        { file = "resource/sprite/FX_General.png", x = 15, y = 0 },
        { file = "resource/sprite/FX_General.png", x = 16, y = 0 },
        { file = "resource/sprite/FX_General.png", x = 17, y = 0 },
    },
    draw = function (animation)
        local proto = game.data(animation)
        local i = math.ceil(state_one.animate * #proto.sprites)
        local sprite = proto.sprites[i]
        local px, py = state_one.get_px(animation.space)
        abstraction.set_color(color_constants.base3)
        abstraction.draw_sprite(sprite, px - 8, py - 12)
    end
}

_database.animation_damage = {
    draw = function (animation)
        local c = List.copy(color_constants.red)
        if state_one.animate < 0.5 then
            local t = state_one.animate * 2
            c[4] = glue.lerp(0, 127, t)
        else
            local t = (state_one.animate - 0.5) * 2
            c[4] = glue.lerp(127, 0, t)
        end
        abstraction.set_color(c)
        abstraction.rect("fill", 0, 0, 1280, 720)
    end
}

