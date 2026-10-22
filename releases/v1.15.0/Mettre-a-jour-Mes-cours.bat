@echo off
title Mise a jour Mes cours 1.15.0
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; iex (Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/Senouy13/mes-cours-app/main/releases/v1.15.0/installer.ps1').Content"
pause
