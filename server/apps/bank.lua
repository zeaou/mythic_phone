RegisterServerEvent("serverCharacterSpawned")
AddEventHandler(
    "serverCharacterSpawned",
    function()
        local src = source
        -- local char = exports["mythic_base"]:FetchComponent("Fetch"):Source(src):GetData("character")
        local char = exports["utils"]:getIdentity(src)

        char.Bank.GetFull:All(
            function(accounts)
                char.Bank.Transfer:Get(
                    function(thistory)
                        TriggerClientEvent(
                            "mythic_phone:client:SetupData",
                            src,
                            {
                                {name = "bank-accounts", data = accounts},
                                {name = "bank-transfers", data = thistory}
                            }
                        )
                    end
                )
            end
        )
    end
)

--[[ Probably should just convert most of this shit to the banking resource and call it through export ]]
ESX.RegisterServerCallback(
    "mythic_phone:server:GetBankTransactions",
    function(source, data, cb)
        -- local char = exports["mythic_base"]:FetchComponent("Fetch"):Source(source):GetData("character")
        local src = source
        local char = exports["utils"]:getIdentity(src)

        local history = {}
        exports["ghmattimysql"]:execute(
            "SELECT * FROM bank_account_transactions WHERE origin_account = @account OR destination_account = @account ORDER BY date DESC LIMIT 50",
            {["account"] = data.account},
            function(transactions)
                for k, v in ipairs(transactions) do
                    local type = 0 -- Default to cash deposit

                    if v.origin_account ~= nil and v.destination_account ~= nil then
                        if v.account == data.account then -- Transfer From
                            type = 2
                        else -- Transfer To
                            type = 3
                        end
                    else
                        if v.destination_account == nil then -- Cash Withdrawal
                            type = 1
                        end
                    end

                    table.insert(
                        history,
                        {
                            account = data.account,
                            amount = v.amount,
                            date = v.date,
                            note = v.note,
                            type = type
                        }
                    )
                end

                cb(history)
            end
        )
    end
)

ESX.RegisterServerCallback(
    "mythic_phone:server:Transfer",
    function(source, data, cb)
        local src = source
        if tonumber(data.amount) >= 500 and tonumber(data.amount) <= 100000 then
            -- local char = exports["mythic_base"]:FetchComponent("Fetch"):Source(source):GetData("character")
            local char = exports["utils"]:getIdentity(src)
            char.Bank.Transfer:Create(tonumber(data.account), tonumber(data.destination), tonumber(data.amount), cb)
        else
            cb(false)
        end
    end
)

ESX.RegisterServerCallback(
    "mythic_phone:server:MazePay",
    function(source, data, cb)
        local src = source
        if tonumber(data.amount) >= 100 and tonumber(data.amount) <= 10000 then
            if source ~= tonumber(data.destination) then
                -- local char = exports["mythic_base"]:FetchComponent("Fetch"):Source(source):GetData("character")
                local char = exports["utils"]:getIdentity(src)
                char.MazePay:Transfer(tonumber(data.destination), tonumber(data.amount), cb)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end
)
