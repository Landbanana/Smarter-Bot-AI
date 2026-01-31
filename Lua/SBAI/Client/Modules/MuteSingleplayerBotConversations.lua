---@param self Module
local function activateBlockAllBotChat(self)
    self:addHook("chatMessage",
    ---@param text string
    ---@param sender Barotrauma.Networking.Client
    ---@param type Barotrauma.Networking.ChatMessageType
    ---@param message Barotrauma.Networking.ChatMessage
    function(text, sender, type, message)
        if message.SenderCharacter.IsBot --[=[@as boolean]=] then
            return true
        end
    end)

    self:addPatch("Barotrauma.Character", "ShowSpeechBubble", nil, "Before",
    function(instance, ptable)
        if instance.IsBot --[=[@as boolean]=] then
            ptable.PreventExecution = true
        end
    end)
end

---@param self Module
local function activate(self)
    if Game.IsSingleplayer then
        self:addPatch("Barotrauma.CrewManager", "UpdateConversations", nil, "Before",
        function(instance, ptable)
            ptable.PreventExecution = true
        end)

        return self:activateOption("BlockAllBotChat", activateBlockAllBotChat)
    end
end

return Types.Module(activate)