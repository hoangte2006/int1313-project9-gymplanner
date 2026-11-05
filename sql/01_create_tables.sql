/* =====================================================================
   Gym Membership & Personal Training Planner  -  Team Dong Vui (#9)
   INT1313 - Database Basics
   Script 01 (DESIGN B): create database and 16 tables (DDL)
   Target: Microsoft SQL Server 2016 SP1+ (T-SQL), run in SSMS
   Database: GymPlanner_dev (separate from the old design-A database GymPlanner)

   Sources: Report section 1.2 (rules), 2.2 (schema), 2.2.3 (FK policy),
            3 (Data Dictionary)

   Authors:
   - Nguyen Luu Trieu Quang : MEMBER, DAILY_PASS_TICKET, MEMBERSHIP_PLAN,
                              MEMBERSHIP, BILLING_LOG (tables 1-5)
   - Nguyen Van Hoang Te    : STAFF, TRAINER, RECEPTIONIST, ROOM, SESSION, CLASS,
                              CLASS_REGISTRATION, PT_BOOKING (tables 6-13, written
                              for Tran Duc Phuong, absent on 04/11),
                              EQUIPMENT, MAINTENANCE_LOG, SESSION_EQUIPMENT_USAGE
                              (tables 14-16)

   Design B: no VISITOR. MEMBER and DAILY_PASS_TICKET are independent strong
   entities. BILLING_LOG points to exactly one of MEMBERSHIP or DAILY_PASS_TICKET.

   Notes
   - SQL Server has no RESTRICT keyword: RESTRICT in the report = NO ACTION.
   - ON UPDATE is NO ACTION everywhere (all PKs are IDENTITY, never updated).
   - Triggers are in script 02, the other indexes in script 03.
   ===================================================================== */

IF DB_ID(N'GymPlanner_dev') IS NULL
    CREATE DATABASE GymPlanner_dev;
GO

USE GymPlanner_dev;
GO

/* ---------------------------------------------------------------------
   Optional reset: remove all tables so the script can be run again.
   Uncomment ONLY when you want to delete everything and start over.
   --------------------------------------------------------------------- */
-- DROP TABLE IF EXISTS dbo.SESSION_EQUIPMENT_USAGE;
-- DROP TABLE IF EXISTS dbo.MAINTENANCE_LOG;
-- DROP TABLE IF EXISTS dbo.CLASS_REGISTRATION;
-- DROP TABLE IF EXISTS dbo.PT_BOOKING;
-- DROP TABLE IF EXISTS dbo.CLASS;
-- DROP TABLE IF EXISTS dbo.[SESSION];
-- DROP TABLE IF EXISTS dbo.EQUIPMENT;
-- DROP TABLE IF EXISTS dbo.ROOM;
-- DROP TABLE IF EXISTS dbo.RECEPTIONIST;
-- DROP TABLE IF EXISTS dbo.TRAINER;
-- DROP TABLE IF EXISTS dbo.STAFF;
-- DROP TABLE IF EXISTS dbo.BILLING_LOG;
-- DROP TABLE IF EXISTS dbo.MEMBERSHIP;
-- DROP TABLE IF EXISTS dbo.MEMBERSHIP_PLAN;
-- DROP TABLE IF EXISTS dbo.DAILY_PASS_TICKET;
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

/* =====================================================================
   STAFF  (Staff_ID is the key of the subclasses too)
   ===================================================================== */

-- Table 6: STAFF (superclass)
CREATE TABLE dbo.STAFF (
    Staff_ID  INT IDENTITY(1,1) NOT NULL,
    Full_Name VARCHAR(100)      NOT NULL,
    Phone     VARCHAR(15)       NOT NULL,
    Role      VARCHAR(30)       NOT NULL
        CONSTRAINT DF_STAFF_Role DEFAULT 'Receptionist',
    Hire_Date DATE              NOT NULL
        CONSTRAINT DF_STAFF_HireDate DEFAULT CAST(GETDATE() AS DATE),
    Salary    DECIMAL(10,2)     NOT NULL
        CONSTRAINT DF_STAFF_Salary DEFAULT 500.00,
    CONSTRAINT PK_STAFF        PRIMARY KEY (Staff_ID),
    CONSTRAINT UQ_STAFF_Phone  UNIQUE (Phone),
    CONSTRAINT CK_STAFF_Role   CHECK (Role IN ('Trainer','Receptionist','Manager')),
    CONSTRAINT CK_STAFF_Salary CHECK (Salary > 0.00)
);
GO

-- Table 7: TRAINER (subclass of STAFF)
CREATE TABLE dbo.TRAINER (
    Staff_ID      INT          NOT NULL,
    Specialty     VARCHAR(50)  NOT NULL
        CONSTRAINT DF_TRAINER_Specialty DEFAULT 'General',
    Certification VARCHAR(100) NULL,
    CONSTRAINT PK_TRAINER PRIMARY KEY (Staff_ID),
    CONSTRAINT FK_TRAINER_STAFF FOREIGN KEY (Staff_ID)
        REFERENCES dbo.STAFF (Staff_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION
);
GO

-- Table 8: RECEPTIONIST (subclass of STAFF)
CREATE TABLE dbo.RECEPTIONIST (
    Staff_ID   INT         NOT NULL,
    Shift_Type VARCHAR(20) NOT NULL
        CONSTRAINT DF_RECEP_Shift DEFAULT 'Morning',
    CONSTRAINT PK_RECEPTIONIST PRIMARY KEY (Staff_ID),
    CONSTRAINT FK_RECEP_STAFF FOREIGN KEY (Staff_ID)
        REFERENCES dbo.STAFF (Staff_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT CK_RECEP_Shift CHECK (Shift_Type IN ('Morning','Evening','Night'))
);
GO

/* =====================================================================
   ROOMS, SESSIONS, CLASSES, PT BOOKINGS  (Te does this part for Phuong)
   ===================================================================== */

-- Table 9: ROOM
CREATE TABLE dbo.ROOM (
    Room_ID        INT IDENTITY(1,1) NOT NULL,
    Room_Name      VARCHAR(50)       NOT NULL,
    Capacity       INT               NOT NULL
        CONSTRAINT DF_ROOM_Capacity DEFAULT 20,
    Floor_Location VARCHAR(30)       NULL
        CONSTRAINT DF_ROOM_Floor DEFAULT 'Floor 1',
    CONSTRAINT PK_ROOM      PRIMARY KEY (Room_ID),
    CONSTRAINT UQ_ROOM_Name UNIQUE (Room_Name),
    CONSTRAINT CK_ROOM_Capacity CHECK (Capacity > 0)
);
GO

-- Table 10: SESSION (superclass of CLASS and PT_BOOKING)
-- Room_ID may be NULL: a session can exist before a room is assigned (HOSTS is partial).
CREATE TABLE dbo.[SESSION] (
    Session_ID   INT IDENTITY(1,1) NOT NULL,
    Session_Type VARCHAR(10)       NOT NULL,
    Room_ID      INT               NULL,
    Trainer_ID   INT               NOT NULL,
    Start_Time   DATETIME          NOT NULL,
    End_Time     DATETIME          NOT NULL,
    CONSTRAINT PK_SESSION PRIMARY KEY (Session_ID),
    CONSTRAINT FK_SESSION_ROOM FOREIGN KEY (Room_ID)
        REFERENCES dbo.ROOM (Room_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_SESSION_TRAINER FOREIGN KEY (Trainer_ID)
        REFERENCES dbo.TRAINER (Staff_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CK_SESSION_Type CHECK (Session_Type IN ('Class','PT')),
    CONSTRAINT CK_SESSION_Time CHECK (End_Time > Start_Time)
);
GO

-- Table 11: CLASS (subclass of SESSION)
-- NOTE: Status is kept because BR-FAC-10 ignores cancelled classes.
--       The report dictionary (Table 11) does not list it yet - decide at the meeting.
CREATE TABLE dbo.CLASS (
    Session_ID   INT         NOT NULL,
    Class_Name   VARCHAR(50) NOT NULL,
    Max_Capacity INT         NOT NULL
        CONSTRAINT DF_CLASS_MaxCap DEFAULT 20,
    Status       VARCHAR(20) NOT NULL
        CONSTRAINT DF_CLASS_Status DEFAULT 'Scheduled',
    CONSTRAINT PK_CLASS PRIMARY KEY (Session_ID),
    CONSTRAINT FK_CLASS_SESSION FOREIGN KEY (Session_ID)
        REFERENCES dbo.[SESSION] (Session_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT CK_CLASS_MaxCap CHECK (Max_Capacity > 0),
    CONSTRAINT CK_CLASS_Status CHECK (Status IN ('Scheduled','Completed','Cancelled'))
);
GO

-- Table 12: CLASS_REGISTRATION (composite PK; M:N REGISTER between MEMBER and CLASS)
CREATE TABLE dbo.CLASS_REGISTRATION (
    Session_ID        INT         NOT NULL,
    Member_ID         INT         NOT NULL,
    Registration_Date DATETIME    NOT NULL
        CONSTRAINT DF_CREG_Date DEFAULT CURRENT_TIMESTAMP,
    Attendance_Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_CREG_Status DEFAULT 'Confirmed',
    CONSTRAINT PK_CLASS_REGISTRATION PRIMARY KEY (Session_ID, Member_ID),
    CONSTRAINT FK_CREG_CLASS FOREIGN KEY (Session_ID)
        REFERENCES dbo.CLASS (Session_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT FK_CREG_MEMBER FOREIGN KEY (Member_ID)
        REFERENCES dbo.MEMBER (Member_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CK_CREG_Status CHECK (Attendance_Status IN ('Confirmed','Attended','Cancelled'))
);
GO

-- Table 13: PT_BOOKING (subclass of SESSION)
CREATE TABLE dbo.PT_BOOKING (
    Session_ID     INT         NOT NULL,
    Member_ID      INT         NOT NULL,
    Booking_Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_PT_Status DEFAULT 'Scheduled',
    CONSTRAINT PK_PT_BOOKING PRIMARY KEY (Session_ID),
    CONSTRAINT FK_PT_SESSION FOREIGN KEY (Session_ID)
        REFERENCES dbo.[SESSION] (Session_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT FK_PT_MEMBER FOREIGN KEY (Member_ID)
        REFERENCES dbo.MEMBER (Member_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CK_PT_Status CHECK (Booking_Status IN ('Scheduled','Completed','Cancelled'))
);
GO

/* =====================================================================
   FACILITY & MAINTENANCE DOMAIN  (Te)
   ===================================================================== */

-- Table 14: EQUIPMENT
CREATE TABLE dbo.EQUIPMENT (
    Equipment_ID       INT IDENTITY(1,1) NOT NULL,
    Equipment_Name     VARCHAR(100)      NOT NULL,
    Room_ID            INT               NULL,
    Operational_Status VARCHAR(20)       NOT NULL
        CONSTRAINT DF_EQUIP_Status DEFAULT 'Active',
    Purchase_Date      DATE              NULL,
    CONSTRAINT PK_EQUIPMENT PRIMARY KEY (Equipment_ID),
    CONSTRAINT FK_EQUIP_ROOM FOREIGN KEY (Room_ID)
        REFERENCES dbo.ROOM (Room_ID)
        ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT CK_EQUIP_Status CHECK (Operational_Status IN ('Active','Under Maintenance','Broken'))
);
GO

-- Table 15: MAINTENANCE_LOG (weak entity, composite PK)
CREATE TABLE dbo.MAINTENANCE_LOG (
    Equipment_ID     INT           NOT NULL,
    Log_no           INT           NOT NULL,
    Maintenance_Date DATE          NOT NULL
        CONSTRAINT DF_MLOG_Date DEFAULT CAST(GETDATE() AS DATE),
    Cost             DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_MLOG_Cost DEFAULT 0.00,
    Description      VARCHAR(255)  NOT NULL,
    Logged_By        INT           NOT NULL,
    CONSTRAINT PK_MAINTENANCE_LOG PRIMARY KEY (Equipment_ID, Log_no),
    CONSTRAINT FK_MLOG_EQUIPMENT FOREIGN KEY (Equipment_ID)
        REFERENCES dbo.EQUIPMENT (Equipment_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT FK_MLOG_STAFF FOREIGN KEY (Logged_By)
        REFERENCES dbo.STAFF (Staff_ID)
        ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT CK_MLOG_Cost CHECK (Cost >= 0.00)
);
GO

-- Table 16: SESSION_EQUIPMENT_USAGE (M:N USES between SESSION and EQUIPMENT)
CREATE TABLE dbo.SESSION_EQUIPMENT_USAGE (
    Usage_ID      INT IDENTITY(1,1) NOT NULL,
    Equipment_ID  INT               NOT NULL,
    Session_ID    INT               NOT NULL,
    Reserved_From DATETIME          NOT NULL,
    Reserved_To   DATETIME          NOT NULL,
    CONSTRAINT PK_SESSION_EQUIPMENT_USAGE PRIMARY KEY (Usage_ID),
    CONSTRAINT FK_SEU_EQUIPMENT FOREIGN KEY (Equipment_ID)
        REFERENCES dbo.EQUIPMENT (Equipment_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT FK_SEU_SESSION FOREIGN KEY (Session_ID)
        REFERENCES dbo.[SESSION] (Session_ID)
        ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT CK_SEU_Time CHECK (Reserved_To > Reserved_From)
);
GO

-- Quick check: list the 16 tables that were created
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
