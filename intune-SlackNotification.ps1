﻿####################################################################################################
#
# Configuration Section (This is where you can edit stuff to fit your needs)
#
####################################################################################################
#### You will need to preinstall the module Install-Module PSSlack from the PSGallery on the end device before running this script ####
#Import the Slack Module after its preinstalled
Import-Module PSSlack
# The webhook URL you got from the Incoming Webhook Connector configuration guide
$windowsalerts = 'slackwebhook'
$newdevices = 'slackwebhook'

# Enable testing mode (will post to the channel on every execution of this script if set to $true (default is $false))
$enableTesting = $false

##### Begin custom logic #####

    # Put any custom logic here, that you need to generate output for the Buttons or Facts in the notification.
    # I have added som example code as an inspiration

    # Get logged in user
    $currentUser = Get-WMIObject -class Win32_ComputerSystem | select -ExpandProperty username

    # Get Computer Serialnumber
    $serialnumber = Get-WmiObject win32_bios | Select Serialnumber

    # Get OS install date
    $myinstallDate = ([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).InstallDate).ToString()

    # Get a nice display friendly OS Name
    $OSinfo = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $OSDisplayName = "$($OSinfo.ProductName) $($OSinfo.ReleaseID)"

##### End custom logic #####

##### Design section starts here, and will determine the look of the notification

    $messageTitle = "$($env:COMPUTERNAME) just enrolled!"
    $activityTitle = "Intune says... "
    $activityText = "You might find the following facts interesting!"

    $facts = "$currentUser","$OSDisplayName","$myinstallDate","$serialnumber"


####################################################################################################
#
# Functions Section (This is a collection of usefull code we are using in the execution section)
#
####################################################################################################

function isNewInstall () {
    # Determine if testing is enabled, and skip checks.
    if ($enableTesting) {
        return $true
    }
    
    # Determine if this computer was enrolled more than a day ago
    $DMClientTime = Get-ItemPropertyValue HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\ConfigManager\DMClient -Name Time -ErrorAction SilentlyContinue | Get-Date
    $nowMinus24Hours = (get-date).AddHours(-24)

    # Placing a cookie file, so this script won't run again by mistake.
    $cookieFile = "$($env:windir)\Temp\intune_notification-cookie.txt"
    if (Test-Path -Path $cookieFile) {
        return $false
    } else {
        Write-Output "this file indicates that the 'Intune-SlackNotification.ps1' script has run on this computer" > $cookieFile 
    }

    if ($nowMinus24Hours -gt $DMClientTime) { 
        return $false 
    } else {
        return $true
    }
}

####################################################################################################
#
# Execution Section (This is where stuff actually get's run!)
#
####################################################################################################

# Determine if this computer was recently installed or not (we dont want to send a notification from all previously enrolled computers)
if ((isNewInstall) -eq $false) {
    Write-Output "This computer was enrolled more than a day ago, so we wont't send a notification to the Slack Channel."
    Exit 0
}

# Building the notification design
New-SlackMessageAttachment -Title "$messagetitle" -Pretext $activitytext -Text "$facts" -Fallback test |
    New-SlackMessage |
    Send-SlackMessage -uri $windowsalerts

New-SlackMessageAttachment -Title "$messagetitle" -Pretext $activitytext -Text "$facts" -Fallback test |
    New-SlackMessage |
    Send-SlackMessage -uri $newdevices
