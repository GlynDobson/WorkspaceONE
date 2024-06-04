#################################################
## Used to trigger a toast notification informing a user that they need to reboot their device if it has not been rebooted in over a week.
## Can be pushed as a sensor
#################################################

#Get last boot time
$Last_reboot = Get-ciminstance Win32_OperatingSystem | Select -Exp LastBootUpTime	
$Check_FastBoot = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -ea silentlycontinue).HiberbootEnabled 

If($Check_FastBoot -eq 1) 	
{
   $Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x1*"}
   If($Boot_Event -ne $null)
   {
      $Last_boot = $Boot_Event[0].TimeCreated		
   }			
}
else
{
   $Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x0*"}
   If($Boot_Event -ne $null)
   {
      $Last_boot = $Boot_Event[0].TimeCreated		
   }
}

If($Last_boot -eq $null)
{
   $Uptime = $Uptime = $Last_reboot
}
Else
{
   If($Last_reboot -gt $Last_boot)
   {
      $Uptime = $Last_reboot
   }
   Else
   {
      $Uptime = $Last_boot
   }	
}
	
$Current_Date = get-date
$Diff_boot_time = $Current_Date - $Uptime
$Boot_Uptime_Days = $Diff_boot_time.Days	

if ($Boot_Uptime_Days -gt 1)
{
   $Restart_Script = "shutdown /r /t 300"
   $Restart_Script | out-file "C:\Temp\RestartScript.cmd" -Force -Encoding ASCII

   New-Item HKCU:\SOFTWARE\Classes\RestartScript\shell\open\command -Force | Out-Null
   New-ItemProperty -Path HKCU:\SOFTWARE\Classes\RestartScript -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null
   Set-ItemProperty -Path HKCU:\SOFTWARE\Classes\RestartScript -Name "(Default)" -Value "URL:RestartScript Protocol" -Force | Out-Null
   Set-ItemProperty -Path HKCU:\SOFTWARE\Classes\RestartScript\shell\open\command -Name "(Default)" -Value "C:\Windows\Temp\RestartScript.cmd" -Force | Out-Null		

   [xml]$Toast = @"
   <toast scenario="reminder">
      <visual>
         <binding template="ToastImageAndText03">
            <text id="1">It is time to reboot your device.</text>
            <text id="2">You are required to reboot your device weekly. It has been $Boot_Uptime_Days days since your device was rebooted. Please reboot as soon as possible.</text>
            <image id="1" src="C:\Program Files (x86)\Airwatch\AgentUI\Resources\hub_logo.png"/>												
         </binding>
      </visual>
      <actions>
         <action activationType="protocol" arguments="RestartScript:" content="Restart now" />		
         <action activationType="protocol" arguments="Dismiss" content="Remind me later" />
      </actions>
   </toast>
"@	

   Register-NotificationApp -AppID "Syst and Deploy informs you" -AppDisplayName "Syst and Deploy informs you"

   # Toast creation and display
   $Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
   $Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
   $ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
   $ToastXml.LoadXml($Toast.OuterXml)	
   # Display the Toast
   [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("com.airwatch.windowsprotectionagent").Show($ToastXml)
}
