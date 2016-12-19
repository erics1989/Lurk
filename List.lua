
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

function List.reverse(a)
    local b = {}
    local j = #a
    for i = 1, j do
        b[i] = a[j - i + 1]
    end
    return b
end

function List.top(l, cf)
    assert(l and cf)
    local top = l[1]
    for i, v in ipairs(l) do
        if cf(v, top) then
            top = v
        end
    end
    return top
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
            acc = f(acc, v)
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
    return List.filter(l2, f)
end

local function percolate_up(l, i, cf)
    if 1 < i then
        local j = math.floor(i / 2)
        if cf(l[i], l[j]) then
            l[i], l[j] = l[j], l[i]
            percolate_up(l, j, cf)
        end
    end
end

local function percolate_dn(l, i, cf)
    local x = i
    local j = i * 2
    local k = i * 2 + 1
    if l[j] and cf(l[j], l[x]) then
        x = j
    end
    if l[k] and cf(l[k], l[x]) then
        x = k
    end
    if x ~= i then
        l[i], l[x] = l[x], l[i]
        percolate_dn(l, x, cf)
    end
end

function List.p_enqueue(l, v, cf)
    local i = #l + 1
    l[i] = v
    percolate_up(l, i, cf)
end

function List.p_dequeue(l, cf)
    local v = l[1]
    local i = #l
    if 1 < i then
        l[1], l[i] = l[i], nil
        percolate_dn(l, 1, cf)
    else
        l[1] = nil
    end
    return v
end

function List.heap(l, cf)
    for i = math.floor(#l / 2), 1, -1 do
        percolate_dn(l, i, cf)
    end
end

return List

