<#
.SYNOPSIS
    Restores drive letter assignments to partitions based on a predefined mapping of volume GUIDs.

.DESCRIPTION
    This script assigns specific drive letters to disk partitions by identifying them via their unique Volume GUID.
    It iterates through a provided hash table mapping drive letters to GUIDs. For each entry, it finds the
    corresponding partition and assigns the correct drive letter.

    The script is designed to handle conflicts: if a target drive letter is already in use by another partition,
    it will attempt to unassign it first before reassigning it to the correct partition.

    Crucially, this script supports the -WhatIf and -Confirm parameters. It is strongly recommended to first run
    the script with the -WhatIf parameter to preview the changes that would be made without actually modifying
    the system. Administrative privileges are required.

.PARAMETER DriveMapping
    A hash table where the keys are the desired drive letters (e.g., "D") and the values are the corresponding
    volume GUIDs (e.g., "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").
    If not provided, the script uses a default, hardcoded mapping defined within the script itself.

.EXAMPLE
    C:\Scripts\Restore-DriveMapping.ps1 -WhatIf

    Description
    -----------
    This command performs a dry run using the default mapping. It will display all the actions it *would* take
    (unassigning and assigning drive letters) but will not make any actual changes to the system. This is the
    safest way to verify the script's intended operations.

.EXAMPLE
    C:\Scripts\Restore-DriveMapping.ps1 -Confirm

    Description
    -----------
    This command executes the drive letter restoration using the default mapping. It will prompt for confirmation
    before performing each individual operation that changes the system.

.EXAMPLE
    $customMapping = @{
        "X" = "12345678-1234-1234-1234-1234567890ab";
        "Y" = "fedcba98-7654-3210-fedc-ba9876543210"
    }
    C:\Scripts\Restore-DriveMapping.ps1 -DriveMapping $customMapping -Verbose

    Description
    -----------
    This command runs the script with a custom mapping defined in the $customMapping variable. The -Verbose switch
    will provide detailed, step-by-step output of the script's execution.

.INPUTS
    None
    This script does not accept pipeline input.

.OUTPUTS
    System.String
    The script outputs status messages to the host console.

.NOTES
    Version:      1.0
    Author:       @neuroinsurgente
    Creation Date: 2025-07-27
    
    Requires:     This script must be run with administrative privileges.
    
    Safety First: Always use the -WhatIf parameter for a dry run before executing any changes. The GUIDs must be
                  accurate for the target machine, otherwise the script will not find the partitions.

.LINK
    Get-Partition
    Set-Partition
    about_Comment_Based_Help
    about_ShouldProcess
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [hashtable]$DriveMapping = @{
        "C" = "62ba4717-c276-46d0-b06b-9257c1c45d0c"
        "D" = "89f13f2a-bb53-4eff-965d-fdd17e37a4ea"
        "E" = "cd7e5bd3-7738-458a-af7d-52049249c33a"
        "F" = "b9d1e173-de72-4edd-904b-607b82f96b0d"
    }
)

#Requires -RunAsAdministrator

try {
    Write-Host "Starting drive letter restoration process..." -ForegroundColor Cyan
    Write-Host "WARNING: This script modifies system settings. Use -WhatIf to preview changes." -ForegroundColor Yellow

    # Process each mapping defined in the hash table.
    foreach ($drive in $DriveMapping.GetEnumerator()) {
        $targetLetter = $drive.Key
        $targetGuid = $drive.Value
        
        Write-Host "`nProcessing mapping: Drive '$($targetLetter)' -> GUID '{$($targetGuid)}'"

        # Find the target partition by its GUID.
        $partition = Get-Partition | Where-Object { $_.Guid -and ($_.Guid -replace '[{}]', '') -eq $targetGuid }

        if ($partition) {
            # Check if the partition already has the correct drive letter.
            if ($partition.DriveLetter -eq $targetLetter) {
                Write-Host "[OK] Drive '$($targetLetter)' is already correctly assigned." -ForegroundColor Green
            }
            else {
                # If the letter needs to be changed, first check if the target letter is already in use.
                $conflictingPartition = Get-Partition | Where-Object { $_.DriveLetter -eq $targetLetter }
                if ($conflictingPartition) {
                    Write-Host "[WARN] Drive letter '$($targetLetter)' is currently in use by another partition. Attempting to unassign..." -ForegroundColor Yellow
                    
                    if ($PSCmdlet.ShouldProcess("partition $($conflictingPartition.PartitionNumber) on Disk $($conflictingPartition.DiskNumber)", "Unassign drive letter '$($targetLetter)'")) {
                        Remove-PartitionAccessPath -DiskNumber $conflictingPartition.DiskNumber -PartitionNumber $conflictingPartition.PartitionNumber -AccessPath "$($targetLetter):"
                    }
                }

                # Now, assign the correct drive letter to the target partition.
                Write-Host "[ACTION] Assigning letter '$($targetLetter)' to partition with GUID '{$($targetGuid)}'."
                if ($PSCmdlet.ShouldProcess("partition $($partition.PartitionNumber) on Disk $($partition.DiskNumber) (GUID: {$targetGuid})", "Assign drive letter '$($targetLetter)'")) {
                    Set-Partition -DiskNumber $partition.DiskNumber -PartitionNumber $partition.PartitionNumber -NewDriveLetter $targetLetter
                }
            }
        }
        else {
            Write-Warning "[NOT FOUND] No partition found with GUID '{$targetGuid}' for drive letter '$($targetLetter)'."
        }
    }

    Write-Host "`nDrive letter restoration process completed." -ForegroundColor Cyan
}
catch {
    Write-Error "A critical error occurred during the restoration process: $($_.Exception.Message)"
    exit 1
}
