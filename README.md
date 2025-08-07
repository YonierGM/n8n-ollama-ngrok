# 🌐 n8n + Ollama + Ngrok

Este proyecto permite levantar localmente una instancia de **n8n** conectada con **Ollama** (para ejecutar modelos LLM locales) y exponerla de forma segura a internet usando **Ngrok**, ideal para probar automatizaciones basadas en webhooks con IA generativa.

## 🚀 Características

- 🔧 Automatización de flujos con [n8n](https://n8n.io/)
- 🤖 Integración con modelos locales de LLM mediante [Ollama](https://ollama.com/)
- 🌍 Exposición de tu entorno local con [Ngrok](https://ngrok.com/)
- ⚙️ Variables de entorno autoconfiguradas para facilitar el uso
- 🐳 Soporte para Docker


## ⚙️ Requisitos

- Docker
- [Ngrok](https://ngrok.com/download) (coloca el ejecutable en la raíz del proyecto)
- [modelo de ollama instalado en el contenedor de ollama en docker]

## ▶️ Cómo usar

1. Asegúrate de tener `ngrok.exe` en la misma carpeta que el script.
2. Abre PowerShell y ejecuta:

```powershell
./start.ps1
```
Este script:

- Inicia Ngrok en segundo plano

- Obtiene la URL pública

- Actualiza automáticamente .env

- Proporciona la URL pública generada por Ngrok, para lanzar n8n como: https://xxxxx.ngrok-free.app

```powershell
./stop.ps1
```
- Detiene ngrok

- Detiene la ejecucion de los contenedores
