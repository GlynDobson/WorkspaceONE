#************************************
#*** USER CONFIGURATION SECTION *****
#************************************
#Confuguration settings for this PowerShell script
$buildFolder = "c:\WindowsImage"

#Connection to UEM API
$acces_token_url = "https://na.uemauth.vmwservices.com/connect/token"
$APIClientID = "xxx"
$APIClientSecret = "xxx"
$apiServer = "asxxxx"

#UEM confiuration for where the device should go
$OGID = "12345678-AAAA-BBBB-CCCC-123456789ABC" #Format: 7376FABC-F6CD-434B-B9CA-55D5BD8739F6
$tag = "DSPOnline"
$ownership = "CorporateDedicated"
#*****************************************
#*** END OF USER CONFIGURATION SECTION ***
#*****************************************

$ISO =  (Get-Item ".\*.iso" | Select-Object -Property FullName).FullName
$WS1Folder = "$buildFolder\WorkspaceONE"

#Clear and format USB drive.
Write-Output "Preparing USB drive. All data will be erased"
$diskNumber = (Get-Disk | where BusType -eq 'USB' | Select-Object Number).number
Clear-Disk -Number $diskNumber -RemoveData -Confirm:$false -PassThru | Out-Null
Set-Disk -PartitionStyle GPT -Number $diskNumber
$USBDrive = (New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS | Select-Object DriveLetter).DriveLetter

#Mount the Windows ISO Image to a virtual drive and copy contents to USB drive
Write-Output "Mouting the Windows ISO"
$devicePath = (Mount-DiskImage -ImagePath $ISO | Select-Object DevicePath).DevicePath
$ISODrive = (Get-DiskImage -DevicePath $devicePath | Get-Volume | Select-Object DriveLetter).DriveLetter
$source = $ISODrive + ":\"
$destination = $USBDrive + ":\"
Write-Output "Copying files. This will take some time..."
Copy-Item -Path "$source\*" -Destination $destination -Recurse

#Dismounting Windows ISO image
Write-Output "Dismounting virtual ISO drive."
Dismount-DiskImage -ImagePath $ISO | Out-Null

#Extract the Enterprise WIM file to the local device
Write-Output "Obtaining index for Enterprise edition of Windows"
$windowsImage = $USBDrive + ":\sources\install.wim"
$imageInfo =  Get-WindowsImage -ImagePath $windowsImage
$imageInfo = $imageInfo | Select-Object * | Where-Object -Property ImageName -match 'Windows \d\d Enterprise'
$imageInfo = $imageInfo | Select-Object * | Where-Object -Property ImageName -notmatch 'Windows \d\d Enterprise N'
$ImageName = $imageInfo.ImageName
$ImageIndex = $imageInfo.ImageIndex

Write-Output "Creating temporary image build folder at $buildFolder"
if (Test-Path $buildFolder)
{
   Remove-Item -Path $buildFolder -Recurse
}
New-Item -Path $buildFolder -ItemType directory | Out-Null

Write-Output "Extracting the WIM for $ImageName from index $ImageIndex"
Set-ItemProperty -Path $windowsImage -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $windowsImage -Index $ImageIndex -Path $buildFolder | Out-Null

#Copy WS1 files to windows image
Write-Output "Copying generic DSP provisioning package to image"
$DSPPackageFullName = (Get-Item ".\*.zip" | Select-Object -Property FullName).FullName
$DSPPackageName = (Get-Item ".\*.zip" | Select-Object -Property Name).Name
$DSPFolderName = $DSPPackageName -replace ".{4}$"
New-Item -Path $WS1Folder -ItemType directory -Force | Out-Null
Expand-Archive -Path $DSPPackageFullName -DestinationPath $WS1Folder

#Update generic package to trigger reboot instead of shutdown
Write-Output "Updating RunPPKGandXML.bat to trigger reboot instead of shutdown"
$RunPPKGandXML = Get-Content -Path "$WS1Folder\$DSPFolderName\RunPPKGandXML.bat"
$RunPPKGandXML = $RunPPKGandXML -replace '-s','-r'
Set-Content -Path "$WS1Folder\$DSPFolderName\RunPPKGandXML.bat" -Value $RunPPKGandXML -Force

#Process unattend.xml
Write-Output "Copying unattend.xml to image"
$panther = "$buildFolder\Windows\Panther"
if (!(Test-Path -Path $Panther))
{
   New-Item -Path $Panther -ItemType directory | Out-Null
}
Copy-Item -Path .\unattend.xml -Destination $panther -Force

#Update DSP_Register.ps1 with environment configuration
write-output "Updating DSP_Register.ps1 with environment configuration"
Copy-Item -Path .\DSP_Register.ps1 -Destination $WS1Folder -Force
$DSP_Register = Get-Content -Path "$WS1Folder\DSP_Register.ps1"
$DSP_Register = $DSP_Register -replace 'XClientIDX',$APIClientID
$DSP_Register = $DSP_Register -replace 'XClientSecretX',$APIClientSecret
$DSP_Register = $DSP_Register -replace 'XOGIDX',$OGID
$DSP_Register = $DSP_Register -replace 'XtagX',$tag
$DSP_Register = $DSP_Register -replace 'XownershipX',$ownership
$DSP_Register = $DSP_Register -replace 'XAccessTokenURLX',$acces_token_url
$DSP_Register = $DSP_Register -replace 'XAPIServerX',$apiServer
Set-Content -Path "$WS1Folder\DSP_Register.ps1" -Value $DSP_Register -Force

#Save updated windows image
Write-Output "Applying image updates to the WIM file"
Dismount-WindowsImage -Path $buildFolder -Save | Out-Null

#Specificy windows edition to auto install
Write-Output "Configuring Enterprise edition to auto install"
$ei = "$USBDrive`:\sources\EI.CFG"
Set-ItemProperty -Path $ei -Name IsReadOnly -Value $false
@("[EditionID]","Enterprise") + (Get-Content -Path $ei) | Set-Content -Path $ei

Start-Sleep -Seconds 1

Write-Output "Process complete. Ejecting USB drive"
$driveEject = New-Object -comObject Shell.Application
$driveEject.Namespace(17).ParseName("$USBDrive`:").InvokeVerb("Eject")
