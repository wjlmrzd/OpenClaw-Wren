$model = "minimax-coding-plan/minimax-2.7"

$jobs = @(
    "f36fe701-5c76-47ad-8cb8-1a996a37d1b5",
    "2b564e59-8ed9-4cd8-8345-a9b41e4349bb",
    "4f5e3918-ce1e-4548-b0c4-97ea5d8c28e5",
    "ccb233d7-0977-4d57-aba7-7564a67041d8",
    "3a1df011-613d-4528-a274-530cfd84f4fb",
    "b6bc413c-0228-48c8-b42c-0af833216d2c",
    "e4248abd-0b9b-4540-9bc5-633547462443",
    "7eb7f35e-fe72-4a90-bfc6-ed59392b10f6",
    "92af6946-b23b-4534-a6b8-5877cfa36f12",
    "2bb2b058-da87-486a-a400-b871cd5cf8a4",
    "f920c2a2-6afc-4fc8-84ad-01593d2d22d1",
    "fa18eb23-19af-4176-8e60-990050ba1fab",
    "c73f1ecf-9f61-47c5-bea1-1c4f322e2ebe",
    "7677e68c-a6e7-4d92-8d31-09fb24bb5769",
    "af025901-6ebc-4541-9698-91c5db9907e6",
    "98d9b2a8-b925-470b-b0ea-4f74290f3e4b",
    "13f18a92-372a-4076-9b97-08f0efa2377f",
    "58540a34-62ab-46a7-a713-cac112e5cd48",
    "b41843c3-9956-4992-860d-df21cd03a766",
    "791c995e-4758-469d-ac35-608da1627167",
    "3c5f825f-60c8-4a90-9400-1e565ab32eaa",
    "e15879fd-59a5-446a-8290-7682fddaca63",
    "2428c991-f51e-47d7-8b6d-0035b8aba1e1",
    "fae5e00a-aca8-4cb5-aa87-16f4099651aa",
    "b65e9a07-abbb-4a2d-b2a1-0396e912308e",
    "f84bb934-49bb-4d5b-8bd3-697c43f8cab3",
    "53b6edc8-7cc6-4900-ab41-d1abd3e1e15f",
    "806f7f0b-f566-452e-a656-6910e5d7531a",
    "0e63f087-5446-4033-b826-19dafe65673b",
    "bb0ed170-fa8f-4441-8016-c2119809b436",
    "afd8aec9-1a66-4bf7-a46a-bedf4490356e",
    "22b950df-29d8-40a7-8d08-427cb032eabb",
    "93a63a28-8825-4a68-9c85-5706d9e011ec"
)

$success = 0
$failed = 0

foreach ($id in $jobs) {
    $output = openclaw cron edit $id --model $model 2>&1
    if ($LASTEXITCODE -eq 0) {
        $success++
        Write-Host "[OK] $id"
    } else {
        $failed++
        Write-Host "[FAIL] $id : $output"
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Success: $success"
Write-Host "Failed: $failed"
