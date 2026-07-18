# Set the Downloads Directory
$DownloadsDir = "$env:USERPROFILE\Downloads"  # or "$env:USERPROFILE\OneDrive\Downloads"

Write-Host "Contents of the Downloads folder:" -ForegroundColor Gray
Write-Host "---------------------------------"

# Display-only view
Get-ChildItem -Path $DownloadsDir -File -Recurse |
    Select-Object Name, CreationTime, LastAccessTime, LastWriteTime

# Full objects kept for logic (includes FullName)
$Files = Get-ChildItem -Path $DownloadsDir -File -Recurse

# Detecting duplicate copies such as number patterns (1), (2), (3), etc.
$copyFiles = $Files | Where-Object { $_.Name -match '\(\d+\)' }

if ($copyFiles.Count -gt 0) {

    Write-Host "`nDisplaying duplicate copies:" -ForegroundColor Yellow
    Write-Host "---------------------------------"

    $copyFiles |
        Select-Object Name, CreationTime, LastAccessTime, LastWriteTime |
        Format-Table

    # Prompt for deletion one-by-one
    foreach ($file in $copyFiles) {
        $prompt = Read-Host "`nDo you want to delete this file?`n$($file.FullName)`n[Y/N]"
        if ($prompt -eq 'Y') {
            try {
                Remove-Item -Path $file.FullName -Force
                Write-Host "Deleted: $($file.FullName)" -ForegroundColor Green
            } catch {
                Write-Host "Failed to delete: $($file.FullName) -- $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Skipped deletion for: $($file.FullName)" -ForegroundColor Yellow
        }
    }

    Write-Host "`nPrompt-based deletion complete." -ForegroundColor Cyan

} else {
    Write-Host "`nNo duplicate copies found." -ForegroundColor Green
}
