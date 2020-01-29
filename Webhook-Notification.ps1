####################################################################################################
#
# Configuration Section (This is where you can edit stuff to fit your needs)
#
####################################################################################################
# Enable testing mode (will post to the channel on every execution of this script if set to $true (default is $false))
$enableTesting = $false

##### Begin custom logic #####

    # Get any information you want posted here

    # Get logged in user
    $currentUser = $env:username

    # Get the Computer Name
    $computername = $env:computername

    # Get Computer Serialnumber
    $serialnumber = Get-WmiObject win32_bios | select -Expand serialnumber

    # Get Wifi Mac Address
    $macaddress = get-netadapter -name wi-fi* | select -Expand MacAddress

    # Get OS install date
    $installdate = ([WMI]'').ConvertToDateTime((Get-WmiObject Win32_OperatingSystem).InstallDate).ToString()

    # Get Posting Date and Time
    $time = Get-Date -Format "dd/MM/yyyy HH:mm"

    # Get a nice display friendly OS Name
    $OSinfo = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $OSDisplayName = "$($OSinfo.ProductName) $($OSinfo.ReleaseID)"

##### End custom logic #####


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
        Write-Output "this file indicates that the 'Intune-EmailNotification.ps1' script has run on this computer" > $cookieFile 
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
    Write-Output "This computer was enrolled more than a day ago, so we wont't send an email notification."
    Exit 0
}

# Building the notification design and post to your webhook
$payload = @{
“type” = “windows.enrolled”
“at” = “$time”
“id” = “$currentuser"
“serial_number” = “$serialnumber”
"computer_name" = "$computername"
"os" = "$OSDisplayname"
"install_date" = "$installdate"
"macaddress" = "$macaddress"
}

#Send to the Webhook
Invoke-WebRequest -Uri https://www.webhookhere.com/ -Method Post -Body (ConvertTo-Json -Compress -InputObject $payload) -ContentType “application/json”