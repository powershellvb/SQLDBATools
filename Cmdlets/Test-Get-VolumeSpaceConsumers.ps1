#Get-VolumeSpaceConsumers -ComputerName $env:computerName -pathOrFolder 'D:\' | Out-GridView;
Get-VolumeSpaceConsumers -ComputerName TUL1CIPEDB3 -pathOrFolder g:\backup -Verbose | Out-GridView