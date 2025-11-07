/*ACA PODREMOS DESARROLLAR LOS SP Y POSTERIORMENTE DIVIDIRLOS EN QUERYS Y/O IOR VOLCANDO LOS QUE YA SIRVEN EN ESTE ARCHIVO*/
USE COM025600
/*IMPORTACION A LA TABLA PERSONA*/
CREATE OR ALTER PROCEDURE ImportarInquilinos_Propietarios
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
            1 AS Tipo_Documento,
            TRY_CAST((TRIM(DatoImportado.Documento)) AS INT) AS Numero_Documento,
            TRIM(DatoImportado.Nombre) AS Nombre, -- Limpieza de espacios
            TRIM(DatoImportado.Apellido) AS Apellido, -- Limpieza de espacios
            TRIM(DatoImportado.Email_Personal) AS Correo_Electronico, -- Limpieza de espacios
            TRY_CAST((TRIM(DatoImportado.Telefono)) AS INT) AS Telefono,
            ROW_NUMBER() OVER (PARTITION BY DatoImportado.Documento ORDER BY DatoImportado.Documento) AS RN
        FROM 
            #DatosImportadosCSV AS DatoImportado
        WHERE
            NULLIF(TRIM(DatoImportado.Documento),'') IS NOT NULL 
            AND NULLIF(TRIM(DatoImportado.Nombre), '') IS NOT NULL
            AND NULLIF(TRIM(DatoImportado.Apellido), '') IS NOT NULL
            AND NULLIF(TRIM(DatoImportado.Email_Personal), '') IS NOT NULL
            AND NULLIF(TRIM(DatoImportado.Telefono), '') IS NOT NULL
    )
    MERGE dbo.Persona AS Transformado
    USING (
        SELECT 
            Tipo_Documento, 
            Numero_Documento, 
            Nombre, 
            Apellido, 
            Correo_Electronico, 
            Telefono
        FROM 
            FuenteCSV
        WHERE 
            RN = 1
    ) AS Fuente
    ON (
        Transformado.numero_documento = Fuente.Numero_Documento AND Transformado.tipo_documento = Fuente.Tipo_Documento
    )
    --
    WHEN MATCHED THEN
        UPDATE SET
            Transformado.nombre = Fuente.Nombre,
            Transformado.apellido = Fuente.Apellido,
            Transformado.correo_electronico = Fuente.Correo_Electronico,
            Transformado.Telefono = Fuente.Telefono
    --
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (tipo_documento, numero_documento, nombre, apellido, correo_electronico, Telefono)
        VALUES (
            Fuente.Tipo_Documento, -- Se inserta la constante 1
            Fuente.Numero_Documento,
            Fuente.Nombre,
            Fuente.Apellido,
            Fuente.Correo_Electronico,
            Fuente.Telefono
        );
    --
    IF OBJECT_ID('tempdb..#DatosImportadosCSV') IS NOT NULL
    DROP TABLE #DatosImportadosCSV;
END
GO
--
DECLARE @Ruta VARCHAR(500) = 'C:\temp\Inquilino-propietarios-datos.csv'
EXEC ImportarInquilinos_Propietarios @RutaArchivoNovedades = @Ruta
GO
--
SELECT * FROM dbo.Persona
GO
/*IMPOTARCION A LA TABLA ADMINISTRACIÓN*/
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
--
DECLARE @Ruta VARCHAR(500) = 'C:\consorcios\UF por consorcio.txt'
EXEC ImportarDatosConsorcio @RutaArchivoNovedades = @Ruta
--
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
        INNER JOIN Consorcio AS C
            ON C.Nombre = TRIM(U.Nombre_Consorcio)
        WHERE
            NULLIF(TRIM(U.Nombre_Consorcio), '') IS NOT NULL
            AND U.nroUnidadFuncional IS NOT NULL
            AND NULLIF(TRIM(U.Piso), '') IS NOT NULL
            AND NULLIF(TRIM(U.Departamento), '') IS NOT NULL
            AND NULLIF(U.Coeficiente, '') IS NOT NULL
    )

    INSERT INTO Unidad_Funcional (
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
            1 AS Tipo_Documento,                 -- constante
            TRY_CAST(P.Documento AS INT) AS Numero_documento,
            P.CBU_CVU AS CBU_CVU,
            CASE 
                WHEN TRIM(P.Flag_Inquilino) = '0' THEN 'PROPIETARIO'
                WHEN TRIM(P.Flag_Inquilino) = '1' THEN 'INQUILINO'
            END AS Rol,
            CAST(GETDATE() AS DATE) AS Fecha_Inicio,
            CAST(DATEADD(DAY, 30, GETDATE()) AS DATE) AS Fecha_Fin
        FROM #DatosRelacionCSV AS R
        INNER JOIN Unidad_Funcional AS UF
            ON UF.NroUnidadFuncional = R.NroUnidadFuncional
        INNER JOIN #DatosPersonasCSV AS P
            ON P.CBU_CVU = R.CBU_CVU
        WHERE
            NULLIF(R.CBU_CVU,'') IS NOT NULL
            AND NULLIF(P.CBU_CVU,'') IS NOT NULL
            AND NULLIF(P.Flag_Inquilino,'') IS NOT NULL
    )

    INSERT INTO Relacion_UF_Persona
        (ID_Relacion,ID_UF, Tipo_Documento, Num_Documento, Fecha_Inicio, Fecha_Fin, Rol, CBU_CVU_Pago)
    SELECT
        ID_Relacion, ID_UF, Tipo_Documento, Numero_documento, Fecha_Inicio, Fecha_Fin, Rol, CBU_CVU
    FROM FuenteRelacion;

    -- Limpieza
    IF OBJECT_ID('tempdb..#DatosPersonasCSV') IS NOT NULL
        DROP TABLE #DatosPersonasCSV;

    IF OBJECT_ID('tempdb..#DatosRelacionCSV') IS NOT NULL
        DROP TABLE #DatosRelacionCSV;
END
GO

-- Ejemplo de ejecución
DECLARE @RutaPersonas VARCHAR(500) = 'C:\temp\Inquilino-propietarios-datos.csv';
DECLARE @RutaRelacion VARCHAR(500) = 'C:\consorcios\Inquilino-propietarios-UF.csv';

EXEC ImportarRelacionUFPersonas 
    @RutaArchivoPersonas = @RutaPersonas,
    @RutaArchivoRelacion = @RutaRelacion;
select * from Relacion_UF_Persona
/*IMPORTACION A LA TABLA EXPENSA*/

/*IMPORTACION A LA TABLA DETALLE_EXPENSA*/
CREATE OR ALTER PROCEDURE dbo.sp_GenerarDetalleExpensaPorProrrateo
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
            Expensa
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
            INNER JOIN Unidad_Funcional AS U_Fun 
                ON ENL.ID_Consorcio = U_Fun.ID_Consorcio
        WHERE NOT EXISTS (
            SELECT 1 FROM Detalle_Expensa AS D_Exp
            WHERE D_Exp.ID_Expensa = ENL.ID_Expensa AND D_Exp.ID_UF = U_Fun.ID_UF
        )
    )
   --
    INSERT INTO Detalle_Expensa(
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

/*IMPORTACION A LA TABLA PAGO*/

/*IMPORTACION A LA TABLA GASTOS*/
