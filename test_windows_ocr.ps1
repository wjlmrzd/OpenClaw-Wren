Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    $ocrEngine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
    if ($ocrEngine) {
        Write-Host "Windows OCR available"
        Write-Host "Languages: $($ocrEngine.AvailableRecognizerLanguages -join ', ')"
    } else {
        Write-Host "Windows OCR not available"
    }
} catch {
    Write-Host "Windows OCR error: $($_.Exception.Message)"
}
