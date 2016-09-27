
-- assorted list functions, based on Python's stdlib

local List = {}

function List.contains(l, v1)
    assert(l and v1)
    for i, v2 in ipairs(l) do
        if v2 == v1 then
            return i
        end
    end
end

function List.delete(l, v)
    assert(l and v)
    local i = List.contains(l, v)
    if i then
        return table.remove(l, i)
    end
end

function List.copy(l1)
    local l2 = {}
    for i, v in ipairs(l1) do
        l2[i] = v
    end
    return l2
end

function List.concat(l1, l2)
    local l3 = List.copy(l1)
    List.extend(l3, l2)
    return l3
end

function List.extend(l1, l2)
    for _, v in ipairs(l2) do
        table.insert(l1, v)
    end
    return l1
end

function List.top(l, compare_f)
    assert(l and compare_f)
    local top = l[1]
    for i, v in ipairs(l) do
        if compare_f(v, top) then
            top = v
        end
    end
    return top
end

function List.pop_top(l, compare_f)
    assert(l and compare_f)
    local top_i, top_v = 1, l[1]
    for i, v in ipairs(l) do
        if compare_f(v, top_v) then
            top_i, top_v = i, v
        end
    end
    return table.remove(l, top_i)
end

function List.set(l)
    local set = {}
    for _, v in ipairs(l) do
        set[v] = true
    end
    return set
end

function List.extend(l1, l2)
    for _, v in ipairs(l2) do
        table.insert(l1, v)
    end
end

function List.map(l1, f)
    local l2 = {}
    for i, v in ipairs(l1) do
        l2[i] = f(v)
    end
    return l2
end

function List.filter(l1, f)
    local l2 = {}
    for i, v in ipairs(l1) do
        if f(v) then
            table.insert(l2, v)
        end
    end
    return l2
end

function List.fold(l, f, acc)
    for _, v in ipairs(l) do
        if acc then
            acc = f(x, v)
        else
            acc = v
        end
    end
    return acc
end

function List.intersection(l1, l2)
    assert(l1, l2)
    local l3 = {}
    local s1 = List.set(l1)
    local f = function (v)
        return s1[v]
    end
    return List.filter(f, l2)
end

return List

