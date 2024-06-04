###############################################################################################
## Scrpt to register a devics serial number to a UEM Tenant for Drop Ship Provisioning Online
##
## $client_id = oAuth Client ID
## $client_secret = oAuth Client Secret
## $OGUUID = GUID of the OG where the device is to be enrolled
## $ownership = Typically CorporateDedicated
## $acces_token_url = Regional Datacenter Token URL
## $apiServer = API server name (as1234)
##
## When executed, script will prompt for device information for DSP registration.
###############################################################################################

$client_id = "xxx" 
$client_secret = "xxx"

$OGUUID = "7376FABC-F6CD-434B-B9CA-55D5BD8739F6" #Windows
$tag = "DSPOnline1" #Script only supports single tag
$ownership = "CorporateDedicated"

$acces_token_url = "https://na.uemauth.vmwservices.com/connect/token"
#$acces_token_url = "https://uat.uemauth.vmwservices.com/connect/token"
#$acces_token_url = "https://emea.uemauth.vmwservices.com/connect/token"
#$acces_token_url = "https://apac.uemauth.vmwservices.com/connect/token"
$apiServer = "asxxxx"

try
{

$oAuthbody = @{ 
    grant_type = "client_credentials" 
    client_id = $client_id 
    client_secret = $client_secret 
}

   $response = Invoke-WebRequest -Method Post -Uri $acces_token_url -Body $oAuthbody -UseBasicParsing
   $oAuthToken = $response | ConvertFrom-Json 
   $oAuthToken = $oAuthToken.access_token

   $serial_number = Read-Host "Enter Device Serial Number"
   $friendly_name = Read-Host "Enter Device Frendly Name (Enter to use Serial)"
   $model_number = Read-Host "Enter Device Model (Enter for none)"

   if ($friendly_name -eq "")
   {
    $friendly_name = $serial_number
   }

   $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
   $headers.Add("Authorization", "Bearer $oAuthToken")
   $headers.Add("Accept", 'application/json;version=3')
   $headers.Add("Content-Type", "application/json")

   $body = @"
   {
      "friendly_name": "$friendly_name",
      "serial_number": "$serial_number",
      "model_number": "$model_number",
      "organization_group_uuid": "$OGUUID",
      "tags": [{name: "$tag"}],
      "ownership_type": "$ownership"
   }
"@

   $continue = Read-Host "Creating device registration for Serial: $serial_number Friendly Name: $friendly_name Model: $model_number. Enter Y [Enter] to continue"

   if ($continue -eq "Y")
   {
      #Register the device serial
      $URI = "https://$apiServer.awmdm.com/api/mdm/enrollment-tokens"
      $response = Invoke-WebRequest -Uri $URI -Headers $headers -Method POST -Body $body -UseBasicParsing
      $response.Content | ConvertFrom-Json

      #Sync the device
      $URI = "https://$apiServer.awmdm.com/API/mdm/dropship-action/organization-group/$OGUUID/sync-devices"
      $response = Invoke-WebRequest -Uri $URI -Headers $headers -Method POST -UseBasicParsing
      $response.StatusDescription
   }
}
catch
{
   Write-Host "StatusCode: $_.Exception.Response.StatusCode.value__ "
   Write-Host "StatusDescription: $_.Exception.Response.StatusDescription"
   Write-Host $_.Exception.message
}
