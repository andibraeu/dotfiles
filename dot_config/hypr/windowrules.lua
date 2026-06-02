hl.window_rule({ match = { class = "firefox" }, workspace = "2" })
hl.window_rule({ match = { class = "kitty" }, workspace = "2" })
hl.window_rule({ match = { class = "google-chrome" }, workspace = "5" })
hl.window_rule({ match = { class = "jetbrains-idea" }, workspace = "4" })
hl.window_rule({ match = { class = "org.gnome.Evolution" }, workspace = "3" })
hl.window_rule({ match = { class = "org.gajim.Gajim" }, workspace = "6" })
hl.window_rule({ match = { class = "org.telegram.desktop" }, workspace = "6" })
hl.window_rule({ match = { class = "signal" }, workspace = "6" })

hl.window_rule({
    match = { title = "Euro Truck Simulator 2" },
    workspace = "8",
    keep_aspect_ratio = true,
})

hl.window_rule({ match = { class = "org.gnome.Calculator" }, float = true })

-- Fix odd behaviors in IntelliJ IDEs
hl.window_rule({
    name  = "jetbrains-splash",
    match = { class = "^(jetbrains-.*)$", title = "^(splash)$", float = true },
    center = true,
    no_focus = true,
    border_size = 0,
})

hl.window_rule({
    name  = "jetbrains-search",
    match = { class = "^(jetbrains-.*)$", float = true, title = "^(?!win)" },
    dim_around = true,
    center = true,
})

hl.window_rule({
    name  = "jetbrains-autocomplete",
    match = { class = "^(jetbrains-.*)$", title = "^(win.*)$" },
    no_anim = true,
    no_initial_focus = true,
    rounding = 0,
})

hl.window_rule({
    name  = "jetbrains-popups",
    match = { class = "^(jetbrains-.*)$", title = "^( )$", float = true },
    center = true,
    stay_focused = true,
    border_size = 0,
})

hl.window_rule({
    name  = "jetbrains-tooltips",
    match = { class = "^(jetbrains-.*)$", title = "^(win.*)$", float = true },
    no_focus = true,
})
