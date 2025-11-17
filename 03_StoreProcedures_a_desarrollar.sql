/*ACA PODREMOS DESARROLLAR LOS SP Y POSTERIORMENTE DIVIDIRLOS EN QUERYS Y/O IOR VOLCANDO LOS QUE YA SIRVEN EN ESTE ARCHIVO*/
USE COM5600G10

/*IMPORTACION A LA TABLA PERSONA*/
IF OBJECT_ID('dbo.ImportarInquilinos_Propietarios', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarInquilinos_Propietarios;
GO
CREATE PROCEDURE ImportarInquilinos_Propietarios
	@RutaArchivoNovedades VARCHAR(500)
AS BEGIN
    CREATE TABLE #DatosImportadosCSV(
        Nombre VARCHAR(100),
        Apellido VARCHAR(100),
        Documento VARCHAR(100),
        Email_Personal VARCHAR(100),
        Telefono VARCHAR(50),           -- Ahora VARCHAR
        CBU_CVU_Pago VARCHAR(50),
        Inquilino_Flag VARCHAR(10)
    );

    --
    DECLARE @ComandoSQL NVARCHAR(MAX);
    SET @ComandoSQL = 
        'BULK INSERT #DatosImportadosCSV
        FROM ''' + @RutaArchivoNovedades + '''
        WITH (
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2
        )';
    --
    EXEC sp_executesql @ComandoSQL;
    --

    WITH FuenteCSV AS (
        SELECT
            'DNI' AS Tipo_Documento,
            TRY_CAST((TRIM(DatoImportado.Documento)) AS INT) AS Numero_Documento,
            TRIM(DatoImportado.Nombre) AS Nombre, -- Limpieza de espacios
            TRIM(DatoImportado.Apellido) AS Apellido, -- Limpieza de espacios
            TRIM(DatoImportado.Email_Personal) AS Correo_Electronico, -- Limpieza de espacios
            TRY_CAST((TRIM(DatoImportado.Telefono)) AS INT) AS Telefono,
            TRIM(DatoImportado.CBU_CVU_Pago) AS CBU_CVU,
            ROW_NUMBER() OVER (PARTITION BY DatoImportado.Documento ORDER BY DatoImportado.Documento) AS RN -- Para importar unidades_funcionales
        FROM 
            #DatosImportadosCSV AS DatoImportado
        WHERE
            NULLIF(TRIM(DatoImportado.Documento),'') IS NOT NULL 
            AND NULLIF(TRIM(DatoImportado.Nombre), '') IS NOT NULL
            AND NULLIF(TRIM(DatoImportado.Apellido), '') IS NOT NULL
            AND NULLIF(TRIM(DatoImportado.Email_Personal), '') IS NOT NULL
            AND NULLIF(TRIM(DatoImportado.Telefono), '') IS NOT NULL
            AND NULLIF(TRIM(DatoImportado.CBU_CVU_Pago), '') IS NOT NULL
    )
    MERGE dbo.Persona AS Transformado
    USING (
        SELECT 
            Tipo_Documento, 
            Numero_Documento, 
            Nombre, 
            Apellido, 
            Correo_Electronico, 
            Telefono,
            CBU_CVU
        FROM 
            FuenteCSV
        WHERE 
            RN = 1
    ) AS Fuente
    ON (
        Transformado.Numero_documento = Fuente.Numero_Documento AND Transformado.Tipo_documento = Fuente.Tipo_Documento
    )
    --
    WHEN MATCHED THEN
        UPDATE SET
            Transformado.Nombre = Fuente.Nombre,
            Transformado.Apellido = Fuente.Apellido,
            Transformado.Correo_Electronico = Fuente.Correo_Electronico,
            Transformado.Telefono = Fuente.Telefono,
            Transformado.CBU_CVU = Fuente.CBU_CVU
    --
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (Tipo_documento, Numero_documento, Nombre, Apellido, Correo_Electronico, Telefono, CBU_CVU)
        VALUES (
            Fuente.Tipo_Documento,
            Fuente.Numero_Documento,
            Fuente.Nombre,
            Fuente.Apellido,
            Fuente.Correo_Electronico,
            Fuente.Telefono,
            Fuente.CBU_CVU
        );
    --
    IF OBJECT_ID('tempdb..#DatosImportadosCSV') IS NOT NULL
    DROP TABLE #DatosImportadosCSV;
END
GO
/*IMPOTARCION A LA TABLA ADMINISTRACIÓN*/
IF OBJECT_ID('dbo.ImportarDatosAdministracion', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarDatosAdministracion;
GO

CREATE OR ALTER PROCEDURE ImportarDatosAdministracion
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

	
/*IMPORTACION A LA TABLA CONSORCIO*/
IF OBJECT_ID('dbo.ImportarDatosConsorcio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarDatosConsorcio;
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


/*IMPORTACION A LA TABLA UNIDAD_FUNCIONAL*/
IF OBJECT_ID('dbo.Importar_Unidades_Funcionales', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Importar_Unidades_Funcionales;
GO

CREATE PROCEDURE Importar_Unidades_Funcionales
    @RutaArchivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #DatosImportadosTXT(
        Nombre_Consorcio VARCHAR(100),
        nroUnidadFuncional INT,
        Piso VARCHAR(10),
        Departamento VARCHAR(10),
        Coeficiente VARCHAR(10),
        m2_unidad_funcional DECIMAL(10,2),
        Bauleras VARCHAR(10),
        Cochera VARCHAR(10),
        m2_baulera DECIMAL(10,2),
        m2_cochera DECIMAL(10,2)
    );

    DECLARE @ComandoSQL NVARCHAR(MAX);
    SET @ComandoSQL = 
        'BULK INSERT #DatosImportadosTXT
         FROM ''' + @RutaArchivo + '''
         WITH (
             FIELDTERMINATOR = ''\t'',
             ROWTERMINATOR = ''\n'',
             FIRSTROW = 2
         )';
    EXEC sp_executesql @ComandoSQL;

    ;WITH DatosLimpios AS (
        SELECT
            U.Nombre_Consorcio,
            U.nroUnidadFuncional,
            C.ID_Consorcio,
            U.Piso,
            U.Departamento,
            CAST(REPLACE(U.Coeficiente, ',', '.') AS DECIMAL(10,2)) AS Porcentaje_Prorrateo,
            CAST(ISNULL(U.m2_unidad_funcional, 0) + ISNULL(U.m2_baulera, 0) + ISNULL(U.m2_cochera, 0) AS DECIMAL(10,2)) AS Superficie_m2,
            CASE WHEN U.Cochera = 'SI' THEN 'SI' ELSE 'NO' END AS Tiene_Cochera,
            CASE WHEN U.Bauleras = 'SI' THEN 'SI' ELSE 'NO' END AS Tiene_Bahulera
        FROM #DatosImportadosTXT AS U
        INNER JOIN dbo.Consorcio AS C
            ON C.Nombre = TRIM(U.Nombre_Consorcio)
        WHERE
            NULLIF(TRIM(U.Nombre_Consorcio), '') IS NOT NULL
            AND U.nroUnidadFuncional IS NOT NULL
            AND NULLIF(TRIM(U.Piso), '') IS NOT NULL
            AND NULLIF(TRIM(U.Departamento), '') IS NOT NULL
            AND NULLIF(U.Coeficiente, '') IS NOT NULL
    )

    INSERT INTO dbo.Unidad_Funcional (
        ID_Consorcio,
        nroUnidadFuncional,
        Piso,
        Departamento,
        Superficie_m2,
        Porcentaje_Prorrateo,
        Tiene_Cochera,
        Tiene_Bahulera
    )
    SELECT
        ID_Consorcio,
        nroUnidadFuncional,
        Piso,
        Departamento,
        Superficie_m2,
        Porcentaje_Prorrateo,
        Tiene_Cochera,
        Tiene_Bahulera
    FROM DatosLimpios;

    DROP TABLE #DatosImportadosTXT;
END;
GO

	
/*IMPORTACION A LA TABLA RELACION_UF_PERSONA*/
IF OBJECT_ID('dbo.ImportarRelacionUFPersonas', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarRelacionUFPersonas;
GO

CREATE PROCEDURE ImportarRelacionUFPersonas
    @RutaArchivoPersonas VARCHAR(500),
    @RutaArchivoRelacion VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabla temporal para personas
    CREATE TABLE #DatosPersonasCSV(
        Nombre VARCHAR(100),
        Apellido VARCHAR(100),
        Documento VARCHAR(100),
        Email_Personal VARCHAR(100),
        Telefono VARCHAR(50),
        CBU_CVU VARCHAR(50),
        Flag_Inquilino VARCHAR(10)
    );

    -- Tabla temporal para relaciones UF
    CREATE TABLE #DatosRelacionCSV(
        CBU_CVU VARCHAR(50),
        Nombre_Consorcio VARCHAR(100),
        NroUnidadFuncional INT,
        Piso VARCHAR(10),
        Departamento VARCHAR(10)
    );

    -- Bulk insert personas
    DECLARE @ComandoSQL NVARCHAR(MAX);
    SET @ComandoSQL = 
        'BULK INSERT #DatosPersonasCSV
         FROM ''' + @RutaArchivoPersonas + '''
         WITH (
             FIELDTERMINATOR = '';'',
             ROWTERMINATOR = ''\n'',
             FIRSTROW = 2
         )';
    EXEC sp_executesql @ComandoSQL;

    -- Bulk insert relaciones
    SET @ComandoSQL = 
        'BULK INSERT #DatosRelacionCSV
         FROM ''' + @RutaArchivoRelacion + '''
         WITH (
             FIELDTERMINATOR = ''|'',
             ROWTERMINATOR = ''\n'',
             FIRSTROW = 2
         )';
    EXEC sp_executesql @ComandoSQL;

    -- Preparar datos finales para insertar
    ;WITH FuenteRelacion AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY P.CBU_CVU) AS ID_Relacion,
            UF.ID_UF,
			PE.ID_Persona,
            P.CBU_CVU AS CBU_CVU,
            CASE 
                WHEN TRIM(P.Flag_Inquilino) = '0' THEN 'PROPIETARIO'
                WHEN TRIM(P.Flag_Inquilino) = '1' THEN 'INQUILINO'
            END AS Rol,
            CAST(GETDATE() AS DATE) AS Fecha_Inicio,
            CAST(DATEADD(DAY, 30, GETDATE()) AS DATE) AS Fecha_Fin
        FROM #DatosRelacionCSV AS R
        INNER JOIN dbo.Unidad_Funcional AS UF
            ON UF.NroUnidadFuncional = R.NroUnidadFuncional
        INNER JOIN #DatosPersonasCSV AS P
            ON P.CBU_CVU = R.CBU_CVU
		INNER JOIN dbo.Persona AS PE
			ON PE.CBU_CVU = P.CBU_CVU
        WHERE
            NULLIF(R.CBU_CVU,'') IS NOT NULL
            AND NULLIF(P.CBU_CVU,'') IS NOT NULL
            AND NULLIF(P.Flag_Inquilino,'') IS NOT NULL
    )

    INSERT INTO dbo.Relacion_UF_Persona
        (ID_Relacion,ID_UF, ID_Persona, Fecha_Inicio, Fecha_Fin, Rol, CBU_CVU_Pago)
    SELECT
        ID_Relacion, ID_UF, ID_Persona, Fecha_Inicio, Fecha_Fin, Rol, CBU_CVU
    FROM FuenteRelacion;

    -- Limpieza
    IF OBJECT_ID('tempdb..#DatosPersonasCSV') IS NOT NULL
        DROP TABLE #DatosPersonasCSV;

    IF OBJECT_ID('tempdb..#DatosRelacionCSV') IS NOT NULL
        DROP TABLE #DatosRelacionCSV;
END
GO

	
/*IMPORTACION A LA TABLA EXPENSA*/
IF OBJECT_ID('dbo.FN_ObtenerNthDiaHabil', 'FN') IS NOT NULL
    DROP FUNCTION dbo.FN_ObtenerNthDiaHabil;
GO

CREATE FUNCTION dbo.FN_ObtenerNthDiaHabil (
    @Anio INT, 
    @Mes INT, 
    @N INT 
)
RETURNS DATE
AS
BEGIN
    DECLARE @Dia INT = 1;
    DECLARE @DiasHabilesEncontrados INT = 0;
    DECLARE @Fecha DATE;

    WHILE @Dia <= 31 AND @DiasHabilesEncontrados < @N
    BEGIN
        SET @Fecha = TRY_CAST(CONCAT(@Anio, '-', @Mes, '-', @Dia) AS DATE);
        IF @Fecha IS NULL OR MONTH(@Fecha) <> @Mes
            BREAK;

        IF DATENAME(WEEKDAY, @Fecha) NOT IN ('Saturday', 'Sunday', 'Sábado', 'Domingo')
        BEGIN
            SET @DiasHabilesEncontrados = @DiasHabilesEncontrados + 1;
        END

        IF @DiasHabilesEncontrados = @N
            RETURN @Fecha;

        SET @Dia = @Dia + 1;
    END
    RETURN NULL;
END
GO
IF OBJECT_ID('dbo.ImportarDatosExpensal', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ImportarDatosExpensa;
GO
CREATE OR ALTER PROCEDURE dbo.ImportarDatosExpensa
    @RutaArchivoJSON VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #JsonTemp (JsonData NVARCHAR(MAX));

    DECLARE @ComandoSQL NVARCHAR(MAX);
    SET @ComandoSQL = 
        N'INSERT INTO #JsonTemp (JsonData)
          SELECT BulkColumn FROM OPENROWSET (BULK N''' + @RutaArchivoJSON + N''', SINGLE_CLOB) AS JsonFile;';
    EXEC sp_executesql @ComandoSQL;

    DECLARE @JsonData NVARCHAR(MAX);
    SELECT @JsonData = JsonData FROM #JsonTemp;

    WITH FuenteJSON AS (
        SELECT
            T.[Nombre del consorcio],
            LTRIM(RTRIM(T.Mes)) AS Mes,
            REPLACE(REPLACE(T.BANCARIOS, '.', ''), ',', '.') AS BANCARIOS_CL,
            REPLACE(REPLACE(T.LIMPIEZA, '.', ''), ',', '.') AS LIMPIEZA_CL,
            REPLACE(REPLACE(T.ADMINISTRACION, '.', ''), ',', '.') AS ADMINISTRACION_CL,
            REPLACE(REPLACE(T.SEGUROS, '.', ''), ',', '.') AS SEGUROS_CL,
            REPLACE(REPLACE(T.[GASTOS GENERALES], '.', ''), ',', '.') AS GASTOS_GENERALES_CL,
            REPLACE(REPLACE(T.[SERVICIOS PUBLICOS-Agua], '.', ''), ',', '.') AS AGUA_CL,
            REPLACE(REPLACE(T.[SERVICIOS PUBLICOS-Luz], '.', ''), ',', '.') AS LUZ_CL
        FROM OPENJSON(@JsonData)
        WITH (
            [Nombre del consorcio] NVARCHAR(100) '$."Nombre del consorcio"',
            Mes NVARCHAR(20),
            BANCARIOS NVARCHAR(20),
            LIMPIEZA NVARCHAR(20),
            ADMINISTRACION NVARCHAR(20),
            SEGUROS NVARCHAR(20),
            [GASTOS GENERALES] NVARCHAR(20),
            [SERVICIOS PUBLICOS-Agua] NVARCHAR(20),
            [SERVICIOS PUBLICOS-Luz] NVARCHAR(20)
        ) AS T
        WHERE T.[Nombre del consorcio] IS NOT NULL
    )
    , DatosBase AS (
        SELECT
            C.ID_Consorcio,
            CASE WHEN TRIM(F.Mes) LIKE 'abril%' THEN 4
                 WHEN TRIM(F.Mes) LIKE 'mayo%' THEN 5
                 WHEN TRIM(F.Mes) LIKE 'junio%' THEN 6
                 ELSE NULL END AS Mes_Gasto_Anterior,

            -- Expensas Ordinarias
            ISNULL(TRY_CAST(REPLACE(REPLACE(F.BANCARIOS_CL, '.', ''), ',', '.') AS DECIMAL(18,2)),0) +
            ISNULL(TRY_CAST(REPLACE(REPLACE(F.LIMPIEZA_CL, '.', ''), ',', '.') AS DECIMAL(18,2)),0) +
            ISNULL(TRY_CAST(REPLACE(REPLACE(F.ADMINISTRACION_CL, '.', ''), ',', '.') AS DECIMAL(18,2)),0) +
            ISNULL(TRY_CAST(REPLACE(REPLACE(F.SEGUROS_CL, '.', ''), ',', '.') AS DECIMAL(18,2)),0) +
            ISNULL(TRY_CAST(REPLACE(REPLACE(F.AGUA_CL, '.', ''), ',', '.') AS DECIMAL(18,2)),0) +
            ISNULL(TRY_CAST(REPLACE(REPLACE(F.LUZ_CL, '.', ''), ',', '.') AS DECIMAL(18,2)),0) 
            AS Expensas_Ord_Calculadas,

            -- Expensas Extraordinarias
            ISNULL(TRY_CAST(REPLACE(REPLACE(F.GASTOS_GENERALES_CL, '.', ''), ',', '.') AS DECIMAL(18,2)),0) 
            AS Expensas_Extraord_Calculadas
        FROM FuenteJSON AS F
        INNER JOIN dbo.Consorcio AS C ON C.Nombre = TRIM(F.[Nombre del consorcio])
    )
    , FechasCalculadas AS (
        SELECT
            D.*,
            dbo.FN_ObtenerNthDiaHabil(2025, D.Mes_Gasto_Anterior + 1, 5) AS Fecha_Generada_Base
        FROM DatosBase AS D
        WHERE D.Mes_Gasto_Anterior IS NOT NULL
    )
    MERGE dbo.Expensa AS Destino
    USING (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY ID_Consorcio, Fecha_Generada_Base) + ISNULL((SELECT MAX(ID_Expensa) FROM dbo.Expensa), 0) AS ID_Expensa,
            ID_Consorcio,
            Fecha_Generada_Base AS Fecha_Generada,
            DATEADD(DAY, 10, Fecha_Generada_Base) AS Fecha_Venc1,
            DATEADD(DAY, 20, Fecha_Generada_Base) AS Fecha_Venc2,
            Expensas_Ord_Calculadas,
            Expensas_Extraord_Calculadas,
            'CERRADA' AS Estado
        FROM FechasCalculadas
        WHERE Fecha_Generada_Base IS NOT NULL
    ) AS Fuente
    ON (Destino.ID_Consorcio = Fuente.ID_Consorcio AND Destino.Fecha_Generada = Fuente.Fecha_Generada)
    WHEN MATCHED THEN
        UPDATE SET 
            Destino.Fecha_Venc1 = Fuente.Fecha_Venc1,
            Destino.Fecha_Venc2 = Fuente.Fecha_Venc2,
            Destino.Expensas_Ord = Fuente.Expensas_Ord_Calculadas,
            Destino.Expensas_Extraord = Fuente.Expensas_Extraord_Calculadas,
            Destino.Estado = Fuente.Estado
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ID_Expensa, ID_Consorcio, Fecha_Generada, Fecha_Venc1, Fecha_Venc2, Expensas_Ord, Expensas_Extraord, Estado)
        VALUES (Fuente.ID_Expensa, Fuente.ID_Consorcio, Fuente.Fecha_Generada, Fuente.Fecha_Venc1, Fuente.Fecha_Venc2, Fuente.Expensas_Ord_Calculadas, Fuente.Expensas_Extraord_Calculadas, Fuente.Estado);

    IF OBJECT_ID('tempdb..#JsonTemp') IS NOT NULL DROP TABLE #JsonTemp;
END
GO
	
/*IMPORTACION A LA TABLA DETALLE_EXPENSA*/
CREATE OR ALTER PROCEDURE dbo.GenerarDetalleExpensaPorProrrateo
AS
BEGIN
    DECLARE @MaxID_Detalle INT;
    SELECT @MaxID_Detalle = ISNULL(MAX(ID_Detalle),0) FROM Detalle_Expensa;
    --
    WITH ExpensasNoLiquidadas AS (
        SELECT  
            ID_Expensa,
            ID_Consorcio,
            Expensas_Ord,
            Expensas_Extraord
        FROM    
            dbo.Expensa
    ),
    DetallesExpensasInsertar AS (
        SELECT
            ENL.ID_Expensa,
            U_Fun.ID_UF,
            ENL.Expensas_Ord,
            ENL.Expensas_Extraord,
            U_Fun.Porcentaje_Prorrateo
        FROM 
            ExpensasNoLiquidadas AS ENL
            INNER JOIN dbo.Unidad_Funcional AS U_Fun 
                ON ENL.ID_Consorcio = U_Fun.ID_Consorcio
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Detalle_Expensa AS D_Exp
            WHERE D_Exp.ID_Expensa = ENL.ID_Expensa AND D_Exp.ID_UF = U_Fun.ID_UF
        )
    )
   --
    INSERT INTO dbo.Detalle_Expensa(
        ID_Detalle,
        ID_Expensa,
        ID_UF,
        Pagos_Recibidos,
        Deuda,
        Interes_Mora,
        Detalle_Ordinarias,
        Detalle_Extraord,
        Total
    )
    SELECT
        @MaxID_Detalle + ROW_NUMBER() OVER (ORDER BY D_E_Insrt.ID_Expensa, D_E_Insrt.ID_UF) AS ID_Detalle,
        D_E_Insrt.ID_Expensa,
        D_E_Insrt.ID_UF,
        0.00 AS Pagos_Recibidos,
        ROUND( (D_E_Insrt.Expensas_Ord + D_E_Insrt.Expensas_Extraord) * D_E_Insrt.Porcentaje_Prorrateo / 100, 2) AS Deuda,
        0.00 AS Interes_Mora,
        ROUND(D_E_Insrt.Expensas_Ord * D_E_Insrt.Porcentaje_Prorrateo / 100, 2) AS Detalle_Ordinarias,
        ROUND(D_E_Insrt.Expensas_Extraord * D_E_Insrt.Porcentaje_Prorrateo / 100, 2) AS Detalle_Extraord,
        ROUND( (D_E_Insrt.Expensas_Ord + D_E_Insrt.Expensas_Extraord) * D_E_Insrt.Porcentaje_Prorrateo / 100, 2) AS Total
    FROM DetallesExpensasInsertar AS D_E_Insrt
END
GO

		
/*IMPORTACION A LA TABLA GASTO*/
IF OBJECT_ID('dbo.ImportarDatosGasto', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarDatosGasto;
GO

CREATE OR ALTER PROCEDURE dbo.ImportarDatosGasto
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
        -- DESPIVOT: Convierte las columnas (Bancarios, Limpieza, etc.) en filas
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
            -- Unir con Expensa para obtener la FK
            E.ID_Expensa

       FROM RubrosDespivotados AS R
        INNER JOIN dbo.Consorcio AS C 
            ON C.Nombre = TRIM(R.NombreConsorcio)
        INNER JOIN dbo.Expensa AS E 
            ON E.ID_Consorcio = C.ID_Consorcio 
            -- Unir por consorcio y mes (sin calcular fechas)
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

/*IMPORTACION A LA TABLA PAGOS*/
CREATE OR ALTER PROCEDURE ImportarPagosConsorcio
    @RutaArchivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    --
    IF OBJECT_ID('tempdb..#PagosCSV') IS NOT NULL DROP TABLE #PagosCSV;
    --
    CREATE TABLE #PagosCSV (
        ID_Pago_CSV VARCHAR(20),
        Fecha_Pago VARCHAR(20),
        CBU_CVU_Pago VARCHAR(30),
        Valor VARCHAR(30)
    );
    --
    DECLARE @ComandoSQL NVARCHAR(MAX);
    SET @ComandoSQL = 
        'BULK INSERT #PagosCSV
         FROM ''' + @RutaArchivo + '''
         WITH (
              FIELDTERMINATOR = '','',
              ROWTERMINATOR = ''\n'',
              FIRSTROW = 2
         )';
    --
    EXEC sp_executesql @ComandoSQL;
    --
    WITH PagosLimpios AS(
        SELECT
            ID_Pago_CSV,
            TRY_CONVERT(DATE, Fecha_Pago, 103) AS Fecha_Pago, 
            TRIM(CBU_CVU_Pago) AS CBU_CVU_Pago,
            TRY_CONVERT(DECIMAL(12,2), REPLACE(REPLACE(Valor, '$', ''), '.', '')) / 100 AS Valor,
            CASE 
                WHEN ABS(CHECKSUM(NEWID())) % 100 < 30 THEN 'CONFIRMADO'
                ELSE 'PENDIENTE'
            END AS Estado
        FROM 
            #PagosCSV
        WHERE 
            TRY_CONVERT(DATE, Fecha_Pago, 103) IS NOT NULL
            AND TRY_CONVERT(DECIMAL(12,2), REPLACE(REPLACE(Valor, '$', ''), '.', '')) IS NOT NULL
    ),
    PagosRankeados AS (
        SELECT
            P.ID_Pago_CSV AS ID_Pago,
            D.ID_Detalle,
            P.Fecha_Pago,
            P.CBU_CVU_Pago,
            P.Valor,
            P.Estado,
            ROW_NUMBER() OVER (
                PARTITION BY P.ID_Pago_CSV 
                ORDER BY D.ID_Detalle DESC 
            ) AS FilaUnica
        FROM PagosLimpios P
        INNER JOIN dbo.Relacion_UF_Persona R 
            ON R.CBU_CVU_Pago = P.CBU_CVU_Pago
        INNER JOIN dbo.Detalle_Expensa D    
            ON D.ID_UF = R.ID_UF
    )
    --
    MERGE INTO dbo.Pago AS T
    USING (
        SELECT
            ID_Pago,
            ID_Detalle,
            Fecha_Pago,
            CBU_CVU_Pago,
            Valor,
            Estado
        FROM PagosRankeados
        WHERE FilaUnica = 1
    ) AS S
    --
    ON T.ID_Pago = S.ID_Pago
    --
    WHEN MATCHED THEN
        UPDATE SET 
            T.Fecha_Pago = S.Fecha_Pago,
            T.Cuenta_Origen = S.CBU_CVU_Pago,
            T.DatoImportado = S.Valor,
            T.Estado = S.Estado 
            
    WHEN NOT MATCHED THEN
        INSERT (ID_Pago, ID_Detalle, Fecha_Pago, Cuenta_Origen, DatoImportado, Estado, Tipo_Pago)
        VALUES (S.ID_Pago, S.ID_Detalle, S.Fecha_Pago, S.CBU_CVU_Pago, S.Valor, S.Estado, 'ORDINARIO');
END;
GO
DECLARE @RutaPersonas VARCHAR(500) = '${RutaPersonas}';
DECLARE @RutaConsorcios VARCHAR(500) = '${RutaPersonas}';
DECLARE @RutaRelacion VARCHAR(500) = '${RutaPersonas}';
DECLARE @RutaJSON VARCHAR(500) = '${RutaPersonas}';
DECLARE @RutaPagos VARCHAR(500) = '${RutaPersonas}';


-- 1. Importar Administración
EXEC ImportarDatosAdministracion;
-- 2. Importar Personas
EXEC ImportarInquilinos_Propietarios @RutaArchivoNovedades = @RutaPersonas;
-- 3. Importar Consorcios y UF
EXEC ImportarDatosConsorcio @RutaArchivoNovedades = @RutaConsorcios;
EXEC Importar_Unidades_Funcionales @RutaArchivo = @RutaConsorcios;
-- 4. Importar Relaciones
EXEC ImportarRelacionUFPersonas 
    @RutaArchivoPersonas = @RutaPersonas,
    @RutaArchivoRelacion = @RutaRelacion;
-- 5. Importar Expensas y Gastos
EXEC dbo.ImportarDatosExpensa @RutaArchivoJSON = @RutaJSON;
EXEC dbo.ImportarDatosGasto @RutaArchivoJSON = @RutaJSON;

-- 6. Generar detalles de expensas
EXEC GenerarDetalleExpensaPorProrrateo;

-- 7. Importar Pagos
EXEC ImportarPagosConsorcio @RutaArchivo = @RutaPagos;