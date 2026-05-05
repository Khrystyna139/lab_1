USE master;
GO

-- Видаляємо стару базу
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'MyPersonalLibrary')
BEGIN
    ALTER DATABASE MyPersonalLibrary SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MyPersonalLibrary;
END
GO

-- Створюємо базу заново
CREATE DATABASE MyPersonalLibrary;
GO

USE MyPersonalLibrary;
GO

-- Створення послідовності
CREATE SEQUENCE BookSequence START WITH 1 INCREMENT BY 1;
GO

-- ТАБЛИЦІ-ДОВІДНИКИ
CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
    FullName NVARCHAR(255) NOT NULL,
    Country NVARCHAR(100),
    UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
    DCR DATETIME DEFAULT (GETDATE()),
    ULC NVARCHAR(100),
    DLC DATETIME
);

CREATE TABLE Publishers (
    PubID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
    PubName NVARCHAR(255) NOT NULL UNIQUE,
    UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
    DCR DATETIME DEFAULT (GETDATE())
);

CREATE TABLE Genres (
    GenreID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
    GenreName NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Tags (
    TagID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
    TagName NVARCHAR(50) NOT NULL UNIQUE,
    UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
    DCR DATETIME DEFAULT (GETDATE())
);

-- ТАБЛИЦЯ КНИГ
CREATE TABLE Books (
    BookID INT PRIMARY KEY DEFAULT (NEXT VALUE FOR BookSequence),
    Title NVARCHAR(255) NOT NULL,
    Price DECIMAL(10, 2),
    Pages INT,
    BookFormat NVARCHAR(50) DEFAULT N'physical' 
        CONSTRAINT CHK_Format CHECK (BookFormat IN (N'physical', N'Digital (audio)', N'E-book', N'mix')),
    FirstPubYear INT,
    CycleName NVARCHAR(255),
    SourceFrom NVARCHAR(100), 
    IsInLibrary BIT DEFAULT 1, 
    BookStatus NVARCHAR(50) DEFAULT N'нечитана' 
        CONSTRAINT CHK_Status CHECK (BookStatus IN (N'прочитана', N'нечитана', N'в процесі', N'закинуто', N'хочу продати')),
    ReadDate DATE, 
    Rating DECIMAL(3,1) CONSTRAINT CHK_Rating_12 CHECK (Rating BETWEEN 0 AND 12),
    Note NVARCHAR(MAX),
    SalePrice DECIMAL(10, 2), 
    PubID INT CONSTRAINT FK_Books_Publishers FOREIGN KEY REFERENCES Publishers(PubID),
    PreviousBookID INT CONSTRAINT FK_Books_Hierarchy FOREIGN KEY REFERENCES Books(BookID),
    UCR NVARCHAR(100) DEFAULT (SUSER_NAME()),
    DCR DATETIME DEFAULT (GETDATE()),
    ULC NVARCHAR(100),
    DLC DATETIME
);

-- ТАБЛИЦІ-ЗВ'ЯЗКИ
CREATE TABLE BookAuthors (BookID INT FOREIGN KEY REFERENCES Books(BookID) ON DELETE CASCADE, AuthorID INT FOREIGN KEY REFERENCES Authors(AuthorID) ON DELETE CASCADE, PRIMARY KEY (BookID, AuthorID));
CREATE TABLE BookGenres (BookID INT FOREIGN KEY REFERENCES Books(BookID) ON DELETE CASCADE, GenreID INT FOREIGN KEY REFERENCES Genres(GenreID) ON DELETE CASCADE, PRIMARY KEY (BookID, GenreID));
CREATE TABLE BookTags (BookID INT FOREIGN KEY REFERENCES Books(BookID) ON DELETE CASCADE, TagID INT FOREIGN KEY REFERENCES Tags(TagID) ON DELETE CASCADE, PRIMARY KEY (BookID, TagID));
GO

-- ПРЕДСТАВЛЕННЯ (VIEWS)
CREATE VIEW v_MyShelf AS
SELECT 
    b.Title, 
    ISNULL(STRING_AGG(a.FullName, ', '), N'Не вказано') AS Authors, 
    b.BookFormat, 
    b.Pages, 
    b.BookStatus
FROM Books b
LEFT JOIN BookAuthors ba ON b.BookID = ba.BookID
LEFT JOIN Authors a ON ba.AuthorID = a.AuthorID
WHERE b.IsInLibrary = 1 AND b.BookStatus != N'хочу продати'
GROUP BY b.BookID, b.Title, b.BookFormat, b.Pages, b.BookStatus;
GO

-- ОНОВЛЕНИЙ v_BookRatings 
CREATE VIEW v_BookRatings AS
SELECT 
    b.Title AS [Назва],
    (SELECT STRING_AGG(a.FullName, ', ') FROM BookAuthors ba JOIN Authors a ON ba.AuthorID = a.AuthorID WHERE ba.BookID = b.BookID) AS [Автор],
    CAST(b.Rating AS NVARCHAR(4)) + '/10' AS [Оцінка],
    (SELECT STRING_AGG(g.GenreName, ', ') FROM BookGenres bg JOIN Genres g ON bg.GenreID = g.GenreID WHERE bg.BookID = b.BookID) AS [Жанр],
    (SELECT STRING_AGG(t.TagName, ', ') FROM BookTags bt JOIN Tags t ON bt.TagID = t.TagID WHERE bt.BookID = b.BookID) AS [Теги],
    b.Pages AS [Кількість сторінок],
    ISNULL(b.CycleName, N'-') AS [Цикл],
    ISNULL(CONVERT(NVARCHAR, b.ReadDate, 104), N'Ще не прочитано') AS [Дата закінчення],
    b.BookFormat AS [Формат],
    ISNULL(b.Note, N'') AS [Примітка]
FROM Books b;
GO

-- НАПОВНЕННЯ ДАНИМИ
DECLARE @A_Clarke INT = NEXT VALUE FOR BookSequence;
DECLARE @A_Gerritsen INT = NEXT VALUE FOR BookSequence;
DECLARE @P_Vivat INT = NEXT VALUE FOR BookSequence;
DECLARE @P_RM INT = NEXT VALUE FOR BookSequence;
DECLARE @G_Fantasy INT = NEXT VALUE FOR BookSequence;
DECLARE @G_Thriller INT = NEXT VALUE FOR BookSequence;
DECLARE @T_Atmospheric INT = NEXT VALUE FOR BookSequence;
DECLARE @T_Detective INT = NEXT VALUE FOR BookSequence;
DECLARE @T_Mystery INT = NEXT VALUE FOR BookSequence;
DECLARE @B_Piranesi INT = NEXT VALUE FOR BookSequence;
DECLARE @B_Surgeon INT = NEXT VALUE FOR BookSequence;

-- Вставка довідників
INSERT INTO Authors (AuthorID, FullName, Country) VALUES (@A_Clarke, N'Сюзанна Кларк', N'Велика Британія'), (@A_Gerritsen, N'Тесс Ґерітсен', N'США');
INSERT INTO Publishers (PubID, PubName) VALUES (@P_Vivat, N'Vivat'), (@P_RM, N'Рідна Мова');
INSERT INTO Genres (GenreID, GenreName) VALUES (@G_Fantasy, N'Фентезі'), (@G_Thriller, N'Трилер');
INSERT INTO Tags (TagID, TagName) VALUES (@T_Atmospheric, N'Атмосферно'), (@T_Detective, N'Детектив'), (@T_Mystery, N'Загадка');

-- Вставка книг
INSERT INTO Books (BookID, Title, Price, Pages, BookFormat, FirstPubYear, PubID, Rating, BookStatus, ReadDate, CycleName, Note)
VALUES 
(@B_Piranesi, N'Піранезі', 450.00, 288, N'physical', 2020, @P_Vivat, 8, N'прочитана', '2026-02-07', NULL, N'Неймовірна атмосфера магічного Лабіринту'),
(@B_Surgeon, N'Хірург', 380.00, 352, N'physical', 2001, @P_RM, 7, N'прочитана', '2024-04-16', N'Ріццолі та Айлс', N'Перша книга серії');

-- Вставка зв'язків
INSERT INTO BookAuthors (BookID, AuthorID) VALUES (@B_Piranesi, @A_Clarke), (@B_Surgeon, @A_Gerritsen);
INSERT INTO BookGenres (BookID, GenreID) VALUES (@B_Piranesi, @G_Fantasy), (@B_Surgeon, @G_Thriller);
INSERT INTO BookTags (BookID, TagID) VALUES (@B_Piranesi, @T_Atmospheric), (@B_Piranesi, @T_Mystery), (@B_Surgeon, @T_Detective), (@B_Surgeon, @T_Mystery);
GO

-- ВИВІД ПОВНИХ РЯДКІВ
SELECT * FROM v_BookRatings;
GO