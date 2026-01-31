---@namespace Config

---@class (partial) Config
---@field package modSettingsMenuFrame? Barotrauma.GUIFrame
local Config = require("SBAI.Shared.config")

do
    LuaUserData.AccessField("Barotrauma.WayPoint", "iconSprites")

    local orderPrefabs = OrderPrefab.Prefabs
    local talentPrefabs = TalentPrefab.TalentPrefabs
    local Identifier = Identifier
    local s = Identifier("operatereactor")
    ---@type Match<string, Barotrauma.Sprite>
    local iconSpriteMatch = Types.Match()
        :case("CombatTweaks",  talentPrefabs[Identifier("commando")].Icon)
        :case("CleaningAdditions", orderPrefabs[Identifier("cleanupitems")].SymbolSprite)
        :case("CrewStaysInSub", orderPrefabs[Identifier("return")].SymbolSprite)
        :case("EquipItems", talentPrefabs[Identifier("safetyfirst")].Icon)
        :case("MuteSingleplayerBotConversations", talentPrefabs[Identifier("bythebook")].Icon)
        :case("OperateReactorTweaks", orderPrefabs[Identifier("operatereactor")].SymbolSprite)
        :case("Orders", talentPrefabs[Identifier("bootcamp")].Icon)
        :case("ReplenishInventory", talentPrefabs[Identifier("bagitup")].Icon)
        :case("SmarterLoadItems", orderPrefabs[Identifier("loaditems")].OptionSprites[Identifier("oxygentanks")])
        :case("SmarterPets", talentPrefabs[Identifier("loyalassistant")].Icon)
        :case("UseFurniture", "IdleObjectiveIcon")
        :case("UseTalents", talentPrefabs[Identifier("steadytune")].Icon)

    local iconSprites = WayPoint.iconSprites

    iconSpriteMatch:case("LadderFix", iconSprites ~= nil and iconSprites["Ladder"] or Sprite("Content/UI/MainIconsAtlas.png", Rectangle(0, 128, 128, 128)))
    for module in Config.data:find("Modules") --[=[@as fun():Config.SectionMajor]=] do
        module:setIcon(iconSpriteMatch:eval(module.name))
    end
end

do
    local GUIHelper = Types.GUIHelper

    ---@package
    function Config.closeGUI()
        local modSettingsMenuFrame = Config.modSettingsMenuFrame

        if modSettingsMenuFrame then
            modSettingsMenuFrame.Parent.RemoveChild(modSettingsMenuFrame)
            Config.modSettingsMenuFrame = nil
        end
    end

    do
        ---@param comp Barotrauma.GUIButton
        ---@param userData any
        local function onClick_clearSBAIMenuFrame(comp, userData)
            local modSettingsMenuFrame = Config.modSettingsMenuFrame

            if modSettingsMenuFrame then
                Config.modSettingsMenuFrame = nil
            end
        end

        local One = Vector2.One
        local LargeFont = GUI.Style.Fonts[Identifier("LargeFont")] ---@as Barotrauma.GUIFont
        local LargeFontLineHeight = LargeFont.LineHeight
        local MaxPoint = GUI.RectTransform.MaxPoint
        local Point = Point
        local sizeConfig = Vector2(GUIHelper.Sizes.Config_W, GUIHelper.Sizes.Config_H)
        local sizeIcon_A = GUIHelper.Sizes.Icon_A
        local sizeItemUIHandle_A = GUIHelper.Sizes.ItemUIHandle_A
        local sizeLine_A = GUIHelper.Sizes.Line_A
        local sizePadding_A = GUIHelper.Sizes.Padding_A
        local SubHeadingFont = GUI.Style.Fonts[Identifier("SubHeadingFont")] ---@as Barotrauma.GUIFont
        local Vector2 = Vector2
        local ZeroV4 = Vector4.Zero

        local addButton = GUIHelper.addButton
        local addClosebutton = GUIHelper.addCloseButton
        local addDragHandle = GUIHelper.addDragHandle
        local addFrame = GUIHelper.addFrame
        local addIconButton = GUIHelper.addIconButton
        local addImage = GUIHelper.addImage
        local addLayoutGroup = GUIHelper.addLayoutGroup
        local addLine = GUIHelper.addLine
        local addListBox = GUIHelper.addListBox
        local addNumberInput = GUIHelper.addNumberInput
        local addSpacer = GUIHelper.addSpacer
        local addSpacesBetween = Stringtools.addSpacesBetween
        local addTextBlock = GUIHelper.addTextBlock
        local cut = GUIHelper.cut
        local ipairs = ipairs
        local padInnerFrame = GUIHelper.padInnerFrame
        local rT = GUIHelper.rT
        local setPosition = GUIHelper.setPosition

        ---@package
        ---@generic S:Section
        ---@param parent Barotrauma.GUIFrame
        ---@param configData S
        function Config.createSettingsMenu(parent, configData)
            local _
            local modSettingsMenuFrameOuter, modSettingsMenuFrameInner = addFrame(
                rT(
                    sizeConfig,
                    nil,
                    "Center",
                    "Center"
                ),
                "GUIFrame",
                true,
                false
            )

            local modSettingsMenuFrameInnerR = modSettingsMenuFrameInner.Rect
            local dragHandle = addDragHandle(modSettingsMenuFrameOuter)
            local closeButton = addClosebutton(dragHandle, modSettingsMenuFrameOuter)
            local closeUserData = closeButton.UserData ---@as {addF:fun(userData:{n:integer, [integer]:fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)}, f:fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)), data?:any, n:integer, [integer]:fun(comp:Barotrauma.GUIButton, userData:any):(boolean?, any?)}
            closeUserData.addF(closeUserData, onClick_clearSBAIMenuFrame)

            local topFrameOuter, topFrameInner = addFrame(
                rT(
                    Point(modSettingsMenuFrameInnerR.Width, sizeIcon_A + 4*sizePadding_A),
                    modSettingsMenuFrameInner,
                    "TopCenter",
                    "TopCenter",
                    nil,
                    true
                ),
                "nil",
                false,
                false
            )

            local generalButtonText = "General Settings"
            local generalButton = addButton(
                rT(
                    Point(SubHeadingFont.MeasureString(generalButtonText, false).X + 4*sizePadding_A, topFrameInner.Rect.Height),
                    topFrameInner,
                    "CenterLeft",
                    "CenterLeft",
                    nil,
                    true
                ),
                "MainMenuNotificationButtonLarge",
                true,
                true,
                true,
                generalButtonText,
                "Center",
                "General",
                nil
            )

            generalButton.Font = SubHeadingFont
            generalButton.ForceUpperCase = GUIHelper.ForceUpperCase.No

            local iconButtonFrameOuter, iconButtonFrameInner = addFrame(
                rT(
                    One,
                    topFrameInner,
                    "Center",
                    "Center"
                ),
                "TalentBackgroundGlow",
                true,
                true
            )

            local bottomSplitFrameOuter, bottomSplitFrameInner = addFrame(
                rT(
                    Point(modSettingsMenuFrameInnerR.Width, modSettingsMenuFrameInnerR.Height - topFrameOuter.Rect.Height - 2*sizePadding_A),
                    modSettingsMenuFrameInner,
                    "BottomCenter",
                    "BottomCenter",
                    nil,
                    true
                ),
                "UpgradeUIFrame",
                true,
                false
            )
            bottomSplitFrameOuter.RectTransform.AbsoluteOffset = Point(0, 2*sizePadding_A)

            local leftLayout_V, rightLayout_V = GUIHelper.CreateSidebars(bottomSplitFrameInner, 0.5, nil, true)
            local topButtons = {} --[=[@as {[integer]:Barotrauma.GUIButton}]=] do --- REMEMBER ConnectionPanel AND TextFrame
                local iconButtonLayout_H = addLayoutGroup(
                    rT(
                        One,
                        iconButtonFrameInner,--iconButtonFramePadded,
                        "Center",
                        "Center"
                    ),
                    "CenterLeft",
                    nil,
                    true,
                    false
                )
                for i, s in ipairs({"PowerButton", "GUICancelButton", "OpenButton", "UndoHistoryButton", "GUIReloadButton", "SaveButton"}) do
                    topButtons[i] = addIconButton(
                        nil,
                        nil,
                        iconButtonLayout_H,
                        nil,
                        nil,
                        s,
                        nil,
                        true,
                        false,
                        false,
                        nil,
                        nil
                    )
                end
                leftLayout_V.AbsoluteSpacing = sizePadding_A
                rightLayout_V.AbsoluteSpacing = sizePadding_A

                local newIconButtonFrameSize = iconButtonLayout_H.CountChildren*(sizeIcon_A + sizePadding_A) - sizePadding_A

                iconButtonFrameOuter.RectTransform.Resize(Point(newIconButtonFrameSize + 3*sizePadding_A, sizeIcon_A + 2*sizePadding_A))
                iconButtonFrameOuter.RectTransform.IsFixedSize = true
                iconButtonFrameInner.RectTransform.Parent.Resize(Point(newIconButtonFrameSize, sizeIcon_A))
                iconButtonFrameInner.RectTransform.Parent.IsFixedSize = true
            end
            local titleTextSizeMin
            local moduleList --[=[@[lsp_optimization("delayed_definition")]]=] do
                local modulesTitleTextRT = rT(
                    Vector2(1, 0),
                    leftLayout_V
                )

                local modulesTitleText = addTextBlock(
                    modulesTitleTextRT,
                    "nil",
                    true,
                    true,
                    false,
                    "Modules",
                    "Center",
                    false,
                    "LargeFont",
                    false,
                    false
                )
                titleTextSizeMin = Point(0, modulesTitleText.TextSize.Y)
                modulesTitleTextRT.MinSize = titleTextSizeMin

                addLine(leftLayout_V, false)

                moduleList = addListBox(
                    rT(
                        One,
                        leftLayout_V
                    ),
                    false,
                    false,
                    nil,
                    true,
                    true,
                    "GUIListBox",
                    true
                )
                local moduleListContent = moduleList.Content


                for module in configData --[[@as fun():(Config.SectionMajor)]] do
                    module:drawLabel(moduleListContent)
                end

            end

            local optionsList --[=[@[lsp_optimization("delayed_definition")]]=] do
                local optionsTitleText = addTextBlock(
                    rT(
                        Vector2(1, 0),
                        rightLayout_V,
                        nil,
                        nil,
                        nil,
                        titleTextSizeMin
                    ),
                    "nil",
                    true,
                    true,
                    false,
                    "",
                    "Center",
                    true,
                    "LargeFont",
                    false,
                    false
                )
                GUIHelper.Spacer(rightLayout_V)
                optionsTitleText.CalculateHeightFromText()

                local leftLayout_VRT = rightLayout_V.RectTransform
                local leftLayoutW, leftLayoutH = rightLayout_V.Rect.Size.ToVector2().Deconstruct() ---@as System.Int32...
                local optionsTitleTextH = optionsTitleText.Rect.Height

                optionsTitleText.RectTransform.MinSize = Point(leftLayoutW, optionsTitleTextH)
                --optionsTitleText.Padding = ZeroV4
                addLine(rightLayout_V, false, optionsTitleTextH + sizePadding_A, sizePadding_A)

                optionsList = addListBox(
                    rT(
                        One,
                        rightLayout_V
                    ),
                    false,
                    true,
                    nil,
                    true,
                    true,
                    "GUIListBox",
                    true
                )
                local optionsListContent = optionsList.Content



                ---@param component Barotrauma.GUIFrame
                ---@param userData SectionMajor
                function moduleList.AfterSelected(component, userData)
                    optionsList.ClearChildren()
                    optionsTitleText.Text = addSpacesBetween(userData.name, "%l", "%u")
                    optionsTitleText.CalculateHeightFromText(nil, false)
                    userData:draw(optionsListContent)
                end

                -- local optionsFrame = addFrame(
                --     rT(
                --         One,
                --         leftLayout_V,
                --         nil,
                --         nil,
                --         nil,
                --         nil,
                --         Point(MaxPoint.X, leftLayoutH - moduleNameTextH - 2*sizePadding_A - 2)
                --     ),
                --     "GUIFrameListBox",
                --     true,
                --     false,
                --     false
                -- )

                -- local optionsLayout_V = addLayoutGroup(
                --     rT(
                --         One,
                --         optionsFrame,
                --         "TopCenter",
                --         "TopCenter"
                --     ),
                --     "TopLeft",
                --     nil,
                --     false,
                --     false
                -- )



                --configData:draw(optionsList.Content)



            end
                -- local pendingChanges = {} ---@type table<Config.Base, any>
                -- local seen = Types.Set() ---@type Set<Config.Base>

                -- ---@param optionData Config.Base
                -- ---@param oldValue any
                -- local function addPendingChange(optionData, oldValue)
                --     if pendingChanges[optionData] == nil then
                --         seen:add(optionData)
                --         pendingChanges[optionData] = oldValue
                --     end
                -- end

            modSettingsMenuFrameOuter.RectTransform.Parent = parent.RectTransform
            Config.modSettingsMenuFrame = modSettingsMenuFrameOuter
        end
    end

    do

        ---@param button Barotrauma.GUIButton
        ---@param userData Barotrauma.GUIFrame
        local function onClicked(button, userData)
            return Config.createSettingsMenu(userData, Config.data:find("Modules"))
        end

        local _GUI = GUI.GUI
        local Int32 = Int32
        local Name = SBAI.Name
        local Point = Point
        local Vector2 = Vector2

        local addButton = GUIHelper.addButton
        local rT = GUIHelper.rT

        Hook.Patch("Client.Config.AddButton", "Barotrauma.GUI", "TogglePauseMenu", {}, "After",
        function(instance, ptable)
            if _GUI.PauseMenuOpen == true then
                local pauseMenu = _GUI.PauseMenu
                local pauseMenuInner = pauseMenu.GetChild(Int32(1)) ---@as Barotrauma.GUIFrame
                local buttonContainer = pauseMenuInner.GetChild(Int32(0)) ---@as Barotrauma.GUILayoutGroup
                local menuButton = addButton(rT(Vector2(1, 0.05), buttonContainer), "GUIButtonSmall", true, true, false, Name, "Center", pauseMenu, onClicked)

                local ySize = 0
                local absoluteSpacing  = buttonContainer.AbsoluteSpacing

                for component in buttonContainer.Children --[=[@as fun():Barotrauma.GUIComponent]=] do
                    ySize = ySize + component.Rect.Height + absoluteSpacing
                end
                ySize = ySize/buttonContainer.RectTransform.RelativeSize.Y + absoluteSpacing

                local pauseMenuInnerRT = pauseMenuInner.RectTransform
                local minSize = pauseMenuInnerRT.MinSize

                if ySize > minSize.Y then
                    pauseMenuInnerRT.MinSize = Point(minSize.X, ySize)
                end
            else
                return Config.closeGUI()
            end
        end)
    end
end

-- Hook.Patch("Barotrauma.GUI", "TogglePauseMenu", {}, function(instance, ptable)
--     if not GUI.PauseMenuOpen and menu.Visible then
--         menu.Visible = false
--         ptable.PreventExecution = true
--     end
-- end, Hook.HookMethodType.Before)

if Net ~= false then
    do
        local writeSend = Net.writeSend

        ---@public
        function Config.sendRequest()
            return writeSend("CONFIG_REQUEST")
        end
    end

    do
        local data = Config.data

        local send = Net.send
        local write = Net.write

        ---@public
        function Config.sendUpdate()
            local msg = write("CONFIG_UPDATE")

            data:serialize(msg)
            return send(msg)
        end
    end

    do
        local data = Config.data

        Net.register("CONFIG_UPDATE",
        function(msg, client)
            data:parse(msg)
            return Config.onUpdate()
        end)
    end

    do
        local Version = SBAI.Version

        local sendRequest = Config.sendRequest
        local writeSend = Net.writeSend

        ---@public
        function Net.init()
            writeSend("INIT", nil, Version)
            return sendRequest()
        end
    end

    do
        local init = Net.init

        Net.register("INIT",
        function(msg, client)
            return init() ---@diagnostic disable-line: access-invisible
        end)
    end
end

return Config
