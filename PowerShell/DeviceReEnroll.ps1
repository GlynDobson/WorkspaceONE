####################################################
## Can be pushed as a script to trigger a device re-enrollment
## Usefull in instences where a device enrollment has partly failed
##
##   "SERVER={Devices Services Server}"
##   "LGName={OG where the device is to be enrolled}"
##   "USERNAME={Staging account username}"
##   "PASSWORD={Staging account password}"
####################################################

$script =@"
`$UninstallString = ""

if (!(test-path -path "C:\temp"))
{
   New-Item -ItemType Directory -Path "C:\temp" | Out-Null
}
Start-BitsTransfer -Source https://packages.vmware.com/wsone/AirwatchAgent.msi -Destination C:\Temp\AirwatchAgent.msi

`$uninstallPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
`$apps = Get-ChildItem -Path `$uninstallPath

foreach (`$app in `$apps)
{
   `$PSChildName = `$app.PSChildName
   `$path = "`$uninstallPath\`$PSChildName"

   if ((Get-ItemProperty -Path `$path).PSObject.Properties.Name -contains "DisplayName")
   {
      `$appName = Get-ItemPropertyValue -Path `$path -Name DisplayName
      if (`$appName -eq "Workspace ONE Intelligent Hub Installer")
      {
         `$UninstallString = Get-ItemPropertyValue -Path `$path -Name UninstallString
      }
   }
}

if (`$UninstallString)
{
   Write-Output "Uninstalling Intelligent Hub"
   `$exe = `$UninstallString.Split(' ')[0]
   `$uninstallArgs = @(
   `$UninstallString.Split(' ')[1]
   "/quiet"
)
   Start-Process `$exe -ArgumentList `$uninstallArgs -NoNewWindow -wait
}
else
{
   write-output "Intelligent Hub not found. No uninstall needed."
}

`$installArgs = @(
  "/i"
  "c:\temp\AirwatchAgent.msi"
  "/quiet"
  "/norestart"
  "ENROLL=Y"
  "SERVER=xxx"
  "LGName=xxx"
  "USERNAME=xxx"
  "PASSWORD=xxx"
  "ASSIGNTOLOGGEDINUSER=Y"
  "/LOG"
  "C:\Windows\logs\WS1Agent.log"
)
Write-Output "Installing Intelligent Hub."
Start-Process msiexec.exe -ArgumentList `$installArgs -NoNewWindow -wait
Write-Output "Intelligent Hub install complete."
Remove-Item -Path C:\Temp\WS1ReEnroll.ps1
"@

$script > C:\Temp\WS1ReEnroll.ps1

if (!(test-path -Path C:\Temp\re-enrolled.txt))
{
   Start-Process powershell.exe -ArgumentList C:\Temp\WS1ReEnroll.ps1 -wait
   New-Item -Path C:\Temp\re-enrolled.txt -ItemType File | Out-Null
}
