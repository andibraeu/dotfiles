local mainMod = "SUPER"

-- Interner Laptop-Bildschirm, Ursprung der Anordnung
local laptop = "eDP-1"
-- Beide externen Monitore teilen sich einen USB-C-Port.
-- Der andere Port bleibt für den Magnetadapter zum Laden frei.
-- Zugeordnet wird über das Modell, der Anschlussname (DP-1, DP-3, …) spielt keine Rolle.
-- Bisheriger Ultrawide, rechts vom Laptop.
local dell = "desc:Dell Inc. DELL U3419W 6R576T2"
-- Zweiter Arbeitsplatz: Philips links vom Laptop.
local philips = "desc:Philips Consumer Electronics Company 34B2U3600CH UK02527039126"

local laptopPos = "0x0"
-- Bestehende Position des Dell, unverändert rechts vom Laptop.
local rightPos = "1560x200"
-- 3440×1440 bei Skalierung 1.25 → 2752 logische Pixel, bündig links vom Laptop.
-- Vertikal wie der Dell (y=200), beide Ultrawides sind gleich groß.
local leftPos = "-2752x200"

local lastExternalName = nil

local function descriptionOf(selector)
    return (selector:gsub("^desc:", ""))
end

local function isMonitor(mon, selector)
    if not mon or not selector then
        return false
    end
    return mon.name == selector or mon.description == selector or mon.description == descriptionOf(selector)
end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.25 })
hl.monitor({ output = dell, mode = "preferred", position = rightPos, scale = 1.25 })
hl.monitor({ output = philips, mode = "preferred", position = leftPos, scale = 1.25 })
hl.monitor({ output = laptop, mode = "preferred", position = laptopPos, scale = 1.25 })

-- Workspace 1 gehört dem Laptop, 2–10 dem angeschlossenen externen Monitor.
-- Die Regeln zeigen immer auf den gerade angeschlossenen externen Monitor.
-- Zeigen sie auf einen fehlenden Monitor, legt Hyprland die persistenten
-- Workspaces 2–6 auf dem Laptop an und holt sie bei jedem Reload/Monitorwechsel
-- dorthin zurück.
-- Hinweis: Regeln mit gleichem Workspace-Selektor werden zusammengeführt;
-- ein erneuter hl.workspace_rule-Aufruf überschreibt also den Monitor.
-- Reihenfolge = Priorität, falls mehrere gleichzeitig angeschlossen sind.
local externals = { dell, philips }
local ruleMonitor = nil

local function shellQuote(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function notify(msg, urgency)
    hl.exec_cmd("notify-send -u " .. (urgency or "normal") .. " Hyprland " .. shellQuote(msg))
end

-- Fehler in Callbacks als bleibende Benachrichtigung zeigen, statt nur kurz im Overlay.
local function safe(name, fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            notify("monitors.lua (" .. name .. "): " .. tostring(err), "critical")
        end
    end
end

-- Beim Abstecken können noch Handles auf den gerade entfernten Monitor
-- auftauchen; deren Felder sind dann evtl. nicht mehr lesbar.
local function monitorName(mon)
    if not mon then
        return nil
    end
    local ok, name = pcall(function() return mon.name end)
    return ok and name or nil
end

-- Ohne externen Monitor bleibt der Dell eingetragen, damit 2–6 weiterhin
-- persistent auf dem Laptop existieren.
local function primaryExternal()
    for _, selector in ipairs(externals) do
        if monitorName(hl.get_monitor(selector)) then
            return selector
        end
    end
    return dell
end

local function updateWorkspaceRules()
    local primary = primaryExternal()
    if primary == ruleMonitor then
        return
    end
    ruleMonitor = primary
    hl.workspace_rule({
        workspace = "1",
        monitor   = laptop,
        default   = true,
    })
    for i = 2, 10 do
        hl.workspace_rule({
            workspace  = tostring(i),
            monitor    = primary,
            default    = (i == 2),
            -- 2–6 immer anlegen, analog zu waybar persistent-workspaces
            persistent = (i >= 2 and i <= 6),
        })
    end
    hl.config({ cursor = { default_monitor = primary } })
end

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
updateWorkspaceRules()

local function remember(mon)
    if mon and mon.name then
        lastExternalName = mon.name
    end
    return mon
end

-- Gespiegelte Outputs stehen nicht in get_monitors(); sie hängen an laptop.mirrors.
local function firstMirrorOf(mon)
    local mirrors = mon and mon.mirrors
    if type(mirrors) ~= "table" then
        return nil
    end
    return mirrors[1]
end

local function isMirroring()
    return firstMirrorOf(hl.get_monitor(laptop)) ~= nil
end

local function getExternal()
    local mon = hl.get_monitor(dell)
    if mon then
        return remember(mon)
    end

    local mirrored = firstMirrorOf(hl.get_monitor(laptop))
    if mirrored then
        return remember(mirrored)
    end

    for _, candidate in ipairs(hl.get_monitors() or {}) do
        if candidate.name ~= laptop then
            return remember(candidate)
        end
    end

    if lastExternalName then
        return hl.get_monitor(lastExternalName) or { name = lastExternalName }
    end
    return nil
end

local function moveWorkspacesToExternal()
    updateWorkspaceRules()
    if isMirroring() then
        return
    end

    local ext = getExternal()
    local extName = monitorName(ext)
    if not extName or extName == laptop then
        return
    end

    local active = hl.get_active_workspace()
    local activeId = active and active.id or nil

    for _, ws in ipairs(hl.get_workspaces() or {}) do
        -- Spezial-Workspaces haben negative IDs und fallen hier heraus.
        local id = ws.id
        if type(id) == "number" and id >= 1 and id <= 10 then
            local target = (id == 1) and laptop or extName
            if monitorName(ws.monitor) ~= target then
                hl.dispatch(hl.dsp.workspace.move({
                    workspace = id,
                    monitor   = target,
                }))
            end
        end
    end

    if type(activeId) == "number" and activeId >= 1 and activeId <= 10 then
        hl.dispatch(hl.dsp.focus({ workspace = activeId }))
    end
end

-- monitor.added hat nur ~50ms Callback-Timeout; kurz warten, bis der Output steht.
local function scheduleMove()
    hl.timer(safe("move", moveWorkspacesToExternal), { timeout = 250, type = "oneshot" })
end

hl.on("monitor.added", safe("monitor.added", function(mon)
    local name = monitorName(mon)
    if not name or name == laptop then
        return
    end
    scheduleMove()
end))

hl.on("monitor.removed", safe("monitor.removed", function()
    hl.timer(safe("rules", updateWorkspaceRules), { timeout = 250, type = "oneshot" })
end))

hl.on("hyprland.start", safe("start", scheduleMove))
hl.on("config.reloaded", safe("reload", scheduleMove))

local function applyExtended()
    local ext = getExternal()
    if not ext then
        return
    end
    -- mirror muss explizit auf "none", sonst bleibt die Spiegelung aktiv.
    hl.monitor({
        output   = laptop,
        mode     = "preferred",
        position = laptopPos,
        scale    = 1.25,
        mirror   = "none",
    })
    hl.monitor({
        output   = philips,
        mode     = "preferred",
        position = leftPos,
        scale    = 1.25,
        mirror   = "none",
    })
    hl.monitor({
        output   = dell,
        mode     = "preferred",
        position = rightPos,
        scale    = 1.25,
        mirror   = "none",
    })
    -- Weitere Monitore am selben USB-C, z. B. über das Dock, bleiben rechts.
    if not isMonitor(ext, philips) and not isMonitor(ext, dell) then
        hl.monitor({
            output   = ext.name,
            mode     = "preferred",
            position = rightPos,
            scale    = 1.25,
            mirror   = "none",
        })
    end
end

local function applyMirror()
    local ext = getExternal()
    if not ext then
        return
    end
    hl.monitor({
        output   = laptop,
        mode     = "preferred",
        position = laptopPos,
        scale    = 1.25,
        mirror   = "none",
    })
    hl.monitor({
        output   = ext.name,
        mode     = "preferred",
        position = "0x0",
        scale    = 1.25,
        mirror   = laptop,
    })
end

local function toggleMirror()
    if not getExternal() then
        notify("Kein externer Monitor gefunden")
        return
    end

    if isMirroring() then
        applyExtended()
        notify("Erweiterte Anzeige")
        scheduleMove()
    else
        applyMirror()
        notify("Bildschirm spiegeln")
    end
end

hl.bind(mainMod .. " + SHIFT + M", safe("mirror", toggleMirror))

hl.env("GDK_SCALE", "1.25")
