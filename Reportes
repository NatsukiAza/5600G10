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
