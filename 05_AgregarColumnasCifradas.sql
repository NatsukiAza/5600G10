USE COM5600G10;
GO

-- Agregar columna para CBU_CVU cifrado
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'CBU_CVU_Cifrado')
BEGIN
    ALTER TABLE Persona
    ADD CBU_CVU_Cifrado VARBINARY(256) NULL;
END

-- Agregar columna para Correo_Electronico cifrado
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Correo_Cifrado')
BEGIN
    ALTER TABLE Persona
    ADD Correo_Cifrado VARBINARY(256) NULL;
END

-- Agregar columna para Telefono cifrado
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Telefono_Cifrado')
BEGIN
    ALTER TABLE Persona
    ADD Telefono_Cifrado VARBINARY(128) NULL;
END

-- Agregar columna para Numero_documento cifrado
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Numero_documento_Cifrado')
BEGIN
    ALTER TABLE Persona
    ADD Numero_documento_Cifrado VARBINARY(128) NULL;
END

-- Agregar columna para CBU_CVU_Pago cifrado
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Relacion_UF_Persona') AND name = 'CBU_CVU_Pago_Cifrado')
BEGIN
    ALTER TABLE Relacion_UF_Persona
    ADD CBU_CVU_Pago_Cifrado VARBINARY(256) NULL;
END

-- Agregar columna para Cuenta_Origen cifrada
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pago') AND name = 'Cuenta_Origen_Cifrada')
BEGIN
    ALTER TABLE Pago
    ADD Cuenta_Origen_Cifrada VARBINARY(256) NULL;
END

-- Agregar columna para Correo_Electronico cifrado
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Administracion') AND name = 'Correo_Cifrado')
BEGIN
    ALTER TABLE Administracion
    ADD Correo_Cifrado VARBINARY(256) NULL;
END






DECLARE @FraseClave VARCHAR(100) = '$(PASSPHRASE_CIFRADO)';

-- Cifrar y migrar todos los datos sensibles persona

UPDATE dbo.Persona
SET 
    CBU_CVU_Cifrado = ENCRYPTBYPASSPHRASE(@FraseClave, CBU_CVU),
    Correo_Cifrado = ENCRYPTBYPASSPHRASE(@FraseClave, Correo_Electronico),
    Telefono_Cifrado = ENCRYPTBYPASSPHRASE(@FraseClave, CAST(Telefono AS VARCHAR(20))),
    Numero_documento_Cifrado = ENCRYPTBYPASSPHRASE(@FraseClave, CAST(Numero_documento AS VARCHAR(20)))
WHERE 
    CBU_CVU IS NOT NULL OR Correo_Electronico IS NOT NULL OR Telefono IS NOT NULL OR Numero_documento IS NOT NULL;

-- Cifrar y migrar todos los datos sensibles relacion uf persona
UPDATE dbo.Relacion_UF_Persona
SET 
    CBU_CVU_Pago_Cifrado = ENCRYPTBYPASSPHRASE(@FraseClave, CBU_CVU_Pago)
WHERE 
    CBU_CVU_PAGO IS NOT NULL;

-- Cifrar y migrar todos los datos sensibles pago
UPDATE dbo.Pago
SET 
    Cuenta_Origen_Cifrada = ENCRYPTBYPASSPHRASE(@FraseClave, Cuenta_Origen)
WHERE 
    Cuenta_Origen IS NOT NULL;

-- Cifrar y migrar todos los datos sensibles administracion
UPDATE dbo.Administracion
SET 
    Correo_Cifrado = ENCRYPTBYPASSPHRASE(@FraseClave, Correo_Electronico)
WHERE 
    Correo_Electronico IS NOT NULL;









--Eliminar columnas persona
GO

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'CBU_CVU')
    ALTER TABLE Persona DROP COLUMN CBU_CVU;

-- Eliminar Correo_Electronico
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Correo_Electronico')
    ALTER TABLE Persona DROP COLUMN Correo_Electronico;

-- Eliminar Telefono
IF EXISTS (
    SELECT * FROM sys.check_constraints 
    WHERE parent_object_id = OBJECT_ID('Persona') 
    AND name = 'CK__Persona__Telefon__440B1D61' -- Usar el nombre de la restricción que aparece en el error
)
BEGIN
    ALTER TABLE Persona 
    DROP CONSTRAINT CK__Persona__Telefon__440B1D61;
    
    PRINT 'Restricción CK__Persona__Telefon__440B1D61 eliminada.';
END

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Telefono')
    ALTER TABLE Persona DROP COLUMN Telefono;

-- Eliminar Numero_documento
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Persona') AND name = 'Numero_documento')
    ALTER TABLE Persona DROP COLUMN Numero_documento;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Relacion_UF_Persona') AND name = 'CBU_CVU_Pago')
BEGIN
    ALTER TABLE Relacion_UF_Persona DROP COLUMN CBU_CVU_Pago
END

-- Agregar columna para Cuenta_Origen cifrada
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pago') AND name = 'Cuenta_Origen')
BEGIN
    ALTER TABLE Pago DROP COLUMN Cuenta_Origen;
END

-- Agregar columna para Correo_Electronico cifrado
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Administracion') AND name = 'Correo_Electronico')
BEGIN
    ALTER TABLE Administracion DROP COLUMN Correo_Electronico;
END



