
-- grammar functions for generating game messages

local grammar = {}

grammar.aeiou = { a = true, e = true, i = true, o = true, u = true }

-- capitalize
function grammar.cap(str)
    return str:sub(1, 1):upper() .. str:sub(2, str:len())
end

-- add "the"
function grammar.the(str)
    return
        str == "you" and str or
        str == "someone" and str or
        string.format("the %s", str)
end

-- add "a"/"an"
function grammar.a(str)
    return
        str == "you" and str or
        grammar.aeiou[str:sub(1, 1)] and string.format("an %s", str) or
        string.format("a %s", str)
end

-- add a possessive "'s"
function grammar.pos(str)
    return
        str:sub(str:len()) == "s" and string.format("%s\'", str) or
        string.format("%s\'s", str)
end

return grammar

