USE COM5600G10;
GO




IF OBJECT_ID('vw_Descifrado_Persona', 'V') IS NOT NULL
    DROP VIEW vw_Descifrado_Persona;
GO

CREATE VIEW vw_Descifrado_Persona
AS
SELECT
    Tipo_Documento,
    CONVERT(VARCHAR(20), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', Numero_documento_Cifrado)) AS Numero_documento,
    Nombre,
    Apellido,
    CONVERT(VARCHAR(100), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', Correo_Cifrado)) AS Correo_Electronico,
    CONVERT(VARCHAR(22), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', CBU_CVU_Cifrado)) AS CBU_CVU,
    CONVERT(VARCHAR(20), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', Telefono_Cifrado)) AS Telefono
FROM Persona;
GO





IF OBJECT_ID('vw_Descifrado_Relacion_UF_Persona', 'V') IS NOT NULL
    DROP VIEW vw_Descifrado_Relacion_UF_Persona;
GO

CREATE VIEW vw_Descifrado_Relacion_UF_Persona
AS
SELECT
    ID_Relacion,
    ID_UF,
	ID_Persona,
    Fecha_Inicio,
    Fecha_Fin,
	Rol,
    CONVERT(VARCHAR(22), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', CBU_CVU_Pago_Cifrado)) AS CBU_CVU_Pago
FROM Relacion_UF_Persona;
GO





IF OBJECT_ID('vw_Descifrado_Pago', 'V') IS NOT NULL
    DROP VIEW vw_Descifrado_Pago;
GO

CREATE VIEW vw_Descifrado_Pago
AS
SELECT
    ID_Pago,
    ID_Detalle,
    Fecha_Pago,
	CONVERT(VARCHAR(30), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', Cuenta_Origen_Cifrada)) AS Cuenta_Origen,
    DatoImportado,
    Estado,
    Tipo_Pago
FROM Pago;
GO





IF OBJECT_ID('vw_Descifrado_Administracion', 'V') IS NOT NULL
    DROP VIEW vw_Descifrado_Administracion;
GO

CREATE VIEW vw_Descifrado_Administracion
AS
SELECT
    ID_Administracion,
    Nombre,
    Direccion,
    CONVERT(VARCHAR(100), DECRYPTBYPASSPHRASE('$(PASSPHRASE_CIFRADO)', Correo_Cifrado)) AS Correo_Electronico
FROM Administracion;
GO







SELECT * FROM Persona;
SELECT * FROM vw_Descifrado_Persona;
SELECT * FROM Pago;
SELECT * FROM vw_Descifrado_Pago;
SELECT * FROM Relacion_UF_Persona;
SELECT * FROM vw_Descifrado_Relacion_UF_Persona;
SELECT * FROM Administracion;
SELECT * FROM vw_Descifrado_Administracion;
