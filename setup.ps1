# ISNA63 Tech Rota — one-shot IIS setup script
# Run this in PowerShell as Administrator AFTER installing:
#   1. dotnet-sdk-8.0.424-win-x64.exe
#   2. dotnet-hosting-8.0.30-win.exe

$ErrorActionPreference = "Stop"

# 1. Clone the repo
Write-Host "Cloning repo..." -ForegroundColor Cyan
if (Test-Path "C:\isna63-tech-rota") { Remove-Item "C:\isna63-tech-rota" -Recurse -Force }
git clone https://github.com/bl4ckph4nt0m/isna63-tech-rota.git C:\isna63-tech-rota

# 2. Publish the app
Write-Host "Publishing app..." -ForegroundColor Cyan
Push-Location C:\isna63-tech-rota\api
dotnet publish -c Release -o C:\inetpub\isna-rota
Pop-Location

# 3. Grant IIS write access for the SQLite database
Write-Host "Setting permissions..." -ForegroundColor Cyan
$acl = Get-Acl "C:\inetpub\isna-rota"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl "C:\inetpub\isna-rota" $acl

# 4. Import IIS module and create the site
Write-Host "Configuring IIS..." -ForegroundColor Cyan
Import-Module WebAdministration

# Remove existing site/pool if re-running
if (Get-Website -Name "ISNA-Rota" -ErrorAction SilentlyContinue) {
    Remove-Website -Name "ISNA-Rota"
}
if (Test-Path "IIS:\AppPools\ISNA-Rota") {
    Remove-WebAppPool -Name "ISNA-Rota"
}

# Create app pool (No Managed Code)
New-WebAppPool -Name "ISNA-Rota"
Set-ItemProperty "IIS:\AppPools\ISNA-Rota" -Name "managedRuntimeVersion" -Value ""

# Create website on port 8080
New-Website -Name "ISNA-Rota" -PhysicalPath "C:\inetpub\isna-rota" -Port 8080 -ApplicationPool "ISNA-Rota"

# 5. Restart IIS to pick up the hosting bundle
Write-Host "Restarting IIS..." -ForegroundColor Cyan
iisreset /restart

# 6. Open firewall
Write-Host "Opening firewall port 8080..." -ForegroundColor Cyan
netsh advfirewall firewall delete rule name="ISNA Rota" >$null 2>&1
netsh advfirewall firewall add rule name="ISNA Rota" dir=in action=allow protocol=tcp localport=8080

# 7. Done
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.PrefixOrigin -ne "WellKnown" } | Select-Object -First 1).IPAddress
Write-Host ""
Write-Host "Done! ISNA63 Tech Rota is live." -ForegroundColor Green
Write-Host "Local:   http://localhost:8080" -ForegroundColor Yellow
Write-Host "Network: http://${ip}:8080" -ForegroundColor Yellow
Write-Host "Passcode: isna2026" -ForegroundColor Yellow
