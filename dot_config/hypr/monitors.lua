local mainMod = "SUPER"

-- Interner Laptop-Bildschirm
local laptop = "eDP-1"
-- Externer Monitor (Name aus `hyprctl monitors` – am Dock oft DP-3 statt HDMI-A-2)
local external = "HDMI-A-2"

local mirrored = false

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.25 })
hl.monitor({ output = "desc:Dell Inc. DELL U3419W 6R576T2", mode = "preferred", position = "1560x200", scale = 1.25 })
hl.monitor({ output = laptop, mode = "preferred", position = "0x0", scale = 1.25 })

local function notify(msg)
    hl.exec_cmd('notify-send "Hyprland" "' .. msg .. '"')
end

local function applyExtended()
    hl.monitor({ output = laptop, mode = "preferred", position = "0x0", scale = 1.25 })
    hl.monitor({ output = external, mode = "preferred", position = "auto", scale = 1.25 })
end

local function applyMirror()
    hl.monitor({ output = laptop, mode = "preferred", position = "0x0", scale = 1.25 })
    hl.monitor({
        output   = external,
        mode     = "preferred",
        position = "0x0",
        scale    = 1.25,
        mirror   = laptop,
    })
end

local function toggleMirror()
    if not hl.get_monitor(external) then
        notify("Kein Monitor „" .. external .. "“ – Name in monitors.lua prüfen")
        return
    end

    if mirrored then
        applyExtended()
        notify("Erweiterte Anzeige")
    else
        applyMirror()
        notify("Bildschirm spiegeln")
    end
    mirrored = not mirrored
end

hl.bind(mainMod .. " + SHIFT + M", toggleMirror)

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.env("GDK_SCALE", "1.25")
