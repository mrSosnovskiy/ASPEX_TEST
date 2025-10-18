--Клиенты из USA
SELECT Name, Passport, [Phone number]
FROM Client 
WHERE Country = 'USA';

-- Топ-5 наиболее рентабельных велосипедов (максимальная выручка при минимальных затратах на ремонт)
SELECT TOP 5
    b.Id AS BicycleId,
    b.Brand,
    b.RentPrice,
    ISNULL(SUM(r.Time * b.RentPrice), 0) AS TotalRentalRevenue,
    ISNULL(SUM(s.Price), 0) AS TotalServiceCost,
    ISNULL(SUM(r.Time * b.RentPrice), 0) - ISNULL(SUM(s.Price), 0) AS NetProfit,
    CASE 
        WHEN ISNULL(SUM(s.Price), 0) = 0 THEN 999999 
        ELSE ISNULL(SUM(r.Time * b.RentPrice), 0) / NULLIF(SUM(s.Price), 0) 
    END AS ProfitRatio
FROM 
    Bicycle b
LEFT JOIN 
    RentBook r ON b.Id = r.BicycleId AND r.Paid = 1
LEFT JOIN 
    ServiceBook s ON b.Id = s.BicycleId
GROUP BY 
    b.Id, b.Brand, b.RentPrice
ORDER BY 
    NetProfit DESC;

-- Аналитика по клиентам и сотрудникам: кто из сотрудников обслужил самых активных клиентов
SELECT 
    s.Name AS StaffName,
    c.Name AS ClientName,
    c.Country,
    COUNT(r.Id) AS TotalRentals,
    SUM(r.Time) AS TotalRentalHours,
    SUM(r.Time * b.RentPrice) AS TotalSpent,
    AVG(r.Time) AS AvgRentalTime
FROM 
    RentBook r
INNER JOIN 
    Staff s ON r.StaffId = s.Id
INNER JOIN 
    Client c ON r.ClientId = c.Id
INNER JOIN 
    Bicycle b ON r.BicycleId = b.Id
WHERE 
    r.Paid = 1
GROUP BY 
    s.Name, c.Name, c.Country
HAVING 
    COUNT(r.Id) >= 2
ORDER BY 
    TotalSpent DESC;

-- Анализ деталей в сервисном обслуживании и их стоимости
SELECT 
    d.Type AS DetailType,
    d.Brand AS DetailBrand,
    d.Name AS DetailName,
    d.Price AS DetailPrice,
    COUNT(s.DetailId) AS TimesUsedInService,
    COUNT(DISTINCT s.BicycleId) AS UniqueBikesServiced,
    SUM(s.Price) AS TotalServiceRevenue,
    AVG(s.Price) AS AvgServicePrice,
    COUNT(DISTINCT dfb.BicycleId) AS CompatibleBikesCount
FROM 
    Detail d
LEFT JOIN 
    ServiceBook s ON d.Id = s.DetailId
LEFT JOIN 
    DetailForBicycle dfb ON d.Id = dfb.DetailId
GROUP BY 
    d.Type, d.Brand, d.Name, d.Price
HAVING 
    COUNT(s.DetailId) > 0
ORDER BY 
    TotalServiceRevenue DESC;

 -- Детальный анализ: клиенты, их предпочтения в брендах и связанные сервисные работы
SELECT 
    c.Name AS ClientName,
    c.Country,
    b.Brand AS PreferredBrand,
    COUNT(r.Id) AS RentalsWithThisBrand,
    SUM(r.Time) AS TotalHoursWithBrand,
    AVG(r.Time) AS AvgRentalTime,
    COUNT(DISTINCT s.BicycleId) AS ServicedBikesRented,
    ISNULL(SUM(s.Price), 0) AS MaintenanceCostForRentedBikes,
    CASE 
        WHEN COUNT(r.Id) > 0 THEN ISNULL(SUM(s.Price), 0) / COUNT(r.Id)
        ELSE 0 
    END AS MaintenanceCostPerRental
FROM 
    Client c
INNER JOIN 
    RentBook r ON c.Id = r.ClientId
INNER JOIN 
    Bicycle b ON r.BicycleId = b.Id
LEFT JOIN 
    ServiceBook s ON r.BicycleId = s.BicycleId AND s.Date >= DATEADD(MONTH, -3, r.Date)
WHERE 
    r.Paid = 1
GROUP BY 
    c.Name, c.Country, b.Brand
HAVING 
    COUNT(r.Id) >= 2
ORDER BY 
    TotalHoursWithBrand DESC, RentalsWithThisBrand DESC;