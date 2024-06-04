#############################################
## Used to obtaon extra information when troubleshooting Windows Update for Business issues
## Files are saved into the WS1 Intelligent Hub logs folder.
## Use the UEM Console to request device logs
## Device logs are returennd in a spanned zip archive. Archve needs to be combined into single zip file before opening.
#############################################

#Windows update - scan only
$updateObject = New-Object -ComObject Microsoft.Update.Session
$updateSearcher = $updateObject.CreateUpdateSearcher()
$searchResults = $updateSearcher.Search("IsInstalled=0 and DeploymentAction='Installation' or IsInstalled=0 and DeploymentAction='OptionalInstallation' or IsPresent=1 and DeploymentAction='Uninstallation' or IsInstalled=1 and DeploymentAction='Installation' and RebootRequired=1 or IsInstalled=0 and DeploymentAction='Uninstallation' and RebootRequired=1")

foreach ($result in $searchResults)
{
   $result.Updates | Format-Table -Property Title, IsDownloaded, IsInstalled, IsMandatory, LastDeploymentChangeTime, MaxDownloadSize > C:\ProgramData\Airwatch\UnifiedAgent\Logs\DiscoveredUpdates.log
}

#Create MDM Diagnostics Report
MdmDiagnosticsTool.exe -out C:\ProgramData\Airwatch\UnifiedAgent\Logs\

#Policy Manager Windows Update Export
Invoke-Command  {reg export 'HKLM\SOFTWARE\Microsoft\PolicyManager' C:\ProgramData\Airwatch\UnifiedAgent\Logs\PolicyUpdateRegKey.txt}

#GPO Windows Update
Invoke-Command  {reg export 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' C:\ProgramData\Airwatch\UnifiedAgent\Logs\GPOUpdateRegKey.txt}

#Get installed Hotfixs
get-hotfix > C:\ProgramData\Airwatch\UnifiedAgent\Logs\hotfixs.txt

#Generate Windows Update logs
Get-WindowsUpdateLog -LogPath C:\ProgramData\Airwatch\UnifiedAgent\Logs\WindowsUpdateLog.log
