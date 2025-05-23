local ESX = exports["es_extended"]:getSharedObject()

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS player_boutique (
            identifier VARCHAR(50) PRIMARY KEY,
            credits INT DEFAULT 0
        )
    ]])

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS purchase_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL,
            item_name VARCHAR(50) NOT NULL,
            item_label VARCHAR(50) NOT NULL,
            price INT NOT NULL,
            purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS pending_items (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL,
            category VARCHAR(50) NOT NULL,
            item_name VARCHAR(50) NOT NULL,
            item_label VARCHAR(50) NOT NULL,
            quantity INT NOT NULL DEFAULT 1,
            price INT NOT NULL,
            purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS boutique_admins (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL UNIQUE,
            added_by VARCHAR(50) NOT NULL,
            added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end)

function GetPlayerCredits(identifier, cb)
    MySQL.Async.fetchScalar('SELECT credits FROM player_boutique WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(credits)
        if credits == nil then
            MySQL.Async.execute('INSERT INTO player_boutique (identifier, credits) VALUES (@identifier, 0)', {
                ['@identifier'] = identifier
            }, function()
                cb(0)
            end)
        else
            cb(credits)
        end
    end)
end

function AddCredits(identifier, amount)
    MySQL.Async.execute('INSERT INTO player_boutique (identifier, credits) VALUES (@identifier, @amount) ON DUPLICATE KEY UPDATE credits = credits + @amount', {
        ['@identifier'] = identifier,
        ['@amount'] = amount
    }, function()
        local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            GetPlayerCredits(identifier, function(newCredits)
                TriggerClientEvent('alz-boutique:updateCredits', xPlayer.source, newCredits)
            end)
        end
    end)
end

function RemoveCredits(identifier, amount, cb)
    MySQL.Async.fetchScalar('SELECT credits FROM player_boutique WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(currentCredits)
        if currentCredits == nil or currentCredits < amount then
            if cb then cb(false) end
            return
        end

        MySQL.Async.execute('UPDATE player_boutique SET credits = credits - @amount WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@amount'] = amount
        }, function(rowsChanged)
            local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
            if xPlayer then
                GetPlayerCredits(identifier, function(newCredits)
                    TriggerClientEvent('alz-boutique:updateCredits', xPlayer.source, newCredits)
                end)
            end
            if cb then cb(true) end
        end)
    end)
end

ESX.RegisterServerCallback('alz-boutique:getPlayerInfo', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        GetPlayerCredits(xPlayer.identifier, function(credits)
            local info = {
                identifier = source,
                name = xPlayer.getName(),
                credits = credits
            }
            cb(info)
        end)
    else
        cb(nil)
    end
end)

function FindItem(itemName, category)
    if not itemName then
        print("^1[ERREUR] itemName est nil")
        return nil
    end

    if not category then
        print("^1[ERREUR] category est nil")
        return nil
    end

    if not Config.Items[category] then
        print("^1[ERREUR] Catégorie non trouvée: " .. tostring(category))
        return nil
    end

    for _, item in ipairs(Config.Items[category]) do
        if item.spawnName == itemName then
            return item
        end
    end
    
    print("^1[ERREUR] Item non trouvé: " .. tostring(itemName) .. " dans la catégorie " .. tostring(category))
    return nil
end

ESX.RegisterServerCallback('alz-boutique:buyVehicle', function(source, cb, vehicleName, quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Joueur non trouvé")
        return
    end
    
    local vehicle = FindItem(vehicleName, 'vehicules')
    if not vehicle then
        cb(false, "Véhicule non trouvé")
        return
    end
    
    local totalPrice = vehicle.price * quantity
    
    RemoveCredits(xPlayer.identifier, totalPrice, function(success)
        if success then
            MySQL.Async.execute("INSERT INTO pending_items (identifier, category, item_name, item_label, quantity, price) VALUES (@identifier, @category, @item_name, @item_label, @quantity, @price)", {
                ["@identifier"] = xPlayer.identifier,
                ["@category"] = "vehicules",
                ["@item_name"] = vehicleName,
                ["@item_label"] = vehicle.name,
                ["@quantity"] = quantity,
                ["@price"] = totalPrice
            }, function(rowsChanged)
                if rowsChanged then
                    AddToHistory(xPlayer.identifier, vehicleName, vehicle.name, totalPrice)
                    UpdatePendingItemCount(xPlayer.source)
                    cb(true)
                else
                    AddCredits(xPlayer.identifier, totalPrice)
                    cb(false, "Erreur lors de l'ajout à l'inventaire")
                end
            end)
        else
            cb(false, "Crédits insuffisants")
        end
    end)
end)

ESX.RegisterServerCallback('alz-boutique:buyItem', function(source, cb, itemName, quantity, category, isOpeningCase)
    local xPlayer = ESX.GetPlayerFromId(source)
    

    
    if not itemName then
        cb(false, "Nom de l'item manquant")
        return
    end

    if not category then
        cb(false, "Catégorie manquante")
        return
    end

    if not xPlayer then
        cb(false, "Joueur non trouvé")
        return
    end
    
    local item = FindItem(itemName, category)
    if not item then
        cb(false, "Item non trouvé")
        return
    end
    
    if not item.price then
        cb(false, "Prix de l'item non défini")
        return
    end

    if category == "caisses" then
        
        if isOpeningCase then
            local totalPrice = item.price * (quantity or 1)
            MySQL.Async.fetchScalar('SELECT credits FROM player_boutique WHERE identifier = @identifier', {
                ['@identifier'] = xPlayer.identifier
            }, function(currentCredits)
                
                if not currentCredits or currentCredits < totalPrice then
                    cb(false, "Crédits insuffisants")
                    return
                end
                MySQL.Async.execute('UPDATE player_boutique SET credits = credits - @amount WHERE identifier = @identifier', {
                    ['@identifier'] = xPlayer.identifier,
                    ['@amount'] = totalPrice
                }, function(rowsChanged)
                    
                    if rowsChanged > 0 then
                        GetPlayerCredits(xPlayer.identifier, function(newCredits)
                            TriggerClientEvent('alz-boutique:updateCredits', xPlayer.source, newCredits)
                            xPlayer.showNotification("~r~-" .. totalPrice .. " crédits")
                        end)
                        AddToHistory(xPlayer.identifier, itemName, item.name, totalPrice)
                        cb(true)
                    else
                        cb(false, "Erreur lors de la déduction des crédits")
                    end
                end)
            end)
        else
            cb(true)
        end
        return
    end
    local totalPrice = item.price * (quantity or 1)
    MySQL.Async.fetchScalar('SELECT credits FROM player_boutique WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(currentCredits)
        if not currentCredits or currentCredits < totalPrice then
            cb(false, "Crédits insuffisants")
            return
        end
        MySQL.Async.execute('UPDATE player_boutique SET credits = credits - @amount WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier,
            ['@amount'] = totalPrice
        }, function(rowsChanged)
            if rowsChanged > 0 then
                GetPlayerCredits(xPlayer.identifier, function(newCredits)
                    TriggerClientEvent('alz-boutique:updateCredits', xPlayer.source, newCredits)
                end)
                if category == "packs" then
                    success = ProcessPack(xPlayer, item)
                    if success then
                        AddToHistory(xPlayer.identifier, itemName, item.name, totalPrice)
                        cb(true)
                    else
                        AddCredits(xPlayer.identifier, totalPrice)
                        cb(false, "Erreur lors de l'attribution des items du pack")
                    end
                    return
                end
                MySQL.Async.execute("INSERT INTO pending_items (identifier, category, item_name, item_label, quantity, price) VALUES (@identifier, @category, @item_name, @item_label, @quantity, @price)", {
                    ["@identifier"] = xPlayer.identifier,
                    ["@category"] = category,
                    ["@item_name"] = itemName,
                    ["@item_label"] = item.name,
                    ["@quantity"] = quantity or 1,
                    ["@price"] = totalPrice
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        AddToHistory(xPlayer.identifier, itemName, item.name, totalPrice)
                        UpdatePendingItemCount(xPlayer.source)
                        cb(true)
                    else
                        AddCredits(xPlayer.identifier, totalPrice)
                        cb(false, "Erreur lors de l'ajout à l'inventaire")
                    end
                end)
            else
                cb(false, "Erreur lors de la déduction des crédits")
            end
        end)
    end)
end)

function ProcessPack(xPlayer, pack)
    local success = true
    local hasErrors = false
    local notifications = {}
    if not pack.content then
        return false
    end
    if pack.content.vehicles then
        for _, vehicle in ipairs(pack.content.vehicles) do
            local plate = GeneratePlate()
            
            MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle, type) VALUES (@owner, @plate, @vehicle, 'car')", {
                ["@owner"] = xPlayer.identifier,
                ["@plate"] = plate,
                ["@vehicle"] = json.encode({ model = vehicle.model, plate = plate })
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    table.insert(notifications, {
                        type = "success",
                        message = "Véhicule reçu: " .. vehicle.name
                    })
                else
                    hasErrors = true
                    table.insert(notifications, {
                        type = "error",
                        message = "Erreur lors de l'ajout du véhicule: " .. vehicle.name
                    })
                end
            end)
            AddToHistory(xPlayer.identifier, vehicle.model, "Pack: " .. vehicle.name, 0)
        end
    end
    if pack.content.weapons then
        for _, weapon in ipairs(pack.content.weapons) do
            if Config.WeaponItem then
                local itemName = weapon.model
                if string.find(itemName, "weapon_") then
                    local weaponItemName = string.gsub(itemName, "weapon_", "")
                    local added = xPlayer.addInventoryItem(weaponItemName, 1)
                    local addSuccess = false
                    
                    if type(added) == 'table' and added.id then
                        addSuccess = true
                    elseif added == true then
                        addSuccess = true
                    elseif type(added) == 'number' and added > 0 then
                        addSuccess = true
                    end
                    
                    if not addSuccess then
                        added = xPlayer.addInventoryItem(itemName, 1)
                    end
                    
                    if (type(added) == 'table' and added.id) or added == true or (type(added) == 'number' and added > 0) then
                        table.insert(notifications, {
                            type = "success",
                            message = "Item d'arme reçu: " .. weapon.name
                        })
                        AddToHistory(xPlayer.identifier, weaponItemName, "Pack (Item): " .. weapon.name, 0)
                    else
                        xPlayer.addWeapon(weapon.model, weapon.ammo or 100)
                        
                        table.insert(notifications, {
                            type = "success",
                            message = "Arme reçue: " .. weapon.name .. " (équipée)"
                        })
                        AddToHistory(xPlayer.identifier, weapon.model, "Pack: " .. weapon.name, 0)
                    end
                else
                    local added = xPlayer.addInventoryItem(itemName, 1)
                    
                    if (type(added) == 'table' and added.id) or added == true or (type(added) == 'number' and added > 0) then
                        table.insert(notifications, {
                            type = "success",
                            message = "Item d'arme reçu: " .. weapon.name
                        })
                        AddToHistory(xPlayer.identifier, itemName, "Pack (Item): " .. weapon.name, 0)
                    else
                        hasErrors = true
                        table.insert(notifications, {
                            type = "error",
                            message = "Erreur lors de l'ajout de l'item d'arme: " .. weapon.name
                        })
                    end
                end
            else
                xPlayer.addWeapon(weapon.model, weapon.ammo or 100)
                
                table.insert(notifications, {
                    type = "success",
                    message = "Arme reçue: " .. weapon.name
                })
                AddToHistory(xPlayer.identifier, weapon.model, "Pack: " .. weapon.name, 0)
            end
        end
    end
    if pack.content.items then
        for _, item in ipairs(pack.content.items) do
            local added = xPlayer.addInventoryItem(item.item, item.count or 1)
            
            if (type(added) == 'table' and added.id) or added == true or (type(added) == 'number' and added > 0) then
                table.insert(notifications, {
                    type = "success",
                    message = "Item reçu: " .. item.name .. " x" .. (item.count or 1)
                })
                AddToHistory(xPlayer.identifier, item.item, "Pack: " .. item.name, 0)
            else
                hasErrors = true
                table.insert(notifications, {
                    type = "error",
                    message = "Erreur lors de l'ajout de l'item: " .. item.name
                })
                success = false
            end
        end
    end
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        xPlayer.showNotification("~g~Pack ~w~" .. pack.name .. "~g~ acheté avec succès!")
        for i, notif in ipairs(notifications) do
            Citizen.Wait(300)
            if notif.type == "success" then
                xPlayer.showNotification("~g~" .. notif.message)
            else
                xPlayer.showNotification("~r~" .. notif.message)
            end
        end
    end)
    
    return not hasErrors
end

RegisterCommand('addcredits', function(source, args)
    if source == 0 then
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])
        
        if targetId and amount then
            local xTarget = ESX.GetPlayerFromId(targetId)
            if xTarget then
                AddCredits(xTarget.identifier, amount)
                print('^2Vous avez ajouté ' .. amount .. ' crédits à ' .. xTarget.getName())
                xTarget.showNotification('~g~Vous avez reçu ' .. amount .. ' crédits')
            else
                print('^1Joueur non trouvé')
            end
        else
            print('^3Usage: addcredits [id] [montant]')
        end
        return
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer and xPlayer.getGroup() == 'admin' then
        local targetId = tonumber(args[1])
        local amount = tonumber(args[2])
        
        if targetId and amount then
            local xTarget = ESX.GetPlayerFromId(targetId)
            if xTarget then
                AddCredits(xTarget.identifier, amount)
                xPlayer.showNotification('~g~Vous avez ajouté ' .. amount .. ' crédits à ' .. xTarget.getName())
                xTarget.showNotification('~g~Vous avez reçu ' .. amount .. ' crédits')
            else
                xPlayer.showNotification('~r~Joueur non trouvé')
            end
        else
            xPlayer.showNotification('~r~Usage: /addcredits [id] [montant]')
        end
    else
        if xPlayer then
            xPlayer.showNotification('~r~Vous n\'avez pas les permissions nécessaires')
        end
    end
end)

function GeneratePlate()
    local plate = ""
    local possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    repeat
        plate = ""
        for i = 1, 8 do
            local rand = math.random(1, #possible)
            plate = plate .. string.sub(possible, rand, rand)
        end
        local result = MySQL.Sync.fetchScalar('SELECT 1 FROM owned_vehicles WHERE plate = @plate', {
            ['@plate'] = plate
        })
    until not result
    
    return plate
end

function AddToHistory(identifier, itemName, itemLabel, price)
    MySQL.Async.execute('INSERT INTO purchase_history (identifier, item_name, item_label, price) VALUES (@identifier, @itemName, @itemLabel, @price)', {
        ['@identifier'] = identifier,
        ['@itemName'] = itemName,
        ['@itemLabel'] = itemLabel,
        ['@price'] = price
    })
end

ESX.RegisterServerCallback('alz-boutique:getPurchaseHistory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM purchase_history WHERE identifier = @identifier ORDER BY purchase_date DESC', {
            ['@identifier'] = xPlayer.identifier
        }, function(results)
            cb(results)
        end)
    else
        cb({})
    end
end)

ESX.RegisterServerCallback('alz-boutique:getBoxWinningItem', function(source, cb, caseId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Joueur non trouvé")
        return
    end
    local caseItem = nil
    for _, item in ipairs(Config.Items["caisses"]) do
        if item.spawnName == caseId then
            caseItem = item
            break
        end
    end
    
    if not caseItem or not caseItem.possible_items then
        cb(false, "Caisse non trouvée ou mal configurée")
        return
    end
    local winningIndex = math.random(1, #caseItem.possible_items)
    local winningItem = caseItem.possible_items[winningIndex]
    cb({
        success = true,
        winningIndex = winningIndex,
        winningItem = winningItem
    })
end)

ESX.RegisterServerCallback('alz-boutique:casePrizeWon', function(source, cb, caseId, prizeItem)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Joueur non trouvé")
        return
    end
    local success = false
    local message = "Erreur lors de l'attribution du prix"
    
    if prizeItem.type == 'vehicle' then
        local plate = GeneratePlate()
        MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle, type) VALUES (@owner, @plate, @vehicle, 'car')", {
            ["@owner"] = xPlayer.identifier,
            ["@plate"] = plate,
            ["@vehicle"] = json.encode({ model = prizeItem.spawnName, plate = plate })
        }, function(rowsChanged)
            if rowsChanged > 0 then
                success = true
                AddToHistory(xPlayer.identifier, prizeItem.spawnName, prizeItem.name, 0)
                xPlayer.showNotification('~g~Vous avez gagné le véhicule ' .. prizeItem.name)
            end
            cb(success, message)
        end)
    elseif prizeItem.type == 'weapon' then
        if Config.WeaponItem then
            local success = false
            local itemName = prizeItem.spawnName
            
            if string.find(itemName, "weapon_") then
                local weaponItemName = string.gsub(itemName, "weapon_", "")
                local added = xPlayer.addInventoryItem(weaponItemName, 1)
                local addSuccess = false
                
                if type(added) == 'table' and added.id then
                    addSuccess = true
                elseif added == true then
                    addSuccess = true
                elseif type(added) == 'number' and added > 0 then
                    addSuccess = true
                end
                
                if not addSuccess then
                    added = xPlayer.addInventoryItem(itemName, 1)
                    
                    if type(added) == 'table' and added.id then
                        addSuccess = true
                    elseif added == true then
                        addSuccess = true
                    elseif type(added) == 'number' and added > 0 then
                        addSuccess = true
                    end
                end
                
                if addSuccess then
                    AddToHistory(xPlayer.identifier, itemName, prizeItem.name .. " (Item)", 0)
                    xPlayer.showNotification('~g~Vous avez gagné l\'item d\'arme ' .. prizeItem.name)
                else
                    xPlayer.addWeapon(itemName, 100)
                    success = true
                    AddToHistory(xPlayer.identifier, itemName, prizeItem.name, 0)
                    xPlayer.showNotification('~g~Vous avez gagné l\'arme ' .. prizeItem.name .. ' (équipée directement)')
                end
            else
                success = xPlayer.addInventoryItem(itemName, 1)
                
                if success then
                    AddToHistory(xPlayer.identifier, itemName, prizeItem.name .. " (Item)", 0)
                    xPlayer.showNotification('~g~Vous avez gagné l\'item d\'arme ' .. prizeItem.name)
                else
                    message = "Erreur lors de l'ajout de l'item d'arme"
                end
            end
        else
            xPlayer.addWeapon(prizeItem.spawnName, 100)
            success = true
            AddToHistory(xPlayer.identifier, prizeItem.spawnName, prizeItem.name, 0)
            xPlayer.showNotification('~g~Vous avez gagné l\'arme ' .. prizeItem.name)
        end
        cb(success, message)
    elseif prizeItem.type == 'money' then
        if prizeItem.amount and tonumber(prizeItem.amount) then
            xPlayer.addMoney(tonumber(prizeItem.amount))
            success = true
            AddToHistory(xPlayer.identifier, 'money', 'Argent: $' .. prizeItem.amount, 0)
            xPlayer.showNotification('~g~Vous avez gagné $' .. prizeItem.amount)
        else
            message = "Montant d'argent invalide"
        end
        cb(success, message)
    elseif prizeItem.type == 'item' then
        if prizeItem.spawnName then
            local itemCount = prizeItem.count or 1
            local added = xPlayer.addInventoryItem(prizeItem.spawnName, itemCount)
            if type(added) == 'table' and added.id then
                success = true
            elseif added == true then
                success = true
            elseif type(added) == 'number' and added > 0 then
                success = true
            else
                 message = "Erreur lors de l'ajout de l'item à l'inventaire"
            end
            if success then
                AddToHistory(xPlayer.identifier, prizeItem.spawnName, prizeItem.name, 0)
                xPlayer.showNotification('~g~Vous avez gagné ' .. prizeItem.name .. (itemCount > 1 and (" x" .. itemCount) or ""))
            end
        else
            message = "Nom de l'item manquant"
        end
        cb(success, message)
    else
        cb(false, "Type d'item invalide: " .. tostring(prizeItem.type))
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    print("^2Ce script a été fait par ^1Alez^0 - ^5discord.gg/VJEuqYkSWt^0")
end)

function UpdatePendingItemCount(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM pending_items WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(count)
        TriggerClientEvent('alz-boutique:updatePendingItemCount', source, count or 0)
    end)
end

ESX.RegisterServerCallback('alz-boutique:getPendingItems', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        MySQL.Async.fetchAll('SELECT * FROM pending_items WHERE identifier = @identifier ORDER BY purchase_date DESC', {
            ['@identifier'] = xPlayer.identifier
        }, function(results)
            cb(results)
        end)
    else
        cb({})
    end
end)

ESX.RegisterServerCallback('alz-boutique:claimItem', function(source, cb, itemId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Joueur non trouvé")
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM pending_items WHERE id = @id AND identifier = @identifier', {
        ['@id'] = itemId,
        ['@identifier'] = xPlayer.identifier
    }, function(results)
        if #results == 0 then
            cb(false, "Item non trouvé dans votre inventaire")
            return
        end
        
        local pendingItem = results[1]
        local success = false
        local message = "Erreur lors de la réclamation de l'item"
        
        if pendingItem.category == "vehicules" then
            local plate = GeneratePlate()
            MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle, type) VALUES (@owner, @plate, @vehicle, 'car')", {
                ["@owner"] = xPlayer.identifier,
                ["@plate"] = plate,
                ["@vehicle"] = json.encode({ model = pendingItem.item_name, plate = plate })
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    MySQL.Async.execute('DELETE FROM pending_items WHERE id = @id', {
                        ['@id'] = itemId
                    })
                    
                    xPlayer.showNotification('~g~Vous avez réclamé le véhicule ' .. pendingItem.item_label)
                    UpdatePendingItemCount(source)
                    
                    cb(true)
                else
                    cb(false, "Erreur lors de l'attribution du véhicule")
                end
            end)
        elseif pendingItem.category == "armes" then
            local itemName = pendingItem.item_name
            local addSuccess = false
            
            if Config.WeaponItem then
                if string.find(itemName, "weapon_") then
                    local weaponItemName = string.gsub(itemName, "weapon_", "")
                    local added = xPlayer.addInventoryItem(weaponItemName, pendingItem.quantity)
                    
                    if (type(added) == 'table' and added.id) or added == true or (type(added) == 'number' and added > 0) then
                        addSuccess = true
                        message = "Arme ajoutée à votre inventaire"
                    else
                        added = xPlayer.addInventoryItem(itemName, pendingItem.quantity)
                        if (type(added) == 'table' and added.id) or added == true or (type(added) == 'number' and added > 0) then
                            addSuccess = true
                            message = "Arme ajoutée à votre inventaire"
                        end
                    end
                    
                    if not addSuccess then
                        xPlayer.addWeapon(itemName, 100)
                        addSuccess = true
                        message = "Arme équipée directement"
                    end
                else
                    local added = xPlayer.addInventoryItem(itemName, pendingItem.quantity)
                    if (type(added) == 'table' and added.id) or added == true or (type(added) == 'number' and added > 0) then
                        addSuccess = true
                        message = "Item ajouté à votre inventaire"
                    end
                end
            else
                xPlayer.addWeapon(itemName, 100)
                addSuccess = true
                message = "Arme équipée directement"
            end
            
            if addSuccess then
                MySQL.Async.execute('DELETE FROM pending_items WHERE id = @id', {
                    ['@id'] = itemId
                }, function(rowsDeleted)
                    if rowsDeleted > 0 then
                        xPlayer.showNotification('~g~Vous avez réclamé: ' .. pendingItem.item_label .. ' | ' .. message)
                        UpdatePendingItemCount(source)
                        cb(true)
                    else
                        cb(false, "Erreur lors de la suppression de l'item en attente")
                    end
                end)
            else
                cb(false, "Erreur lors de l'attribution de l'arme")
            end
        elseif pendingItem.category == "consommables" then
            local added = xPlayer.addInventoryItem(pendingItem.item_name, pendingItem.quantity)
            
            if type(added) == 'table' and added.id then
                success = true
            elseif added == true then
                success = true
            elseif type(added) == 'number' and added > 0 then
                success = true
            end
            
            if success then
                MySQL.Async.execute('DELETE FROM pending_items WHERE id = @id', {
                    ['@id'] = itemId
                })
                
                xPlayer.showNotification('~g~Vous avez réclamé: ' .. pendingItem.quantity .. 'x ' .. pendingItem.item_label)
                UpdatePendingItemCount(source)
                
                cb(true)
            else
                cb(false, "Erreur lors de l'attribution de l'item")
            end
        else
            cb(false, "Type d'item non pris en charge")
        end
    end)
end)

ESX.RegisterServerCallback('alz-boutique:refundItem', function(source, cb, itemId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Joueur non trouvé")
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM pending_items WHERE id = @id AND identifier = @identifier', {
        ['@id'] = itemId,
        ['@identifier'] = xPlayer.identifier
    }, function(results)
        if #results == 0 then
            cb(false, "Item non trouvé dans votre inventaire")
            return
        end
        
        local pendingItem = results[1]
        AddCredits(xPlayer.identifier, pendingItem.price)
        MySQL.Async.execute('DELETE FROM pending_items WHERE id = @id', {
            ['@id'] = itemId
        }, function(rowsChanged)
            if rowsChanged > 0 then
                xPlayer.showNotification('~g~Vous avez été remboursé de ' .. pendingItem.price .. ' crédits pour: ' .. pendingItem.item_label)
                UpdatePendingItemCount(source)
                GetPlayerCredits(xPlayer.identifier, function(newCredits)
                    TriggerClientEvent('alz-boutique:updateCredits', xPlayer.source, newCredits)
                end)
                
                cb(true)
            else
                cb(false, "Erreur lors du remboursement")
            end
        end)
    end)
end)

function IsPlayerBoutiqueAdmin(identifier, cb)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM boutique_admins WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(count)
        cb(count > 0)
    end)
end

RegisterCommand('addboutiqueadmin', function(source, args)
    if source == 0 then
        if not args[1] then
            print('^3Usage: addboutiqueadmin [id]')
            return
        end
        
        local targetId = tonumber(args[1])
        local xTarget = ESX.GetPlayerFromId(targetId)
        
        if not xTarget then
            print('^1Joueur non trouvé')
            return
        end
        
        MySQL.Async.execute('INSERT INTO boutique_admins (identifier, added_by) VALUES (@identifier, @added_by) ON DUPLICATE KEY UPDATE added_by = @added_by', {
            ['@identifier'] = xTarget.identifier,
            ['@added_by'] = 'console'
        }, function(rowsChanged)
            if rowsChanged > 0 then
                print('^2Le joueur ' .. xTarget.getName() .. ' est maintenant administrateur de la boutique')
                xTarget.showNotification('~g~Vous êtes maintenant administrateur de la boutique')
                TriggerClientEvent('alz-boutique:updateAdminStatus', targetId, true)
            else
                print('^1Erreur lors de l\'ajout de l\'administrateur')
            end
        end)
        
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and (xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'owner') then
        if not args[1] then
            xPlayer.showNotification('~r~Usage: /addboutiqueadmin [id]')
            return
        end
        
        local targetId = tonumber(args[1])
        local xTarget = ESX.GetPlayerFromId(targetId)
        
        if not xTarget then
            xPlayer.showNotification('~r~Joueur non trouvé')
            return
        end
        
        MySQL.Async.execute('INSERT INTO boutique_admins (identifier, added_by) VALUES (@identifier, @added_by) ON DUPLICATE KEY UPDATE added_by = @added_by', {
            ['@identifier'] = xTarget.identifier,
            ['@added_by'] = xPlayer.identifier
        }, function(rowsChanged)
            if rowsChanged > 0 then
                xPlayer.showNotification('~g~Le joueur ' .. xTarget.getName() .. ' est maintenant administrateur de la boutique')
                xTarget.showNotification('~g~Vous êtes maintenant administrateur de la boutique')
                TriggerClientEvent('alz-boutique:updateAdminStatus', targetId, true)
            else
                xPlayer.showNotification('~r~Erreur lors de l\'ajout de l\'administrateur')
            end
        end)
    else
        IsPlayerBoutiqueAdmin(xPlayer.identifier, function(isAdmin)
            if isAdmin then
                if not args[1] then
                    xPlayer.showNotification('~r~Usage: /addboutiqueadmin [id]')
                    return
                end
                
                local targetId = tonumber(args[1])
                local xTarget = ESX.GetPlayerFromId(targetId)
                
                if not xTarget then
                    xPlayer.showNotification('~r~Joueur non trouvé')
                    return
                end
                
                MySQL.Async.execute('INSERT INTO boutique_admins (identifier, added_by) VALUES (@identifier, @added_by) ON DUPLICATE KEY UPDATE added_by = @added_by', {
                    ['@identifier'] = xTarget.identifier,
                    ['@added_by'] = xPlayer.identifier
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        xPlayer.showNotification('~g~Le joueur ' .. xTarget.getName() .. ' est maintenant administrateur de la boutique')
                        xTarget.showNotification('~g~Vous êtes maintenant administrateur de la boutique')
                        TriggerClientEvent('alz-boutique:updateAdminStatus', targetId, true)
                    else
                        xPlayer.showNotification('~r~Erreur lors de l\'ajout de l\'administrateur')
                    end
                end)
            else
                xPlayer.showNotification('~r~Vous n\'avez pas les permissions nécessaires')
            end
        end)
    end
end)

RegisterCommand('removeboutiqueadmin', function(source, args)
    if source == 0 then
        if not args[1] then
            print('^3Usage: removeboutiqueadmin [id]')
            return
        end
        
        local targetId = tonumber(args[1])
        local xTarget = ESX.GetPlayerFromId(targetId)
        
        if not xTarget then
            print('^1Joueur non trouvé')
            return
        end
        
        MySQL.Async.execute('DELETE FROM boutique_admins WHERE identifier = @identifier', {
            ['@identifier'] = xTarget.identifier
        }, function(rowsChanged)
            if rowsChanged > 0 then
                print('^2Le joueur ' .. xTarget.getName() .. ' n\'est plus administrateur de la boutique')
                xTarget.showNotification('~r~Vous n\'êtes plus administrateur de la boutique')
                TriggerClientEvent('alz-boutique:updateAdminStatus', targetId, false)
            else
                print('^1Erreur: Le joueur n\'était pas administrateur de la boutique')
            end
        end)
        
        return
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and (xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'owner') then
        if not args[1] then
            xPlayer.showNotification('~r~Usage: /removeboutiqueadmin [id]')
            return
        end
        
        local targetId = tonumber(args[1])
        local xTarget = ESX.GetPlayerFromId(targetId)
        
        if not xTarget then
            xPlayer.showNotification('~r~Joueur non trouvé')
            return
        end
        
        MySQL.Async.execute('DELETE FROM boutique_admins WHERE identifier = @identifier', {
            ['@identifier'] = xTarget.identifier
        }, function(rowsChanged)
            if rowsChanged > 0 then
                xPlayer.showNotification('~g~Le joueur ' .. xTarget.getName() .. ' n\'est plus administrateur de la boutique')
                xTarget.showNotification('~r~Vous n\'êtes plus administrateur de la boutique')
                TriggerClientEvent('alz-boutique:updateAdminStatus', targetId, false)
            else
                xPlayer.showNotification('~r~Erreur: Le joueur n\'était pas administrateur de la boutique')
            end
        end)
    else
        IsPlayerBoutiqueAdmin(xPlayer.identifier, function(isAdmin)
            if isAdmin then
                if not args[1] then
                    xPlayer.showNotification('~r~Usage: /removeboutiqueadmin [id]')
                    return
                end
                
                local targetId = tonumber(args[1])
                local xTarget = ESX.GetPlayerFromId(targetId)
                
                if not xTarget then
                    xPlayer.showNotification('~r~Joueur non trouvé')
                    return
                end
                
                MySQL.Async.execute('DELETE FROM boutique_admins WHERE identifier = @identifier', {
                    ['@identifier'] = xTarget.identifier
                }, function(rowsChanged)
                    if rowsChanged > 0 then
                        xPlayer.showNotification('~g~Le joueur ' .. xTarget.getName() .. ' n\'est plus administrateur de la boutique')
                        xTarget.showNotification('~r~Vous n\'êtes plus administrateur de la boutique')
                        TriggerClientEvent('alz-boutique:updateAdminStatus', targetId, false)
                    else
                        xPlayer.showNotification('~r~Erreur: Le joueur n\'était pas administrateur de la boutique')
                    end
                end)
            else
                xPlayer.showNotification('~r~Vous n\'avez pas les permissions nécessaires')
            end
        end)
    end
end)

ESX.RegisterServerCallback('alz-boutique:isPlayerBoutiqueAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    if xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'owner' then
        cb(true)
        return
    end
    IsPlayerBoutiqueAdmin(xPlayer.identifier, function(isAdmin)
        cb(isAdmin)
    end)
end)

ESX.RegisterServerCallback('alz-boutique:addCreditsAdmin', function(source, cb, targetId, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Erreur: administrateur non trouvé")
        return
    end
    if xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'owner' then
        AddCreditsToPlayer(targetId, amount, cb)
    else
        IsPlayerBoutiqueAdmin(xPlayer.identifier, function(isAdmin)
            if isAdmin then
                AddCreditsToPlayer(targetId, amount, cb)
            else
                cb(false, "Vous n'avez pas les permissions nécessaires")
            end
        end)
    end
end)

ESX.RegisterServerCallback('alz-boutique:removeCreditsAdmin', function(source, cb, targetId, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Erreur: administrateur non trouvé")
        return
    end
    if xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'owner' then
        RemoveCreditsFromPlayer(targetId, amount, cb)
    else
        IsPlayerBoutiqueAdmin(xPlayer.identifier, function(isAdmin)
            if isAdmin then
                RemoveCreditsFromPlayer(targetId, amount, cb)
            else
                cb(false, "Vous n'avez pas les permissions nécessaires")
            end
        end)
    end
end)

function AddCreditsToPlayer(targetId, amount, cb)
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        if cb then cb(false, "Montant invalide") end
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        if cb then cb(false, "Joueur non trouvé") end
        return
    end
    
    AddCredits(xTarget.identifier, amount)
    xTarget.showNotification('~g~Vous avez reçu ' .. amount .. ' crédits')
    
    if cb then cb(true, "Crédits ajoutés avec succès") end
end
function RemoveCreditsFromPlayer(targetId, amount, cb)
    amount = tonumber(amount)
    
    if not amount or amount <= 0 then
        if cb then cb(false, "Montant invalide") end
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    
    if not xTarget then
        if cb then cb(false, "Joueur non trouvé") end
        return
    end
    GetPlayerCredits(xTarget.identifier, function(currentCredits)
        if currentCredits < amount then
            if cb then cb(false, "Le joueur n'a pas assez de crédits") end
            return
        end
        
        RemoveCredits(xTarget.identifier, amount, function(success)
            if success then
                xTarget.showNotification('~r~' .. amount .. ' crédits ont été retirés de votre compte')
                if cb then cb(true, "Crédits retirés avec succès") end
            else
                if cb then cb(false, "Erreur lors du retrait des crédits") end
            end
        end)
    end)
end 
