Write-Host "===================================================="
Write-Host "Dang tu dong tai va cai dat Flutter SDK vao D:\flutter..."
Write-Host "===================================================="

$flutterZip = "D:\miniproject3\flutter_sdk.zip"
$targetDir = "D:\"
$flutterBin = "D:\flutter\bin"

if (-not (Test-Path "D:\flutter")) {
    if (-not (Test-Path $flutterZip)) {
        Write-Host "1/3: Dang tai Flutter SDK bang BitsTransfer/curl (vui long cho)..."
        curl.exe -L -o $flutterZip "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.3-stable.zip"
    }

    if (Test-Path $flutterZip) {
        Write-Host "2/3: Dang giai nen vao D:\flutter..."
        Expand-Archive -Path $flutterZip -DestinationPath $targetDir -Force
        Remove-Item $flutterZip -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "D:\flutter da co san."
}

Write-Host "3/3: Dang them bien moi truong D:\flutter\bin..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*D:\flutter\bin*") {
    $newPath = "$userPath;D:\flutter\bin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Da them D:\flutter\bin vao User Path thành công!"
} else {
    Write-Host "Bien moi truong D:\flutter\bin da co san."
}

Write-Host "===================================================="
Write-Host "HOAN THANH! Hay khoi dong lai VS Code va go: flutter devices"
Write-Host "===================================================="
