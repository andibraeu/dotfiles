-- Zentraler Autostart (nur bei Session-Start, nicht bei hyprctl reload)
hl.on("hyprland.start", function()
    -- graphical-session.target wird ohne UWSM nie aktiv, daher explizit starten
    hl.exec_cmd("systemctl --user restart hyprpaper")
    hl.exec_cmd("hypridle")
    require("autostart")()
end)
