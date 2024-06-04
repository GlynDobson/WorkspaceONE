<h1>Windows device lifecycle</h1>
<h2>Automated reprovisioning of devices using Workspace ONE</h2>

Use this set of script to re-image a device with a fresh Windows install and have the device automatically enroll into Workspace ONE and join the domain.

Requirements:

An oAuth client for use with the API's. This is used to register the devices serial number with the UEM Tenant and target OG.
Reference: https://docs.omnissa.com/bundle/WorkspaceONE-UEM-Console-BasicsVSaaS/page/UsingUEMFunctionalityWithRESTAPI.html#create_an_oauth_client_to_use_for_api_commands_saas

If the device is to be joined to an AD domain, create the Domain Join configutation.
Reference: https://docs.omnissa.com/bundle/Windows_Desktop_ManagementV2306/page/uemWindeskDomainJoin.html#on_premises_domain_join

Create a tag that will be applied to your device. This tag should be assigned to the Smart Group created in the previoius step
Referene: https://docs.omnissa.com/bundle/WorkspaceONE-UEM-Managing-DevicesVSaaS/page/DeviceTags.html

Deploymnt:

