@echo off
setlocal enabledelayedexpansion

echo ============================================
echo      CARGA AUTOMATIZADA DE DATOS - CONSORCIO
echo ============================================
echo.

REM === 1. Solicitar el nombre del servidor (Instancia SQL) ===
set /p ServerName=Ingrese el nombre del servidor SQL (ej: DESKTOP-B8B7SP5\MSSQLSERVER01): 

echo.
REM === 2. Elegir el método de autenticación ===
set AuthType=
:AuthLoop
echo Seleccione el metodo de autenticacion:
echo [W] - Autenticacion de Windows (Recomendado)
echo [S] - Autenticacion de SQL Server (Usuario/Contraseña)
set /p AuthType=Opcion (W/S): 

if /I "!AuthType!"=="W" (
    set SqlAuthParam=-E
    goto AuthDone 
)

if /I "!AuthType!"=="S" (
    set /p SqlUser=Ingrese el usuario SQL (ej: sa): 
    set /p SqlPass=Ingrese la contraseña SQL: 
    set SqlAuthParam=-U "!SqlUser!" -P "!SqlPass!"
    goto AuthDone
)

echo.
echo ❌ Opcion invalida. Intente de nuevo.
goto AuthLoop

:AuthDone
echo.
REM === 3. Solicitar la ruta base de los archivos ===
set /p RutaBase=Ingrese la ruta completa de la carpeta donde estan los archivos: 

echo.
echo Ejecutando script SQL en el servidor: !ServerName!
echo.

REM === Escapar las barras invertidas en la ruta base para T-SQL ===
set "RutaBaseSQL=!RutaBase:\=\\!"

REM === Ejecutar el script SQL con las variables y autenticación dinamica ===
sqlcmd -S "!ServerName!" -d COM5600G10 !SqlAuthParam! -i "03_StoreProcedures_a_desarrollar.sql" ^
     -v RutaPersonas="!RutaBaseSQL!\\Inquilino-propietarios-datos.csv" ^
        RutaConsorcios="!RutaBaseSQL!\\UF por consorcio.txt" ^
        RutaRelacion="!RutaBaseSQL!\\Inquilino-propietarios-UF.csv" ^
        RutaJSON="!RutaBaseSQL!\\Servicios.Servicios.json" ^
        RutaPagos="!RutaBaseSQL!\\pagos_consorcios.csv"

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

