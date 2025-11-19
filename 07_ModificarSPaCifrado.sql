USE COM5600G10;
GO



IF OBJECT_ID('dbo.ImportarInquilinos_Propietarios', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarInquilinos_Propietarios;
GO

CREATE PROCEDURE ImportarInquilinos_Propietarios
    @RutaArchivoNovedades VARCHAR(500)
AS 
BEGIN
    SET NOCOUNT ON;  

	DECLARE @Passphrase VARCHAR(100);
	SET @Passphrase = '$(PASSPHRASE_CIFRADO)';

    CREATE TABLE #DatosImportadosCSV
	(
        Nombre VARCHAR(100),
        Apellido VARCHAR(100),
        Documento VARCHAR(100),
        Email_Personal VARCHAR(100),
        Telefono VARCHAR(50),
        CBU_CVU_Pago VARCHAR(50),
        Inquilino_Flag VARCHAR(10)
    );

    DECLARE @ComandoSQL NVARCHAR(MAX);
    SET @ComandoSQL = 
        'BULK INSERT #DatosImportadosCSV
        FROM ''' + @RutaArchivoNovedades + '''
        WITH 
		(
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2
        )';
    
    EXEC sp_executesql @ComandoSQL;

    WITH FuenteCSV AS 
	(
        SELECT
            'DNI' AS Tipo_Documento,
            TRY_CAST((TRIM(DatoImportado.Documento)) AS INT) AS Numero_Documento,
            TRIM(DatoImportado.Nombre) AS Nombre,
            TRIM(DatoImportado.Apellido) AS Apellido,
            TRIM(DatoImportado.Email_Personal) AS Correo_Electronico,
            TRY_CAST((TRIM(DatoImportado.Telefono)) AS INT) AS Telefono,
            TRIM(DatoImportado.CBU_CVU_Pago) AS CBU_CVU,
            ROW_NUMBER() OVER (PARTITION BY DatoImportado.Documento ORDER BY DatoImportado.Documento) AS RN
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
    USING 
	(
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
    ON 
	(
        Transformado.numero_documento = Fuente.Numero_Documento 
        AND 
		Transformado.tipo_documento = Fuente.Tipo_Documento
    )
    
    -- ACTUALIZACIÓN CON CIFRADO
    WHEN MATCHED THEN
        UPDATE SET
            Transformado.nombre = Fuente.Nombre,
            Transformado.apellido = Fuente.Apellido,
            Transformado.Correo_Cifrado = ENCRYPTBYPASSPHRASE(@Passphrase, Fuente.Correo_Electronico),
            Transformado.Telefono_Cifrado = ENCRYPTBYPASSPHRASE(@Passphrase, CAST(Fuente.Telefono AS VARCHAR(20))),
            Transformado.CBU_CVU_Cifrado = ENCRYPTBYPASSPHRASE(@Passphrase, Fuente.CBU_CVU),
            Transformado.Numero_documento_Cifrado = ENCRYPTBYPASSPHRASE(@Passphrase, CAST(Fuente.Numero_Documento AS VARCHAR(20)))
    
    -- INSERCIÓN CON CIFRADO
    WHEN NOT MATCHED BY TARGET THEN
        INSERT 
		(
            tipo_documento, 
            numero_documento, 
            nombre, 
            apellido, 
            Correo_Cifrado,
            Telefono_Cifrado,
            CBU_CVU_Cifrado,
            Numero_documento_Cifrado
        )
        VALUES 
		(
            Fuente.Tipo_Documento,
            Fuente.Numero_Documento,
            Fuente.Nombre,
            Fuente.Apellido,
            ENCRYPTBYPASSPHRASE(@Passphrase, Fuente.Correo_Electronico),
            ENCRYPTBYPASSPHRASE(@Passphrase, CAST(Fuente.Telefono AS VARCHAR(20))),
            ENCRYPTBYPASSPHRASE(@Passphrase, Fuente.CBU_CVU),
            ENCRYPTBYPASSPHRASE(@Passphrase, CAST(Fuente.Numero_Documento AS VARCHAR(20)))
        );

    IF OBJECT_ID('tempdb..#DatosImportadosCSV') IS NOT NULL
        DROP TABLE #DatosImportadosCSV;
     
END
GO






IF OBJECT_ID('dbo.ImportarDatosAdministracion', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarDatosAdministracion;
GO

CREATE OR ALTER PROCEDURE ImportarDatosAdministracion
AS 
BEGIN
    SET NOCOUNT ON;
    
	DECLARE @Passphrase VARCHAR(100);
	SET @Passphrase = '$(PASSPHRASE_CIFRADO)';

    MERGE dbo.Administracion AS Destino
    USING 
	(
        VALUES 
            (1, 'Altos de Saint Just Administración', 'Calle A 123', 'contacto@altosstjust.com'),
            (2, 'Consorcios del Sur', 'Avenida Sur 456', 'info@consorciosdelsur.com'),
            (3, 'Administradora Central', 'Carrera Central 789', 'administracion@central.com') 
    ) AS Fuente(ID_Administracion, Nombre, Direccion, Correo_Electronico)
    ON 
	(
        Destino.ID_Administracion = Fuente.ID_Administracion 
    )
    
    -- ACTUALIZACIÓN CON CIFRADO
    WHEN MATCHED THEN
        UPDATE SET
            Destino.Nombre = Fuente.Nombre,
            Destino.Direccion = Fuente.Direccion,
            Destino.Correo_Cifrado = ENCRYPTBYPASSPHRASE(@Passphrase, Fuente.Correo_Electronico)
    
    -- INSERCIÓN CON CIFRADO
    WHEN NOT MATCHED BY TARGET THEN
        INSERT
		(
            ID_Administracion,
            Nombre,
            Direccion,
            Correo_Cifrado
        )
        VALUES 
		(
            Fuente.ID_Administracion, 
            Fuente.Nombre, 
            Fuente.Direccion,
            ENCRYPTBYPASSPHRASE(@Passphrase, Fuente.Correo_Electronico)
        );
    
    PRINT 'sp_ImportarDatosAdministracion: Datos cifrados correctamente.';
END
GO






IF OBJECT_ID('dbo.ImportarRelacionUFPersonas', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarRelacionUFPersonas;
GO

CREATE PROCEDURE ImportarRelacionUFPersonas
    @RutaArchivoPersonas VARCHAR(500),
    @RutaArchivoRelacion VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @Passphrase VARCHAR(100);
	SET @Passphrase = '$(PASSPHRASE_CIFRADO)';

    -- Tabla temporal para personas
    CREATE TABLE #DatosPersonasCSV
	(
        Nombre VARCHAR(100),
        Apellido VARCHAR(100),
        Documento VARCHAR(100),
        Email_Personal VARCHAR(100),
        Telefono VARCHAR(50),
        CBU_CVU VARCHAR(50),
        Flag_Inquilino VARCHAR(10)
    );

    -- Tabla temporal para relaciones UF
    CREATE TABLE #DatosRelacionCSV
	(
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
         WITH 
		 (
             FIELDTERMINATOR = ''|'',
             ROWTERMINATOR = ''\n'',
             FIRSTROW = 2
         )';
    EXEC sp_executesql @ComandoSQL;

    -- Preparar datos finales para insertar CON CIFRADO
    ;WITH FuenteRelacion AS 
	(
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
        INNER JOIN Unidad_Funcional AS UF
            ON UF.NroUnidadFuncional = R.NroUnidadFuncional
        INNER JOIN #DatosPersonasCSV AS P
            ON P.CBU_CVU = R.CBU_CVU
		INNER JOIN dbo.Persona AS PE
			ON CONVERT(VARCHAR(22), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', PE.CBU_CVU_Cifrado)) = P.CBU_CVU
        WHERE
            NULLIF(R.CBU_CVU,'') IS NOT NULL
            AND NULLIF(P.CBU_CVU,'') IS NOT NULL
            AND NULLIF(P.Flag_Inquilino,'') IS NOT NULL
    )

    -- INSERCIÓN CON CIFRADO DE CBU_CVU_Pago
    INSERT INTO Relacion_UF_Persona
	(
        ID_Relacion,
        ID_UF, 
		ID_Persona,
        Fecha_Inicio, 
        Fecha_Fin, 
        Rol, 
        CBU_CVU_Pago_Cifrado
    )
    SELECT
        ID_Relacion, 
        ID_UF, 
		ID_Persona,
        Fecha_Inicio, 
        Fecha_Fin, 
        Rol, 
        ENCRYPTBYPASSPHRASE(@Passphrase, CBU_CVU) AS CBU_CVU_Pago_Cifrado
    FROM FuenteRelacion;

    -- Limpieza
    IF OBJECT_ID('tempdb..#DatosPersonasCSV') IS NOT NULL
        DROP TABLE #DatosPersonasCSV;

    IF OBJECT_ID('tempdb..#DatosRelacionCSV') IS NOT NULL
        DROP TABLE #DatosRelacionCSV;
    
END
GO








IF OBJECT_ID('dbo.ImportarPagosConsorcio', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ImportarPagosConsorcio;
GO


CREATE OR ALTER PROCEDURE ImportarPagosConsorcio
    @RutaArchivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
	DECLARE @Passphrase VARCHAR(100);
	SET @Passphrase = '$(PASSPHRASE_CIFRADO)';

    IF OBJECT_ID('tempdb..#PagosCSV') IS NOT NULL 
        DROP TABLE #PagosCSV;
    
    CREATE TABLE #PagosCSV 
	(
        ID_Pago_CSV VARCHAR(20),
        Fecha_Pago VARCHAR(20),
        CBU_CVU_Pago VARCHAR(30),
        Valor VARCHAR(30)
    );
    
    DECLARE @ComandoSQL NVARCHAR(MAX);
    SET @ComandoSQL = 
        'BULK INSERT #PagosCSV
         FROM ''' + @RutaArchivo + '''
         WITH 
		 (
              FIELDTERMINATOR = '','',
              ROWTERMINATOR = ''\n'',
              FIRSTROW = 2
         )';
    
    EXEC sp_executesql @ComandoSQL;
    
    WITH PagosLimpios AS
	(
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
    PagosRankeados AS 
	(
        SELECT
            P.ID_Pago_CSV AS ID_Pago,
            D.ID_Detalle,
            P.Fecha_Pago,
            P.CBU_CVU_Pago,
            P.Valor,
            P.Estado,
            ROW_NUMBER() OVER 
			(
                PARTITION BY P.ID_Pago_CSV 
                ORDER BY D.ID_Detalle DESC 
            ) AS FilaUnica
        FROM PagosLimpios P
        INNER JOIN Relacion_UF_Persona R 
            ON CONVERT(VARCHAR(30), DECRYPTBYPASSPHRASE(@Passphrase, R.CBU_CVU_Pago_Cifrado)) = P.CBU_CVU_Pago
        INNER JOIN Detalle_Expensa D    
            ON D.ID_UF = R.ID_UF
    )
    
    -- MERGE CON CIFRADO DE Cuenta_Origen
    MERGE INTO Pago AS T
    USING 
	(
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
    
    ON T.ID_Pago = S.ID_Pago
    
    -- ACTUALIZACIÓN CON CIFRADO
    WHEN MATCHED THEN
        UPDATE SET 
            T.Fecha_Pago = S.Fecha_Pago,
            T.Cuenta_Origen_Cifrada = ENCRYPTBYPASSPHRASE(@Passphrase, S.CBU_CVU_Pago),
            T.DatoImportado = S.Valor,
            T.Estado = S.Estado 
    
    -- INSERCIÓN CON CIFRADO        
    WHEN NOT MATCHED THEN
        INSERT
		(
            ID_Pago, 
            ID_Detalle, 
            Fecha_Pago, 
            Cuenta_Origen_Cifrada, 
            DatoImportado, 
            Estado, 
            Tipo_Pago
        )
        VALUES 
		(
            S.ID_Pago, 
            S.ID_Detalle, 
            S.Fecha_Pago, 
            ENCRYPTBYPASSPHRASE(@Passphrase, S.CBU_CVU_Pago), 
            S.Valor, 
            S.Estado, 
            'ORDINARIO'
        );
    
    IF OBJECT_ID('tempdb..#PagosCSV') IS NOT NULL
        DROP TABLE #PagosCSV;
    
END;
GO
