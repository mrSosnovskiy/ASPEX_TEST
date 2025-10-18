CREATE TABLE [StaffBonusMart] (
    [Id] int IDENTITY(1,1) PRIMARY KEY,
    [Year] int NOT NULL,
    [Month] int NOT NULL,
    [StaffId] int NOT NULL,
    [StaffName] varchar(50) NOT NULL,
    [ExperienceYears] int NOT NULL,
    [ExperienceBonusPercent] decimal(5,2) NOT NULL,
    [RentalRevenue] decimal(10,2) NOT NULL DEFAULT 0,
    [ServiceRevenue] decimal(10,2) NOT NULL DEFAULT 0,
    [TotalBonus] decimal(10,2) NOT NULL,
    [LoadDate] datetime2 NOT NULL DEFAULT GETUTCDATE()
    CONSTRAINT UK_StaffBonusMart_Unique UNIQUE ([Year], [Month], [StaffId])
);
