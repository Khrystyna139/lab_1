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
-- 2. ДОДАВАННЯ КНИГ (ЧЕРЕЗ MERGE ЗАХИСТ ВІД ДУБЛІКАТІВ)
-- ==========================================

MERGE INTO Books AS target
USING (
    VALUES 
    -- Хірург
    (N'Хірург', 352, 250.00, N'physical', 2001, NULL, 9.0, N'прочитана', CAST('2024-05-05' AS DATE), N'мій перший захоплюючий і напружуючий детектив', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    
    -- Асистент
    (N'Асистент', 400, 250.00, N'physical', 2002, NULL, 8.0, N'прочитана', CAST('2024-07-13' AS DATE), N'цікаве продовження від лиця Джейн Ріццолі', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    
    -- Грішна
    (N'Грішна', 368, 250.00, N'physical', 2003, NULL, 10.0, N'прочитана', CAST('2024-08-11' AS DATE), N'неочікува закінчення', (SELECT PubID FROM Publishers WHERE PubName = N'КСД'), 1),
    
    -- Крах людини
    (N'Крах людини', 108, 320.00, N'physical', 1952, NULL, 10.0, N'прочитана', CAST('2025-02-20' AS DATE), N'неймовірно прониклива та болісна сповідь про абсолютну самотність і відчуження від світу', (SELECT PubID FROM Publishers WHERE PubName = N'Морфеус'), 1),
    
    -- Аріадна
    (N'Аріадна', 392, 455.00, N'physical', 2021, NULL, 8.0, N'прочитана', CAST('2025-08-25' AS DATE), N'новий погляд на грецькі міфи', (SELECT PubID FROM Publishers WHERE PubName = N'yakaboo'), 1),
    
    -- Служниця
    (N'Служниця', 352, 380.00, N'physical', 2022, NULL, 7.0, N'прочитана', CAST('2024-10-10' AS DATE), N'динамічний та захопливий трилер, від якого важко відірватися', (SELECT PubID FROM Publishers WHERE PubName = N'Vivat'), 0),
    
    -- Танці з кістками
    (N'Танці з кістками', 368, 350.00, N'physical', 2022, NULL, 7.0, N'прочитана', CAST('2024-06-30' AS DATE), N'український трилер, який показує закулісся медичного світу', (SELECT PubID FROM Publishers WHERE PubName = N'Віхола'), 0),
    
    -- Червона зима
    (N'Червона зима', 320, 545.00, N'physical', 2016, NULL, 9.0, N'прочитана', CAST('2024-08-23' AS DATE), N'надзвичайно атмосферне фентезі, яку з головою занурює у магію стародавньої Японії', (SELECT PubID FROM Publishers WHERE PubName = N'Nebo'), 1),
    
    -- Темна буря
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

-- Автори
INSERT INTO BookAuthors (BookID, AuthorID) 
SELECT b.BookID, a.AuthorID FROM Books b, Authors a 
WHERE ((b.Title IN (N'Хірург', N'Асистент', N'Грішна') AND a.FullName = N'Тесс Ґеррітсен')
   OR (b.Title = N'Крах людини' AND a.FullName = N'Дадзай Осаму')
   OR (b.Title = N'Аріадна' AND a.FullName = N'Дженніфер Сейнт')
   OR (b.Title = N'Служниця' AND a.FullName = N'Фріда Мак-Фадден')
   OR (b.Title = N'Танці з кістками' AND a.FullName = N'Андрій Сем`янків')
   OR (b.Title IN (N'Червона зима', N'Темна буря') AND a.FullName = N'Аннет Марі'))
AND NOT EXISTS (SELECT 1 FROM BookAuthors ba WHERE ba.BookID = b.BookID AND ba.AuthorID = a.AuthorID);

-- Жанри
INSERT INTO BookGenres (BookID, GenreID) 
SELECT b.BookID, g.GenreID FROM Books b, Genres g 
WHERE ((b.Title IN (N'Хірург', N'Асистент', N'Грішна') AND g.GenreName = N'Детектив')
   OR (b.Title = N'Крах людини' AND g.GenreName = N'Автобіографічна проза')
   OR (b.Title = N'Аріадна' AND g.GenreName = N'Історичне фентезі')
   OR (b.Title IN (N'Служниця', N'Танці з кістками') AND g.GenreName = N'Трилер')
   OR (b.Title IN (N'Червона зима', N'Темна буря') AND g.GenreName = N'Фентезі'))
AND NOT EXISTS (SELECT 1 FROM BookGenres bg WHERE bg.BookID = b.BookID AND bg.GenreID = g.GenreID);

-- Теги
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

-- ==========================================
-- ПЕРЕВІРКА
-- ==========================================
SELECT * FROM v_BookRatings;