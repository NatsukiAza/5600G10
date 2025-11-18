use COM5600G10

-- REPORTE 1: Flujo de caja semanal (XML)
EXEC sp_ReporteFlujoCajaXML @Anio = 2025, @MesInicio = 5, @MesFin = 6;

-- REPORTE 2: Recaudación por mes y departamento (tabla cruzada)
EXEC sp_ReporteRecaudacionCruzada;
GO

-- REPORTE 3: Recaudación total desagregada según su procedencia
EXEC sp_ReporteRecaudacionProcedencia 
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-12-31',
    @FormatoXML = 0;
GO

-- REPORTE 4: Obtener los 5 meses de mayores gastos y los 5 de mayores ingresos
EXEC sp_ReporteTopGastosIngresos_API 2025, NULL, 1, 0;
EXEC sp_ReporteTopGastosIngresos_API 2025, NULL, 1, 1;
GO

-- REPORTE 5: Obtener los 3 propietarios con mayor morosidad
EXEC sp_ReporteTopMorosos 
    @FechaInicio = '2024-01-01',
    @FechaFin = '2025-12-31',
    @Rol = 'PROPIETARIO';
GO

-- REPORTE 6: Fechas de pagos de expensas ordinarias de cada UF y la cantidad de días
EXEC sp_ReporteFrecuenciaPagosOrdinarios
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-12-31';
GO
