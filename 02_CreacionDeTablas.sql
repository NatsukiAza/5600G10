USE COM5600G10;

CREATE TABLE Administracion(
	 ID_Administracion INT PRIMARY KEY,
	 Nombre VARCHAR(100) NOT NULL,
     Direccion VARCHAR(100) NOT NULL,
     Correo_Electronico VARCHAR(100) NOT NULL
)

CREATE TABLE Consorcio(
	ID_Consorcio INT PRIMARY KEY,
	ID_Administracion INT FOREIGN KEY References  Administracion(ID_Administracion) ON DELETE CASCADE,
	Nombre VARCHAR(100) NOT NULL,
	Direccion VARCHAR(100) NOT NULL,
	Superficie DECIMAL(10,2) NOT NULL
)

CREATE TABLE Unidad_Funcional(
	ID_UF INT PRIMARY KEY IDENTITY(1,1),
	ID_Consorcio INT FOREIGN KEY references Consorcio(ID_Consorcio) ON DELETE CASCADE,
    nroUnidadFuncional INT NOT NULL,
	Piso CHAR(2) NOT NULL, check (Piso = 'PB' or (TRY_CAST(Piso as INT) between 0 and 20)),
	Departamento CHAR(1) NOT NULL,
	Superficie_m2 DECIMAL(10,2) NOT NULL,check (Superficie_m2>10),
	Porcentaje_Prorrateo DECIMAL(10,2) NOT NULL, check( Porcentaje_Prorrateo >=0 and Porcentaje_Prorrateo <= 100),
	Tiene_Cochera CHAR(2) NOT NULL, check (Tiene_Cochera in ('SI','NO')),
	Tiene_Bahulera CHAR(2) NOT NULL, check (Tiene_Bahulera in ('SI','NO'))
)

CREATE TABLE Persona(
	Tipo_Documento TINYINT,
	Numero_documento INT,
	Nombre VARCHAR(100) NOT NULL,
	Apellido VARCHAR(100) NOT NULL,
	Correo_Electronico VARCHAR(100) NOT NULL,
	CBU_CVU CHAR(22) NULL,
	Telefono INT NOT NULL CHECK(Telefono between 1100000000 and 1200000000),
	PRIMARY KEY(Tipo_Documento,Numero_documento)
)

CREATE TABLE Relacion_UF_Persona(
	ID_Relacion INT Primary key,
	ID_UF INT,
	Tipo_Documento TINYINT,
	Num_Documento INT,
	Fecha_Inicio DATE NOT NULL,
	Fecha_Fin DATE NOT NULL, CHECK(Fecha_Fin > Fecha_Inicio),
	Rol VARCHAR(11) NOT NULL CHECK (Rol IN ('PROPIETARIO','INQUILINO')),
	CBU_CVU_Pago CHAR(22) NOT NULL,
	CONSTRAINT FK_Relacion_Persona FOREIGN KEY (Tipo_Documento, Num_Documento)
    REFERENCES Persona(Tipo_Documento, Numero_documento) ON DELETE CASCADE,
	CONSTRAINT FK_Relacion_UF FOREIGN KEY (ID_UF)
    REFERENCES Unidad_Funcional(ID_UF) ON DELETE CASCADE
)

CREATE TABLE Expensa (
    ID_Expensa INT PRIMARY KEY,
    ID_Consorcio INT NOT NULL,
    Fecha_Generada DATE NOT NULL,
    Fecha_Venc1 DATE NOT NULL,
    Fecha_Venc2 DATE NOT NULL,
    Expensas_Ord DECIMAL(12,2) CHECK (Expensas_Ord >= 0),
    Expensas_Extraord DECIMAL(12,2) CHECK (Expensas_Extraord >= 0),
    Total_Expensa AS (Expensas_Ord + Expensas_Extraord),
    Estado VARCHAR(15) CHECK (Estado IN ('PENDIENTE','GENERADA','CERRADA','ANULADA')),

    CONSTRAINT FK_Expensa_Consorcio FOREIGN KEY (ID_Consorcio)
        REFERENCES Consorcio(ID_Consorcio)
        ON DELETE CASCADE,
    
    CONSTRAINT CHK_Fecha_Venc2_Mayor_Venc1 CHECK (Fecha_Venc2 > Fecha_Venc1)
)

CREATE TABLE Gasto (
    ID_Gasto INT PRIMARY KEY,
    ID_Expensa INT NOT NULL,
    Tipo_Gasto NVARCHAR(50) NOT NULL,
    Fecha DATE NOT NULL,
    Monto DECIMAL(12,2) CHECK (Monto >= 0),
    Detalle NVARCHAR(255),

    CONSTRAINT FK_Gasto_Expensa FOREIGN KEY (ID_Expensa)
        REFERENCES Expensa(ID_Expensa)
        ON DELETE CASCADE
)

CREATE TABLE Detalle_Expensa (
    ID_Detalle INT PRIMARY KEY,
    ID_Expensa INT NOT NULL,
    ID_UF INT NOT NULL,
    Pagos_Recibidos DECIMAL(12,2) DEFAULT 0 CHECK (Pagos_Recibidos >= 0),
    Deuda DECIMAL(12,2) DEFAULT 0 CHECK (Deuda >= 0),
    Interes_Mora DECIMAL(12,2) DEFAULT 0 CHECK (Interes_Mora >= 0),
    Detalle_Ordinarias DECIMAL(12,2) CHECK (Detalle_Ordinarias >= 0),
    Detalle_Extraord DECIMAL(12,2) CHECK (Detalle_Extraord >= 0),
    Total DECIMAL(12,2) CHECK (Total >= 0),

    CONSTRAINT FK_Detalle_Expensa FOREIGN KEY (ID_Expensa)
        REFERENCES Expensa(ID_Expensa)
        ON DELETE CASCADE,

    CONSTRAINT FK_Detalle_UF FOREIGN KEY (ID_UF)
        REFERENCES unidad_Funcional(ID_UF)
        ON DELETE NO ACTION 
)

CREATE TABLE Pago (
    ID_Pago INT PRIMARY KEY,
    ID_Detalle INT NOT NULL,
    Fecha_Pago DATE NOT NULL,
    Cuenta_Origen VARCHAR(30) NOT NULL,
    DatoImportado DECIMAL(12,2) CHECK (DatoImportado >= 0),
    Estado VARCHAR(15) CHECK (Estado IN ('PENDIENTE','CONFIRMADO','ANULADO')),
    Tipo_Pago VARCHAR(15) CHECK (Tipo_Pago IN ('ORDINARIO','EXTRAORDINARIO')),

    CONSTRAINT FK_Pago_Detalle FOREIGN KEY (ID_Detalle)
        REFERENCES Detalle_Expensa(ID_Detalle)
        ON DELETE CASCADE
)

