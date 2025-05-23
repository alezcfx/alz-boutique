local ESX = exports["es_extended"]:getSharedObject()

local display = false
local previewVehicle = nil
local isInPreview = false
local previewCam = nil
local previewCoords = vector4(-1095.51, -3196.6, 13.94, 60.0)
local camOffset = vector3(6.0, 6.0, 2.5)
local originalCoords = nil
local originalAlpha = nil
local currentVehicleData = nil
local isAdmin = false

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

function OpenUI()
    if not isInPreview then
        display = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "show"
        })
        ESX.TriggerServerCallback('alz-boutique:isPlayerBoutiqueAdmin', function(admin)
            isAdmin = admin
            ESX.TriggerServerCallback('alz-boutique:getPlayerInfo', function(info)
                SendNUIMessage({
                    type = "updateUserInfo",
                    identifier = info.identifier,
                    name = info.name
                })
                SendNUIMessage({
                    type = "updateCredits",
                    credits = info.credits
                })
                SendNUIMessage({
                    type = "initializeData",
                    categories = Config.Categories,
                    items = Config.Items,
                    isAdmin = isAdmin
                })
                ESX.TriggerServerCallback('alz-boutique:getPurchaseHistory', function(history)
                    SendNUIMessage({
                        type = "updatePurchaseHistory",
                        history = history
                    })
                end)
            end)
        end)
    end
end

function CloseUI()
    if not isInPreview then
        display = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "hide"
        })
    end
end

function StartPreview(vehicleName)
    for _, vehicle in ipairs(Config.Items.vehicules) do
        if vehicle.spawnName == vehicleName then
            currentVehicleData = vehicle
            break
        end
    end
    
    if not currentVehicleData then
        --ESX.ShowNotification("~r~Véhicule non trouvé")
        return
    end
    
    isInPreview = true
    display = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "hide"
    })
    local ped = PlayerPedId()
    originalCoords = GetEntityCoords(ped)
    originalAlpha = GetEntityAlpha(ped)
    local camPos = vector3(
        previewCoords.x + camOffset.x,
        previewCoords.y + camOffset.y,
        previewCoords.z + camOffset.z
    )
    SetEntityCoords(ped, camPos.x, camPos.y, camPos.z, false, false, false, false)
    SetEntityAlpha(ped, 0, false)
    FreezeEntityPosition(ped, true)
    Wait(500)
    RequestModel(GetHashKey(vehicleName))
    while not HasModelLoaded(GetHashKey(vehicleName)) do
        Wait(1)
    end
    
    previewVehicle = CreateVehicle(GetHashKey(vehicleName), previewCoords.x, previewCoords.y, previewCoords.z, previewCoords.w, false, false)
    SetEntityInvincible(previewVehicle, true)
    FreezeEntityPosition(previewVehicle, true)
    SetVehicleDirtLevel(previewVehicle, 0.0)
    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, camPos.x, camPos.y, camPos.z)
    PointCamAtEntity(previewCam, previewVehicle, 0.0, 0.0, 0.0, true)
    SetCamFov(previewCam, 45.0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 0, true, true)
end

function BuyPreviewVehicle()
    if not currentVehicleData then return end
    local result = KeyboardInput("TAPER 'CONFIRMER' pour confirmer", "", 20)
    
    if result == "CONFIRMER" then
        ESX.TriggerServerCallback('alz-boutique:buyVehicle', function(success, message)
            if success then
                ESX.ShowNotification('~g~Vous avez acheté le véhicule ' .. currentVehicleData.name)
                StopPreview()
            else
                ESX.ShowNotification('~r~' .. message)
            end
        end, currentVehicleData.spawnName, 1)
    else
        ESX.ShowNotification('~r~Achat annulé')
    end
end

function StopPreview()
    if previewVehicle then
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end
    
    if previewCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    local ped = PlayerPedId()
    SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
    SetEntityAlpha(ped, originalAlpha, false)
    FreezeEntityPosition(ped, false)
    
    isInPreview = false
    currentVehicleData = nil
    OpenUI()
end

CreateThread(function()
    while true do
        Wait(0)
        if isInPreview then
            if previewVehicle then
                local rotation = GetEntityRotation(previewVehicle, 2)
                SetEntityRotation(previewVehicle, rotation.x, rotation.y, rotation.z + 0.3, 2, true)
            end
            ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour quitter la prévisualisation")
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("Appuyez sur ~r~X~w~ pour acheter")
            DrawText(0.5, 0.85)
            if IsControlJustPressed(0, 38) then
                StopPreview()
            end
            if IsControlJustPressed(0, 73) then
                BuyPreviewVehicle()
            end
        else
            Wait(500)
        end
    end
end)

RegisterCommand('boutique', function()
    if not isInPreview then
        OpenUI()
    end
end)

RegisterKeyMapping('boutique', 'Ouvrir la boutique', 'keyboard', 'F7')

RegisterNUICallback('close', function(data, cb)
    CloseUI()
    cb('ok')
end)

RegisterNUICallback('previewVehicle', function(data, cb)
    StartPreview(data.vehicle)
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    
    if not data.itemName then
        cb({ success = false, message = "Nom de l'item manquant" })
        return
    end

    if not data.category then
        cb({ success = false, message = "Catégorie manquante" })
        return
    end

    local quantity = tonumber(data.quantity) or 1
    
    ESX.TriggerServerCallback('alz-boutique:buyItem', function(success, message)
        
        if success then
            ESX.TriggerServerCallback('alz-boutique:getPlayerInfo', function(info)
                if info and info.credits then
                    SendNUIMessage({
                        type = "updateCredits",
                        credits = info.credits
                    })
                end
            end)
        end
        
        cb({
            success = success,
            message = message
        })
    end, data.itemName, quantity, data.category, data.isOpeningCase)
end)

RegisterNUICallback('getBoxWinningItem', function(data, cb)
    ESX.TriggerServerCallback('alz-boutique:getBoxWinningItem', function(result)
        cb(result)
    end, data.caseId)
end)

RegisterNetEvent('alz-boutique:updateCredits')
AddEventHandler('alz-boutique:updateCredits', function(credits)
    SendNUIMessage({
        type = "updateCredits",
        credits = credits
    })
end)

RegisterNetEvent('alz-boutique:updatePendingItemCount')
AddEventHandler('alz-boutique:updatePendingItemCount', function(count)
    SendNUIMessage({
        type = "updatePendingItemCount",
        count = count
    })
end)

RegisterNUICallback('getPendingItems', function(data, cb)
    ESX.TriggerServerCallback('alz-boutique:getPendingItems', function(items)
        cb(items)
    end)
end)

RegisterNUICallback('claimItem', function(data, cb)
    if not data.itemId then
        cb({ success = false, message = "ID de l'item manquant" })
        return
    end

    ESX.TriggerServerCallback('alz-boutique:claimItem', function(success, message)
        if success then
            ESX.ShowNotification('~g~Item réclamé avec succès')
        else
            ESX.ShowNotification('~r~' .. (message or "Erreur lors de la réclamation"))
        end
        cb({ success = success, message = message })
    end, data.itemId)
end)

RegisterNUICallback('refundItem', function(data, cb)
    if not data.itemId then
        cb({ success = false, message = "ID de l'item manquant" })
        return
    end

    ESX.TriggerServerCallback('alz-boutique:refundItem', function(success, message)
        if success then
            ESX.ShowNotification('~g~Remboursement effectué avec succès')
        else
            ESX.ShowNotification('~r~' .. (message or "Erreur lors du remboursement"))
        end
        cb({ success = success, message = message })
    end, data.itemId)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    if previewVehicle then
        DeleteEntity(previewVehicle)
        previewVehicle = nil
    end
    
    if previewCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
end)

RegisterNUICallback('showNotification', function(data, cb)
    ESX.ShowNotification(data.message)
    cb('ok')
end)

RegisterNUICallback('casePrizeWon', function(data, cb)
    ESX.TriggerServerCallback('alz-boutique:casePrizeWon', function(success, message)
        if not success then
            ESX.ShowNotification('~r~' .. (message or 'Erreur lors de la réception du prix'))
        end
    end, data.caseId, data.prizeItem)
    cb('ok')
end)


RegisterNetEvent('alz-boutique:updateAdminStatus')
AddEventHandler('alz-boutique:updateAdminStatus', function(admin)
    isAdmin = admin
    if display then
        SendNUIMessage({
            type = "updateAdminStatus",
            isAdmin = isAdmin
        })
    end
end)

RegisterNUICallback('adminAddCredits', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    
    if not targetId or not amount then
        cb({ success = false, message = "ID ou montant invalide" })
        return
    end
    
    ESX.TriggerServerCallback('alz-boutique:addCreditsAdmin', function(success, message)
        cb({ success = success, message = message })
    end, targetId, amount)
end)

RegisterNUICallback('adminRemoveCredits', function(data, cb)
    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    
    if not targetId or not amount then
        cb({ success = false, message = "ID ou montant invalide" })
        return
    end
    
    ESX.TriggerServerCallback('alz-boutique:removeCreditsAdmin', function(success, message)
        cb({ success = success, message = message })
    end, targetId, amount)
end) 
