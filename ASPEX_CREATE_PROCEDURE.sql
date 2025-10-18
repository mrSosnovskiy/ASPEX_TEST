CREATE PROCEDURE [LoadStaffBonusMart]
    @TargetYear int = NULL,
    @TargetMonth int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Если год и месяц не указаны, используем текущую дату
    IF @TargetYear IS NULL
        SET @TargetYear = YEAR(GETDATE());
    
    IF @TargetMonth IS NULL
        SET @TargetMonth = MONTH(GETDATE());
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Удаляем существующие данные за указанный период (идиомпотентность)
        DELETE FROM [StaffBonusMart] 
        WHERE [Year] = @TargetYear AND [Month] = @TargetMonth;
        
        -- Рассчитываем и вставляем данные о премиях
        INSERT INTO [StaffBonusMart] (
            [Year], 
            [Month], 
            [StaffId], 
            [StaffName], 
            [ExperienceYears],
            [ExperienceBonusPercent],
            [RentalRevenue],
            [ServiceRevenue],
            [TotalBonus]
        )
        SELECT 
            @TargetYear AS [Year],
            @TargetMonth AS [Month],
            s.Id AS StaffId,
            s.Name AS StaffName,
            DATEDIFF(YEAR, s.Date, GETDATE()) AS ExperienceYears,
            CASE 
                WHEN DATEDIFF(YEAR, s.Date, GETDATE()) < 1 THEN 0.05  -- 5%
                WHEN DATEDIFF(YEAR, s.Date, GETDATE()) BETWEEN 1 AND 2 THEN 0.10  -- 10%
                ELSE 0.15  -- 15%
            END AS ExperienceBonusPercent,
            ISNULL(SUM(CASE WHEN r.Paid = 1 THEN r.Time * b.RentPrice ELSE 0 END), 0) AS RentalRevenue,
            ISNULL(SUM(sb.Price), 0) AS ServiceRevenue,
            -- Расчет премии по формуле: (P1 * X1 + P2 * X2) * X0
            -- P1 * X1 = RentalRevenue * 0.30 (30% от аренды)
            -- P2 * X2 = ServiceRevenue * 0.80 (80% от ремонта)
            -- X0 = ExperienceBonusPercent
            (
                (ISNULL(SUM(CASE WHEN r.Paid = 1 THEN r.Time * b.RentPrice ELSE 0 END), 0) * 0.30) +
                (ISNULL(SUM(sb.Price), 0) * 0.80)
            ) * 
            CASE 
                WHEN DATEDIFF(YEAR, s.Date, GETDATE()) < 1 THEN 0.05
                WHEN DATEDIFF(YEAR, s.Date, GETDATE()) BETWEEN 1 AND 2 THEN 0.10
                ELSE 0.15
            END AS TotalBonus
        FROM 
            Staff s
        LEFT JOIN RentBook r ON s.Id = r.StaffId 
            AND YEAR(r.Date) = @TargetYear 
            AND MONTH(r.Date) = @TargetMonth
        LEFT JOIN Bicycle b ON r.BicycleId = b.Id
        LEFT JOIN ServiceBook sb ON s.Id = sb.StaffId 
            AND YEAR(sb.Date) = @TargetYear 
            AND MONTH(sb.Date) = @TargetMonth
        WHERE 
            s.Id IS NOT NULL
        GROUP BY 
            s.Id, s.Name, s.Date;
        
        -- Логируем результат загрузки
        DECLARE @LoadedRows int = @@ROWCOUNT;
        DECLARE @Message varchar(500) = 'Successfully loaded ' + CAST(@LoadedRows AS varchar) + 
                      ' records for ' + CAST(@TargetYear AS varchar) + '-' + CAST(@TargetMonth AS varchar);
        
        PRINT @Message;
        
        COMMIT TRANSACTION;
        
        -- Возвращаем результаты для проверки
        SELECT 
            [Year],
            [Month],
            [StaffName],
            [ExperienceYears],
            [ExperienceBonusPercent] * 100 AS ExperienceBonusPercent,
            [RentalRevenue],
            [ServiceRevenue],
            [TotalBonus]
        FROM [StaffBonusMart]
        WHERE [Year] = @TargetYear AND [Month] = @TargetMonth
        ORDER BY [TotalBonus] DESC;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage varchar(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity int = ERROR_SEVERITY();
        DECLARE @ErrorState int = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;