<#
.SYNOPSIS
    Generates a PowerShell param block with a hashtable for mapping drive letters to their volume GUIDs.

.DESCRIPTION
    This script queries the local system for all disk partitions that have an assigned drive letter and a volume GUID.
    It then formats this information into a PowerShell param block with a hashtable. The output is designed to be 
    copied and pasted directly into another script that uses [CmdletBinding()] and SupportsShouldProcess.

    Partitions without a drive letter or a GUID (like system reserved partitions) are automatically excluded. 
    The script must be run with administrative privileges to access partition information.

.EXAMPLE
    C:\Scripts\Get-DriveMapping.ps1

    Description
    -----------
    This command executes the script and prints the param block configuration to the console. 
    The output will look like the following:

    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$DriveMapping = @{
            "C" = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            "D" = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
        }
    )

.OUTPUTS
    System.String
    The script outputs strings directly to the host console using Write-Host.

.INPUTS
    None
    This script does not accept any pipeline input.

.NOTES
    Version:      1.0
    Author:       @neuroinsurgente
    Creation Date: 2025-07-27
    
    Requires:     This script requires administrative privileges to run, enforced by the #Requires -RunAsAdministrator statement.
    
    GUID Format:  The curly braces {} are removed from the GUID for cleaner formatting within the hash table string.
                  The GUID retrieved is the Volume GUID, which is a reliable way to identify a volume even if its 
                  drive letter changes.

.LINK
    Get-Partition
    about_Functions_CmdletBindingAttribute
#>

#Requires -RunAsAdministrator

try {
    # Output the param block structure
    Write-Host "[CmdletBinding(SupportsShouldProcess=`$true)]" -ForegroundColor Cyan
    Write-Host "param(" -ForegroundColor Cyan
    Write-Host "    [Parameter(Mandatory=`$false)]" -ForegroundColor Cyan
    Write-Host "    [hashtable]`$DriveMapping = @{" -ForegroundColor Cyan
    
    Get-Partition | 
        Where-Object { $_.DriveLetter -and $_.Guid } | 
        Sort-Object DriveLetter | 
        ForEach-Object {
            # Removes curly braces from the GUID string for a clean output.
            $cleanGuid = $_.Guid -replace '[{}]', ''
            # Format the line as "Key" = "Value"
            '        "{0}" = "{1}"' -f $_.DriveLetter, $cleanGuid
        }

    # Close the hashtable and param block
    Write-Host "    }" -ForegroundColor Cyan
    Write-Host ")" -ForegroundColor Cyan
}
catch {
    # Catch and display any terminating errors.
    Write-Error "An error occurred: $_"
    exit 1
}