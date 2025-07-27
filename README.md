# PowerShell Drive Mapping Tools

A set of PowerShell scripts to reliably export and restore drive letter assignments on Windows systems by using persistent volume GUIDs. This is especially useful for system migration, disaster recovery, or ensuring configuration consistency across multiple machines.

## Features

- **GUID-Based Logic**: Uses Volume GUIDs, the most reliable method to identify partitions, regardless of disk order.
- **Automated Configuration Generation**: Includes a script to automatically generate the required mapping configuration from a source machine.
- **Conflict Resolution**: The restore script can automatically unassign a drive letter if it's currently in use by a different partition.
- **Safe Execution**: Fully supports -WhatIf and -Confirm parameters, allowing you to preview all changes before they are made.
- **Administrator-Ready**: Includes #Requires -RunAsAdministrator to prevent errors from insufficient permissions.

## Prerequisites

- Windows PowerShell 5.1 or later.
- Must be run with Administrator privileges.

## Scripts Included

### 1. Get-DriveMapping.ps1

This script scans the local machine and generates a PowerShell parameter block containing a hashtable that maps the current drive letters to their respective volume GUIDs.

**Usage:**
Simply execute the script. The output is designed to be copied directly into the Restore-DriveMapping.ps1 script or used as a parameter.

```powershell
.\Get-DriveMapping.ps1
```

### 2. Restore-DriveMapping.ps1

This script reads a hashtable of drive letter-to-GUID mappings and applies them to the local system. It ensures each partition identified by its GUID is assigned the correct drive letter.

**Usage:**
The script can use its default, hardcoded mapping, or you can provide a custom one.

**Perform a dry run to see what changes would be made**
```powershell
.\Restore-DriveMapping.ps1 -WhatIf
```

**Execute the restoration, prompting for confirmation on each change**
```powershell
.\Restore-DriveMapping.ps1 -Confirm
```

**Execute with a custom mapping without individual prompts**
```powershell
$customMap = @{ "E" = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" }
.\Restore-DriveMapping.ps1 -DriveMapping $customMap -Verbose
```

## Recommended Workflow

This is the standard procedure for cloning a drive letter configuration from a source machine to a target machine.

### On the SOURCE machine:
1. Run Get-DriveMapping.ps1.
2. Copy the entire output block (from [CmdletBinding... to the final )).

### On the TARGET machine:
1. Open Restore-DriveMapping.ps1 in an editor.
2. Replace the existing param(...) block at the top of the script with the block you copied from the source machine.
3. Save the modified script.
4. Execute the restoration on the TARGET machine:

**First, always perform a dry run to ensure the operations are correct:**
```powershell
.\Restore-DriveMapping.ps1 -WhatIf
```

**Review the output. If everything looks correct, execute the script for real:**
```powershell
.\Restore-DriveMapping.ps1
```

## License

This project is licensed under the MIT License.