USE MyPersonalLibrary;
GO

-- ==========================================
-- КРОК 1: ПОВНЕ ОЧИЩЕННЯ ТА НАПОВНЕННЯ ДОВІДНИКІВ
-- ==========================================
DELETE FROM BookTags;
DELETE FROM BookGenres;
DELETE FROM BookAuthors;
DELETE FROM Books;
DELETE FROM Publishers; -- Повністю очищуємо видавництва, щоб не було старих/зайвих назв
GO

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

-- Видавництва (тільки короткі назви)
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
-- КРОК 2: ДОДАВАННЯ КНИГ
-- ==========================================
INSERT INTO Books (Title, Pages, Price, BookFormat, FirstPubYear, CycleName, Rating, BookStatus, ReadDate, Note, PubID, IsInLibrary)
VALUES 
    (N'Хірург', 352, 250.00, N'physical', 2001, NULL, 9.0, N'прочитана', '2024-05-05', N'мій перший захоплюючий і напружуючий детектив', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    (N'Асистент', 400, 250.00, N'physical', 2002, NULL, 8.0, N'прочитана', '2024-07-13', N'цікаве продовження від лиця Джейн Ріццолі', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    (N'Грішна', 368, 250.00, N'physical', 2003, NULL, 10.0, N'прочитана', '2024-08-11', N'неочікуване закінчення', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    (N'Крах людини', 108, 320.00, N'physical', 1952, NULL, 10.0, N'прочитана', '2025-02-20', N'неймовірно прониклива та болісна сповідь', (SELECT PubID FROM Publishers WHERE PubName = N'Морфеус'), 1),
    (N'Аріадна', 392, 455.00, N'physical', 2021, NULL, 8.0, N'прочитана', '2025-08-25', N'новий погляд на грецькі міфи', (SELECT PubID FROM Publishers WHERE PubName = N'yakaboo'), 1),
    (N'Служниця', 352, 380.00, N'physical', 2022, NULL, 7.0, N'прочитана', '2024-10-10', N'динамічний та захопливий трилер', (SELECT PubID FROM Publishers WHERE PubName = N'Vivat'), 0),
    (N'Танці з кістками', 368, 350.00, N'physical', 2022, NULL, 7.0, N'прочитана', '2024-06-30', N'український трилер', (SELECT PubID FROM Publishers WHERE PubName = N'Віхола'), 0),
    (N'Червона зима', 320, 545.00, N'physical', 2016, NULL, 9.0, N'прочитана', '2024-08-23', N'атмосферне фентезі', (SELECT PubID FROM Publishers WHERE PubName = N'Nebo'), 1),
    (N'Темна буря', 312, 545.00, N'physical', 2017, NULL, 10.0, N'прочитана', '2025-01-28', N'захопливе продовження', (SELECT PubID FROM Publishers WHERE PubName = N'Nebo'), 1);
GO

-- ==========================================
-- КРОК 3: СТВОРЕННЯ ЗВ'ЯЗКІВ (АВТОРИ, ЖАНРИ, ТЕГИ)
-- ==========================================
INSERT INTO BookAuthors (BookID, AuthorID) 
SELECT b.BookID, a.AuthorID FROM Books b, Authors a 
WHERE ((b.Title IN (N'Хірург', N'Асистент', N'Грішна') AND a.FullName = N'Тесс Ґеррітсен')
   OR (b.Title = N'Крах людини' AND a.FullName = N'Дадзай Осаму')
   OR (b.Title = N'Аріадна' AND a.FullName = N'Дженніфер Сейнт')
   OR (b.Title = N'Служниця' AND a.FullName = N'Фріда Мак-Фадден')
   OR (b.Title = N'Танці з кістками' AND a.FullName = N'Андрій Сем`янків')
   OR (b.Title IN (N'Червона зима', N'Темна буря') AND a.FullName = N'Аннет Марі'));

INSERT INTO BookGenres (BookID, GenreID) 
SELECT b.BookID, g.GenreID FROM Books b, Genres g 
WHERE ((b.Title IN (N'Хірург', N'Асистент', N'Грішна') AND g.GenreName = N'Детектив')
   OR (b.Title = N'Крах людини' AND g.GenreName = N'Автобіографічна проза')
   OR (b.Title = N'Аріадна' AND g.GenreName = N'Історичне фентезі')
   OR (b.Title IN (N'Служниця', N'Танці з кістками') AND g.GenreName = N'Трилер')
   OR (b.Title IN (N'Червона зима', N'Темна буря') AND g.GenreName = N'Фентезі'));

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
);
GO

-- ==========================================
-- КРОК 4: ЗВ'ЯЗКИ МІЖ КНИГАМИ (ПОСЛІДОВНІСТЬ)
-- ==========================================
UPDATE Books SET PreviousBookID = (SELECT BookID FROM Books WHERE Title = N'Хірург') WHERE Title = N'Асистент' AND PreviousBookID IS NULL;
UPDATE Books SET PreviousBookID = (SELECT BookID FROM Books WHERE Title = N'Асистент') WHERE Title = N'Грішна' AND PreviousBookID IS NULL;
UPDATE Books SET PreviousBookID = (SELECT BookID FROM Books WHERE Title = N'Червона зима') WHERE Title = N'Темна буря' AND PreviousBookID IS NULL;
GO


-----------------------------------------------------------------------------
-- 1. SELECT на базі однієї таблиці (виправлені умови, щоб виводило дані)
-----------------------------------------------------------------------------
SELECT Title, Price, Rating, Pages
FROM Books
WHERE (ISNULL(Price, 0) > 200 OR ISNULL(Rating, 0) >= 8) AND ISNULL(Pages, 0) >= 350
ORDER BY Rating DESC, Price ASC;
GO

-----------------------------------------------------------------------------
-- 2. SELECT з виводом обчислюваних полів
-----------------------------------------------------------------------------
SELECT 
    Title, 
    Price AS [Загальна ціна],
    Pages AS [К-ть сторінок],
    CAST(ISNULL(Price, 0) / NULLIF(ISNULL(Pages, 0), 0) AS DECIMAL(10,2)) AS [Вартість 1 сторінки],
    CASE 
        WHEN FirstPubYear < 2000 THEN N'Ретро/Класика'
        ELSE N'Сучасне видання'
    END AS [Категорія за віком]
FROM Books
WHERE Pages > 0;
GO

-----------------------------------------------------------------------------
-- 3. SELECT на базі кількох таблиць (Inner Join, Сортування, Умови)
-----------------------------------------------------------------------------
SELECT 
    b.Title AS [Книга], 
    a.FullName AS [Автор], 
    p.PubName AS [Видавництво]
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
JOIN Publishers p ON b.PubID = p.PubID
WHERE ISNULL(a.Country, N'') = N'США' OR p.PubName LIKE N'%КСД%'
ORDER BY b.Title;
GO

-----------------------------------------------------------------------------
-- 4. SELECT з типом поєднання Outer Join (без порожніх рядків)
-----------------------------------------------------------------------------
SELECT 
    p.PubName, 
    COUNT(b.BookID) AS [Кількість книг у базі]
FROM Publishers p
LEFT OUTER JOIN Books b ON p.PubID = b.PubID
WHERE p.PubName IS NOT NULL AND LTRIM(RTRIM(p.PubName)) <> N''
GROUP BY p.PubName;
GO

-----------------------------------------------------------------------------
-- 5. SELECT з використанням Like, Between, In, Exists
-----------------------------------------------------------------------------
SELECT Title, FirstPubYear, BookFormat
FROM Books b
WHERE Title LIKE N'%Хірург%' 
  AND ISNULL(FirstPubYear, 0) BETWEEN 2000 AND 2025 
  AND BookFormat IN (N'physical', N'Digital (audio)') 
  AND EXISTS (SELECT 1 FROM BookAuthors ba WHERE ba.BookID = b.BookID);
GO

-----------------------------------------------------------------------------
-- 6. SELECT з використанням підсумовування та групування
-----------------------------------------------------------------------------
SELECT 
    BookStatus, 
    COUNT(*) AS [Кількість],
    SUM(ISNULL(Pages, 0)) AS [Всього сторінок],
    AVG(ISNULL(Price, 0)) AS [Середня ціна покупки]
FROM Books
GROUP BY BookStatus
HAVING COUNT(*) > 0;
GO

-----------------------------------------------------------------------------
-- 7. SELECT з використанням під-запитів в частині WHERE
-----------------------------------------------------------------------------
SELECT 
    b.Title AS [Книга], 
    a.FullName AS [Автор]
FROM Books b
JOIN BookAuthors ba ON b.BookID = ba.BookID
JOIN Authors a ON ba.AuthorID = a.AuthorID
WHERE b.BookID IN (
    SELECT BookID 
    FROM BookAuthors 
    WHERE AuthorID IN (
        SELECT AuthorID FROM BookAuthors GROUP BY AuthorID HAVING COUNT(*) > 1
    )
);
GO

-----------------------------------------------------------------------------
-- 8. SELECT з використанням під-запитів в частині FROM
-----------------------------------------------------------------------------
SELECT T.Title, T.Rating
FROM (SELECT Title, ISNULL(Rating, 0) AS Rating FROM Books) AS T
WHERE T.Rating > (SELECT AVG(ISNULL(Rating, 0)) FROM Books);
GO

-----------------------------------------------------------------------------
-- 9. Ієрархічний SELECT запит (Recursive CTE)
-----------------------------------------------------------------------------
WITH BookSeries AS (
    SELECT BookID, Title, PreviousBookID, CycleName, 1 AS Level,
           CAST(Title AS NVARCHAR(MAX)) AS FullPath
    FROM Books 
    WHERE PreviousBookID IS NULL
    
    UNION ALL
    
    SELECT b.BookID, b.Title, b.PreviousBookID, b.CycleName, bs.Level + 1,
           bs.FullPath + N' > ' + b.Title
    FROM Books b
    INNER JOIN BookSeries bs ON b.PreviousBookID = bs.BookID
)
SELECT 
    ISNULL(CycleName, N'Поза циклами') AS [Серія],
    REPLICATE(N'    ', Level - 1) + 
    CASE WHEN Level > 1 THEN N'╚══ > ' ELSE N'' END + Title AS [Порядок читання],
    Level AS [Рівень у серії]
FROM BookSeries
ORDER BY [Серія], Level;
GO

-----------------------------------------------------------------------------
-- 10. SELECT запит типу CrossTab (PIVOT)
-----------------------------------------------------------------------------
SELECT BookStatus, [physical], [Digital (audio)], [E-book]
FROM (
    SELECT BookStatus, BookFormat, BookID FROM Books
) AS SourceTable
PIVOT (
    COUNT(BookID) 
    FOR BookFormat IN ([physical], [Digital (audio)], [E-book])
) AS PivotTable;
GO

-----------------------------------------------------------------------------
-- 11. UPDATE на базі однієї таблиці
-----------------------------------------------------------------------------
UPDATE Books
SET SalePrice = ISNULL(Price, 0) * 1.1,
    ULC = SUSER_NAME(),
    DLC = GETDATE()
WHERE ISNULL(Rating, 0) >= 10;

SELECT Title, Price, SalePrice, Rating 
FROM Books 
WHERE ISNULL(Rating, 0) >= 10;
GO

-----------------------------------------------------------------------------
-- 12. UPDATE на базі кількох таблиць (через JOIN)
-----------------------------------------------------------------------------
UPDATE b
SET b.BookStatus = N'хочу продати'
FROM Books b
JOIN BookGenres bg ON b.BookID = bg.BookID
JOIN Genres g ON bg.GenreID = g.GenreID
WHERE g.GenreName = N'Детектив';
GO

SELECT b.Title, b.BookStatus, g.GenreName
FROM Books b
JOIN BookGenres bg ON b.BookID = bg.BookID
JOIN Genres g ON bg.GenreID = g.GenreID
WHERE g.GenreName = N'Детектив';
GO

-----------------------------------------------------------------------------
-- 13. Append (INSERT) з явно вказаними значеннями
-----------------------------------------------------------------------------
INSERT INTO Genres (GenreName) VALUES (N'Наукова фантастика');
GO
SELECT * FROM Genres WHERE GenreName = N'Наукова фантастика';
GO

-----------------------------------------------------------------------------
-- 14. Append (INSERT) з інших таблиць
-----------------------------------------------------------------------------
SELECT * INTO ReadBooksArchive
FROM Books
WHERE BookStatus = N'прочитана';

SELECT * FROM ReadBooksArchive;
GO

-----------------------------------------------------------------------------
-- 15. DELETE для видалення вибраних записів
-----------------------------------------------------------------------------
DELETE FROM Books 
WHERE ISNULL(Rating, 0) = 0 AND IsInLibrary = 0;
GO
SELECT COUNT(*) AS [Книг після видалення] FROM Books;
GO

-----------------------------------------------------------------------------
-- 16. СКЛАДНИЙ ЗАПИТ №1 (Агрегація + JOIN + Subquery + Calculated Field)
-----------------------------------------------------------------------------
SELECT 
    a.FullName,
    SUM(ISNULL(b.Price, 0)) AS [Загальна вартість книг автора],
    COUNT(b.BookID) AS [Кількість книг],
    CAST(SUM(ISNULL(b.Price, 0)) * 100.0 / (SELECT SUM(ISNULL(Price, 0)) FROM Books) AS DECIMAL(5,2)) AS [% від вартості бібліотеки]
FROM Authors a
JOIN BookAuthors ba ON a.AuthorID = ba.AuthorID
JOIN Books b ON ba.BookID = b.BookID
GROUP BY a.FullName
HAVING SUM(ISNULL(b.Price, 0)) > 200
ORDER BY [Загальна вартість книг автора] DESC;
GO

-----------------------------------------------------------------------------
-- 17. СКЛАДНИЙ ЗАПИТ №2 (CTE + Windows Function + Outer Join)
-----------------------------------------------------------------------------
WITH PubStats AS (
    SELECT 
        p.PubName,
        b.Title,
        ISNULL(b.Rating, 0) AS Rating,
        AVG(ISNULL(b.Rating, 0)) OVER(PARTITION BY p.PubName) AS [Середній рейтинг видавництва],
        RANK() OVER(PARTITION BY p.PubName ORDER BY ISNULL(b.Rating, 0) DESC) AS [Ранг у видавництві]
    FROM Publishers p
    LEFT JOIN Books b ON p.PubID = b.PubID
)
SELECT *, (Rating - [Середній рейтинг видавництва]) AS [Відхилення від середнього]
FROM PubStats
WHERE Title IS NOT NULL;
GO
