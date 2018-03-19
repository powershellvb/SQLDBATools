# SQLDBATools
Powershell Module containing cmdlets for carrying out SQL DBA activities. It includes:-

<b>1)</b>
PS C:\\> <b>Get-ServerInfo</b> -ServerName 'BAN-1ADWIVEDI-L'
<table>
  <tr><td>ComputerName</td><td>:</td><td>BAN-1ADWIVEDI-L</td></tr>
  <tr><td>OS</td><td>:</td><td>Microsoft Windows 7 Professional</td></tr>
  <tr><td>SPVersion</td><td>: </td><td>Service Pack 1</td></tr>
  <tr><td>LastBootTime</td><td>:</td><td></td></tr>
  <tr><td>Model</td><td>:</td><td>HP EliteBook 840 G3</td></tr>
  <tr><td>RAM(MB)</td><td>:</td><td>8073</td></tr>
  <tr><td>CPU</td><td>:</td><td>4</td></tr>
 </table>

This function returns basic information about machine passed as parameter.


<b>2)</b>
PS C:\\> <b>Get-VolumeInfo</b> -ComputerName 'BAN-1ADWIVEDI-L' | ft -AutoSize
<table>
<tr><td>ComputerName   </td><td>VolumeName</td><td><td>Capacity(GB)</td><td>Used Space(GB)</td><td>Used Space(%)</td><td>FreeSpace(GB)</td><td>Label   </td></tr>
<tr><td>------------   </td><td>----------</td><td><td>------------</td><td>--------------</td><td>-------------</td><td>-------------</td><td>-----   </td></tr>
<tr><td>BAN-1ADWIVEDI-L</td><td>C:\       </td><td><td>         237</td><td>           102</td><td>           43</td><td>          134</td><td>		   </td></tr>
<tr><td>BAN-1ADWIVEDI-L</td><td>D:\       </td><td><td>           2</td><td>             0</td><td>            4</td><td>            2</td><td>HP_TOOLS</td></tr>
</table>

This function returns utilization of Disk Volumes on machine including mounted volumes.
