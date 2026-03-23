; ============================================================
;  Yet Another Windows Terminal Launcher
;  Ctrl+Alt+T         -> Launch Windows Terminal (normal)
;  Ctrl+Alt+Shift+T   -> Launch Windows Terminal (elevated)
; ============================================================

; @Ahk2Exe-SetName        Yet Another Windows Terminal Launcher
; @Ahk2Exe-SetDescription Keyboard shortcuts to launch Windows Terminal
; @Ahk2Exe-SetVersion     1.0.0
; @Ahk2Exe-SetCopyright   Copyright (c) 2026, licensed under GPL v3
; @Ahk2Exe-SetCompanyName Joao Fernandes
; @Ahk2Exe-SetOrigFilename YetAnotherWindowsTerminalLauncher.exe
; @Ahk2Exe-SetMainIcon    assets\icon.ico

#Requires AutoHotkey v2.0
#SingleInstance Force

; ── Globals ──────────────────────────────────────────────────
global AppName     := "YetAnotherWindowsTerminalLauncher"
global ExeName     := AppName ".exe"
global InstallDir  := A_AppData "\" AppName
global InstallPath := InstallDir "\" ExeName
global RegKey      := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

; ── First-run check ──────────────────────────────────────────
if !IsInstalled()
    ShowInstallDialog()

; ── System Tray ──────────────────────────────────────────────
A_TrayMenu.Delete()
A_TrayMenu.Add("Yet Another Windows Terminal Launcher", (*) => 0)
A_TrayMenu.Disable("Yet Another Windows Terminal Launcher")
A_TrayMenu.Add()
A_TrayMenu.Add("Launch Terminal`tCtrl+Alt+T",            (*) => LaunchNormal())
A_TrayMenu.Add("Launch Terminal as Admin`tCtrl+Shift+T", (*) => LaunchElevated())
A_TrayMenu.Add()
A_TrayMenu.Add("Uninstall && Exit", (*) => ShowUninstallDialog())
A_TrayMenu.Add("Exit",              (*) => ExitApp())
A_TrayMenu.Default := "Launch Terminal`tCtrl+Alt+T"
A_IconTip := "Yet Another Windows Terminal Launcher"

; ── Hotkeys ──────────────────────────────────────────────────
^!t:: {
    LaunchNormal()
}

^!+t:: {
    LaunchElevated()
}

; ── End of auto-execute section ──────────────────────────────
return

; ============================================================
;  HOTKEY FUNCTIONS
; ============================================================

LaunchNormal() {
    try {
        Run "wt.exe"
    } catch {
        MsgBox "Could not find Windows Terminal.`nMake sure it is installed from the Microsoft Store.", "Error", "IconX"
    }
}

LaunchElevated() {
    try {
        Run "*RunAs wt.exe"
    } catch {
        MsgBox "Could not launch Windows Terminal as Administrator.", "Error", "IconX"
    }
}

; ============================================================
;  INSTALL / UNINSTALL
; ============================================================

IsInstalled() {
    global RegKey, AppName
    try {
        val := RegRead(RegKey, AppName)
        return (val != "")
    } catch {
        return false
    }
}

Install() {
    global InstallDir, InstallPath, RegKey, AppName

    if !DirExist(InstallDir)
        DirCreate InstallDir

    try {
        FileCopy A_ScriptFullPath, InstallPath, 1
    } catch as e {
        MsgBox "Failed to copy file:`n" e.Message, "Install Error", "IconX"
        return
    }

    try {
        RegWrite InstallPath, "REG_SZ", RegKey, AppName
    } catch as e {
        MsgBox "Failed to write to registry:`n" e.Message, "Install Error", "IconX"
        return
    }

    ShowSuccessDialog()
}

Uninstall() {
    global InstallDir, InstallPath, RegKey, AppName

    try {
        RegDelete RegKey, AppName
    } catch {
    }

    if (A_ScriptFullPath = InstallPath) {
        batPath := A_Temp "\uninstall_wtl.bat"
        batContent := "@echo off`r`ntimeout /t 2 /nobreak >nul`r`nrmdir /s /q `"" InstallDir "`"`r`ndel `"%~f0`""
        FileOpen(batPath, "w").Write(batContent)
        Run 'cmd.exe /c "' batPath '"',, "Hide"
    } else {
        try {
            DirDelete InstallDir, 1
        } catch {
        }
    }

    MsgBox "Windows Terminal Launcher has been uninstalled.", "Uninstalled", "Icon!"
    ExitApp()
}

; ============================================================
;  GUI - Install Dialog
; ============================================================

ShowInstallDialog() {
    global InstallDir

    g := Gui("+AlwaysOnTop -SysMenu", "Windows Terminal Launcher")
    g.BackColor := "0D1117"
    g.SetFont("s10 cE6EDF3", "Consolas")

    g.Add("Progress", "x0 y0 w480 h3 Background238636 c238636", 100)

    logo := g.Add("Text", "x0 y14 w480 h50 +Center c58A6FF BackgroundTrans")
    logo.SetFont("s26 Bold", "Consolas")
    logo.Value := ">_"

    title := g.Add("Text", "x0 y66 w480 +Center cE6EDF3 BackgroundTrans")
    title.SetFont("s13 Bold", "Consolas")
    title.Value := "Windows Terminal Launcher"

    sub := g.Add("Text", "x0 y90 w480 +Center c8B949E BackgroundTrans")
    sub.SetFont("s9", "Consolas")
    sub.Value := "Keyboard shortcuts for Windows Terminal"

    g.Add("Progress", "x30 y116 w420 h1 Background30363D c30363D", 100)

    sc1 := g.Add("Text", "x30 y132 w420 c8B949E BackgroundTrans")
    sc1.SetFont("s9", "Consolas")
    sc1.Value := "  Ctrl + Alt + T              Launch Terminal"

    sc2 := g.Add("Text", "x30 y150 w420 c8B949E BackgroundTrans")
    sc2.SetFont("s9", "Consolas")
    sc2.Value := "  Ctrl + Alt + Shift + T      Launch Terminal (Admin)"

    g.Add("Progress", "x30 y174 w420 h1 Background30363D c30363D", 100)

    prompt := g.Add("Text", "x30 y188 w420 cE6EDF3 BackgroundTrans")
    prompt.SetFont("s9", "Consolas")
    prompt.Value := "Install and run automatically at startup?"

    pathLabel := g.Add("Text", "x30 y206 w420 c8B949E BackgroundTrans")
    pathLabel.SetFont("s8", "Consolas")
    pathLabel.Value := "  " InstallDir

    btnInstall := g.Add("Button", "x30 y240 w200 h36", "Install")
    btnInstall.SetFont("s10 Bold", "Consolas")

    btnSkip := g.Add("Button", "x250 y240 w200 h36", "Run without installing")
    btnSkip.SetFont("s9", "Consolas")

    g.Add("Text", "x0 y285 w480 h10 BackgroundTrans", "")

    g.Show("w480 h296")
    MonitorGetWorkArea(, &ml, &mt, &mr, &mb)
    g.Move((mr - ml) // 2 - 240 + ml, (mb - mt) // 2 - 148 + mt)

    btnInstall.OnEvent("Click", (*) => (g.Destroy(), Install()))
    btnSkip.OnEvent("Click",    (*) => g.Destroy())
    g.OnEvent("Close",          (*) => g.Destroy())

    WinWaitClose g.Hwnd
}

; ============================================================
;  GUI - Success Dialog
; ============================================================

ShowSuccessDialog() {
    g := Gui("+AlwaysOnTop -SysMenu", "Installed")
    g.BackColor := "0D1117"
    g.SetFont("s10 cE6EDF3", "Consolas")

    g.Add("Progress", "x0 y0 w380 h3 Background238636 c238636", 100)

    check := g.Add("Text", "x0 y18 w380 +Center c238636 BackgroundTrans")
    check.SetFont("s22 Bold", "Consolas")
    check.Value := "OK"

    title := g.Add("Text", "x0 y54 w380 +Center cE6EDF3 BackgroundTrans")
    title.SetFont("s11 Bold", "Consolas")
    title.Value := "Installation complete!"

    desc := g.Add("Text", "x20 y82 w340 +Center c8B949E BackgroundTrans")
    desc.SetFont("s9", "Consolas")
    desc.Value := "The launcher will now start with Windows.`nFind it in your system tray anytime."

    g.Add("Progress", "x30 y118 w320 h1 Background30363D c30363D", 100)

    sc1 := g.Add("Text", "x20 y130 w340 +Center c58A6FF BackgroundTrans")
    sc1.SetFont("s9", "Consolas")
    sc1.Value := "Ctrl+Alt+T  ->  Terminal"

    sc2 := g.Add("Text", "x20 y148 w340 +Center c58A6FF BackgroundTrans")
    sc2.SetFont("s9", "Consolas")
    sc2.Value := "Ctrl+Alt+Shift+T  ->  Terminal (Admin)"

    btnOK := g.Add("Button", "x115 y174 w150 h34", "Got it!")
    btnOK.SetFont("s10 Bold", "Consolas")

    g.Add("Text", "x0 y214 w380 h10 BackgroundTrans", "")

    g.Show("w380 h224")
    MonitorGetWorkArea(, &ml, &mt, &mr, &mb)
    g.Move((mr - ml) // 2 - 190 + ml, (mb - mt) // 2 - 112 + mt)

    btnOK.OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Close",     (*) => g.Destroy())

    WinWaitClose g.Hwnd
}

; ============================================================
;  GUI - Uninstall Dialog
; ============================================================

ShowUninstallDialog() {
    g := Gui("+AlwaysOnTop -SysMenu", "Uninstall")
    g.BackColor := "0D1117"
    g.SetFont("s10 cE6EDF3", "Consolas")

    g.Add("Progress", "x0 y0 w420 h3 BackgroundDA3633 cDA3633", 100)

    warn := g.Add("Text", "x0 y20 w420 +Center cDA3633 BackgroundTrans")
    warn.SetFont("s20 Bold", "Consolas")
    warn.Value := "!"

    title := g.Add("Text", "x0 y54 w420 +Center cE6EDF3 BackgroundTrans")
    title.SetFont("s11 Bold", "Consolas")
    title.Value := "Uninstall Windows Terminal Launcher?"

    desc := g.Add("Text", "x30 y84 w360 +Center c8B949E BackgroundTrans")
    desc.SetFont("s9", "Consolas")
    desc.Value := "This will remove the startup entry and delete all installed files."

    g.Add("Progress", "x30 y116 w360 h1 Background30363D c30363D", 100)

    btnYes := g.Add("Button", "x30 y132 w168 h34", "Uninstall")
    btnYes.SetFont("s10 Bold", "Consolas")

    btnNo := g.Add("Button", "x222 y132 w168 h34", "Cancel")
    btnNo.SetFont("s10", "Consolas")

    g.Add("Text", "x0 y175 w420 h10 BackgroundTrans", "")

    g.Show("w420 h186")
    MonitorGetWorkArea(, &ml, &mt, &mr, &mb)
    g.Move((mr - ml) // 2 - 210 + ml, (mb - mt) // 2 - 93 + mt)

    btnYes.OnEvent("Click", (*) => (g.Destroy(), Uninstall()))
    btnNo.OnEvent("Click",  (*) => g.Destroy())
    g.OnEvent("Close",      (*) => g.Destroy())

    WinWaitClose g.Hwnd
}
