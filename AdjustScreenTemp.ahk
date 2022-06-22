; Adjust Screen Temperature

; This script uses the little CLI program ddcset by arcnmx
; to adjust the color temperature of the screen
; using the color settings of the actual hardware.

; Use Alt + Win + PageUp/PageDown to adjust temperature up and down.
; Change that according to your preferences.
!#PgUp::AdjustTemp(true)
!#PgDn::AdjustTemp(false)

AdjustTemp(increase)
{
  EnvGet, Blue, screen_temp
  
  ; Initialize.
  if (!Blue && Blue != 0) {
    Blue := GetBlue()
  }
  
  Blue += increase = true ? 10 : -10
  
  if (Blue < 0 || Blue > 100) {
    return
  }
  
  ; Calculate the green component as a function of the blue.
  ; Change this ratio according to your preferences.
  Green := (Blue + 100) // 2
  
  Run ddcset.exe -b winapi setvcp 1a %Blue%,,Hide
  Run ddcset.exe -b winapi setvcp 18 %Green%,,Hide
  EnvSet, screen_temp, %Blue%
}

GetBlue()
{
  ; Prevent script window from flashing.
  ; https://www.autohotkey.com/boards/viewtopic.php?p=22245#p22245
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows On
  Run "%ComSpec%" /k,, Hide, pid
  while !(hConsole := WinExist("ahk_pid" pid))
    Sleep 10
  DllCall("AttachConsole", "UInt", pid)
  DetectHiddenWindows %dhw%
  objShell := ComObjCreate("WScript.Shell")
  
  ; Get the value of the blue setting of the screen.
  ; VCP code will probably always be `1a`, but you may need to use `nvapi` instead of `winapi`.
  objExec := objShell.Exec("ddcset -b winapi getvcp 1a")
  While !objExec.Status
    Sleep 100
  Blue := objExec.StdOut.ReadAll()
  
  DllCall("FreeConsole")
  Process Exist, %pid%
  if (ErrorLevel == pid)
    Process Close, %pid%
  
  ; Not sure what the --raw argument is supposed to do,
  ; but the command always returns a block of text regardless.
  ; Something like this:
  
  ; Display on winapi:
  ;       ID: Scren Model
  ;       Feature 0x1a = 80 / 100
  
  ; Extract the relevant value. Should be between 0 and 100.
  RegExMatch(Blue, "\d+(?= \/)", Blue)
  
  ; Store the value in the environment to limit querying of the API.
  EnvSet, screen_temp, %Blue%
  return %Blue%
}
