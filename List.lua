
-- assorted list functions, based on Python's stdlib

local List = {}

function List.contains(L, v1)
    assert(L and v1)
    for i, v2 in ipairs(L) do
        if v2 == v1 then
            return i
        end
    end
end

function List.delete(L, v)
    assert(L and v)
    local i = List.contains(L, v)
    if i then
        return table.remove(L, i)
    end
end

function List.copy(L1)
    local L2 = {}
    for i, v in ipairs(L1) do
        L2[i] = v
    end
    return L2
end

function List.concat(L1, L2)
    local L3 = List.copy(L1)
    List.extend(L3, L2)
    return L3
end

function List.extend(L1, L2)
    for _, v in ipairs(L2) do
        table.insert(L1, v)
    end
    return L1
end

function List.top(L, sortF)
    assert(L and sortF)
    local top = L[1]
    for i, v in ipairs(L) do
        if sortF(v, top) then
            top = v
        end
    end
    return top
end

function List.pop_top(L, sortF)
    assert(L and sortF)
    local top_i, top_v = 1, L[1]
    for i, v in ipairs(L) do
        if sortF(v, top_v) then
            top_i, top_v = i, v
        end
    end
    return table.remove(L, top_i)
end

function List.set(L)
    local set = {}
    for _, v in ipairs(L) do
        set[v] = true
    end
    return set
end

function List.extend(L1, L2)
    for _, v in ipairs(L2) do
        table.insert(L1, v)
    end
end

function List.map(F, L1)
    local L2 = {}
    for i, v in ipairs(L1) do
        L2[i] = F(v)
    end
    return L2
end

function List.filter(F, L1)
    local L2 = {}
    for i, v in ipairs(L1) do
        if F(v) then
            table.insert(L2, v)
        end
    end
    return L2
end

function List.reduce(F, L, init)
    local x = init
    for _, v in ipairs(L) do
        if x then
            x = F(x, v)
        else
            x = v
        end
    end
    return x
end

function List.intersection(L1, L2)
    assert(L1, L2)
    local L3 = {}
    local S1 = List.set(L1)
    local f = function (v)
        return S1[v]
    end
    return List.filter(f, L2)
end

return List

