USE MyPersonalLibrary;
GO

-- ==========================================
-- 1. Створення логінів (Рівень сервера)
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Library_Admin')
    CREATE LOGIN Library_Admin WITH PASSWORD = 'StrongPassword123!';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Reader_Guest')
    CREATE LOGIN Reader_Guest WITH PASSWORD = 'StrongPassword123!';

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'Data_Operator')
    CREATE LOGIN Data_Operator WITH PASSWORD = 'StrongPassword123!';
GO

-- ==========================================
-- 2. Створення користувачів (Рівень БД)
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Library_Admin_User')
    CREATE USER Library_Admin_User FOR LOGIN Library_Admin;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Reader_Guest_User')
    CREATE USER Reader_Guest_User FOR LOGIN Reader_Guest;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Data_Operator_User')
    CREATE USER Data_Operator_User FOR LOGIN Data_Operator;
GO

-- ==========================================
-- 3. Створення ролей та надання прав
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Library_Manager_Role' AND type = 'R')
    CREATE ROLE Library_Manager_Role;

GRANT SELECT, INSERT, UPDATE, DELETE ON Books TO Library_Manager_Role;
IF OBJECT_ID('Borrowers') IS NOT NULL
    GRANT SELECT, INSERT, UPDATE, DELETE ON Borrowers TO Library_Manager_Role;

GRANT EXECUTE TO Library_Manager_Role;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Library_Viewer_Role' AND type = 'R')
    CREATE ROLE Library_Viewer_Role;

IF OBJECT_ID('v_FullLibraryReport') IS NOT NULL
    GRANT SELECT ON v_FullLibraryReport TO Library_Viewer_Role;
IF OBJECT_ID('v_MyShelf') IS NOT NULL
    GRANT SELECT ON v_MyShelf TO Library_Viewer_Role;
IF OBJECT_ID('v_BookRatings') IS NOT NULL
    GRANT SELECT ON v_BookRatings TO Library_Viewer_Role;
GO

-- ==========================================
-- 4. Призначення ролей користувачам
-- ==========================================
ALTER ROLE Library_Manager_Role ADD MEMBER Data_Operator_User;
ALTER ROLE Library_Viewer_Role ADD MEMBER Reader_Guest_User;
GO

-- ==========================================
-- 5. Перевірка логіки безпеки
-- ==========================================
GRANT SELECT ON Books TO Data_Operator_User;
REVOKE SELECT ON Books FROM Data_Operator_User;
GO

-- Перевірка Оператора
EXECUTE AS USER = 'Data_Operator_User';
SELECT TOP 5 Title FROM Books; 
REVERT;
GO

IF OBJECT_ID('v_MyShelf') IS NOT NULL
    GRANT SELECT ON v_MyShelf TO Reader_Guest_User;

ALTER ROLE Library_Viewer_Role DROP MEMBER Reader_Guest_User;
GO

-- Перевірка Гостя
EXECUTE AS USER = 'Reader_Guest_User';
IF OBJECT_ID('v_MyShelf') IS NOT NULL
    SELECT * FROM v_MyShelf; 
REVERT;
GO

-- ==========================================
-- 6. Фінальний звіт зв'язків ролей
-- ==========================================
SELECT 
    DP1.name AS RoleName, 
    DP2.name AS MemberName  
FROM sys.database_role_members AS DRM  
JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id  
JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id;
GO