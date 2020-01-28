# intune-TeamsNotification, intune-SlackNoficiation, intune-EmailNotification

A script that uses the PSTeams module to post notifications to a Microsoft Teams Incoming Webhook connector.

The script is designed to be used with Microsoft Intune, and posts a notification when a new Windows 10 Device has enrolled with Intune.

A blog post on the useage will soon be available....


---------------------

I've used the TeamsNotification template to create a quick no frills ability to send the notifications to Slack (if the PSSlack module is preinstalled) and to send to an email address. 

You can workaround the PSSlack module if you don't want to install the module on the end users computers

The use case here woould be if you have a Windows 10 BYOD policy and have users adding devices to AzureAD/Intune.

---------------------

Webhook-Notification.ps1 will use the native invoke command to send information to your chosen webhook. You must edit the $payload information to format to your chosen method of JSON output.
