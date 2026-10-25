$ErrorActionPreference = 'Stop'
$group = 'ow-block-middleeast'
$awsRegions = 'me-south-1'                              # Bahrain
$gcpRegions = 'me-central1', 'me-central2', 'me-west1'  # Doha, Dammam, Tel Aviv

# Reopen in an admin window if needed
$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process (Get-Process -Id $PID).Path "-NoProfile -NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    return
}

$rules = @(Get-NetFirewallRule -Group $group -ErrorAction SilentlyContinue)
Write-Host "Overwatch Middle East block: $(if ($rules) { 'ON' } else { 'OFF' })"
$choice = Read-Host '[B]lock, [U]nblock, or Enter to quit'

if ($choice -eq 'u') {
    if ($rules) { $rules | Remove-NetFirewallRule }
    Write-Host 'Middle East servers unblocked.'
}
elseif ($choice -eq 'b') {
    # Check for Overwatch.exe
    $key = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Overwatch'
    $suggest = Get-ItemProperty $key -ErrorAction SilentlyContinue | Where-Object InstallLocation |
        ForEach-Object { Join-Path $_.InstallLocation '_retail_\Overwatch.exe' } | Where-Object { Test-Path -LiteralPath $_ }
    while ($true) {
        $exe = (Read-Host "Overwatch.exe path$(if ($suggest) { " [$suggest]" })").Trim(' "')
        if (-not $exe) { $exe = $suggest }
        if ($exe -and (Test-Path -LiteralPath $exe -PathType Container)) {
            $exe = Get-ChildItem -LiteralPath $exe -Filter Overwatch.exe -Recurse -Depth 1 | Select-Object -First 1 -ExpandProperty FullName
        }
        if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) { break }
        Write-Warning 'Overwatch.exe not found there, try again.'
    }

    # Pull the current Middle East ranges from the official AWS and Google Cloud lists
    Write-Host 'Fetching server ranges...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 'Tls12'
    $aws = (Invoke-RestMethod 'https://ip-ranges.amazonaws.com/ip-ranges.json').prefixes | Where-Object { $_.service -eq 'EC2' -and $_.region -in $awsRegions }
    $gcp = (Invoke-RestMethod 'https://www.gstatic.com/ipranges/cloud.json').prefixes | Where-Object { $_.ipv4Prefix -and $_.scope -in $gcpRegions }
    $ranges = @($aws.ip_prefix) + @($gcp.ipv4Prefix) | Sort-Object -Unique
    if (-not $ranges) { throw 'Could not get any server ranges.' }

    # Swap Overwatch.exe game traffic to those ranges is dropped
    if ($rules) { $rules | Remove-NetFirewallRule }
    $rule = @{
        DisplayName   = 'Overwatch - block Middle East servers'
        Group         = $group
        Direction     = 'Outbound'
        Action        = 'Block'
        Protocol      = 'UDP'
        RemotePort    = '6250', '12000-64000'
        RemoteAddress = $ranges
        Program       = $exe
    }
    New-NetFirewallRule @rule | Out-Null
    Write-Host "Blocked $($ranges.Count) Middle East ranges for $exe"
    Write-Host 'Restart Overwatch if it is running.'
}
