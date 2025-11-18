USE COM5600G10;
GO

IF OBJECT_ID('dbo.Permisos', 'P') IS NOT NULL
	DROP PROCEDURE dbo.Permisos;
GO
    CREATE TABLE Permisos (
        ID_Permiso INT IDENTITY(1,1) PRIMARY KEY,
        Rol VARCHAR(50) NOT NULL,
        NomObj VARCHAR(100) NOT NULL,
        TipoObj VARCHAR(20) NOT NULL,
        TipoPermiso VARCHAR(20) NOT NULL, 
        Fecha DATETIME2 DEFAULT GETDATE(),
        OtorgadoPor VARCHAR(100) DEFAULT SUSER_SNAME()
    );

CREATE ROLE administrativo_general;

CREATE ROLE administrativo_bancario;

CREATE ROLE administrativo_operativo;

CREATE ROLE sistemas;

--Asignación de permisos a rol administrativo_general

GRANT SELECT, UPDATE ON Unidad_Funcional TO administrativo_general;
INSERT INTO Permisos (Rol, NomObj, TipoObj, TipoPermiso)
VALUES ('administrativo_general', 'Unidad_Funcional', 'TABLE', 'SELECT'),
       ('administrativo_general', 'Unidad_Funcional', 'TABLE', 'UPDATE');

GRANT SELECT ON Consorcio TO administrativo_general;

INSERT INTO Permisos (Rol, NomObj, TipoObj, TipoPermiso)
VALUES ('administrativo_general', 'Consorcio', 'TABLE', 'SELECT');
GO


--Asignación de permisos a rol administrativo_bancario

GRANT SELECT, INSERT ON Pago TO administrativo_bancario;
INSERT INTO Permisos (Rol, NomObj, TipoObj, TipoPermiso)
VALUES ('administrativo_bancario', 'Pago', 'TABLE', 'SELECT'),
       ('administrativo_bancario', 'Pago', 'TABLE', 'INSERT');

GRANT SELECT ON Detalle_Expensa TO administrativo_bancario;
INSERT INTO Permisos (Rol, NomObj, TipoObj, TipoPermiso)
VALUES ('administrativo_bancario', 'Detalle_Expensa', 'TABLE', 'SELECT');
GO


--Asignación de permisos administrativo_operativo

GRANT SELECT, UPDATE ON Unidad_Funcional TO administrativo_operativo;
INSERT INTO Permisos (Rol, NomObj, TipoObj, TipoPermiso)
VALUES ('administrativo_operativo', 'Unidad_Funcional', 'TABLE', 'SELECT'),
       ('administrativo_operativo', 'Unidad_Funcional', 'TABLE', 'UPDATE');

GRANT SELECT ON Consorcio TO administrativo_operativo;
INSERT INTO Permisos (Rol, NomObj, TipoObj, TipoPermiso)
VALUES ('administrativo_operativo', 'Consorcio', 'TABLE', 'SELECT');
GO


--Asignación de permisos a rol sistemas
INSERT INTO Permisos (Rol, NomObj, TipoObj, TipoPermiso)
VALUES ('sistemas', 'NO_BASE_TABLES', 'TABLE', 'NONE');
GO
