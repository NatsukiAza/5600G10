@echo off
REM =============================================
REM  Script de automatización para la carga de datos
REM  Ejecuta los SP en SQL Server
REM  con rutas de archivos dinámicas
REM =============================================

setlocal

REM === Solicitamos las rutas al usuario ===
echo.
set /p RutaPersonas=Ingrese la ruta completa del archivo de PERSONAS (.csv): 
set /p RutaConsorcios=Ingrese la ruta completa del archivo de CONSORCIOS (.txt): 
set /p RutaRelacion=Ingrese la ruta completa del archivo de RELACIONES (.csv): 
set /p RutaJSON=Ingrese la ruta completa del archivo de EXPENSAS Y GASTOS (.json): 
set /p RutaPagos=Ingrese la ruta completa del archivo de PAGOS (.csv): 

echo.
echo Ejecutando script SQL...
echo.

REM === Ejecutar el script SQL pasando las variables ===
sqlcmd -S localhost -d ConsorcioDB -E -i ImportarDatos.sql ^
      -v RutaPersonas="'!RutaPersonas!'" ^
         RutaConsorcios="'!RutaConsorcios!'" ^
         RutaRelacion="'!RutaRelacion!'" ^
         RutaJSON="'!RutaJSON!'" ^
         RutaPagos="'!RutaPagos!'"

if %errorlevel% neq 0 (
    echo ❌ Error al ejecutar el script SQL.
    exit /b %errorlevel%
)

echo ---------------------------------------------
echo ✅ Proceso completado correctamente.
echo ---------------------------------------------
pause

endlocal


