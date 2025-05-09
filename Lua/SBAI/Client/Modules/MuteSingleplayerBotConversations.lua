local Types = require("SBAI.Shared.types")

---@param self Types.Module
local function activateBlockAllBotChat(self)
    self:AddHook("chatMessage",
    ---@param text string
    ---@param sender Barotrauma.Networking.Client
    ---@param type Barotrauma.Networking.ChatMessageType
    ---@param message Barotrauma.Networking.ChatMessage
    function(text, sender, type, message)
        if message.Sender.IsBot then
            return true
        end
    end)

    self:AddPatch("Barotrauma.Character", "ShowSpeechBubble", nil,
    function(instance, ptable)
        if instance.IsBot then
            ptable.PreventExecution = true
        end
    end, Hook.HookMethodType.Before)
end

---@param self Types.Module
local function activate(self)
    if Game.IsSingleplayer then
        self:AddPatch("Barotrauma.CrewManager", "UpdateConversations", nil,
        function(instance, ptable)
            ptable.PreventExecution = true
        end, Hook.HookMethodType.Before)

        self:DoOption("BlockAllBotChat", activateBlockAllBotChat)
    end
end

return Types.Module.new(activate)