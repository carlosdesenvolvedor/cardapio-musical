Get-ChildItem -Path "$env:USERPROFILE\Downloads\*.key" | Select-Object Name, CreationTime, LastWriteTime | Sort-Object CreationTime -Descending | Format-Table -AutoSize
