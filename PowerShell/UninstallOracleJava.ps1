######################################################
## Used to unintall any instanced of Oracle Java
## Canbe pushed as a script
######################################################

$apps = Get-WmiObject -Class Win32_Product | Where-Object {($_.Name -match "Java") -and ($_.vendor -match "oracle")}
$result = ""
if ($apps)
{
   foreach($app in $apps)
   {
      $appName = $app.Name
      $appVendor = $app.vendor
      $result = $result + "Uninstalling $appName by $appVendor |"
      $app.uninstall() | Out-Null
   }
}
else
{
   $result = "Oracle Java not found"
}
Write-Output $result
