/*ACA PODREMOS DESARROLLAR LOS SP Y POSTERIORMENTE DIVIDIRLOS EN QUERYS Y/O IOR VOLCANDO LOS QUE YA SIRVEN EN ESTE ARCHIVO*/

/*IMPORTACION A LA TABLA PERSONA*/

CREATE PROCEDURE ImportarCSV
	@RutaArchivoNovedades VARCHAR(500)
AS BEGIN
    CREATE TABLE #DatosImportadosCSV(
        Nombre VARCHAR(100),
        Apellido VARCHAR(100),
        Documento INT,
        Email_Personal VARCHAR(100),
        Telefono INT,
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
    BEGIN TRY
        EXEC sp_executesql @ComandoSQL;
    END TRY
    BEGIN CATCH
        PRINT 'ERROR AL EJECUTAR BULK INSERT. Revise la ruta del archivo y los permisos.';
        RETURN;
    END CATCH;
    --
    MERGE Persona AS Transformado
    USING (
        SELECT DISTINCT
            1 AS Tipo_Documento, -- Se inserta la constante 1
            DatoImportado.Documento AS Numero_Documento,
            TRIM(DatoImportado.Nombre) AS Nombre, -- Limpieza de espacios
            TRIM(DatoImportado.Apellido) AS Apellido, -- Limpieza de espacios
            TRIM(DatoImportado.Email_Personal) AS Correo_Electronico, -- Limpieza de espacios
            DatoImportado.Telefono AS Telefono
        FROM #DatosImportadosCSV AS DatoImportado
    ) AS Fuente 
    ON (
        Transformado.numero_documento = Fuente.Numero_Documento AND Transformado.tipo_documento = Fuente.Tipo_Documento
    )
    --
    WHEN MATCHED THEN
        UPDATE SET
            Transformado.nombre = Fuente.Nombre,                 -- Se actualiza el nombre por si hubo corrección
            Transformado.apellido = Fuente.Apellido,             -- Se actualiza el apellido
            Transformado.correo_electronico = Fuente.Correo_Electronico,
            Transformado.Telefono = Fuente.Telefono
    --
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (tipo_documento, numero_documento, nombre, apellido, correo_electronico, Telefono)
        VALUES (
            Fuente.Tipo_Documento, 
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
            (1, 'Altos de Saint Just Administración', 'contacto@altosstjust.com'),
            (2, 'Consorcios del Sur', 'info@consorciosdelsur.com'),
            (3, 'Administradora Central', 'administracion@central.com') 
    ) AS Fuente(ID_Administracion,Nombre,Correo_Electronico)
    ON (
        Destino.ID_Administracion = Fuente.ID_Administracion 
    )
    --
    WHEN MATCHED THEN
        UPDATE SET
            Destino.Nombre = Fuente.Nombre,
            Destino.Correo_Electronico = Fuente.Correo_Electronico
    --
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (ID_Administracion,Nombre,Correo_Electronico)
        VALUES (
        Fuente.ID_Administracion, 
        Fuente.Nombre, 
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
        coeficiente VARCHAR(10), -- Mantenemos VARCHAR para manejar la coma decimal
        m2_unidad_funcional DECIMAL(10,2), -- Estos serán nuestros sumandos
        bauleras VARCHAR(10),
        cochera VARCHAR(10),
        m2_baulera DECIMAL(10,2), -- Estos serán nuestros sumandos
        m2_cochera DECIMAL(10,2)  -- Estos serán nuestros sumandos
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

/*IMPORTACION A LA TABLA EXPENSA*/

/*IMPORTACION A LA TABLA DETALLE_EXPENSA*/

/*IMPORTACION A LA TABLA PAGO*/

/*IMPORTACION A LA TABLA GASTOS*/
