---@class (partial) Config
local Config = require("SBAI.Shared.config")

--Config.dirPath = ToolBox.CleanUpPath(concat({Game.SaveFolder, ToolBox.CleanUpPathCrossPlatform("ModConfigs", true, Game.SaveFolder)}, "/"))
--Config.filePath = ToolBox.CleanUpPath(concat({Config.dirPath, ToolBox.CleanUpPathCrossPlatform((Acronym..".json"), true, Config.dirPath)}, "/"))

Config.dirPath = Stringtools.cleanUpPath(Game.SaveFolder, "ModConfigs")
Config.filePath = Stringtools.cleanUpPath(Config.dirPath, Stringtools.prefixAcronym("json"))

do
    local CanReadFromPath = File.CanReadFromPath ---@as fun(path:string):(boolean)
    local ferror = ferror

    ---@public
    ---@param filePath string
    ---@return boolean
    ---@nodiscard
    function Config.checkRead(filePath)
        if CanReadFromPath(filePath)  then
            return true
        else
            return ferror("Cannot read from mod config file: %s", 3, filePath)
        end
    end
end

do
    local CanWriteToPath = File.CanWriteToPath ---@as fun(path:string):(boolean)
    local CreateDirectory = File.CreateDirectory ---@as fun(path:string):(boolean)
    local DirectoryExists = File.DirectoryExists ---@as fun(path:string):(boolean)
    local ferror = ferror

    ---@public
    ---@param filePath string
    ---@param dirPath string
    ---@return boolean
    ---@nodiscard
    function Config.checkWrite(filePath, dirPath)
        if not (CanWriteToPath(dirPath) or CanWriteToPath(filePath)) then
            return ferror("Cannot write to mod config file: %s", 3, filePath)
        elseif not (DirectoryExists(dirPath) or CreateDirectory(dirPath)) then
            return ferror("Cannot create mod config directory: %s", 3, dirPath)
        else
            return true
        end
    end
end

do
    local filePath = Config.filePath

    local checkRead = Config.checkRead
    local Exists = File.Exists ---@as fun(path:string):(boolean)
    local jsonParse = json.parse
    local _parse = Config._parse
    local Read = File.Read---@as fun(path:string):(string)


    ---@public
    function Config.load()
        if checkRead(filePath) and Exists(filePath) then
            return _parse(jsonParse(Read(filePath)))
        end
    end




end

do
    local dirPath = Config.dirPath
    local filePath = Config.filePath

    local checkWrite = Config.checkWrite
    local tostring = tostring
    local Write = File.Write ---@as fun(path:string, test:string)

    ---@public
    function Config.save()
        if checkWrite(filePath, dirPath) then
            Write(filePath, tostring(Config.data))
            return Config.onUpdate()
        end
    end
end

if Net ~= false then
    do
        local data = Config.data

        local send = Net.send
        local write = Net.write

        ---@public
        ---@param client? Barotrauma.Networking.Client
        function Config.sendUpdate(client)
            local msg = write("CONFIG_UPDATE")

            data:serialize(msg)
            return send(msg, client)
        end
    end

    do
        local data = Config.data
        local ManageSettings = ClientPermissions.ManageSettings

        local save = Config.save

        Net.register("CONFIG_UPDATE",
        function(msg, client)
            if client.CheckPermission(ManageSettings) --[=[@as bool]=] then
                data:parse(msg)
                return save()
            end
        end)
    end

    do
        local sendUpdate = Config.sendUpdate

        Net.register("CONFIG_REQUEST",
        function(msg, client)
            return sendUpdate(client)
        end)
    end
end

return Config