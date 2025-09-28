; --- AutoHotkey Script ---
; Win+1 -> WezTerm
; Win+2 -> VSCode (via "code" CLI)
; Win+3 -> Firefox

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; -------------------------------
; Hotkeys
; -------------------------------

; WezTerm (Win+1)
#1::
    RunOrActivate("wezterm-gui.exe", "ahk_exe wezterm-gui.exe")
return

; VSCode (Win+2)
#2::
    ; Option 1: If `code` is in PATH
    RunOrActivate("code", "ahk_exe Code.exe")

    ; Option 2 (fallback): Direct to bin\code.cmd
    ; RunOrActivate(A_LocalAppData . "\Programs\Microsoft VS Code\bin\code.cmd .", "ahk_exe Code.exe")
return

; Firefox (Win+3)
#3::
    RunOrActivate("firefox.exe", "ahk_exe firefox.exe")
return


; -------------------------------
; Function: RunOrActivate
; -------------------------------
RunOrActivate(Target, WinCriteria) {
    if WinExist(WinCriteria) {
        WinActivate
    } else {
        Run, %Target%
    }
}
