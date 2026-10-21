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

-- Workspaces 1–10 gehören auf den Dell, sobald er da ist.
-- Hyprland legt auf dem Laptop automatisch einen leeren Extra-Workspace an.
for i = 1, 10 do
    hl.workspace_rule({
        workspace  = tostring(i),
        monitor    = dell,
        default    = (i == 1),
        -- 2–6 immer anlegen, analog zu waybar persistent-workspaces
        persistent = (i >= 2 and i <= 6),
    })
end

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    cursor = {
        default_monitor = dell,
    },
})

local function notify(msg)
    hl.exec_cmd('notify-send "Hyprland" "' .. msg .. '"')
end

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
    if isMirroring() then
        return
    end

    local ext = getExternal()
    if not ext then
        return
    end

    local active = hl.get_active_workspace()
    local activeId = active and active.id or nil

    for _, ws in ipairs(hl.get_workspaces() or {}) do
        if not ws.special and ws.id >= 1 and ws.id <= 10 then
            local mon = ws.monitor
            if not mon or mon.name ~= ext.name then
                hl.dispatch(hl.dsp.workspace.move({
                    workspace = ws.id,
                    monitor   = ext.name,
                }))
            end
        end
    end

    if activeId and activeId >= 1 and activeId <= 10 then
        hl.dispatch(hl.dsp.focus({ workspace = activeId }))
    end
end

-- monitor.added hat nur ~50ms Callback-Timeout; kurz warten, bis der Output steht.
local function scheduleMove()
    hl.timer(moveWorkspacesToExternal, { timeout = 250, type = "oneshot" })
end

hl.on("monitor.added", function(mon)
    if not mon or mon.name == laptop then
        return
    end
    scheduleMove()
end)

hl.on("hyprland.start", scheduleMove)
hl.on("config.reloaded", scheduleMove)

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

hl.bind(mainMod .. " + SHIFT + M", toggleMirror)

hl.env("GDK_SCALE", "1.25")
