USE MyPersonalLibrary;
GO

-- ==========================================
-- 1. НАПОВНЕННЯ ДОВІДНИКІВ
-- ==========================================

-- Автори
INSERT INTO Authors (FullName) 
SELECT Name FROM (VALUES 
    (N'Тесс Ґеррітсен'), 
    (N'Дадзай Осаму'), 
    (N'Дженніфер Сейнт'), 
    (N'Фріда Мак-Фадден'), 
    (N'Андрій Сем`янків'), 
    (N'Аннет Марі')
) AS T(Name)
WHERE NOT EXISTS (SELECT 1 FROM Authors WHERE FullName = T.Name);

-- Видавництва
INSERT INTO Publishers (PubName) 
SELECT Name FROM (VALUES 
    (N'КСД'), 
    (N'Морфеус'), 
    (N'yakaboo'), 
    (N'Vivat'), 
    (N'Віхола'), 
    (N'Nebo')
) AS T(Name)
WHERE NOT EXISTS (SELECT 1 FROM Publishers WHERE PubName = T.Name);

-- Жанри
INSERT INTO Genres (GenreName) 
SELECT Name FROM (VALUES 
    (N'Детектив'), 
    (N'Автобіографічна проза'), 
    (N'Історичне фентезі'), 
    (N'Трилер'), 
    (N'Фентезі')
) AS T(Name)
WHERE NOT EXISTS (SELECT 1 FROM Genres WHERE GenreName = T.Name);

-- Теги
INSERT INTO Tags (TagName) 
SELECT Name FROM (VALUES 
    (N'трилери та жахи'), (N'розслідування'), (N'поліція'), 
    (N'его-роман'), (N'психологічний роман'), (N'філосовська драма'), 
    (N'ретелінг'), (N'грецька міфологія'), (N'психологічна драма'), (N'феміністична проза'), 
    (N'психологічний трилер'), (N'домашній нуар'), (N'детектив із закритим фіналом'), 
    (N'кримінальний детектив'), (N'події розгортаються в Україні'), 
    (N'роментезі'), (N'японська міфологія'), (N'пригоднецьке'), (N'епічне фентезі'),
    (N'монастир'), (N'таємниче селище')
) AS T(Name)
WHERE NOT EXISTS (SELECT 1 FROM Tags WHERE TagName = T.Name);

GO

-- ==========================================
-- 2. ДОДАВАННЯ КНИГ (MERGE - ЗАХИСТ ВІД ДУБЛІКАТІВ)
-- ==========================================

MERGE INTO Books AS target
USING (
    VALUES 
    (N'Хірург', 352, 250.00, N'physical', 2001, NULL, 9.0, N'прочитана', CAST('2024-05-05' AS DATE), N'мій перший захоплюючий і напружуючий детектив', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    (N'Асистент', 400, 250.00, N'physical', 2002, NULL, 8.0, N'прочитана', CAST('2024-07-13' AS DATE), N'цікаве продовження від лиця Джейн Ріццолі', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    (N'Грішна', 368, 250.00, N'physical', 2003, NULL, 10.0, N'прочитана', CAST('2024-08-11' AS DATE), N'неочікува закінчення', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    (N'Крах людини', 108, 320.00, N'physical', 1952, NULL, 10.0, N'прочитана', CAST('2025-02-20' AS DATE), N'неймовірно прониклива та болісна сповідь про абсолютну самотність і відчуження від світу', (SELECT PubID FROM Publishers WHERE PubName = N'Морфеус'), 1),
    (N'Аріадна', 392, 455.00, N'physical', 2021, NULL, 8.0, N'прочитана', CAST('2025-08-25' AS DATE), N'новий погляд на грецькі міфи', (SELECT PubID FROM Publishers WHERE PubName = N'yakaboo'), 1),
    (N'Служниця', 352, 380.00, N'physical', 2022, NULL, 7.0, N'прочитана', CAST('2024-10-10' AS DATE), N'динамічний та захопливий трилер, від якого важко відірватися', (SELECT PubID FROM Publishers WHERE PubName = N'Vivat'), 0),
    (N'Танці з кістками', 368, 350.00, N'physical', 2022, NULL, 7.0, N'прочитана', CAST('2024-06-30' AS DATE), N'український трилер, який показує закулісся медичного світу', (SELECT PubID FROM Publishers WHERE PubName = N'Віхола'), 0),
    (N'Червона зима', 320, 545.00, N'physical', 2016, NULL, 9.0, N'прочитана', CAST('2024-08-23' AS DATE), N'надзвичайно атмосферне фентезі, яку з головою занурює у магію стародавньої Японії', (SELECT PubID FROM Publishers WHERE PubName = N'Nebo'), 1),
    (N'Темна буря', 312, 545.00, N'physical', 2017, NULL, 10.0, N'прочитана', CAST('2025-01-28' AS DATE), N'захопливе продовження', (SELECT PubID FROM Publishers WHERE PubName = N'Nebo'), 1)
) AS source (Title, Pages, Price, BookFormat, FirstPubYear, CycleName, Rating, BookStatus, ReadDate, Note, PubID, IsInLibrary)
ON target.Title = source.Title
WHEN NOT MATCHED THEN
    INSERT (Title, Pages, Price, BookFormat, FirstPubYear, CycleName, Rating, BookStatus, ReadDate, Note, PubID, IsInLibrary)
    VALUES (source.Title, source.Pages, source.Price, source.BookFormat, source.FirstPubYear, source.CycleName, source.Rating, source.BookStatus, source.ReadDate, source.Note, source.PubID, source.IsInLibrary);

GO

-- ==========================================
-- 3. СТВОРЕННЯ ЗВ'ЯЗКІВ (АВТОРИ, ЖАНРИ, ТЕГИ)
-- ==========================================

INSERT INTO BookAuthors (BookID, AuthorID) 
SELECT b.BookID, a.AuthorID FROM Books b, Authors a 
WHERE ((b.Title IN (N'Хірург', N'Асистент', N'Грішна') AND a.FullName = N'Тесс Ґеррітсен')
   OR (b.Title = N'Крах людини' AND a.FullName = N'Дадзай Осаму')
   OR (b.Title = N'Аріадна' AND a.FullName = N'Дженніфер Сейнт')
   OR (b.Title = N'Служниця' AND a.FullName = N'Фріда Мак-Фадден')
   OR (b.Title = N'Танці з кістками' AND a.FullName = N'Андрій Сем`янків')
   OR (b.Title IN (N'Червона зима', N'Темна буря') AND a.FullName = N'Аннет Марі'))
AND NOT EXISTS (SELECT 1 FROM BookAuthors ba WHERE ba.BookID = b.BookID AND ba.AuthorID = a.AuthorID);

INSERT INTO BookGenres (BookID, GenreID) 
SELECT b.BookID, g.GenreID FROM Books b, Genres g 
WHERE ((b.Title IN (N'Хірург', N'Асистент', N'Грішна') AND g.GenreName = N'Детектив')
   OR (b.Title = N'Крах людини' AND g.GenreName = N'Автобіографічна проза')
   OR (b.Title = N'Аріадна' AND g.GenreName = N'Історичне фентезі')
   OR (b.Title IN (N'Служниця', N'Танці з кістками') AND g.GenreName = N'Трилер')
   OR (b.Title IN (N'Червона зима', N'Темна буря') AND g.GenreName = N'Фентезі'))
AND NOT EXISTS (SELECT 1 FROM BookGenres bg WHERE bg.BookID = b.BookID AND bg.GenreID = g.GenreID);

INSERT INTO BookTags (BookID, TagID) 
SELECT b.BookID, t.TagID FROM Books b, Tags t 
WHERE (
    (b.Title IN (N'Хірург', N'Асистент') AND t.TagName IN (N'трилери та жахи', N'розслідування', N'поліція'))
    OR (b.Title = N'Грішна' AND t.TagName IN (N'трилери та жахи', N'розслідування', N'поліція', N'монастир', N'таємниче селище'))
    OR (b.Title = N'Крах людини' AND t.TagName IN (N'его-роман', N'психологічний роман', N'філосовська драма'))
    OR (b.Title = N'Аріадна' AND t.TagName IN (N'ретелінг', N'грецька міфологія', N'психологічна драма', N'феміністична проза'))
    OR (b.Title = N'Служниця' AND t.TagName IN (N'психологічний трилер', N'домашній нуар', N'детектив із закритим фіналом'))
    OR (b.Title = N'Танці з кістками' AND t.TagName IN (N'психологічний трилер', N'кримінальний детектив', N'події розгортаються в Україні'))
    OR (b.Title IN (N'Червона зима', N'Темна буря') AND t.TagName IN (N'роментезі', N'японська міфологія', N'пригоднецьке', N'епічне фентезі'))
)
AND NOT EXISTS (SELECT 1 FROM BookTags bt WHERE bt.BookID = b.BookID AND bt.TagID = t.TagID);

GO

-- ==========================================
-- 4. ЗВ'ЯЗКИ МІЖ КНИГАМИ (ПОСЛІДОВНІСТЬ)
-- ==========================================

UPDATE Books SET PreviousBookID = (SELECT BookID FROM Books WHERE Title = N'Хірург') WHERE Title = N'Асистент' AND PreviousBookID IS NULL;
UPDATE Books SET PreviousBookID = (SELECT BookID FROM Books WHERE Title = N'Асистент') WHERE Title = N'Грішна' AND PreviousBookID IS NULL;
UPDATE Books SET PreviousBookID = (SELECT BookID FROM Books WHERE Title = N'Червона зима') WHERE Title = N'Темна буря' AND PreviousBookID IS NULL;
GO

-- ==========================================
-- 5. ПОВНИЙ НАБІР ВИМОГУВАНИХ SELECT, UPDATE ТА DELETE ЗАПИТІВ
-- ==========================================

-- 1. SELECT на базі однієї таблиці (сортування, умови AND / OR)
SELECT Title, Pages, Price, Rating, BookStatus 
FROM Books 
WHERE (IsInLibrary = 1 OR Pages > 350) AND Rating >= 8.0
ORDER BY Title ASC;

-- 2. SELECT з виводом обчислюваних полів (виразів)
SELECT 
    Title, 
    Price, 
    Pages, 
    (Price / NULLIF(Pages, 0)) AS PricePerPage,          
    (Rating * 2 + Pages / 100.0) AS CalculatedValue      
FROM Books;

-- 3. SELECT на базі кількох таблиць (сортування, умови AND / OR)
SELECT b.Title, p.PubName, b.FirstPubYear, b.Rating
FROM Books b
JOIN Publishers p ON b.PubID = p.PubID
WHERE (p.PubName = N'КСД' OR p.PubName = N'Vivat') AND b.FirstPubYear > 2000
ORDER BY b.FirstPubYear DESC;

-- 4. SELECT на базі кількох таблиць з типом поєднання Outer Join (LEFT JOIN)
SELECT 
    b.Title AS CurrentBook, 
    ISNULL(prev.Title, N'Перша книга циклу / Окрема') AS PreviousBook
FROM Books b
LEFT JOIN Books prev ON b.PreviousBookID = prev.BookID;

-- 5. SELECT з використанням операторів Like, Between, In, Exists, All, Any
SELECT Title, Price, FirstPubYear 
FROM Books 
WHERE Price BETWEEN 200 AND 500 
  AND Title LIKE N'%р%'
  AND PubID IN (SELECT PubID FROM Publishers WHERE PubName IN (N'КСД', N'Vivat', N'Морфеус'))
  AND EXISTS (SELECT 1 FROM BookAuthors ba WHERE ba.BookID = Books.BookID);

-- 6. SELECT з використанням підсумовування та групування (GROUP BY)
SELECT 
    BookStatus, 
    COUNT(BookID) AS TotalBooks, 
    AVG(Pages) AS AvgPages, 
    SUM(Price) AS TotalPrice
FROM Books
GROUP BY BookStatus;

-- 7. SELECT з використанням підзапитів в частині WHERE та FROM
SELECT Title, Price 
FROM Books 
WHERE Price >= (SELECT AVG(Price) FROM Books);

SELECT PubSub.PubName, PubSub.BookCount
FROM (
    SELECT p.PubName, COUNT(b.BookID) AS BookCount
    FROM Publishers p
    LEFT JOIN Books b ON p.PubID = b.PubID
    GROUP BY p.PubName
) AS PubSub
WHERE PubSub.BookCount > 0;

-- 8. Ієрархічний SELECT-запит (CTE)
WITH BookHierarchy AS (
    SELECT BookID, Title, PreviousBookID, 1 AS Level
    FROM Books
    WHERE PreviousBookID IS NULL
    UNION ALL
    SELECT b.BookID, b.Title, b.PreviousBookID, bh.Level + 1
    FROM Books b
    INNER JOIN BookHierarchy bh ON b.PreviousBookID = bh.BookID
)
SELECT * FROM BookHierarchy;

-- 9. SELECT-запит типу CrossTab (PIVOT)
SELECT BookFormat, [прочитана], [не прочитана]
FROM (
    SELECT BookFormat, BookStatus, BookID 
    FROM Books
) AS SourceTable
PIVOT (
    COUNT(BookID) FOR BookStatus IN ([прочитана], [не прочитана])
) AS PivotTable;

-- ==========================================
-- 6. СКЛАДНІ ЗАПИТИ (Згідно з вимогами: поєднують кілька типів)
-- ==========================================

-- СКЛАДНИЙ ЗАПИТ №1: Кілька таблиць, JOIN, агрегатні функції, GROUP BY + HAVING, підзапит у HAVING
SELECT 
    p.PubName, 
    COUNT(b.BookID) AS BooksCount,
    AVG(b.Rating) AS AvgRating,
    SUM(b.Price * b.Pages) / SUM(b.Pages) AS WeightedAveragePrice 
FROM Publishers p
JOIN Books b ON p.PubID = b.PubID
WHERE b.FirstPubYear >= 2000 AND b.Rating >= 7.0
GROUP BY p.PubName
HAVING COUNT(b.BookID) >= 1  
   AND AVG(b.Rating) > (SELECT AVG(Rating) FROM Books) 
ORDER BY AvgRating DESC;

-- СКЛАДНИЙ ЗАПИТ №2: Багато таблиць (Books, BookAuthors, Authors, Publishers), IN, LIKE, обчислювані колонки
SELECT 
    b.Title, 
    LEN(b.Title) AS TitleLength, 
    a.FullName AS AuthorName, 
    p.PubName,
    b.Price
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
JOIN Publishers p ON b.PubID = p.PubID
WHERE b.Title LIKE N'%а%'  
  AND p.PubName IN (N'КСД', N'Vivat', N'Морфеус') 
  AND b.Price > 200
ORDER BY TitleLength DESC, b.Price ASC;

-- ==========================================
-- 7. ПРИКЛАДИ UPDATE ТА DELETE
-- ==========================================

-- UPDATE на базі однієї таблиці (підняття ціни):
-- UPDATE Books SET Price = Price * 1.1 WHERE BookStatus <> N'прочитана';

-- UPDATE на базі кількох таблиць:
UPDATE b
SET b.Note = b.Note + N' [Видавництво Nebo]'
FROM Books b
JOIN Publishers p ON b.PubID = p.PubID
WHERE p.PubName = N'Nebo' AND b.Note NOT LIKE N'%[Видавництво Nebo]%';

-- DELETE вибіркових записів (залишено закоментованим для безпеки даних):
-- DELETE FROM Books WHERE Pages < 100;

GO
