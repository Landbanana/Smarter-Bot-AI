---@class (partial) Config
---@field public data Config.Section
---@field public onChange Event<fun(config:Config.SectionMajor)>
---@field private _parse fun(configFlat:{[string]:Json})
local Config = {
    onChange=Types.Event(true, true)
}

do
    local Bool = Types.Config.OptionBool
    local Float = Types.Config.OptionFloat
    local Int = Types.Config.OptionInt
    local Loadout = Types.Config.OptionLoadout
    local Radio = Types.Config.OptionRadio
    local Section = Types.Config.Section
    local SectionMajor = Types.Config.SectionMajor
    local SectionToggle = Types.Config.SectionToggle

    local minCondition = Int("minCondition", 10, 0, 95)
    local minHealth = Int("minHealth", 75, 10, 90)
    local checkDelay = Int("checkDelay", 10, 5, 1000)

    local data = Section("Options")/{
        SectionMajor("General")/{
            Bool("ModEnabled"),
            Section("GamePerformance")/{
                Int("updateRate", 5, 1, 60),
                Bool("onlyAffectPlayerCrew", false),
                Bool("pauseWhenSafelyDocked", false)
            }
        },
        Section("Modules")/{
            SectionMajor("CombatTweaks")/{
                Bool("PreventAttackingHandcuffed"),
                SectionToggle("ArrestHumansInPlayerSub")/{
                    Bool("onlyPreviouslyCuffed", false),
                    minHealth:copyWith {default=75}
                },
                SectionToggle("PreSpinTurrets")/{
                    Bool("reduceNoise")
                }
            },
            SectionMajor("CleaningAdditions")/{
                SectionToggle("PurchasedItemCrates",  false)/{
                    Radio("autoOrder", 1, {
                        "deconstruct",
                        "ignore"
                    })
                },
                SectionToggle("DeconstructInBulk")/{
                    Int("maxCheck", 32, 2, 128)
                },
                Bool("OnlyUseShipDeconstructor")
            },
            SectionMajor("CrewStaysInSub")/{},
            SectionMajor("EquipItems")/{
                --Loadout("CrewLoadout"), TODO
                Bool("reEquipArmor"),
                checkDelay:copyWith {default=60}
            },
            SectionMajor("LadderFix")/{
                checkDelay:copyWith {default=30}
            },
            SectionMajor("MuteSingleplayerBotConversations", false)/{
                Bool("BlockAllBotChat", false)
            },
            SectionMajor("OperateReactorTweaks")/{
                Radio("behavior", 2, {
                    "mostlyVanilla",
                    "fuelOnlyWhenController",
                    "fuelOnly"
                }),
                Int("numFuelRods", 1, 1, 4),
                minCondition:copyWith {default=10}
            },
            SectionMajor("Orders", false),
            SectionMajor("ReplenishInventory")/{
                Section("OrderOptions")/{
                    SectionToggle("Idle")/{
                        Bool("onlyAtFriendlyOutposts", false)
                    },
                    SectionToggle("Wait")/{
                        Bool("onlyAtFriendlyOutposts")
                    }
                },
                Bool("fillEmpty"),
                Bool("forceSameItemType"),
                Bool("forceQualityGEQ"),
                checkDelay:copyWith {default=30},
                Section("ItemOptions")/{
                    SectionToggle("Ammunition")/{
                        minCondition:copyWith {default=80},
                        minCondition:copyWith {name="minEquippedCondition", default=80}
                    },
                    SectionToggle("BatteryCells")/{
                        minCondition:copyWith {default=75},
                        minCondition:copyWith {name="minEquippedCondition", default=10}
                    },
                    SectionToggle("OxygenTanks")/{
                        minCondition:copyWith {default=95},
                        minCondition:copyWith {name="minEquippedCondition", default=10}
                    },
                    SectionToggle("WeldingFuel")/{
                        minCondition:copyWith {default=75},
                        minCondition:copyWith {name="minEquippedCondition", default=10}
                    }
                }
            },
            SectionMajor("SmarterLoadItems")/{
                SectionToggle("BatteryCells")/{
                    minCondition:copyWith {default=90},
                },
                SectionToggle("OxygenTanks")/{
                    minCondition:copyWith {default=90},
                }
            },
            SectionMajor("SmarterPets")/{
                SectionToggle("EatFoodInInventory")/{
                    Bool("overrideProtectOwner"),
                    checkDelay:copyWith {default=15}
                },
                SectionToggle("BotsPlayWhenIdle")/{
                    checkDelay:copyWith {default=15}
                },
                Bool("CleanableProduce")
            },
            SectionMajor("UseFurniture")/{
                SectionToggle("AutoUseWhenIdle")/{
                    Bool("beds"),
                    Bool("chairs")
                },
                Bool("stayInBedIfHurt")
            },
            SectionMajor("UseTalents")/{
                SectionToggle("Assistant")/{
                    SectionToggle("InspiringTunes")/{
                        Bool("idle"),
                        Bool("wait"),
                        Bool("stopAfterBuffed"),
                        checkDelay:copyWith {default=15}
                    },
                    SectionToggle("JengaMaster")/{
                        checkDelay:copyWith {default=120}
                    },
                    SectionToggle("NonThreatening")/{
                        minHealth:copyWith {default=75}
                    }
                },
                SectionToggle("Captain")/{
                    SectionToggle("SteadyTune")/{
                        Bool("idle"),
                        Bool("wait"),
                        Bool("stopAfterBuffed"),
                        checkDelay:copyWith {default=15}
                    }
                },
                SectionToggle("Engineer")/{
                    SectionToggle("MelodicRespite")/{
                        Bool("idle"),
                        Bool("wait"),
                        Bool("stopAfterBuffed"),
                        checkDelay:copyWith {default=15}
                    }
                }
            }
        }
    }
    Config.data = data
end

do
    local logError = Errortools.logError
    local pcall = pcall

    ---@param k string
    ---@param t table
    ---@param n Deque<string>
    local function onEnter(k, t, n)
        return n:push(k)
    end

    ---@param k string
    ---@param t table
    ---@param n Deque<string>
    local function onExit(k, t, n)
        return n:pop()
    end

    local onValue --[=[@[lsp_optimization("delayed_definition")]]=] do
        local concat = concat

        ---@param k string
        ---@param v Json
        ---@param n Deque<string>
        onValue = function(k, v, n)
            n:push(k)

            local success, msg = pcall(Config.data.set, Config.data, v, concat(n, ".", n.i, n.j))

            if not success then
                logError("Shared.Config._parse", msg)
            end

            n:pop()
        end
    end

    local Deque = Types.Deque

    local traverse = Tabletools.traverse

    function Config._parse(configFlat)
        local namespace = Deque() ---@type Deque<string>

        traverse(onEnter, onExit, onValue, configFlat, namespace)
    end
end




do
    local _print --[=[@[lsp_optimization("delayed_definition")]]=] do
        local next = next
        local print = print
        local tostring = tostring
        local type = type

        _print = function(s, i)
            local indent = ("    "):rep(i)

            for k, v in next, s do
                if type(v) == "table" then
                    print(("%s%s {"):format(indent, k))
                    _print(v, i + 1)
                    print(("%s}"):format(indent))
                else
                    print(("%s%s: %s"):format(indent, k, tostring(v)))
                end
            end
        end
    end

    local data = Config.data

    ---@public
    function Config.print()
        return _print(data:flatten(), 0)
    end
end

return Config