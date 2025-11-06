/*ADMINISTRACION*/
IF OBJECT_ID('dbo.ImportarDatosAdministracion', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarDatosAdministracion;
GO
	
CREATE OR ALTER PROCEDURE sp_ImportarDatosAdministracion
AS 
BEGIN
   SET NOCOUNT ON
    
    MERGE dbo.Administracion AS Destino
    USING (
        VALUES 
            (1, 'Altos de Saint Just Administración', 'Calle A 123', 'contacto@altosstjust.com'),
            (2, 'Consorcios del Sur', 'Avenida Sur 456', 'info@consorciosdelsur.com'),
            (3, 'Administradora Central', 'Carrera Central 789', 'administracion@central.com') 
    ) AS Fuente(ID_Administracion, Nombre, Direccion, Correo_Electronico)
    ON (
        Destino.ID_Administracion = Fuente.ID_Administracion 
    )
    --
    WHEN MATCHED THEN
        UPDATE SET
            Destino.Nombre = Fuente.Nombre,
            Destino.Direccion = Fuente.Direccion,
            Destino.Correo_Electronico = Fuente.Correo_Electronico
    --
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ID_Administracion,Nombre,Direccion,Correo_Electronico)
        VALUES (
        Fuente.ID_Administracion, 
        Fuente.Nombre, 
        Fuente.Direccion,
        Fuente.Correo_Electronico);
    --
END
GO

EXEC sp_ImportarDatosAdministracion
GO


/*CONSORCIO8*/
IF OBJECT_ID('dbo.ImportarDatosConsorcio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarDatosConsorcio;
GO

DROP PROCEDURE ImportarDatosConsorcio
GO

CREATE PROCEDURE ImportarDatosConsorcio
	@RutaArchivoNovedades VARCHAR(500)
AS 
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #DatosImportadosTXT(
        Nombre_Consorcio VARCHAR(100),
        nroUnidadFuncional VARCHAR(10),
        Piso VARCHAR(10),
        departamento VARCHAR(10),
        coeficiente VARCHAR(10), 
        m2_unidad_funcional DECIMAL(10,2), 
        bauleras VARCHAR(10),
        cochera VARCHAR(10),
        m2_baulera DECIMAL(10,2), 
        m2_cochera DECIMAL(10,2)  
    );
    --
    DECLARE @ComandoSQL NVARCHAR(MAX);

    SET @ComandoSQL = 
        'BULK INSERT #DatosImportadosTXT
        FROM ''' + @RutaArchivoNovedades + '''
        WITH (
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2
        )';

    --
    EXEC sp_executesql @ComandoSQL;
    --
    WITH FuenteCalculada AS (
       SELECT
          TRIM(Nombre_Consorcio) AS Nombre_Consorcio,
          -- CONVERSIÓN CON REEMPLAZO DE COMA A PUNTO
          SUM(ISNULL(m2_unidad_funcional, 0) + 
              ISNULL(m2_baulera, 0) + 
              ISNULL(m2_cochera, 0)
            ) AS Superficie_Total_Calculada,
            DENSE_RANK() OVER (ORDER BY T.Nombre_Consorcio) + 100 AS ID_Consorcio_Calculado,
        CASE TRIM(Nombre_Consorcio)
               WHEN 'Azcuenaga' THEN 1
               WHEN 'Alzaga' THEN 1
               WHEN 'Alberdi' THEN 2
               WHEN 'Unzue' THEN 3
               WHEN 'Pereyra Iraola' THEN 3
               ELSE 1 
            END AS ID_Administracion_Asignado,
            -- ASIGNACIÓN DE DIRECCIÓN (Dato Inventado para cumplir NOT NULL)
            TRIM(T.Nombre_Consorcio) + ' St. 123' AS Direccion_Inventada
        FROM 
            #DatosImportadosTXT AS T
        WHERE
            NULLIF(TRIM(Nombre_Consorcio), '') IS NOT NULL
        GROUP BY 
            T.Nombre_Consorcio 
       )
    MERGE dbo.Consorcio AS Destino
    USING FuenteCalculada as Fuente
    ON (
        Destino.Nombre = Fuente.Nombre_Consorcio
    )
    --
    WHEN MATCHED THEN
        UPDATE SET
            Destino.ID_Administracion = Fuente.ID_Administracion_Asignado,
            Destino.Nombre = Fuente.Nombre_Consorcio,
            Destino.Direccion = Fuente.Direccion_Inventada,
            Destino.Superficie= Fuente.Superficie_Total_Calculada
    --
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ID_Consorcio, ID_Administracion, Nombre, Direccion, Superficie)
        VALUES (
            Fuente.ID_Consorcio_Calculado,
            Fuente.ID_Administracion_Asignado,
            Fuente.Nombre_Consorcio,
            Fuente.Direccion_Inventada,
            Fuente.Superficie_Total_Calculada
        );
    --

    IF OBJECT_ID('tempdb..#DatosImportadosTXT') IS NOT NULL
    DROP TABLE #DatosImportadosTXT;
END
GO
--
DECLARE @Ruta VARCHAR(500) = 'C:\consorcios\UF por consorcio.txt'
EXEC ImportarDatosConsorcio @RutaArchivoNovedades = @Ruta
--
GO


/*GASTO*/
IF OBJECT_ID('dbo.sp_ImportarDatosGasto', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ImportarDatosGasto;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ImportarDatosGasto
    @RutaArchivoJSON VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #JsonTemp (JsonData NVARCHAR(MAX));
    DECLARE @ComandoSQL NVARCHAR(MAX);
    DECLARE @JsonData NVARCHAR(MAX);
    
    SET @ComandoSQL = 
        N'INSERT INTO #JsonTemp (JsonData)
          SELECT BulkColumn FROM OPENROWSET (BULK N''' + @RutaArchivoJSON + N''', SINGLE_CLOB) AS JsonFile;';
    
    EXEC sp_executesql @ComandoSQL;
    SELECT @JsonData = JsonData FROM #JsonTemp;

    WITH DatosOrigen AS (
        SELECT
            T.[Nombre del consorcio] AS NombreConsorcio,
            T.Mes,
            T.BANCARIOS AS BANCARIOS,
            T.LIMPIEZA AS LIMPIEZA,
            T.ADMINISTRACION AS ADMINISTRACION,
            T.SEGUROS AS SEGUROS,
            T.[GASTOS GENERALES] AS GASTOS_GENERALES,
            T.[SERVICIOS PUBLICOS-Agua] AS AGUA,
            T.[SERVICIOS PUBLICOS-Luz] AS LUZ
        FROM OPENJSON(@JsonData)
            WITH (
                [Nombre del consorcio] NVARCHAR(100), 
                Mes NVARCHAR(20), 
                BANCARIOS NVARCHAR(20),
                LIMPIEZA NVARCHAR(20), 
                ADMINISTRACION NVARCHAR(20), 
                SEGUROS NVARCHAR(20),
                [GASTOS GENERALES] NVARCHAR(20), 
                [SERVICIOS PUBLICOS-Agua] NVARCHAR(20), 
                [SERVICIOS PUBLICOS-Luz] NVARCHAR(20)
            ) AS T
    )
    , RubrosDespivotados AS (
        SELECT
            D.NombreConsorcio,
            -- Obtener el número de mes del gasto (Mes Anterior)
            CASE 
                 WHEN TRIM(D.Mes) = 'abril' THEN 4
                 WHEN TRIM(D.Mes) = 'mayo' THEN 5
                 WHEN TRIM(D.Mes) = 'junio' THEN 6
                 ELSE NULL END AS Mes_Gasto_Anterior,
            
            -- Despivotar los rubros y convertirlos a DECIMAL
            V.Tipo_Gasto,
            V.Monto_Texto AS Monto_Original,
            
            CASE 
                WHEN LEN(V.Monto_Texto) >= 2 THEN
                    TRY_CAST(
                        STUFF(
                            REPLACE(REPLACE(V.Monto_Texto, '.', ''), ',', ''), 
                            LEN(REPLACE(REPLACE(V.Monto_Texto, '.', ''), ',', '')) - 1, 
                            0, 
                            '.'
                        ) AS DECIMAL(12,2)
                    )
                ELSE 0
            END AS Monto_Final
			FROM DatosOrigen AS D

        CROSS APPLY (VALUES 
            ('BANCARIOS', D.BANCARIOS),
            ('LIMPIEZA', D.LIMPIEZA),
            ('ADMINISTRACION', D.ADMINISTRACION),
            ('SEGUROS', D.SEGUROS),
            ('GASTOS GENERALES', D.GASTOS_GENERALES),
            ('SERVICIOS PUBLICOS-Agua', D.AGUA),
            ('SERVICIOS PUBLICOS-Luz', D.LUZ)
        ) AS V(Tipo_Gasto, Monto_Texto)
        
        WHERE TRY_CAST(
                STUFF(
                    REPLACE(REPLACE(V.Monto_Texto, '.', ''), ',', ''), 
                    LEN(REPLACE(REPLACE(V.Monto_Texto, '.', ''), ',', '')) - 1, 
                    0, 
                    '.'
                ) AS DECIMAL(12,2)
            ) IS NOT NULL 
    )
    , FuenteFinal AS (
        SELECT
            R.Tipo_Gasto,
            R.Monto_Final,
            R.Monto_Original,
            E.Fecha_Generada AS Fecha_Generacion_Gasto,

            E.ID_Expensa

       FROM RubrosDespivotados AS R
        INNER JOIN dbo.Consorcio AS C 
            ON C.Nombre = TRIM(R.NombreConsorcio)
        INNER JOIN dbo.Expensa AS E 
            ON E.ID_Consorcio = C.ID_Consorcio 

            AND MONTH(E.Fecha_Generada) = R.Mes_Gasto_Anterior + 1
            AND YEAR(E.Fecha_Generada) = 2025
    )
    
    MERGE dbo.Gasto AS Destino
    USING (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY ID_Expensa, Tipo_Gasto) + ISNULL((SELECT MAX(ID_Gasto) FROM dbo.Gasto), 0) AS ID_Gasto,
            *
        FROM FuenteFinal
    ) AS Fuente
    ON (
        Destino.ID_Expensa = Fuente.ID_Expensa AND Destino.Tipo_Gasto = Fuente.Tipo_Gasto
    )
    
    WHEN MATCHED THEN
        UPDATE SET
            Destino.Monto = Fuente.Monto_Final,
            Destino.Fecha = Fuente.Fecha_Generacion_Gasto
    
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ID_Gasto, ID_Expensa, Tipo_Gasto, Fecha, Monto, Detalle)
        VALUES (
            Fuente.ID_Gasto,
            Fuente.ID_Expensa,
            Fuente.Tipo_Gasto,
            Fuente.Fecha_Generacion_Gasto,
            Fuente.Monto_Final,
            'Gasto correspondiente al rubro ' + Fuente.Tipo_Gasto + ' - Valor original: ' + Fuente.Monto_Original
        );
    
    IF OBJECT_ID('tempdb..#JsonTemp') IS NOT NULL DROP TABLE #JsonTemp;
    
END
GO

DECLARE @Ruta VARCHAR(500) = 'C:\consorcios\Servicios.Servicios.json'
EXEC dbo.sp_ImportarDatosGasto @RutaArchivoJSON = @Ruta
