---@class Stringtools
local Stringtools = {}

do
    local CleanUpPath = ToolBox.CleanUpPath
    local CleanUpPathCrossPlatform = ToolBox.CleanUpPathCrossPlatform
    local concat = table.concat

    ---@param dir string
    ---@param subPath string
    ---@return string
    ---@nodiscard
    function Stringtools.cleanUpPath(dir, subPath)
        return CleanUpPath(concat({dir, CleanUpPathCrossPlatform(subPath, true, dir)}, "/"))
    end
end

do
    ---@param s string
    ---@param prefix string
    ---@return boolean
    ---@nodiscard
    function Stringtools.startsWith(s, prefix)
        return s:sub(1, #prefix) == prefix
    end
end

do
    ---@param s string
    ---@param suffix string
    ---@return boolean
    ---@nodiscard
    function Stringtools.endsWith(s, suffix)
        return s:sub(-#suffix) == suffix
    end
end

do
    local Deque = Types.Deque

    ---@param s string
    ---@param del string
    ---@return Deque<string>
    ---@nodiscard
    function Stringtools.split(s, del)
        local out = Deque() ---@as Deque<string>

        for _s in s:gmatch(("[^%s]+"):format(del)) do
            out:push(_s)
        end
        return out
    end
end

do
    local templateStr = ("%s%s"):format(Acronym, ("%s"):rep(2))
    local format = string.format

    ---@param s string
    ---@param del? string "."
    ---@return string
    ---@nodiscard
    function Stringtools.prefixAcronym(s, del)
        return format(templateStr, del or ".", s)
    end
end

do
    local _casefoldLiteralStr --[=[@[lsp_optimization("delayed_definition")]]=] do
        local format = string.format
        local lower = string.lower
        local upper = string.upper

        ---@param c string
        ---@return string
        ---@nodiscard
        _casefoldLiteralStr = function(c)
            return format("[%s%s]", upper(c), lower(c))
        end
    end

    local gsub = string.gsub

    ---@param literalStr string
    ---@return string
    ---@nodiscard
    function Stringtools.casefoldLiteralStr(literalStr)
        return (gsub(literalStr, "%a", _casefoldLiteralStr))
    end
end

do
    local format = string.format

    ---@param s1 string
    ---@param s2 string
    ---@return string
    ---@nodiscard
    local _addSpacesBetween = function(s1, s2)
        return format("%s %s", s1, s2)
    end

    local gsub = string.gsub

    ---@param s string
    ---@param p1 string
    ---@param p2 string
    ---@return string
    ---@nodiscard
    function Stringtools.addSpacesBetween(s, p1, p2)
        return (gsub(s, format("(%s)(%s)", p1, p2), _addSpacesBetween))
    end
end

do
    local lower = string.lower

    ---@param s1 string
    ---@param s2 string
    ---@return boolean
    ---@nodiscard
    function Stringtools.eqNoCase(s1, s2)
       return lower(s1) == lower(s2)
    end
end

do
    local ceil = math.ceil
    local floor = math.floor
    local max = math.max
    local round = Mathtools.round
    local type = type

    ---@param v integer|number|string
    ---@param w integer
    ---@param tag? "%A"|"%a"|"%c"|"%d"|"%E"|"%e"|"%f"|"%G"|"%g"|"%i"|"%o"|"%u"|"%X"|"%x"|"%s" %s
    function Stringtools.center(v, w, tag)
        local l = #v
        local _w = (w - l)*0.5
        local wL, wR

        if l % 2 == 0 then
            wL = floor(_w) + 1
            wR = ceil(_w)
        else
            wL = floor(_w)
            wR = ceil(_w) + 1
        end

        return ((" "):rep(wL)..(tag or "%s")..(" "):rep(wR)):format(v)
    end
end

do
    local floor = math.floor
    local format = string.format
    local log = math.log
    local max = math.max

    ---@param v number
    ---@param sigFigs? integer 6
    ---@return string
    function Stringtools.formatFloat(v, sigFigs)
        return (("%%.%df"):format(max((sigFigs or 6) - floor(log(v, 10)), 0)):format(v):gsub("(%d%d%d%d)(%d)", "%1‖color:0,0,0,0‖_‖end‖%2"))
    end
end

return Stringtools