USE MyPersonalLibrary;
GO


-- ==========================================
-- ЗАВДАННЯ 1: Автоматизація полів аудиту (ULC, DLC)
-- ==========================================
CREATE OR ALTER TRIGGER trg_Books_Audit_Update
ON Books
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Оновлюємо лише ті рядки, які були змінені
    UPDATE Books
    SET ULC = SUSER_NAME(),
        DLC = GETDATE()
    FROM Books b
    INNER JOIN inserted i ON b.BookID = i.BookID;
END;
GO


-- ==========================================
-- ЗАВДАННЯ 2: Сурогатний ключ через тригер (Таблиця Borrowers)
-- ==========================================
IF OBJECT_ID('Borrowers') IS NOT NULL DROP TABLE Borrowers;
CREATE TABLE Borrowers (
    BorrowerID INT PRIMARY KEY,
    FullName NVARCHAR(255),
    DebtAmount DECIMAL(10,2) DEFAULT 0
);
GO

CREATE OR ALTER TRIGGER trg_Borrowers_PK
ON Borrowers
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MaxID INT = ISNULL((SELECT MAX(BorrowerID) FROM Borrowers), 0);

    INSERT INTO Borrowers (BorrowerID, FullName, DebtAmount)
    SELECT @MaxID + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), FullName, DebtAmount
    FROM inserted;
END;
GO


-- ==========================================
-- ЗАВДАННЯ 3: Обмеження цілісності (Додавання зв'язку та тригерів лімітів)
-- ==========================================

-- Додаємо поле CurrentBorrowerID до вашої таблиці Books, якщо його ще немає
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Books') AND name = 'CurrentBorrowerID')
    ALTER TABLE Books ADD CurrentBorrowerID INT FOREIGN KEY REFERENCES Borrowers(BorrowerID);
GO

-- ВАРІАНТ А: Обмеження за сумою (не більше 1000 грн у одних руках)
CREATE OR ALTER TRIGGER trg_CheckBorrowingLimit_Sum
ON Books
AFTER UPDATE
AS
BEGIN
    IF UPDATE(CurrentBorrowerID)
    BEGIN
        IF EXISTS (
            SELECT i.CurrentBorrowerID
            FROM inserted i
            JOIN Books b ON b.CurrentBorrowerID = i.CurrentBorrowerID
            WHERE i.CurrentBorrowerID IS NOT NULL
            GROUP BY i.CurrentBorrowerID
            HAVING SUM(ISNULL(b.Price, 0)) > 1000
        )
        BEGIN
            RAISERROR (N'Помилка (Сума): Позичальник не може мати книжок на суму більше 1000 грн!', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END;
GO

-- ВАРІАНТ Б: Обмеження за кількістю (не більше 3-х книжок одночасно)
CREATE OR ALTER TRIGGER trg_CheckBorrowingLimit_Count
ON Books
AFTER UPDATE
AS
BEGIN
    IF UPDATE(CurrentBorrowerID)
    BEGIN
        IF EXISTS (
            SELECT i.CurrentBorrowerID
            FROM inserted i
            JOIN Books b ON b.CurrentBorrowerID = i.CurrentBorrowerID
            WHERE i.CurrentBorrowerID IS NOT NULL
            GROUP BY i.CurrentBorrowerID
            HAVING COUNT(b.BookID) > 3
        )
        BEGIN
            RAISERROR (N'Помилка (Кількість): Один позичальник не може тримати більше 3-х книжок одночасно!', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END;
GO


-- ==========================================
-- ПРИКЛАДИ ПЕРЕВІРКИ В ДІЇ (Тестування на вашій базі)
-- ==========================================

-- 1. Підготовка тестового позичальника
INSERT INTO Borrowers (FullName) VALUES (N'Олексій Тестовий');
DECLARE @BorrowerID INT = (SELECT TOP 1 BorrowerID FROM Borrowers WHERE FullName = N'Олексій Тестовий');

-- 2. Сценарій А: Перевірка ліміту вартості (Сума > 1000)
-- Встановлюємо високу ціну для реальної книги «Хірург», щоб спровокувати помилку
UPDATE Books SET Price = 1200 WHERE Title = N'Хірург';

BEGIN TRY
    UPDATE Books SET CurrentBorrowerID = @BorrowerID WHERE Title = N'Хірург';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Виведе: Помилка (Сума): Позичальник не може мати книжок на суму більше 1000 грн!
END CATCH;

-- 3. Сценарій Б: Перевірка ліміту кількості (Кількість > 3)
-- Знижуємо ціну книг, щоб не спрацьовувало перше обмеження
UPDATE Books SET Price = 10;

BEGIN TRY
    -- Намагаємося видати 4 реальні книги з вашої бази одному позичальнику
    UPDATE Books SET CurrentBorrowerID = @BorrowerID WHERE BookID IN (SELECT TOP 4 BookID FROM Books);
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE(); -- Виведе: Помилка (Кількість): Один позичальник не може тримати більше 3-х книжок одночасно!
END CATCH;

-- 4. Перевірка аудиту (поля ULC та DLC)
-- Змінюємо нотатку у реальної книги «Асистент»
UPDATE Books SET Note = N'Тестова зміна аудиту' WHERE Title = N'Асистент';

-- Дивимось результат: хто і коли змінив запис
SELECT Title, ULC, DLC FROM Books WHERE Title = N'Асистент';
GO