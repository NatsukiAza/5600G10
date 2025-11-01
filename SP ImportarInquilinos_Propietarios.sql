USE COM025600

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
--
GO

SELECT * FROM dbo.Persona
