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

/*IMPORTACION A LA TABLA CONSORCIO*/

/*IMPORTACION A LA TABLA UNIDAD_FUNCIONAL*/
