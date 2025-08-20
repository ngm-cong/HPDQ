param(
    [string]$FileName
)

# Tải script về máy
$rawUrl = "https://raw.githubusercontent.com/ngm-cong/HPDQ/main/$FileName.ps1"
$outputPath = "C:\temp\$FileName.ps1"

try {
	New-Item -Path "C:\temp" -ItemType Directory -Force
	
    # Tải file về máy tính
    Invoke-WebRequest -Uri $rawUrl -OutFile $outputPath

    # Chạy script đã tải về
    & $outputPath

} catch {
    Write-Host "Đã xảy ra lỗi: $($_.Exception.Message)"
}