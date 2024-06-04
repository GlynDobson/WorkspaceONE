#################################
## Upload application to the UEM console.
## Usefull for larger applications that may take time.
#################################

$client_id = "xxx" 
$client_secret = "xxx"

$acces_token_url = "https://na.uemauth.vmwservices.com/connect/token"

$AppFilePath = 'C:\temp\W10 20H2 Sep 2023\Win10_SAC_22H2_Sep_2023_Upgrade.zip'
$FileName = (Get-ChildItem $AppFilePath).Name

try
{

$oAuthbody = @{ 
    grant_type = "client_credentials" 
    client_id = $client_id 
    client_secret = $client_secret 
}

   $response = Invoke-WebRequest -Method Post -Uri $acces_token_url -Body $oAuthbody 
   $oAuthToken = $response | ConvertFrom-Json 
   $oAuthToken = $oAuthToken.access_token

   $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
   $headers.Add("Authorization", "Bearer $oAuthToken")
   $headers.Add("Accept", 'application/json')
   $headers.Add("content-type", 'application/json')

   # App Setup
   $TotalAppSize = (Get-Item -Path $AppFilePath).Length
   $ChunkSequenceNumber = 1 # Sequence is indexed at 1
   $TransactionID = ""   #empty string for first upload

   # Break app file into chunks
   $ChunkSize = 100 * 1024 * 1024 # Set to 20 MB - 100 MB is the max recommended. For slower connections set to lower settings like 5MB
   $fileStream = [System.IO.File]::OpenRead($AppFilePath)
   $chunk = New-Object byte[] $ChunkSize
   $chunksUploaded = 0;

   # Read the file in $ChunkSize increments, calling the UploadChunk API to upload portions of the application in each request
   # until the entire file has been uploaded and associated by incrementing the $ChunkSequenceNumber
   Write-Host "Starting to upload app chunks, depending on app size this may take some time"
   Write-Host "App size is: $TotalAppSize/1024/1024"
   while($chunksRead = $fileStream.Read($chunk, 0, $ChunkSize))
   {
      #Prepare chunk for upload
      $currentSize = $chunk.Length
      $b64Chunk = [System.Convert]::ToBase64String($chunk)
    
      $body = @{
         TransactionId = $TransactionID
         ChunkData = $b64Chunk
         ChunkSequenceNumber = $ChunkSequenceNumber
         TotalApplicationSize = $TotalAppSize
         ChunkSize = $currentSize
}

      $body = $body | ConvertTo-Json
    
      # Upload file chunk
      $URI = "https://asxxx.awmdm.com/api/mam/apps/internal/uploadchunk"
      $response = Invoke-WebRequest -Uri $URI -Headers $headers -Method POST -Body $body
      $TransactionID = ($response.Content | ConvertFrom-Json).TranscationId

    
      # Update on successful upload
      $chunksUploaded += $chunksRead
      $ChunkSequenceNumber++
      $currentStatusMessage = ("Uploaded {0} MB" -f ($chunksUploaded / 1MB))
      Write-Host $currentStatusMessage
   }

   Write-Host "Finished Uploading app chunks"

   # Call the SaveApp API with the app metadata formatted as JSON to save the app to UEM and make it available in the UEM administration console
   Write-Host "Saving app in Workspace ONE UEM...this may take a few minutes"

   $AppMetaData = @"
   {
    "BlobId": 0,
    "IconBlobUuId": "",
    "TransactionId": "$TransactionID",
    "ApplicationName": "Windows 10 SAC 22H2 September 2023 Upgrade",
    "PushMode": "0",
    "Description": "",
    "SupportEmail": "",
    "SupportPhone": "",
    "Developer": "",
    "DeveloperEmail": "",
    "DeveloperPhone": "",
    "AutoUpdateVersion": false,
    "LocationGroupId": 0,
    "AppVersion": "10.0.19045.3448",
    "EnableProvisioning": false,
    "FileName": "$FileName",
    "SupportedProcessorArchitecture": "x64",
    "IsDependencyFile": false,
    "DeviceType": "WinRT",
    "SupportedModels": {
        "Model": [
            {
                "ModelId": 83,
                "ModelName": "Desktop"
            }
        ]
    },
    "DeploymentOptions": {
        "WhenToInstall": {
            "DataContingencies": [],
            "DiskSpaceRequiredInKb": 0,
            "DevicePowerRequired": 0,
            "RamRequiredInMb": 0
        },
        "HowToInstall": {
            "InstallContext": "User",
            "InstallCommand": "powershell -executionpolicy bypass -file InplaceUpgradeWS1.ps1",
            "AdminPrivileges": true,
            "DeviceRestart": "DoNotRestart",
            "RetryCount": 0,
            "RetryIntervalInMinutes": 5,
            "InstallTimeoutInMinutes": 150,
            "InstallerRebootExitCode": "",
            "InstallerSuccessExitCode": ""
        },
        "WhenToCallInstallComplete": {
            "UseAdditionalCriteria": true,
            "IdentifyApplicationBy": "DefiningCriteria",
            "CriteriaList": [
                {
                    "CriteriaType": "RegistryExists",
                    "RegistryCriteria":  {
                             "Path":  "HKEY_LOCAL_MACHINE\\SOFTWARE\\InPlaceUpgrade",
                             "KeyName":  "InPlaceWS1",
                             "KeyType":  "String",
                             "KeyValue":  "22H2",
                             "VersionCondition":  "2"
                    },
                    "LogicalCondition": "End"
                }                
            ]
        }
    },
    "FilesOptions": {
        "AppDependenciesList": [],
        "AppTransformsList": [],
        "AppPatchesList": [],
        "ApplicationUnInstallProcess": {
            "UseCustomScript": true,
            "CustomScript": {
                "CustomScriptType": "Input",
                "UninstallCommand": "N/A",
                "UninstallScriptBlobId": 0
            }
        }
    }
}
"@ 

   $URI = "https://asxxx.awmdm.com/api/v1/mam/apps/internal/begininstall"
   $response = Invoke-RestMethod -Method Post -Uri $URI -Headers $headers -Body $AppMetaData
}
catch
{
   Write-Host "StatusCode: $_.Exception.Response.StatusCode.value__ "
   Write-Host "StatusDescription: $_.Exception.Response.StatusDescription"
   Write-Host $_.Exception.message
}
