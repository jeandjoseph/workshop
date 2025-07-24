-- 🧨 Drop AgenticAI database if it exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'AgenticAI')
BEGIN
    ALTER DATABASE AgenticAI SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AgenticAI;
END

-- 🏗️ Create AgenticAI database
CREATE DATABASE AgenticAI;


-- 👤 Create SQL Server login
USE master;
IF NOT EXISTS (SELECT name FROM sys.sql_logins WHERE name = 'AgentUser')
BEGIN
    CREATE LOGIN AgentUser WITH PASSWORD = 'SecureP@ssw0rd!'; -- 🔐 Replace with a strong password
END

-- 🎯 Create database user mapped to login
USE AgenticAI;

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'AgentUser')
BEGIN
    CREATE USER AgentUser FOR LOGIN AgentUser;
END

-- ✅ Grant read/write permissions
ALTER ROLE db_datareader ADD MEMBER AgentUser;
ALTER ROLE db_datawriter ADD MEMBER AgentUser;
