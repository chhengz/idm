Write-Host "=== Windows Defender Recovery Script (Win11) ===" -ForegroundColor Cyan

# 1. Remove Defender policy registry locks
$defenderPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$securityCenterPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Security Center"

Write-Host "Removing Defender policy restrictions..."
If (Test-Path $defenderPolicyPath) {
    Remove-Item -Recurse -Force $defenderPolicyPath
}

If (Test-Path $securityCenterPath) {
    Remove-Item -Recurse -Force $securityCenterPath
}

# 2. Ensure Defender services are enabled
Write-Host "Configuring Defender services..."
$services = @(
    "WinDefend",
    "WdNisSvc",
    "SecurityHealthService"
)

foreach ($svc in $services) {
    Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name $svc -ErrorAction SilentlyContinue
}

# 3. Reset Windows Security app
Write-Host "Resetting Windows Security UI..."
Get-AppxPackage Microsoft.SecHealthUI -AllUsers | Reset-AppxPackage

# 4. Repair Windows security policy
Write-Host "Repairing security policy..."
secedit /configure /cfg "$env:windir\inf\defltbase.inf" /db defltbase.sdb /verbose | Out-Null

# 5. Repair system files
Write-Host "Running system file repair (SFC)..."
sfc /scannow

Write-Host "Running DISM health restore..."
DISM /Online /Cleanup-Image /RestoreHealth

# 6. Force Defender re-enable
Write-Host "Re-enabling Defender real-time protection..."
Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue

Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Rebooting in 10 seconds..."
Start-Sleep -Seconds 10
Restart-Computer -Force
