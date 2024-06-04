$client_id = "xxx" 
$client_secret = "xxx"

$acces_token_url = "https://na.uemauth.vmwservices.com/connect/token"

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

   $URI = "https://asxxx.awmdm.com/api/mdm/devices/search?platform=Android"
   $response = Invoke-WebRequest -Uri $URI -Headers $headers -Method get
   ($response.Content | ConvertFrom-Json).devices
}
catch
{
   Write-Host "StatusCode: $_.Exception.Response.StatusCode.value__ "
   Write-Host "StatusDescription: $_.Exception.Response.StatusDescription"
   Write-Host $_.Exception.message
}
