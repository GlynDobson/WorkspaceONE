<h1>Windows device lifecycle</h1>
<h2>Automated reprovisioning of devices using Workspace ONE</h2>

Use this set of scripts to re-image a device with a fresh Windows install and have the device automatically enroll into Workspace ONE and join the domain.

Requirements:

* Windows ISO.
* USB stick where the modified ISO image will be deployed to.
* Dropship Provisioning Online configured at the OG where devices should be placed: Reference: https://docs.omnissa.com/bundle/workspace_one_drop_ship_provisioningV2310/page/DSPOnlineInfo.html
* Dropship-GenericPPKG-ProvTool package available from my.workspaceone.com. At time of writing, this is Dropship-GenericPPKG-ProvTool3.4.zip
* An oAuth client for use with the API's. This is used to register the devices serial number with the UEM Tenant and target OG. Reference: https://docs.omnissa.com/bundle/WorkspaceONE-UEM-Console-BasicsVSaaS/page/UsingUEMFunctionalityWithRESTAPI.html#create_an_oauth_client_to_use_for_api_commands_saas
* If the device is to be joined to an AD domain, create the Domain Join configuration. Reference: https://docs.omnissa.com/bundle/Windows_Desktop_ManagementV2306/page/uemWindeskDomainJoin.html#on_premises_domain_join
* Create a tag that will be applied to your device. This tag should be assigned to the Smart Group created in the previoius step. Referene: https://docs.omnissa.com/bundle/WorkspaceONE-UEM-Managing-DevicesVSaaS/page/DeviceTags.html

Deployment:

* Copy DSPCreater.ps1, DSP_Register.ps1 and unattend.xml to a folder on a computer where the USB image will be created.
* In the same folder, place the Generic PPKG package zip file and a copy of the Windows ISO file that is to be used.

Update DSPCreater.ps1 file as follows:

* Set the value of **$buildFolder** to a temporary location on your computer what will be used to build the Windows image
* Set the value of **$acces_token_url** to the appropriate datacenter URL as published here: https://docs.omnissa.com/bundle/WorkspaceONE-UEM-Console-BasicsVSaaS/page/UsingUEMFunctionalityWithRESTAPI.html#datacenter_and_token_urls_for_oauth_20_support
* Set the value of **$APIClientID** to the oAuth Client ID
* Set the value of **$APIClientSecret** to the oAuth Client Secret
* Set the value of **$apiServer** to the name of the API server. This can be found under Site URLs and is listed as the value for **REST API URL**. Reference: https://docs.omnissa.com/bundle/SystemSettingsVSaaS/page/SiteURLsforWorkspaceONE.html
* Set the value of **$OGID** to the GUID for the OG where the device should be enrolled. This is obtained from the Drop Ship Provisioning configuration screen. 
* Set the value of **$tag** to the name of the tag to be applied to the device. This is the tag created above that is assigned to the Smart Group where the Domain configuration is assigned.
* Update the value of **$ownership** if required. Typically this will not need to be changed.

With the USB drive connected, open a PS session, change to the location of the files and run DSPCreater.ps1. The process will do the following:
* Formats the USB drive
* Mounts the ISO to a virtual DVD drive
* Copies all files from the ISO to the USB drive
* Dismounts the ISO file
* Extracts the install.wim file for the Enterprise version of Windows to the temporary folder in $buildFolder (this is the Windows image that will be applied to the device)
* Adds the Workspace ONE PPKG files to the to the windows image folder
* Updates the standard PPGK files to trigger a reboot instead of a shut down
* Adds the unatend.xml file to the windows panther folder
* Updates DSP_Register.ps1 with the specified API endpoint URL and credentials
* Applies the updates to the install.wim image
* Specifies the version of windows to install as the Enterprise edition
* Ejects the USB drive

Imaging process
* Boot device using UBS stick.
* unantend.xml boots the device into audit mode and triggers execution of DSP_Register.ps1 which registeres the device serial number to the UEM tenant.
* RunPPKGandXML.bat is then launched which stages the Generic PPKG package.
* Device reboots and automatically logs in using a staging account called workspaceone.
* Workspace ONE provisioning agent is relaunched, the device is enrolled into WS1 as a staging account and resources are applied to the device.
* Once provisioning is complete, the device can be shut down and given to the end user.
* When the end user logs in, the device is reassigned from the staging account (staging-cp-{OG})to the end user.
