#############################################################################
## Identify all unenrolled devices and delete (If running in DELETE mode)  ##
## CSV file is generated containing all unenrolled devices identified      ##
##                                                                         ##
## Usage:                                                                  ##
## Set $authType to either OAUTH or BASIC dependong on method used         ##
##                        (OAUTH is currently not supported ON-Prem)       ##
##                                                                         ##
## Set $APIServer to the server where the API's are running                ##
##                                                                         ##
## Set $mode to either REPORT or DELTE.                                    ##
##                     REPORT will report only and not delete devices      ##
##                     DELETE will delete devices after confirmation       ##
##                                                                         ##
## set $ID and $Pass to credentials to be used in the API call             ##
##        $APITenantCode is only needed if using BASIC authentication      ##
##                                                                         ##
## Created by Glyn Dobson, VMware, September 2022                          ##
#############################################################################

###################### BEGIN USER CONFIGURABLE SECTION ######################

#Set the authentication type here
$authType = "OAUTH"
#$authType = "BASIC"

#Specify API servername here
$APIServer = "xxx.awmdm.com"

#Set the Mode heere
$mode = "Report"
#$mode = "Delete"

#Specify credentials here
$ID = "xxx"
$Pass = "xxx"
$APITenantCode = "{rest API Tenant Code}" #Basic auth only - Not needed for oAuth

#Specify file path here
$filePath = "/Users/glynd/Temp/"

#Ignored Usernames
$ignoredUsers = @('USER1','USER2')

####################### END USER CONFIGURABLE SECTION #######################

if ($authType -eq "OAUTH")
{
    $client_id = $ID
    $client_secret = $Pass

    $acces_token_url = "https://na.uemauth.vmwservices.com/connect/token"
    #$acces_token_url = "https://uat.uemauth.vmwservices.com/connect/token"
}

if ($authType -eq "BASIC")
{
    $UserName = $ID
    $Password = $Pass
}

#Output path and filename to be generated
$year = (get-date | select-object year).year
$month = (get-date | select-object month).month
$day = (get-date | select-object day).day
$hour = (get-date | select-object hour).hour
$minute = (get-date | select-object minute).minute
$second = (get-date | select-object second).second
$timestamp = "$year$month$day$hour$minute$second"
$filename = $filePath + "Unenrolled_devices_for_deletion_$timestamp.csv"

try
{
   $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

   if ($authType -eq "OAUTH")
   {
$oAuthbody = @{ 
        grant_type = "client_credentials" 
        client_id = $client_id 
        client_secret = $client_secret 
    }
       Write-Host "Using oAUth authentication"
       Write-Host "Generating oAuth Token"
       $response = Invoke-WebRequest -Method Post -Uri $acces_token_url -Body $oAuthbody 
       $oAuthToken = $response | ConvertFrom-Json 
       $oAuthToken = $oAuthToken.access_token
    
       $headers.Add("Authorization", "Bearer $oAuthToken")
   }

   if ($authType -eq "BASIC")
   {
      Write-Host "Using Basic authentication"
      $Text = $UserName + ":" + $Password
      $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
      $EncodedText =[Convert]::ToBase64String($Bytes)

      $headers.Add("Authorization", 'Basic ' + $EncodedText)
      $headers.Add("aw-tenant-code", "$APITenantCode")
   }

   $headers.Add("Accept", 'application/json')
   $headers.Add("content-type", 'application/json')

   #Get list of unenrolled devices to delete
   $URI = "https://$APIServer/api/mdm/devices/extensivesearch?enrollmentstatus=Unenrolled"
   
   $response2 = Invoke-WebRequest -Uri $URI -Headers $headers -Method get
   $deviceList = ($response2.Content | ConvertFrom-Json).devices | select-Object DeviceId, DeviceFriendlyName, SerialNumber, UserName, UnEnrolledDate | Where-Object -Property UserName -NotIn $ignoredUsers #| Where-Object -Property UserName -ne "USER2"

   $deleteCount = $deviceList.Count

   Write-Output "Identified $deleteCount unenrolled devices for deletion. Generating deleted device report at $filename"
   Write-Output "Running in $mode moode"

   #Generate report
   $deviceList | Export-Csv -Path $filename

   $deviceList = $deviceList | Select-Object -ExpandProperty DeviceId

   $csvDeviceList = ""
   $counter = 1

   #Create CSV List of devices to delete
   foreach ($device in $deviceList)
   {
      if ($counter -lt $deviceList.Count)
      {
        $csvDeviceList = $csvDeviceList + "`"" + $device + "`","
        $counter++
      }
      else 
      {
        $csvDeviceList = $csvDeviceList + "`"" + $device + "`""
      }
   }

   if ($mode -eq "Delete" -and $deleteCount -gt 0)
   {
      $a = Read-Host "About to perform delete. Type `"YES`" to procede with delete. This will delete $deleteCount devices"

      if ($a -eq "YES")
      {
        $Body = "{`"BulkValues`":{`"Value`":[" + $csvDeviceList + "]}}"

        #Delete devices in bulk using single API Call
        $URI = "https://$APIServer/api/mdm/devices/bulk?searchby=DeviceId"
        $response = Invoke-WebRequest -Uri $URI -Headers $headers -Method Post -Body $Body
   
        Write-Host "Total Devices: " ($response | ConvertFrom-Json).TotalItems
        Write-Host "Accepted Devices: " ($response | ConvertFrom-Json).AcceptedItems
        Write-Host "Failed Devices: " ($response | ConvertFrom-Json).FailedItems
      }
      else
      {
          Write-Host "Delete aborted by user"
      }
   }
   else 
   {
       Write-Host "No delete performed due to script running in REPORT mode or 0 devices identified for deletion"
   }
}
catch
{
   Write-Host "StatusCode: $_.Exception.Response.StatusCode.value__ "
   Write-Host "StatusDescription: $_.Exception.Response.StatusDescription"
   Write-Host $_.Exception.message
}
