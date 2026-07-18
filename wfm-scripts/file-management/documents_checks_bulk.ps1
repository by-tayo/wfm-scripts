# Set the Downloads Directory

$DocumentsDir = "$env:USERPROFILE\Documents" #You can add OneDrive if you have one

Write-Host "Contents of the Documents folder:" -ForegroundColor Gray
Write-Host "---------------------------------"

# Get all files in Downloads and Subfolders

Get-ChildItem -Path $DocumentsDir -File -Recurse | Select-Object Name, CreationTime, LastAccessTime, LastWriteTime

# Making a pointer reference

$Files = Get-ChildItem -Path $DocumentsDir -File -Recurse | Select-Object Name, CreationTime, LastAccessTime, LastWriteTime

#Detecting duplicate copies

$copyFiles = $Files | Where-Object { $_.Name -match '\(\d+\)' }

if ($copyFiles.Count -gt 0) {

    Write-Host "`nDisplaying duplicate copies:" -ForegroundColor Yellow
    Write-Host "---------------------------------"

$copyFiles | Format-Table Name, LastAccessTime, FullName -AutoSize

    # Single prompt to delete all
    $groupPrompt = Read-Host "`nDelete ALL duplicate copies listed above? (Y/N)"
    if ($groupPrompt -eq 'Y') {
        foreach ($file in $copyFiles) {
            try {
                Remove-Item -Path $file.FullName -Force
                Write-Host "Deleted: $($file.FullName)" -ForegroundColor Green
            } catch {
                Write-Host "Failed to delete: $($file.FullName) -- $_" -ForegroundColor Red
            }
        }
        Write-Host "`nBatch deletion complete." -ForegroundColor Cyan
    } else {
        Write-Host "`nNo files were deleted." -ForegroundColor Yellow
    }

} else {
    Write-Host "`nNo duplicate copies found." -ForegroundColor Green
}
