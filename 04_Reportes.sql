use COM5600G10
-----------------------------------------
-- REPORTE 1: Flujo de caja semanal (XML)
-----------------------------------------

CREATE OR ALTER PROCEDURE sp_ReporteFlujoCajaXML
    @Anio INT = 2025,
    @MesInicio INT = 1,
    @MesFin INT = 12
AS
BEGIN
    ;WITH RecaudoSemanal AS (
        SELECT 
            DATEPART(WEEK, P.Fecha_Pago) AS NumeroSemana,
            MIN(P.Fecha_Pago) AS FechaInicioSemana,
            MAX(P.Fecha_Pago) AS FechaFinSemana,
            SUM(CASE WHEN P.Tipo_Pago = 'ORDINARIO' THEN P.DatoImportado ELSE 0 END) AS RecaudacionOrdinaria,
            SUM(CASE WHEN P.Tipo_Pago = 'EXTRAORDINARIO' THEN P.DatoImportado ELSE 0 END) AS RecaudacionExtraordinaria,
            SUM(P.DatoImportado) AS TotalSemanal
        FROM Pago P
        WHERE YEAR(P.Fecha_Pago) = @Anio
          AND MONTH(P.Fecha_Pago) BETWEEN @MesInicio AND @MesFin
          AND P.Estado = 'CONFIRMADO'
        GROUP BY DATEPART(YEAR, P.Fecha_Pago), DATEPART(WEEK, P.Fecha_Pago)
    )
    SELECT 
        NumeroSemana,
        FechaInicioSemana,
        FechaFinSemana,
        RecaudacionOrdinaria,
        RecaudacionExtraordinaria,
        TotalSemanal AS RecaudacionTotal,
        AVG(TotalSemanal) OVER () AS PromedioRecaudacionSemanal,
        SUM(TotalSemanal) OVER (ORDER BY NumeroSemana ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS AcumuladoProgresivo
    FROM RecaudoSemanal
    ORDER BY NumeroSemana
    FOR XML PATH('Semana'), ROOT('ReporteFlujoCaja'), ELEMENTS;
END;
GO


----------------------------------------------------------------
-- REPORTE 2: Recaudación por mes y departamento (tabla cruzada)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ReporteRecaudacionCruzada
    @Anio INT = 2025,
    @Departamento CHAR(1) = NULL,
    @EstadoPago VARCHAR(15) = 'CONFIRMADO'
AS
BEGIN
    SELECT *
    FROM (
        SELECT 
            DATENAME(MONTH, P.Fecha_Pago) AS Mes,
            MONTH(P.Fecha_Pago) AS MesNumero,
            UF.Departamento,
            P.DatoImportado AS Recaudacion
        FROM Pago P
        INNER JOIN Detalle_Expensa DE ON P.ID_Detalle = DE.ID_Detalle
        INNER JOIN Unidad_Funcional UF ON DE.ID_UF = UF.ID_UF
        WHERE YEAR(P.Fecha_Pago) = @Anio
            AND P.Estado = 'CONFIRMADO'
    ) AS SourceTable
    PIVOT (
        SUM(Recaudacion)
        FOR Departamento IN ([A], [B], [C], [D], [E])
    ) AS PivotTable
    ORDER BY MesNumero;
END;
GO

    
----------------------------------------------------------------
-- REPORTE 3: Recaudación total desagregada según su procedencia
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ReporteRecaudacionProcedencia
    @FechaInicio DATE,
    @FechaFin DATE,
    @FormatoXML BIT = 0
AS
BEGIN
    IF @FormatoXML = 1
    BEGIN
        SELECT 
            YEAR(p.Fecha_Pago) AS Anio,
            MONTH(p.Fecha_Pago) AS Mes,
            p.Tipo_Pago AS Procedencia,
            SUM(p.DatoImportado) AS TotalRecaudado
        FROM Pago p
        WHERE p.Fecha_Pago BETWEEN @FechaInicio AND @FechaFin
            AND p.Estado = 'CONFIRMADO'
        GROUP BY YEAR(p.Fecha_Pago), MONTH(p.Fecha_Pago), p.Tipo_Pago
        ORDER BY Anio, Mes, Procedencia
        FOR XML PATH('Recaudacion'), ROOT('Resultados');
    END
    ELSE
    BEGIN
        SELECT 
            CAST(Anio AS VARCHAR) + '-' + RIGHT('0' + CAST(Mes AS VARCHAR), 2) AS Periodo,
            ISNULL([ORDINARIO], 0) AS ORDINARIO,
            ISNULL([EXTRAORDINARIO], 0) AS EXTRAORDINARIO,
            ISNULL([ORDINARIO], 0) + ISNULL([EXTRAORDINARIO], 0) AS Total
        FROM (
            SELECT 
                YEAR(p.Fecha_Pago) AS Anio,
                MONTH(p.Fecha_Pago) AS Mes,
                p.Tipo_Pago,
                SUM(p.DatoImportado) AS TotalRecaudado
            FROM Pago p
            WHERE p.Fecha_Pago BETWEEN @FechaInicio AND @FechaFin
                AND p.Estado = 'CONFIRMADO'
            GROUP BY YEAR(p.Fecha_Pago), MONTH(p.Fecha_Pago), p.Tipo_Pago
        ) AS SourceTable
        PIVOT (
            SUM(TotalRecaudado)
            FOR Tipo_Pago IN ([ORDINARIO], [EXTRAORDINARIO])
        ) AS PivotTable
        ORDER BY Anio, Mes;
    END
END;
GO

    
------------------------------------------------------------
-- REPORTE 5: Obtener los 3 propietarios con mayor morosidad
------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_ReporteTopMorosos
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @Rol VARCHAR(11) = 'PROPIETARIO',
    @Top INT = 3
AS
BEGIN
    -- Si no se especifican fechas, toma el último año
    IF @FechaInicio IS NULL SET @FechaInicio = DATEADD(YEAR, -1, GETDATE());
    IF @FechaFin IS NULL SET @FechaFin = GETDATE();

    SELECT TOP (@Top)
        P.ID_Persona,
        P.Nombre + ' ' + P.Apellido AS Propietario,
        P.Tipo_Documento,
        P.Numero_documento AS DNI,
        P.Correo_Electronico,
        P.Telefono,
        P.CBU_CVU,
        UF.nroUnidadFuncional,
        UF.Departamento,
        UF.Piso,
        C.Nombre AS Consorcio,
        SUM(DE.Deuda) AS Total_Deuda,
        COUNT(DE.ID_Detalle) AS Cantidad_Expensas_Vencidas,
        MAX(E.Fecha_Venc2) AS Ultimo_Vencimiento,
        DATEDIFF(DAY, MAX(E.Fecha_Venc2), GETDATE()) AS Dias_En_Mora
    FROM Detalle_Expensa DE
        INNER JOIN Expensa E ON DE.ID_Expensa = E.ID_Expensa
        INNER JOIN Unidad_Funcional UF ON DE.ID_UF = UF.ID_UF
        INNER JOIN Consorcio C ON UF.ID_Consorcio = C.ID_Consorcio
        INNER JOIN Relacion_UF_Persona R ON UF.ID_UF = R.ID_UF
        INNER JOIN Persona P ON R.ID_Persona = P.ID_Persona  
    WHERE 
        E.Fecha_Generada BETWEEN @FechaInicio AND @FechaFin
        AND R.Rol = @Rol
        AND DE.Deuda > 0  
        AND R.Fecha_Fin > GETDATE()  
    GROUP BY 
        P.ID_Persona, P.Nombre, P.Apellido, P.Tipo_Documento, P.Numero_documento, 
        P.Correo_Electronico, P.Telefono, P.CBU_CVU, UF.nroUnidadFuncional, 
        UF.Departamento, UF.Piso, C.Nombre
    ORDER BY 
        SUM(DE.Deuda) DESC;
END;
GO
