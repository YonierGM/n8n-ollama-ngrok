Write-Host "🛑 Deteniendo ngrok..."
Stop-Process -Name ngrok -ErrorAction SilentlyContinue

Write-Host "🛑 Deteniendo contenedor de n8n..."
docker compose stop
