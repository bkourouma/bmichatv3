# Script PowerShell pour tester l'API Docker
$uri = "http://localhost:3006/api/chat"
$body = @{
    message = "Quels sont les documents necessaires pour ouvrir un compte TresorMoney"
    session_id = "test_docker_session"
    user_id = "test_user"
} | ConvertTo-Json

Write-Host "Testing Docker API..."
Write-Host "URI: $uri"
Write-Host "Body: $body"

try {
    $response = Invoke-RestMethod -Uri $uri -Method POST -ContentType "application/json" -Body $body
    Write-Host "Response:"
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)"
} 