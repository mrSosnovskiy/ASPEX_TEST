--Изменения типа данных в поле RentPrice на DECIMAL  для правильного подсчета д.с.
ALTER TABLE [Bicycle] 
ALTER COLUMN [RentPrice] DECIMAL(10, 2) NOT NULL;

-- По таблице Client можно добавить уникальность паспорта и телефонного номера, но в ретроспективе может храниться один клиент с разными номерами при изменении номера или паспортных данных
ALTER TABLE [Client]
ADD CONSTRAINT UQ_Client_Passport UNIQUE ([Passport]),
    CONSTRAINT UQ_Client_PhoneNumber UNIQUE ([PhoneNumber]);
-- Увеличени кол-ва символов в полу name
ALTER TABLE [Client]
ALTER COLUMN [Name] NVARCHAR(50) NOT NULL;

--Изменения типа данных в поле Price на DECIMAL  для правильного подсчета д.с.
ALTER TABLE [Detail]
ALTER COLUMN [Price] DECIMAL(10, 2) NOT NULL;

--Добавление  проверки на положительную цену
ALTER TABLE [Detail]
ADD CONSTRAINT CK_Detail_Price CHECK ([Price] >= 0);

--Увеличение кол-ва символов в имени сотрудников
ALTER TABLE [Staff]
ALTER COLUMN [Name] NVARCHAR(50) NOT NULL;