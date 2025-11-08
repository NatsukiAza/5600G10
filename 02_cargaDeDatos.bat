@echo off
setlocal enabledelayedexpansion

echo ============================================
echo     CARGA AUTOMATIZADA DE DATOS - CONSORCIO
echo ============================================
echo.

REM === Solicitar la ruta base de los archivos ===
set /p RutaBase=Ingrese la ruta completa de la carpeta donde están los archivos: 

echo.
echo ============================================
echo   Rutas detectadas:
echo   Personas: !RutaBase!\Inquilino-propietarios-datos.csv
echo   Consorcios: !RutaBase!\UF por consorcio.txt
echo   Relacion: !RutaBase!\Inquilino-propietarios-UF.csv
echo   JSON: !RutaBase!\Servicios.Servicios.json
echo   Pagos: !RutaBase!\pagos_consorcios.csv
echo ============================================
echo.

REM === Confirmación del usuario ===
set /p continuar=¿Desea continuar con la carga? (S/N): 
if /I not "!continuar!"=="S" (
    echo Operación cancelada por el usuario.
    pause
    exit /b
)

echo.
echo Ejecutando script SQL...
echo.

REM === Ejecutar el script SQL con las rutas pasadas como variables ===
sqlcmd -S localhost -d COM5600G10 -E -i "02_StoreProcedures_a_desarrollar.sql" ^
    -v RutaPersonas="'!RutaBase!\Inquilino-propietarios-datos.csv'" ^
       RutaConsorcios="'!RutaBase!\UF por consorcio.txt'" ^
       RutaRelacion="'!RutaBase!\Inquilino-propietarios-UF.csv'" ^
       RutaJSON="'!RutaBase!\Servicios.Servicios.json'" ^
       RutaPagos="'!RutaBase!\pagos_consorcios.csv'"

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ ERROR: Falló la ejecución del script SQL.
    echo Revise la ruta del archivo o la conexión al servidor.
) else (
    echo.
    echo ✅ Ejecución completada correctamente.
)

echo.
pause
endlocal
