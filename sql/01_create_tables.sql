
/* =====================================================================
   Gym Membership & Personal Training Planner - Team Dong Vui (#9)
   INT1313 - Database Basics
   Phase 3 - Script 01: Create Database and Tables (DDL)
   Domain: Membership & Billing
   Author: Nguyen Luu Trieu Quang
   Target: Microsoft SQL Server (T-SQL), run in SSMS

   Source:
   - Section 1.2.1: Business Rules (BR-MEM-01 to BR-MEM-13)
   - Section 2.2: Logical Schema Mapping
   - Section 2.3: Functional Dependencies and Normalization
   - Section 3.1: Attribute Tables

   Notes:
   - Model B contains 16 tables in total.
   - This script creates only Quang's 5 tables.
   - MEMBER and DAILY_PASS_TICKET are independent strong entities.
   - Member_ID, Plan_ID, Membership_ID, Ticket_ID and Bill_ID use INT.
   - SQL Server RESTRICT = NO ACTION.
   - Triggers and business transactions are handled in later scripts.
   ===================================================================== */


-- 1) Create the database (only if it does not exist yet)

IF DB_ID(N'GymPlanner_dev') IS NULL
    CREATE DATABASE GymPlanner_dev;
GO

USE GymPlanner_dev;
GO


/* ---------------------------------------------------------------------
   Optional reset: remove Quang's tables to start over.
   Uncomment ONLY when intentionally deleting existing data.

   WARNING:
   If tables belonging to other team members reference MEMBER,
   those dependent foreign keys must be handled first.
   --------------------------------------------------------------------- */

-- DROP TABLE IF EXISTS dbo.BILLING_LOG;
-- DROP TABLE IF EXISTS dbo.MEMBERSHIP;
-- DROP TABLE IF EXISTS dbo.DAILY_PASS_TICKET;
-- DROP TABLE IF EXISTS dbo.MEMBERSHIP_PLAN;
-- DROP TABLE IF EXISTS dbo.MEMBER;
-- GO


/* =====================================================================
   MEMBER & BILLING DOMAIN
   NGUYEN LUU TRIEU QUANG
   ===================================================================== */


-- Table 1: MEMBER (Independent Strong Entity)

CREATE TABLE dbo.MEMBER (
    Member_ID         INT IDENTITY(1,1) NOT NULL,
    Full_Name         VARCHAR(100)      NOT NULL,
    Phone_Number      VARCHAR(20)       NOT NULL,
    Email             VARCHAR(255)      NULL,
    Birth_Date        DATE              NULL,
    Photo             VARBINARY(MAX)    NULL,
    Registration_Date DATE              NOT NULL,

    CONSTRAINT PK_MEMBER
        PRIMARY KEY (Member_ID),

    CONSTRAINT UQ_MEMBER_Phone_Number
        UNIQUE (Phone_Number)
);
GO

-- Optional email must be unique when provided.

CREATE UNIQUE INDEX UX_MEMBER_Email_NotNull
ON dbo.MEMBER (Email)
WHERE Email IS NOT NULL;
GO


-- Table 2: DAILY_PASS_TICKET (Independent Strong Entity)

CREATE TABLE dbo.DAILY_PASS_TICKET (
    Ticket_ID   INT IDENTITY(1,1) NOT NULL,
    Guest_Name  VARCHAR(100)      NOT NULL,
    Guest_Phone VARCHAR(20)       NOT NULL,
    Visit_Date  DATE              NOT NULL,
    Daily_Rate  DECIMAL(10,2)     NOT NULL,

    CONSTRAINT PK_DAILY_PASS_TICKET
        PRIMARY KEY (Ticket_ID),

    CONSTRAINT UQ_DPT_Phone_VisitDate
        UNIQUE (Guest_Phone, Visit_Date),

    CONSTRAINT CK_DPT_Rate
        CHECK (Daily_Rate > 0.00)
);
GO


-- Table 3: MEMBERSHIP_PLAN

CREATE TABLE dbo.MEMBERSHIP_PLAN (
    Plan_ID         INT IDENTITY(1,1) NOT NULL,
    Plan_Name       VARCHAR(100)      NOT NULL,
    Duration_Months INT               NOT NULL,
    Price           DECIMAL(10,2)     NOT NULL,
    Description     VARCHAR(255)      NULL,

    CONSTRAINT PK_MEMBERSHIP_PLAN
        PRIMARY KEY (Plan_ID),

    CONSTRAINT UQ_PLAN_Name
        UNIQUE (Plan_Name),

    CONSTRAINT CK_PLAN_Duration
        CHECK (Duration_Months > 0),

    CONSTRAINT CK_PLAN_Price
        CHECK (Price > 0.00)
);
GO


-- Table 4: MEMBERSHIP

CREATE TABLE dbo.MEMBERSHIP (
    Membership_ID INT IDENTITY(1,1) NOT NULL,
    Member_ID     INT               NOT NULL,
    Plan_ID       INT               NOT NULL,
    Start_Date    DATE              NOT NULL,
    End_Date      DATE              NOT NULL,
    Status        VARCHAR(20)       NOT NULL,

    CONSTRAINT PK_MEMBERSHIP
        PRIMARY KEY (Membership_ID),

    CONSTRAINT FK_MEMBERSHIP_MEMBER
        FOREIGN KEY (Member_ID)
        REFERENCES dbo.MEMBER (Member_ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_MEMBERSHIP_PLAN
        FOREIGN KEY (Plan_ID)
        REFERENCES dbo.MEMBERSHIP_PLAN (Plan_ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT CK_MEMBERSHIP_Dates
        CHECK (End_Date > Start_Date),

    CONSTRAINT CK_MEMBERSHIP_Status
        CHECK (
            Status IN (
                'Active',
                'Expired',
                'Cancelled'
            )
        )
);
GO


/* ---------------------------------------------------------------------
   BR-MEM-06: Single Active Membership

   A member may have multiple historical memberships.

   Do not add UNIQUE(Member_ID).

   Overlapping active membership periods must be checked
   in a later trigger or transaction-safe validation procedure.
   --------------------------------------------------------------------- */


-- Table 5: BILLING_LOG

CREATE TABLE dbo.BILLING_LOG (
    Bill_ID        INT IDENTITY(1,1) NOT NULL,
    Membership_ID  INT               NULL,
    Ticket_ID      INT               NULL,
    Invoice_Date   DATE              NOT NULL,
    Due_Date       DATE              NULL,
    Payment_Date   DATE              NULL,
    Amount_Paid    DECIMAL(10,2)     NOT NULL,
    Billing_Status VARCHAR(20)       NOT NULL,

    CONSTRAINT PK_BILLING_LOG
        PRIMARY KEY (Bill_ID),

    CONSTRAINT FK_BILL_MEMBERSHIP
        FOREIGN KEY (Membership_ID)
        REFERENCES dbo.MEMBERSHIP (Membership_ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_BILL_TICKET
        FOREIGN KEY (Ticket_ID)
        REFERENCES dbo.DAILY_PASS_TICKET (Ticket_ID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    -- BR-MEM-09: Exactly one billing source.

    CONSTRAINT CK_BILL_Exclusive_Source
        CHECK (
            (
                Membership_ID IS NOT NULL
                AND Ticket_ID IS NULL
            )
            OR
            (
                Membership_ID IS NULL
                AND Ticket_ID IS NOT NULL
            )
        ),

    -- BR-MEM-11: Amount must not be negative.

    CONSTRAINT CK_BILL_Amount
        CHECK (Amount_Paid >= 0.00),

    -- BR-MEM-10: Allowed billing statuses.

    CONSTRAINT CK_BILL_Status
        CHECK (
            Billing_Status IN (
                'Pending',
                'Paid',
                'Failed'
            )
        ),

    -- BR-MEM-11: Payment date must match billing status.

    CONSTRAINT CK_BILL_Payment_Date
        CHECK (
            (
                Billing_Status = 'Paid'
                AND Payment_Date IS NOT NULL
            )
            OR
            (
                Billing_Status IN ('Pending', 'Failed')
                AND Payment_Date IS NULL
            )
        )
);
GO


/* =====================================================================
   BR-MEM-10: One Billing Record per Purchase

   SQL Server filtered unique indexes prevent duplicate invoices
   for the same Membership or Daily Pass Ticket.
   ===================================================================== */


-- One billing record per membership purchase.

CREATE UNIQUE INDEX UX_BILL_Membership_NotNull
ON dbo.BILLING_LOG (Membership_ID)
WHERE Membership_ID IS NOT NULL;
GO


-- One billing record per daily-pass purchase.

CREATE UNIQUE INDEX UX_BILL_Ticket_NotNull
ON dbo.BILLING_LOG (Ticket_ID)
WHERE Ticket_ID IS NOT NULL;
GO


/* =====================================================================
   Remaining Business Rules for Later Scripts

   BR-MEM-06:
   Prevent overlapping active membership periods.

   BR-MEM-08:
   Prevent overlapping membership and daily-pass access.

   BR-MEM-10:
   Create purchase records and billing records atomically
   using transactions.

   BR-MEM-13:
   Grant access only when membership dates, status and payment
   satisfy the access requirements.

   ===================================================================== */


-- 2) Quick check: list the five tables created by Trieu Quang.

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME IN (
      'MEMBER',
      'DAILY_PASS_TICKET',
      'MEMBERSHIP_PLAN',
      'MEMBERSHIP',
      'BILLING_LOG'
  )
ORDER BY TABLE_NAME;
GO

-- END OF SCRIPT 01 - NGUYEN LUU TRIEU QUANG
