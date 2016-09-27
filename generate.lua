
-- functions for generating levels

-- cellular automata
-- use start_f to describe what spaces are alive or dead at the start
-- use process1_f on alive cells at the end
-- use process2_f on dead cells at the end
-- do n iterations
function automata(startF, process1F, process2F, n)
    assert(startF)
    n = n or 1
    local generation1 = {}
    for _, space in ipairs(_state.spaces) do
        generation1[space] = startF(space)
    end
    for i = 1, n do
        local generation2 = {}
        for _, space1 in ipairs(_state.spaces) do
            local counter = 0
            if generation1[space1] then
                counter = counter + 1
            end
            for _, space2 in ipairs(Hex.adjacent(space1)) do
                if generation1[space2] then
                    counter = counter + 1
                end
            end
            generation2[space1] = counter > 3
        end
        generation1 = generation2
    end
    for _, space in ipairs(_state.spaces) do
        if generation1[space] then
            if process1F then
                process1F(space)
            end
        else
            if process2F then
                process2F(space)
            end
        end
    end
end

-- flood fill and process valid spaces
function flood_fill(src, validF, processF)
    assert(src)
    assert(validF)
    assert(processF)
    local done = {}
    local q = {}
    for _, space in ipairs(src) do
        if validF(space) then
            processF(space)
            done[space] = true
            table.insert(q, space)
        end
    end
    while q[1] do
        local space1 = table.remove(q, 1)
        for _, space2 in ipairs(Hex.adjacent(space1)) do
            if validF(space2) and not done[space2] then
                processF(space2)
                done[space2] = true
                table.insert(q, space2)
            end
        end
    end
end

-- connects all valid spaces
function connect1(validF, connectF)
    assert(validF)
    assert(connectF)
    -- get a valid space
    local space1 = List.filter(_state.spaces, validF)[1]
    assert(space1)
    while true do
        -- flood fill to find connected/disconnected valid spaces
        local connected_set = {}
        flood_fill(
            { space1 },
            validF,
            function (space) connected_set[space] = true end
        )
        local connected = {}
        local disconnected = {}
        for _, space in ipairs(_state.spaces) do
            if validF(space) then
                if connected_set[space] then
                    table.insert(connected, space)
                else
                    table.insert(disconnected, space)
                end
            end
        end
        if disconnected[1] then
            -- create a distance map from connected spaces
            local dist, prev = Path.dist(
                connected,
                function (space) return true end
            )
            -- get the closest disconnected space, and connect it
            local src = List.top(
                disconnected,
                function (space1, space2)
                    return dist[space1] < dist[space2]
                end
            )
            local path = Path.get_path(src, prev)
            for _, space in ipairs(path) do
                if not validF(space) then
                    connectF(space)
                end
            end
        else
            break
        end
    end
end

-- creates loops from dead ends
function connect2(validF, connectF, n)
    assert(validF)
    assert(connectF)
    n = n or 1
    for i = 1, n do
        -- find distant spaces
        local src, dst = get_distant_spaces(validF)
        -- connect them better
        local path = Path.astar(
            src,
            { dst },
            function (space) return true end,
            function (space1, space2)
                return validF(space2) and 1 or 2
            end
        )
        for _, space in ipairs(path) do
            if not validF(space) then
                connectF(space)
            end
        end
    end
end

-- gets 2 distant spaces
function get_distant_spaces(validF)
    assert(validF)
    local spaces = List.filter(_state.spaces, validF)
    assert(spaces[1])
    local space1 = spaces[game.rand1(#spaces)]
    local dist = Path.dist({ space1 }, validF)
    local space1 = List.top(
        spaces,
        function (space1, space2)
            return dist[space1] > dist[space2]
        end
    )
    local dist = Path.dist({ space1 }, validF)
    local space2 = List.top(
        spaces,
        function (space1, space2)
            return dist[space1] > dist[space2]
        end
    )
    return space1, space2
end



