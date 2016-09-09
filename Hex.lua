
-- functions for hex grids

local Hex = {}

--

local function get_space(x, y, z)
    return game.get_space(x, y)
end

local function lerp(x1, x2, t)
    return x1 + (x2 - x1) * t
end

--

-- hex to pixel
function Hex.pos(space, size)
    assert(space)
    assert(size)
    local px = size * math.sqrt(3) * (space.x + space.y / 2)
    local py = size * 3/2 * space.y
    return px, py
end

-- pixel to hex
function Hex.at_pos(px, py, size)
    assert(px)
    assert(py)
    assert(size)
    local x = (px * math.sqrt(3)/3 - py / 3) / size
    local y = py * 2/3 / size
    return Hex.round(x, y)
end

-- distance
function Hex.dist(space1, space2)
    assert(space1)
    assert(space2)
    local dx = math.abs(space2.x - space1.x)
    local dy = math.abs(space2.y - space1.y)
    local dz = math.abs(space2.z - space1.z)
    return math.max(dx, dy, dz)
end

-- directions
Hex.directions = {
    { dx = -1, dy = 0 },
    { dx = -1, dy = 1 },
    { dx = 0, dy = -1 },
    { dx = 0, dy = 1 },
    { dx = 1, dy = -1 },
    { dx = 1, dy = 0 },
}

-- get adjacent hexes
function Hex.adjacent(space1)
    assert(space1)
    local spaces = {}
    for _, d in ipairs(Hex.directions) do
        local space2 = get_space(space1.x + d.dx, space1.y + d.dy)
        if space2 then
            table.insert(spaces, space2)
        end
    end
    return spaces
end

-- get hexes within a certain distance
function Hex.range(space, dist)
    local spaces = {}
    for dx = -dist, dist do
        for dy =
            math.max(-dist, -dx - dist),
            math.min(dist, -dx + dist)
        do
            table.insert(
                spaces,
                get_space(space.x + dx, space.y + dy)
            )
        end
    end
    return spaces
end

-- check if hexes lie on the same axis
function Hex.axis(space1, space2)
    return
        space1.x == space2.x or
        space1.y == space2.y or
        space1.z == space2.z
end

-- round decimals off x-y coordinates
function Hex.round(x, y)
    assert(x)
    assert(y)
    local z = 0 - x - y
    local rx = math.floor(x + 0.5)
    local ry = math.floor(y + 0.5)
    local rz = math.floor(z + 0.5)
    local dx = math.abs(rx - x)
    local dy = math.abs(ry - y)
    local dz = math.abs(rz - z)
    if dx > dy and dx > dz then
        rx = 0 - ry - rz
    elseif dy > dz then
        ry = 0 - rx - rz
    else
        rz = 0 - rx - ry
    end
    return get_space(rx, ry)
end

-- create a line of hexes w/ linear interpolation
function Hex.line(space1, space2)
    assert(space1)
    assert(space2)
    local dist = Hex.dist(space1, space2)
    local dx = space2.x - space1.x
    local dy = space2.y - space1.y
    local dz = space2.z - space1.z
    local diag = dx == dy or dy == dz or dz == dx
    local spaces = {}
    for i = 0, dist do
        local x = lerp(space1.x, space2.x, i / dist)
        local y = lerp(space1.y, space2.y, i / dist)
        if diag and i % 2 == 1 then
            table.insert(spaces, Hex.round(x - 0.1, y))
            table.insert(spaces, Hex.round(x + 0.1, y))
        else
            table.insert(spaces, Hex.round(x, y))
        end
    end
    return spaces
end

return Hex

