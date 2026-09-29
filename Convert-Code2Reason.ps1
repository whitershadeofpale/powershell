<#
.SYNOPSIS
   Converts shutdown/reboot reason codes to human understandable reasons.
.DESCRIPTION
    Some events provide reason codes in order to tell why specific shutdown or reboot happens.
    First writen    : 2023-02-24
    Re-discovered   : 2024-02-23
    Modified        : 2024-05-28 (0x85000000 case added)
    Maj/Min/Add     : 2026-09-29 (labels added)
.LINK
    https://learn.microsoft.com/en-us/windows/win32/shutdown/system-shutdown-reason-codes

    Alternative way; use WinDbg, start it, attach to a process and use 
        !error c00a0032
    to get the reason text. (2025-09-10)


.EXAMPLE
    usage
        Convert-Code2Reason -ReasonCode 0x00000014
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [int]$ReasonCode
)

# $ReasonCode
# $ReasonCode | Format-Hex
$NetResult = @()

# The following are the major reason flags. They indicate the general issue type.
if (($ReasonCode -band 0x00070000) -eq 0x00070000) { # 1 2 4
    $NetResult += "Major: Legacy API used"
}
elseif (($ReasonCode -band 0x00060000) -eq 0x00060000) { # 2 4
    $NetResult += "Major: Power failure"
}
elseif (($ReasonCode -band 0x00050000) -eq 0x00050000) { # 1 4
    $NetResult += "Major: System failure"
}
elseif (($ReasonCode -band 0x00030000) -eq 0x00030000) { # 1 2
    $NetResult += "Major: Software issue"
}
elseif (($ReasonCode -band 0x00010000) -eq 0x00010000) {
    $NetResult += "Major: Hardware issue"
}
elseif (($ReasonCode -band 0x00020000) -eq 0x00020000) {
    $NetResult += "Major: OS issue"
}
elseif (($ReasonCode -band 0x00040000) -eq 0x00040000) {
    $NetResult += "Major: Application issue"
}


# The following are the minor reason flags.

if (($ReasonCode -band 0x00000017) -eq 0x00000017) { # 1 2 4 16
    $NetResult += "Minor: Hotfix uninstallation"
}
elseif (($ReasonCode -band 0x00000007) -eq 0x00000007) { # 1 2 4
    $NetResult += "Minor: Disk"
}
elseif (($ReasonCode -band 0x0000000c) -eq 0x0000000c) { # 4 8
    $NetResult += "Minor: Environment"
}
elseif (($ReasonCode -band 0x0000000d) -eq 0x0000000d) { # 1 4 8
    $NetResult += "Minor: Driver"
}
elseif (($ReasonCode -band 0x00000011) -eq 0x00000011) { # 1 16
    $NetResult += "Minor: Hotfix"
}
elseif (($ReasonCode -band 0x00000005) -eq 0x00000005) { # 1 4
    $NetResult += "Minor: Unresponsive"
}
elseif (($ReasonCode -band 0x00000002) -eq 0x00000002) {
    $NetResult += "Minor: Installation"
}
elseif (($ReasonCode -band 0x00000019) -eq 0x00000019) { # 1 2 16
    $NetResult += "Minor: MMC issue"
}
elseif (($ReasonCode -band 0x00000014) -eq 0x00000014) { # 4 16
    $NetResult += "Minor: Network connectivity"
}
elseif (($ReasonCode -band 0x00000009) -eq 0x00000009) { # 1 8
    $NetResult += "Minor: Network card"
}
elseif (($ReasonCode -band 0x0000000e) -eq 0x0000000e) { # 2 4 8
    $NetResult += "Minor: Other driver event"
}
elseif (($ReasonCode -band 0x0000000a) -eq 0x0000000a) { # 2 8
    $NetResult += "Minor: Power supply"
}
elseif (($ReasonCode -band 0x00000008) -eq 0x00000008) {
    $NetResult += "Minor: Processor"
}
elseif (($ReasonCode -band 0x00000004) -eq 0x00000004) {
    $NetResult += "Minor: Reconfigure"
}
elseif (($ReasonCode -band 0x00000013) -eq 0x00000013) {
    $NetResult += "Minor: Security issue"
}
elseif (($ReasonCode -band 0x00000012) -eq 0x00000012) {
    $NetResult += "Minor: Security patch"
}
elseif (($ReasonCode -band 0x00000018) -eq 0x00000018) {
    $NetResult += "Minor: Security patch uninstall"
}
elseif (($ReasonCode -band 0x00000010) -eq 0x00000010) {
    $NetResult += "Minor: Service pack"
}
elseif (($ReasonCode -band 0x00000016) -eq 0x00000016) {
    $NetResult += "Minor: Service pack uninstallation"
}
elseif (($ReasonCode -band 0x00000020) -eq 0x00000020) {
    $NetResult += "Minor: Terminal Services"
}
elseif (($ReasonCode -band 0x00000006) -eq 0x00000006) {
    $NetResult += "Minor: Unstable"
}
elseif (($ReasonCode -band 0x00000003) -eq 0x00000003) {
    $NetResult += "Minor: Upgrade"
}
elseif (($ReasonCode -band 0x00000015) -eq 0x00000015) {
    $NetResult += "Minor: WMI issue"
}

# The following optional flags provide additional information about the event.
if ($ReasonCode -band 0x40000000) { # removed -eq 0x04000000
    $NetResult += "Addit: user defined reason code"
}
elseif ($ReasonCode -band 0x80000000) { # removed -eq 0x80000000
    $NetResult += "Addit: Planned"
}

if ($ReasonCode -band 0x05000000) { # added 2024-05-28 to account for 0x85000000 code, which is a result of manual user initiation, with being prompted "Shutdown Event Tracker" dialog. Look for the comment.
    $NetResult += "Last : User initiated restart/shutdown. Look for the comment field."
}

if ($ReasonCode -eq 0) {
    $NetResult = "Other issue - 0x0"
}

$NetResult