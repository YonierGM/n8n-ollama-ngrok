# start.ps1
Write-Host "🌐 Iniciando ngrok..."

# Ruta al ejecutable
$ngrokPath = ".\ngrok.exe"

# Verifica si ngrok existe
if (-Not (Test-Path $ngrokPath)) {
    Write-Error "❌ ngrok.exe no encontrado. Coloca ngrok.exe en la carpeta actual o agrégalo al PATH."
    exit 1
}

# Iniciar ngrok en segundo plano y capturar su proceso para monitorear
$ngrokProcess = Start-Process $ngrokPath -ArgumentList "http 5678" -NoNewWindow -PassThru # -PassThru para obtener el objeto del proceso

# Esperar a que la API de ngrok esté disponible
$ngrokApi = "http://127.0.0.1:4040/api/tunnels"
$maxTries = 15 # Aumentar los intentos
$tries = 1

do {
    if (-not $ngrokProcess.HasExited) { # Verifica si el proceso de ngrok sigue corriendo
        try {
            $response = Invoke-RestMethod -Uri $ngrokApi -ErrorAction SilentlyContinue # Suprimir errores para que no inunden la consola
            if ($response -and $response.tunnels) {
                $ngrokReady = $true
            }
        } catch {
            # No es necesario mostrar el error aquí, el do-while lo maneja
        }
    } else {
        Write-Error "❌ El proceso de ngrok ha terminado inesperadamente."
        exit 1
    }

    if (-not $ngrokReady) {
        Write-Host "Esperando ngrok API ($tries/$maxTries)..."
        Start-Sleep -Seconds 2
        $tries++
    }
} while (-not $ngrokReady -and $tries -le $maxTries)

if (-not $ngrokReady) {
    Write-Error "❌ No se pudo conectar con la API de ngrok en http://127.0.0.1:4040 después de múltiples intentos."
    exit 1
}

# Obtener URL pública (asegúrate de que sea el túnel HTTPS si hay múltiples)
# Idealmente, buscamos el túnel HTTPS. Si solo hay uno, será ese.
$publicUrl = $response.tunnels | Where-Object { $_.proto -eq 'https' } | Select-Object -ExpandProperty public_url
if (-not $publicUrl) {
    $publicUrl = $response.tunnels[0].public_url # Si no se encuentra HTTPS, toma el primero
}

Write-Host "🌍 URL de ngrok: $publicUrl"

# --- PROCESAMIENTO ROBUSTO DEL ARCHIVO .env ---
$envFile = ".env"
$tempEnvFile = "$envFile.tmp" # Archivo temporal para escribir los cambios
$lines = Get-Content $envFile # Lee el archivo línea por línea

$updatedLines = @() # Array para almacenar las líneas actualizadas
$foundWebhook = $false
$foundProtocol = $false

foreach ($line in $lines) {
    # N8N_HOST DEBE SER 0.0.0.0 O NO ESTAR PRESENTE EN EL .ENV PARA ESTE USO
    # NO LO MODIFIQUES DINÁMICAMENTE CON LA URL DE NGROK
    if ($line -match '^N8N_HOST=') {
        $updatedLines += "N8N_HOST=0.0.0.0" # Vuelve al valor predeterminado
    }
    elseif ($line -match '^WEBHOOK_URL=') {
        $updatedLines += "WEBHOOK_URL=$publicUrl"
        $foundWebhook = $true
    }
    elseif ($line -match '^N8N_PROTOCOL=') {
        $updatedLines += "N8N_PROTOCOL=https"
        $foundProtocol = true
    }
    else {
        $updatedLines += $line # Mantener líneas que no sean relevantes
    }
}

# Añadir si no existen
# N8N_HOST NO NECESITA ESTAR SIEMPRE EN EL .ENV SI VALOR PREDETERMINADO ES 0.0.0.0
# PERO SI ESTÁ, ASEGÚRATE DE QUE SEA 0.0.0.0
# if (-not $foundHost) { $updatedLines += "N8N_HOST=0.0.0.0" } # Puedes añadirlo si quieres asegurarte

if (-not $foundWebhook) { $updatedLines += "WEBHOOK_URL=$publicUrl" }
if (-not $foundProtocol) { $updatedLines += "N8N_PROTOCOL=https" }

# Escribir las líneas actualizadas al archivo temporal
$updatedLines | Set-Content $tempEnvFile -Encoding UTF8

# Reemplazar el archivo original con el temporal
Move-Item -Path $tempEnvFile -Destination $envFile -Force

Write-Host "✅ Variables actualizadas en .env"

# Iniciar contenedor
Write-Host "🚀 Iniciando contenedor de n8n y ollama..."
docker compose up -d --force-recreate --build n8n ollama