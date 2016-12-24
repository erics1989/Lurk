glue = {}

function glue.true_f()
    return true
end

function glue.false_f()
    return false
end

function glue.dist_e(ax, ay, bx, by)
    return math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
end

function glue.lerp(a, b, t)
    return a + (b - a) * t
end

