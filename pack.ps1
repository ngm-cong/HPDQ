param (
    [string]$Projects = "C:\Projects\HPDQ.WebSupport",
	[string]$Publish = "C:\IIS",
	[string]$Version = "1.0.1.0"
)
Write-Host "⏳ " -ForegroundColor Yellow -NoNewline
Write-Host "Tìm kiếm các thư mục..."
$filePathObject = Get-ChildItem -Path "$Projects" -Filter "*HPDQ.WebSupport.API.csproj" -Recurse
$apiFullPath = $filePathObject.FullName
if ($apiFullPath -eq $null) {
	Write-Host "❗ " -ForegroundColor Red -NoNewline
    Write-Host "Không tìm thấy API trong $Projects."
	return
} else {
	Write-Host "✔ " -ForegroundColor Green -NoNewline
	Write-Host "Tìm thấy API ở $apiFullPath."
}
$filePathObject = Get-ChildItem -Path "$Projects" -Filter "*HPDQ.WebSupport.SignalR.csproj" -Recurse
$signalRFullPath = $filePathObject.FullName
if ($signalRFullPath -eq $null) {
	Write-Host "❗ " -ForegroundColor Red -NoNewline
    Write-Host "Không tìm thấy SignalR trong $Projects."
	return
} else {
	Write-Host "✔ " -ForegroundColor Green -NoNewline
	Write-Host "Tìm thấy SignalR ở $signalRFullPath."
}
$filePathObject = Get-ChildItem -Path "$Projects" -Filter "*HPDQ.WebSupport.csproj" -Recurse
$websiteFullPath = $filePathObject.FullName
if ($websiteFullPath -eq $null) {
	Write-Host "❗ " -ForegroundColor Red -NoNewline
    Write-Host "Không tìm thấy Website trong $Projects."
	return
} else {
	Write-Host "✔ " -ForegroundColor Green -NoNewline
	Write-Host "Tìm thấy Website ở $websiteFullPath."
}

Write-Host "✍ " -ForegroundColor Yellow -NoNewline
Write-Host "Tự động đánh phiên bản ở website."
$websiteFullPath = "C:\Projects\HPDQ.WebSupport\7. HPDQ.WebSupport.PresentationUI\src\HPDQ.WebSupport.csproj"
$websiteDirectory = Split-Path -Path $websiteFullPath -Parent
$filePathObject = Get-ChildItem -Path "$websiteDirectory" -Filter "*_Layout.cshtml" -Recurse
$layoutFullPath = $filePathObject.FullName
if ($layoutFullPath -eq $null) {
	Write-Host "❗ " -ForegroundColor Red -NoNewline
    Write-Host "Không tìm thấy layout trong $websiteDirectory."
	return
} else {
	Write-Host "✔ " -ForegroundColor Green -NoNewline
	Write-Host "Tìm thấy layout ở $layoutFullPath."
}
$fileContent = Get-Content -Path $layoutFullPath
$newContent = $fileContent -replace "\d\.\d\.\d\.\d*", "$Version"
$newContent = $newContent.TrimEnd("`n", "`r")
$newContent | Set-Content -Path $layoutFullPath -Encoding utf8

Write-Host "🔒 " -ForegroundColor Yellow -NoNewline
Write-Host "Đóng gói API."
dotnet publish "$apiFullPath" -c Release -o "$Publish\HPDQ.WebSupport.API"
Write-Host "🔒 " -ForegroundColor Yellow -NoNewline
Write-Host "Đóng gói SignalR."
dotnet publish "$signalRFullPath" -c Release -o "$Publish\HPDQ.WebSupport.SignalR"
Write-Host "🔒 " -ForegroundColor Yellow -NoNewline
Write-Host "Đóng gói Website."
dotnet publish "$websiteFullPath" -c Release -o "$Publish\HPDQ.WebSupport"
Write-Host "🗜 " -ForegroundColor Blue -NoNewline
Write-Host "Nén nội dung đóng gói."
$compressFilePath = "$Publish\HPDQ.WebSupport.$Version.zip"
if (Test-Path -Path $compressFilePath -PathType Leaf) {
    Remove-Item -Path $compressFilePath -Force
}
Compress-Archive -Path "$Publish\HPDQ.WebSupport.API", "$Publish\HPDQ.WebSupport.SignalR", "$Publish\HPDQ.WebSupport" -DestinationPath "$compressFilePath"
Write-Host "🗑 " -ForegroundColor Blue -NoNewline
Write-Host "Dọn dẹp."
Remove-Item -Path "$Publish\HPDQ.WebSupport.API", "$Publish\HPDQ.WebSupport.SignalR", "$Publish\HPDQ.WebSupport" -Recurse -Force
Write-Host "✔ " -ForegroundColor Green -NoNewline
Write-Host "Hoàn tất."
#& "C:\Projects\HPDQ.WebSupport\7. HPDQ.WebSupport.PresentationUI\pack.ps1" -Version "1.0.1.0" -Projects "C:\Projects\HPDQ.WebSupport" -Publish "C:\IIS"