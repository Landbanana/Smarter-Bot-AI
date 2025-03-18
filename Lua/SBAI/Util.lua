SBAI.Util = {}

function SBAI.Util.ListContains(list, obj)
    for o in list do
        if o == obj then
            return true
        end
    end
    return false
end