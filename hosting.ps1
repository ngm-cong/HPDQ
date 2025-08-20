## Check for administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: This script must be run as an administrator." -ForegroundColor Red
    return
}

# Import the WebAdministration module
try {
    Import-Module WebAdministration -ErrorAction Stop
}
catch {
    Write-Host "Error: The WebAdministration module could not be loaded. Please ensure the IIS Management Tools are installed." -ForegroundColor Red
    return
}

# Define variables
$siteName = "DEVFTPsite"
$dirPath = "C:\FTP"
$ftpPort = 21
$version = "1.0.0"

$system32Path = Join-Path -Path $env:windir -ChildPath "System32"
$appcmd = "$system32Path\inetsrv\AppCmd.exe";

# Check if the FTP site already exists
if (& $appcmd list site $siteName) {
    Write-Host "The FTP site '$siteName' already exists. Skipping creation." -ForegroundColor Yellow
}
else {
    Write-Host "The FTP site '$siteName' does not exist. Creating now..." -ForegroundColor Green

    # Ensure the physical directory exists
    if (-not (Test-Path $dirPath)) {
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
        Write-Host "Created physical directory: $dirPath" -ForegroundColor Cyan
    }

    # Create the new FTP site
    New-WebFtpSite -Name $siteName -Port $ftpPort -PhysicalPath $dirPath | Out-Null
    Write-Host "Successfully created FTP site '$siteName' on port $ftpPort." -ForegroundColor Green
	
	# 3. Cấu hình quyền cho người dùng Administrator
    Write-Host "Đang cấu hình quyền Read & Write cho nhóm 'BUILTIN\Administrators'..."
    
    # Sử dụng Add-WebConfiguration để thêm quy tắc ủy quyền
    # Add-WebConfiguration -pspath 'MACHINE/WEBROOT/APPHOST' `
    #                      -Filter "system.ftpserver/security/authorization" `
    #                      -Value @{accessType="Allow"; users="BUILTIN\Administrators"; permissions="Read, Write"}
                       
    Write-Host "Đã cấu hình quyền thành công."
	
	$ruleName = "Allow Inbound Port FTP"
	$port = 21
	$protocol = "TCP"

	Write-Host "Đang tạo quy tắc tường lửa để mở port $port ($protocol)..."

	try {
		# Kiểm tra xem quy tắc đã tồn tại chưa để tránh tạo trùng
		if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
			New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol $protocol -LocalPort $port
			Write-Host "✅ Quy tắc '$ruleName' đã được tạo thành công." -ForegroundColor Green
		} else {
			Write-Host "ℹ️ Quy tắc '$ruleName' đã tồn tại. Không cần tạo lại." -ForegroundColor Yellow
		}
	} catch {
		Write-Host "❌ Đã xảy ra lỗi khi tạo quy tắc tường lửa: $($_.Exception.Message)" -ForegroundColor Red
	}
}

$projects = @("HPDQ.WebSupport.API", "HPDQ.WebSupport.SignalR", "HPDQ.WebSupport")
$sitePort = 8080
foreach ($siteName in $projects) {
	$dirPath = "C:\IIS\$siteName"
	if (-not (Test-Path $dirPath)) {
		New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
		Write-Host "Created physical directory: $dirPath" -ForegroundColor Cyan
	}
	$sitePort += 1
	# Check if the FTP site already exists
	if (& $appcmd list site $siteName) {
		Write-Host "Website '$siteName' already exists. Skipping creation." -ForegroundColor Yellow
	}
	else {
		New-WebAppPool -Name $siteName | Out-Null
		New-WebSite -Name $siteName -Port $sitePort -PhysicalPath $dirPath -ApplicationPool $siteName | Out-Null
		Write-Host "Website '$siteName' has been created successfully." -ForegroundColor Green
	}
}

if (Test-Path -Path "C:\FTP\data\$version.zip") {
	Write-Host "Found '$version'." -ForegroundColor Green
}