New-ItemProperty 
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' 
  Personal -Value '%SystemDrive%/.config/Microsoft.PowerShell_profile.ps1' -Type ExpandString -Force