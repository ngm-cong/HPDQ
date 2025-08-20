param(
    [string]$ftpPassword
)

# Lấy đường dẫn đầy đủ của thư mục chứa script
$scriptPath = $PSScriptRoot

# Lấy ký tự ổ đĩa (ví dụ: C, D)
$driveLetter = $scriptPath.Substring(0, 2) # Lấy 2 ký tự đầu tiên, ví dụ: "C:"

# Write-Host "Đường dẫn script: $scriptPath"
# Write-Host "Ổ đĩa hiện tại: $driveLetter"

$version = "1.0.0"

$outputPath = @()
# $projects = @("C:\Projects\HPDQ.WebSupport.API\src")
$projects = @("C:\Projects\HPDQ.WebSupport.API\src", "C:\Projects\HPDQ.WebSupport.SignalR\src", "C:\Projects\HPDQ.WebSupport.PresentationUI\src")
foreach ($project in $projects) {
	$projectFiles = Get-ChildItem -Path "$project" -Filter "*.csproj"
	if ($projectFiles.Count -gt 0) {
		$projectName = $projectFiles[0] -replace ".csproj", ""
		$path = "${driveLetter}\IIS\${projectName}"
		dotnet publish "$project\$projectFiles" --output "$path"
		$outputPath += $path
		Write-Host ""
	}
}
$compressPath = "${driveLetter}\IIS\${version}.zip"
if (Test-Path -Path "$compressPath") {
    Remove-Item -Path "$compressPath"
}
Compress-Archive -Path $outputPath -DestinationPath "$compressPath"
Remove-Item -Path $outputPath -Recurse -Force

# FTP Server Details
$ftpServer = "ftp://10.192.39.52/data"
$ftpUsername = "administrator"
# $ftpPassword = "password"
$remoteFile = "$ftpServer/${version}.zip"

# Create an FtpWebRequest object
$ftpRequest = [System.Net.FtpWebRequest]::Create($remoteFile)
$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftpRequest.Credentials = New-Object System.Net.NetworkCredential($ftpUsername, $ftpPassword)
$ftpRequest.UseBinary = $true # For binary files like zips, images, etc.
$ftpRequest.EnableSsl = $false # Use this for secure FTPS

# Read the file content
$fileContent = [System.IO.File]::ReadAllBytes($compressPath)
$ftpRequest.ContentLength = $fileContent.Length

# Get the request stream and write the file
$requestStream = $ftpRequest.GetRequestStream()
$requestStream.Write($fileContent, 0, $fileContent.Length)
$requestStream.Close()

# Get the response to ensure the upload was successful
$ftpResponse = $ftpRequest.GetResponse()
Write-Host "File uploaded. Status: $($ftpResponse.StatusDescription)"

# Cleanup
$ftpResponse.Close()