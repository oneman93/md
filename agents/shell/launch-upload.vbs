' Launches upload-to-conf.ps1 with a hidden PowerShell window.
' Called by confupload: registry protocol handler.
WScript.CreateObject("WScript.Shell").Run _
    "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File """ & _
    "C:\Works\md\agents\shell\upload-to-conf.ps1"" " & WScript.Arguments(0), 0, False
