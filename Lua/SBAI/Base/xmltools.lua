---@class Xmltools
local Xmltools = {}

do
    local tostringL = Functools.pipe(tostring, string.lower)
    local tostringL_m, tostringL_c = Functools.memoize(tostringL)

    ---@param e1 System.Xml.Linq.XElement
    ---@param e2 System.Xml.Linq.XElement
    ---@return boolean
    ---@nodiscard
    function Xmltools.xComp(e1, e2)
        return tostringL_m(e1) < tostringL_m(e2)
    end

    function Xmltools.xComp_clear()
        return tostringL_c:clear()
    end
end

do
    local xComp = Xmltools.xComp
    local xComp_clear = Xmltools.xComp_clear

    local sort = table.sort

    ---@param t System.Xml.Linq.XElement[]
    function Xmltools.xSort(t)
        sort(t, xComp)
        return xComp_clear()
    end
end

do
    local Set = Types.Set

    ---@param outSet Set<string>|Set<System.Xml.Linq.XElement>
    ---@param eR System.Xml.Linq.XElement
    ---@param e System.Xml.Linq.XElement
    ---@param s string
    local function parse(outSet, eR, e, s)
        if s == "" then
            return outSet:add(e)
        else
            local s2a, s1d, s2p ---@type boolean|string|nil, string?, boolean|string|nil
            local s1, s2, sR1, sR2 ---@type string?, string?, string?, string?

            s1, s1d, sR1 = s:match("^(%.?/?(/?))(.-)$") ---@cast sR1 -?
            
            s1d = s1d == "" and "Elements" or "Descendants"

            s2p, s2a, s2, sR2 = sR1:match("^(%[?)(@?)(%.?/?/?[^%[%]/|%.=@]+)(.-)$") ---@cast s2 -? ---@cast sR2 -?

            s2a = s2a and s2a ~= ""
            s2p = s2p and s2p ~= ""

            if s1 == nil then
                --- maybe TODO?
            else
                if s2p then
                    s2, sR2 = sR1:match("^(%b[])(.-)$") ---@cast s2 -? ---@cast sR2 -?
                    s2 = s2:sub(2, -2)

                    if s2a then
                        local aName, aComp = s2:match("@([^%[%]/|%.=@]+)=?[\"\']?([^=%]\"\']*)[\"\']?") ---@as string
                        local aVal = e.GetAttributeString(aName, "")

                        if aVal == aComp then
                            return parse(outSet, eR, e, sR2)
                        end
                    else
                        local pSet = Set()
                        
                        parse(pSet, eR, e, s2)
                        if not pSet.isEmpty then
                            return outSet:add(e) 
                        end
                    end
                else
                    if s2a then
                        local aVal = e.GetAttributeString(s2, "")
                        
                        if aVal ~= "" then
                            return parse(outSet, eR, aVal, sR2)
                        end
                    else
                        for e1 in e[s1d](s2) --[=[@as fun():(System.Xml.Linq.XElement)]=] do
                            parse(outSet, eR, e1, sR2)                        
                        end
                    end
                end
            end
        end
    end

    local IsTargetType = LuaUserData.IsTargetType
    local sort = table.sort
    local type = type
    local xSort = Xmltools.xSort

    ---@param xElementOrPrefab System.Xml.Linq.XElement|Barotrauma.CharacterPrefab|Barotrauma.ItemPrefab|Barotrauma.TalentPrefab
    ---@param xPathStr string
    ---@return (System.Xml.Linq.XElement[])|(string[])
    ---@overload fun(prefab:Barotrauma.CharacterPrefab|Barotrauma.ItemPrefab|Barotrauma.TalentPrefab, xPathStr:string):(Deque<System.Xml.Linq.XElement|string>)
    ---@overload fun(xElement:System.Xml.Linq.XElement, xPathStr:string):(Deque<System.Xml.Linq.XElement|string>)
    function Xmltools.xPath(xElementOrPrefab, xPathStr)
        if not IsTargetType(xElementOrPrefab, "System.Xml.Linq.XElement") then
            xElementOrPrefab = xElementOrPrefab.ConfigElement.Element
        end

        local outSet = Set() ---@type Set<System.Xml.Linq.XElement>|Set<string>
        
        parse(outSet, xElementOrPrefab, xElementOrPrefab, xPathStr)

        local out = outSet:tolist()
        
        if not outSet.isEmpty then
            if type(out[1]) == "string" then ---@cast out string[]
                sort(out)
            else ---@cast out System.Xml.Linq.XElement[]
                xSort(out)
            end
        end
        return out
    end
end

return Xmltools