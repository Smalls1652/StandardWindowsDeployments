<#
.SYNOPSIS
    Set the consumer features setting for Windows 10 Enterprise/Education.
.DESCRIPTION
    Set the consumer features setting for Windows 10 SKUs Enterprise and Education to enable or disable features and apps that would normally appear on consumer based editions of Windows 10.
.PARAMETER DisableSetting
    Disable the policy setting to have consumer features enabled.
.EXAMPLE
    PS > Set-ConsumerFeatures.ps1
    
    Enables the policy setting for 'DisableWindowsConsumerFeatures' to disable consumer features for users.
.EXAMPLE
    PS > Set-ConsumerFeatures.ps1 -DisableSetting
    
    Disables the policy setting for 'DisableWindowsConsumerFeatures' to enable consumer features for users.
.NOTES
    - Using the parameter '-DisableSetting' does not disable consumer features. It only acts as a way to disable the local policy option.
    - This setting only works on the Enterprise and Education SKUs of Windows 10.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DisableSetting
)

begin {

    #Setting the path and property for the policy setting.
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $RegProperty = "DisableWindowsConsumerFeatures"

    #Depending on the usage of the parameter -DisableSetting...
    switch ($DisableSetting) {
        $true { #Disable the policy setting.
            $RegSettings = @{
                "Status" = "Disabled";
                "Value"  = "0"
            }
        }

        Default { #Enable the policy setting.
            $RegSettings = @{
                "Status" = "Enabled";
                "Value"  = "1"
            }
        }
    }
}

process {
    if ($PSCmdlet.ShouldProcess($RegProperty, "Set to $($RegSettings['Status'])")) {
        try {
            #Try to create the policy setting.
            $null = New-ItemProperty -Path $RegPath -Name $RegProperty -Value $RegSettings['Value'] -PropertyType "DWORD" -ErrorAction Stop
        }
        catch [System.IO.IOException] {
            #If New-ItemProperty throws an IOException error, the setting probably already exists. This will fallback to Set-ItemProperty.
            Write-Verbose "Entry already exists, trying to use 'Set-ItemProperty' instead."
            $null = Set-ItemProperty -Path $RegPath -Name $RegProperty -Value $RegSettings['Value'] -ErrorAction Stop
        }
        catch [System.Security.SecurityException] {
            #If a SecurityException error is thrown, relay to the user to run the script in an elevated prompt.
            $ErrorDetails = $PSItem

            $ErrorSplat = @{
                "Message"           = "Failed to write registry setting. Please run this script in an elevated prompt.";
                "Exception"         = $ErrorDetails.FullyQualifiedErrorId;
                "Category"          = "PermissionDenied";
                "TargetObject"      = $RegPath;
                "RecommendedAction" = "Run in an elevated prompt."
            }

            Write-Error @ErrorSplat -ErrorAction Stop
        }
        catch {
            #All other errors are thrown normally.
            $ErrorDetails = $PSItem
            throw $ErrorDetails
        }
        finally {
            #If the -Verbose parameter is supplied, then get the value of the setting after execution and show it in the verbose output.
            switch ($VerbosePreference) {
                "Continue" {
                    $CurrentRegValue = Get-ItemPropertyValue -Path $RegPath -Name $RegProperty

                    Write-Verbose "$($RegProperty) was set to '$($CurrentRegValue)' after execution."
                }
            }
        }
    }
}

end {
    #Return an object of what was done.
    return [pscustomobject]@{
        "Setting" = $RegProperty;
        "Value"   = $RegSettings['Status']
    }
}