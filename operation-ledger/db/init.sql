-- Seed the reporting database. Nothing secret lives in these tables.

IF DB_ID('reports') IS NULL
    CREATE DATABASE reports;
GO

USE reports;
GO

IF OBJECT_ID('dbo.accounts', 'U') IS NOT NULL DROP TABLE dbo.accounts;
IF OBJECT_ID('dbo.allocations', 'U') IS NOT NULL DROP TABLE dbo.allocations;
IF OBJECT_ID('dbo.support_tickets', 'U') IS NOT NULL DROP TABLE dbo.support_tickets;
GO

CREATE TABLE dbo.accounts (
    account_id    VARCHAR(32) PRIMARY KEY,
    display_name  VARCHAR(128),
    tier          VARCHAR(16),
    status        VARCHAR(16)
);

CREATE TABLE dbo.allocations (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    account_id    VARCHAR(32) REFERENCES dbo.accounts(account_id),
    amount        DECIMAL(38, 0),
    granted_at    DATETIME2 DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.support_tickets (
    ticket_id     INT IDENTITY(1,1) PRIMARY KEY,
    account_id    VARCHAR(32) REFERENCES dbo.accounts(account_id),
    subject       VARCHAR(256),
    body          VARCHAR(MAX),
    created_at    DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO

INSERT INTO dbo.accounts (account_id, display_name, tier, status) VALUES
    ('tester_182', 'A. Okafor',   'standard', 'active'),
    ('tester_203', 'M. Delgado',  'standard', 'active'),
    ('tester_219', 'R. Novak',    'standard', 'suspended'),
    ('whale_047',  'J. Santoro',  'whale',    'active');

INSERT INTO dbo.allocations (account_id, amount) VALUES
    ('tester_182', 1500),
    ('tester_203', 2200),
    ('tester_219', 900),
    ('whale_047',  4200000);

INSERT INTO dbo.support_tickets (account_id, subject, body) VALUES
    ('tester_182', 'Cannot see my allocation', 'Dashboard shows zero since the reset.'),
    ('tester_203', 'Whitelist question',       'Is my address still on the early access list?'),
    ('tester_219', 'Found something odd',       'A log line printed what looked like a seed phrase: alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima - is that expected?');
GO
