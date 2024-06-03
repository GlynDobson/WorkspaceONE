$client_id = "XClientIDX" 
$client_secret = "XClientSecretX"

$OGUUID = "XOGIDX"
$tag = "XtagX"
$ownership = "XownershipX"

$acces_token_url = "XAccessTokenURLX"
$apiServer = "XAPIServerX"

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

   #Get local device information
   $win32_bios = Get-WmiObject win32_bios
   $win32_computersystem = Get-WmiObject win32_computersystem

   $friendly_name = $win32_computersystem.Name
   $serial_number = $win32_bios.SerialNumber
   $model_number = $win32_computersystem.Model

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

   #Register the device serial
   $URI = "https://$apiServer.awmdm.com/api/mdm/enrollment-tokens"
   $response = Invoke-WebRequest -Uri $URI -Headers $headers -Method POST -Body $body -UseBasicParsing
   $response.Content | ConvertFrom-Json

   #Sync the device
   $URI = "https://$apiServer.awmdm.com/API/mdm/dropship-action/organization-group/$OGUUID/sync-devices"
   $response = Invoke-WebRequest -Uri $URI -Headers $headers -Method POST -UseBasicParsing
   $response.StatusDescription
}

catch
{
   Write-Host "StatusCode: $_.Exception.Response.StatusCode.value__ "
   Write-Host "StatusDescription: $_.Exception.Response.StatusDescription"
   Write-Host $_.Exception.message
}
