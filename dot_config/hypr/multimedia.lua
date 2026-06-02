local mainMod = "SUPER"

hl.bind(mainMod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("volumectl down"), { locked = true, repeating = true })
hl.bind(mainMod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("volumectl up"),   { locked = true, repeating = true })
hl.bind(mainMod .. " + F12", hl.dsp.exec_cmd("volumectl toggle-mute"), { locked = true })
hl.bind(mainMod .. " + F4", hl.dsp.exec_cmd("light -U 5"), { locked = true, repeating = true })
hl.bind(mainMod .. " + F5", hl.dsp.exec_cmd("light -A 5"), { locked = true, repeating = true })
