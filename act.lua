
-- functions for person_act functions

function game.person_execute(person, dst_f, valid_f, dist_f)
    local f = dst_f(person.space)
    if f then
        f()
        return true
    else
        return game.person_step_to(person, dst_f, valid_f, dist_f)
    end
end

function game.person_step_to(person, dst_f, valid_f, dist_f)
    local path = Path.dijk({ person.space }, dst_f, valid_f, dist_f)
    if path then
        if path[2] then
            game.person_step(person, path[2])
        else
            game.person_rest(person)
        end
        return true
    end
end

function game.person_set_point_opponents(
    person, valid_f, dist_f, opponents
)
    assert(person.points)
    for _, opponent in ipairs(opponents) do
        local path = Path.astar(
            { person.space }, opponent.space, valid_f, dist_f
        )
        if path then
            person.points[opponent] = true
        end
    end
end

function game.person_set_point_rng(person, valid_f, dist_f)
    assert(person.points)
    local dist = Path.dist({ person.space }, valid_f, dist_f, 8)
    local f = function (space)
        local d = dist[space]
        return 0 < d and d < math.huge
    end
    local spaces = List.filter(_state.map.spaces, f)
    local space = spaces[game.rand2(#spaces)]
    person.points[space] = true
end

function game.person_step_to_points(person, valid_f, dist_f)
    assert(person.points)
    local dst_f = function (space)
        return person.points[space]
    end
    return game.person_step_to(person, dst_f, valid_f, dist_f)
end

function game.person_regroup(person, valid_f, dist_f)
    local friend1 = person.friends[1]
    local dst_f = function (space)
        return Hex.dist(space, friend.space) <= 1
    end
    return game.person_step_to(person, dst_f, valid_f, dist_f)
end

