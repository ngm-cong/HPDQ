# Verify the Installation
if (Get-Service -Name "MSSQLSERVER"  -ErrorAction SilentlyContinue) {
	Write-Host "SQL Instance already exists. Skipping creation." -ForegroundColor Yellow
}
else {
	#& "C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\SQL2022\setup.exe" /q /action=Uninstall /instancename=MSSQLSERVER /features=SQLEngine
	$installerName = "SQLEXPR_x64_ENU.exe"
	if (-not (Test-Path -Path "C:\SQLInstall")) {
		$downloadPath = "C:\SQLInstall"
		$installerUrl = "https://go.microsoft.com/fwlink/?linkid=866658" # Link for SQL Server 2019 Express

		New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null
		Set-Location -Path $downloadPath

		Invoke-WebRequest -Uri $installerUrl -OutFile $installerName
	}
	
	$configContent = @"
	[OPTIONS]
	FEATURES=SQLEngine
	INSTANCENAME=MSSQLSERVER
	SQLSVCACCOUNT="NT Authority\System"
	SQLSYSADMINACCOUNTS="NT Authority\System"
	SAPWD="HPDQ@123"
	IACCEPTSQLSERVERLICENSETERMS=True
"@

	$configFilePath = "C:\SQLInstall\Configuration.ini"

	# Tạo thư mục nếu chưa tồn tại
	$directory = Split-Path -Path $configFilePath -Parent
	if (-not (Test-Path $directory)) {
		New-Item -Path $directory -ItemType Directory -Force | Out-Null
	}

	# Ghi nội dung vào file
	Set-Content -Path $configFilePath -Value $configContent
	Write-Host "Đã tạo file Configuration.ini tại $configFilePath" -ForegroundColor Gree
	
	# Start the installation process
	Start-Process -FilePath "C:\SQLInstall\$installerName" -ArgumentList "/Q /IAcceptSQLServerLicenseTerms", "/ConfigurationFile=`"$configFilePath`"" -Wait -PassThru

}