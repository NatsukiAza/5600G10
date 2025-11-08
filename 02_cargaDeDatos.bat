@echo off
REM =============================================
REM  Script de automatización de carga de datos
REM  Ejecuta los procedimientos almacenados en SQL Server
REM  con rutas de archivos dinámicas
REM =============================================

setlocal

echo ---------------------------------------------
echo   INICIO DEL PROCESO DE IMPORTACION
echo ---------------------------------------------

REM Pedimos al usuario las rutas de los archivos
set /p RutaPersonas="Ingrese la ruta del archivo de PERSONAS (.csv): "
set /p RutaConsorcios="Ingrese la ruta del archivo de CONSORCIOS (.csv): "
set /p RutaRelacion="Ingrese la ruta del archivo de RELACIONES (.csv): "
set /p RutaJSON="Ingrese la ruta del archivo de EXPENSAS (.json): "
set /p RutaPagos="Ingrese la ruta del archivo de PAGOS (.csv): "

echo ---------------------------------------------
echo Ejecutando script SQL en SQL Server...
echo ---------------------------------------------

sqlcmd -S . -d COM025600 -E -i "02_StoreProcedures_a_desarrollar.sql" ^
    -v RutaPersonas="%RutaPersonas%" ^
       RutaConsorcios="%RutaConsorcios%" ^
       RutaRelacion="%RutaRelacion%" ^
       RutaJSON="%RutaJSON%" ^
       RutaPagos="%RutaPagos%"

if %errorlevel% neq 0 (
    echo ❌ Error al ejecutar el script SQL.
    exit /b %errorlevel%
)

echo ---------------------------------------------
echo ✅ Proceso completado correctamente.
echo ---------------------------------------------
pause

endlocal

