/* =====================================================================
   Gym Membership & Personal Training Planner  -  Team Dong Vui (#9)
   INT1313 - Database Basics
   Script 04 (DESIGN B): sample data
   Database: GymPlanner_dev

   Authors: Te (data for all 16 tables; Quang and Phuong may adjust their part)

   Run order: 01_create_tables.sql -> 04_sample_data.sql -> 02_triggers.sql
              -> 03_indexes.sql -> 05_trigger_tests.sql
   Load the data BEFORE the triggers (some triggers use the current date).
   Run on EMPTY tables: IDENTITY must start at 1, because the rows below
   refer to each other by ID number.

   All dates are computed from TODAY (@T), so the data stays valid on any
   day the script is run and the tests do not break when the date changes.
   Example: @T + 5 days is "five days from today".

   The data follows the business rules, so it will also be accepted by the
   triggers of script 02:
   - MEMBER (1-6) and DAILY_PASS_TICKET (1-3) are independent; no member has
     an Active membership on the date of a ticket with the same phone
   - each member has at most one 'Active' membership at a time
   - only members with an active membership are registered for classes and PT
   - no two sessions overlap in the same room or for the same trainer
   - session 9 has no room yet (Room_ID NULL); class 10 is 'Cancelled'
   - equipment is reserved only while 'Active', inside the session time
   - maintenance logs are signed by a Receptionist or the Manager
   ===================================================================== */

USE GymPlanner_dev;
GO

-- Read date literals as year-month-day on every server language setting
SET DATEFORMAT ymd;
GO

/* ---------------------------------------------------------------------
   Optional reset (comment block). Use only to wipe the data and reload.
   --------------------------------------------------------------------- */
/*
DELETE FROM dbo.SESSION_EQUIPMENT_USAGE;
DELETE FROM dbo.MAINTENANCE_LOG;
DELETE FROM dbo.EQUIPMENT;
DELETE FROM dbo.PT_BOOKING;
DELETE FROM dbo.CLASS_REGISTRATION;
DELETE FROM dbo.CLASS;
DELETE FROM dbo.[SESSION];
DELETE FROM dbo.ROOM;
DELETE FROM dbo.RECEPTIONIST;
DELETE FROM dbo.TRAINER;
DELETE FROM dbo.STAFF;
DELETE FROM dbo.BILLING_LOG;
DELETE FROM dbo.MEMBERSHIP;
DELETE FROM dbo.MEMBERSHIP_PLAN;
DELETE FROM dbo.DAILY_PASS_TICKET;
DELETE FROM dbo.MEMBER;
DBCC CHECKIDENT ('dbo.SESSION_EQUIPMENT_USAGE', RESEED, 0);
DBCC CHECKIDENT ('dbo.EQUIPMENT', RESEED, 0);
DBCC CHECKIDENT ('dbo.[SESSION]', RESEED, 0);
DBCC CHECKIDENT ('dbo.ROOM', RESEED, 0);
DBCC CHECKIDENT ('dbo.STAFF', RESEED, 0);
DBCC CHECKIDENT ('dbo.BILLING_LOG', RESEED, 0);
DBCC CHECKIDENT ('dbo.MEMBERSHIP', RESEED, 0);
DBCC CHECKIDENT ('dbo.MEMBERSHIP_PLAN', RESEED, 0);
DBCC CHECKIDENT ('dbo.DAILY_PASS_TICKET', RESEED, 0);
DBCC CHECKIDENT ('dbo.MEMBER', RESEED, 0);
GO
*/

/* All inserts run in ONE batch (no GO in between) so the date variables
   below stay available. */
DECLARE @T  DATE     = CAST(GETDATE() AS DATE);          -- today
DECLARE @d5 DATETIME = CAST(DATEADD(DAY,  5, @T) AS DATETIME);   -- today + 5
DECLARE @d6 DATETIME = CAST(DATEADD(DAY,  6, @T) AS DATETIME);
DECLARE @d7 DATETIME = CAST(DATEADD(DAY,  7, @T) AS DATETIME);
DECLARE @d8 DATETIME = CAST(DATEADD(DAY,  8, @T) AS DATETIME);
DECLARE @d9 DATETIME = CAST(DATEADD(DAY,  9, @T) AS DATETIME);
DECLARE @p2 DATETIME = CAST(DATEADD(DAY, -2, @T) AS DATETIME);   -- 2 days ago (already held)

/* =====================================================================
   1) MEMBER: 6 members (IDs 1-6)
   Photo is optional (BR-MEM-01): members 1-5 have a small placeholder
   (0xFFD8FFE0 = start of a JPEG file); member 6 has none, and can still
   buy a membership.
   ===================================================================== */
INSERT INTO dbo.MEMBER (Full_Name, Phone_Number, Email, Birth_Date, Photo, Registration_Date) VALUES
('An Nguyen',   '0912000001', 'an.nguyen@example.com',  '1998-04-12', 0xFFD8FFE0, DATEADD(DAY, -200, @T)),  -- 1
('Binh Tran',   '0912000002', 'binh.tran@example.com',  '2001-09-30', 0xFFD8FFE0, DATEADD(DAY,  -90, @T)),  -- 2
('Cuong Le',    '0912000003', 'cuong.le@example.com',   '1995-01-18', 0xFFD8FFE0, DATEADD(DAY,  -40, @T)),  -- 3
('Dung Pham',   '0912000004', 'dung.pham@example.com',  '2000-06-05', 0xFFD8FFE0, DATEADD(DAY, -150, @T)),  -- 4 (expired + renewed)
('Em Vo',       '0912000005', 'em.vo@example.com',      '2003-11-22', 0xFFD8FFE0, DATEADD(DAY, -120, @T)),  -- 5 (cancelled membership)
('Giang Dang',  '0912000006', NULL,                     NULL,         NULL,       DATEADD(DAY,   -3, @T));  -- 6 (no photo, no email, no membership yet)

/* 2) DAILY_PASS_TICKET: independent one-day guests (IDs 1-3)
   Ticket 3 belongs to the phone of member 4 on a day when member 4 had only an
   Expired membership, so BR-MEM-08 allows it. */
INSERT INTO dbo.DAILY_PASS_TICKET (Guest_Name, Guest_Phone, Visit_Date, Daily_Rate) VALUES
('Huy Do',     '0912000007', DATEADD(DAY,   -7, @T), 15.00),   -- 1
('Lan Bui',    '0912000008', DATEADD(DAY,   -6, @T), 15.00),   -- 2
('Dung Pham',  '0912000004', DATEADD(DAY, -100, @T), 15.00);   -- 3

/* =====================================================================
   3) MEMBERSHIP_PLAN
   ===================================================================== */
INSERT INTO dbo.MEMBERSHIP_PLAN (Plan_Name, Duration_Months, Price, Description) VALUES
('Monthly',   1,  30.00, 'One month, access to all open gym areas'),
('Quarterly', 3,  80.00, 'Three months, access to all open gym areas'),
('Annual',   12, 280.00, 'Twelve months, access to all open gym areas');

/* 4) MEMBERSHIP (member 4 has an Expired one and a newer Active one)
   End_Date is exclusive: a membership covers [Start_Date, End_Date). */
INSERT INTO dbo.MEMBERSHIP (Member_ID, Plan_ID, Start_Date, End_Date, Status) VALUES
(1, 3, DATEADD(DAY,  -60, @T), DATEADD(DAY,  305, @T), 'Active'),     -- 1
(2, 2, DATEADD(DAY,  -30, @T), DATEADD(DAY,   60, @T), 'Active'),     -- 2
(3, 1, DATEADD(DAY,  -10, @T), DATEADD(DAY,   20, @T), 'Active'),     -- 3
(4, 1, DATEADD(DAY, -120, @T), DATEADD(DAY,  -90, @T), 'Expired'),    -- 4
(5, 2, DATEADD(DAY,  -90, @T), DATEADD(DAY,    0, @T), 'Cancelled'),  -- 5
(4, 1, DATEADD(DAY,  -20, @T), DATEADD(DAY,   10, @T), 'Active');     -- 6

/* 5) BILLING_LOG: exactly one source per bill (membership OR daily pass),
   one bill per purchase. Paid has a Payment_Date; Pending/Failed have none. */
INSERT INTO dbo.BILLING_LOG
    (Membership_ID, Ticket_ID, Invoice_Date, Due_Date, Payment_Date, Amount_Paid, Billing_Status) VALUES
(1,    NULL, DATEADD(DAY,  -60, @T), DATEADD(DAY,  -53, @T), DATEADD(DAY,  -59, @T), 280.00, 'Paid'),     -- 1
(2,    NULL, DATEADD(DAY,  -30, @T), DATEADD(DAY,  -23, @T), DATEADD(DAY,  -30, @T),  80.00, 'Paid'),     -- 2
(3,    NULL, DATEADD(DAY,  -10, @T), DATEADD(DAY,   -3, @T), NULL,                     0.00, 'Pending'),  -- 3 not paid yet
(4,    NULL, DATEADD(DAY, -120, @T), DATEADD(DAY, -113, @T), DATEADD(DAY, -120, @T),  30.00, 'Paid'),     -- 4
(5,    NULL, DATEADD(DAY,  -90, @T), DATEADD(DAY,  -83, @T), NULL,                     0.00, 'Failed'),   -- 5 card declined
(6,    NULL, DATEADD(DAY,  -20, @T), DATEADD(DAY,  -13, @T), DATEADD(DAY,  -20, @T),  30.00, 'Paid'),     -- 6
(NULL, 1,    DATEADD(DAY,   -7, @T), DATEADD(DAY,   -7, @T), DATEADD(DAY,   -7, @T),  15.00, 'Paid'),     -- 7 daily pass
(NULL, 2,    DATEADD(DAY,   -6, @T), DATEADD(DAY,   -6, @T), DATEADD(DAY,   -6, @T),  15.00, 'Paid'),     -- 8 daily pass
(NULL, 3,    DATEADD(DAY, -100, @T), DATEADD(DAY, -100, @T), DATEADD(DAY, -100, @T),  15.00, 'Paid');     -- 9 daily pass

/* =====================================================================
   6) STAFF: 3 trainers, 2 receptionists, 1 manager
   ===================================================================== */
INSERT INTO dbo.STAFF (Full_Name, Phone, Role, Hire_Date, Salary) VALUES
('Khoa Nguyen Minh', '0901000001', 'Trainer',      '2025-03-01', 800.00),   -- 1
('Ha Tran Thu',      '0901000002', 'Trainer',      '2025-06-15', 850.00),   -- 2
('Trang Le Thu',     '0901000003', 'Receptionist', '2025-04-10', 500.00),   -- 3
('Long Pham Hai',    '0901000004', 'Receptionist', '2025-08-20', 500.00),   -- 4
('Phuong Vu Mai',    '0901000005', 'Manager',      '2024-01-05', 1200.00),  -- 5
('Duc Hoang Anh',    '0901000006', 'Trainer',      '2026-02-01', 780.00);   -- 6

INSERT INTO dbo.TRAINER (Staff_ID, Specialty, Certification) VALUES
(1, 'Yoga',     'RYT-200'),
(2, 'Strength', 'NASM-CPT'),
(6, 'Cardio',   NULL);

INSERT INTO dbo.RECEPTIONIST (Staff_ID, Shift_Type) VALUES
(3, 'Morning'),
(4, 'Evening');

/* =====================================================================
   7) ROOM, EQUIPMENT, MAINTENANCE_LOG
   ===================================================================== */
INSERT INTO dbo.ROOM (Room_Name, Capacity, Floor_Location) VALUES
('Yoga Room',   20, 'Floor 1'),   -- 1
('Cardio Zone', 30, 'Floor 2'),   -- 2
('PT Studio',    4, 'Floor 1');   -- 3

INSERT INTO dbo.EQUIPMENT (Equipment_Name, Room_ID, Operational_Status, Purchase_Date) VALUES
('Treadmill T-01',      2, 'Active',            '2024-05-10'),   -- 1
('Spin Bike S-01',      2, 'Active',            '2024-06-01'),   -- 2
('Yoga Mat Set',        1, 'Active',            '2025-01-15'),   -- 3
('Cable Machine C-01',  3, 'Under Maintenance', '2023-11-20'),   -- 4
('Rowing Machine R-01', 2, 'Broken',            '2023-09-02'),   -- 5
('Barbell Set B-01',    3, 'Active',            '2024-02-18');   -- 6

INSERT INTO dbo.MAINTENANCE_LOG (Equipment_ID, Log_no, Maintenance_Date, Cost, Description, Logged_By) VALUES
(1, 1, DATEADD(DAY, -80, @T),  45.00, 'Routine belt lubrication',             3),
(4, 1, DATEADD(DAY,  -2, @T), 120.00, 'Replace worn cable, waiting for test', 3),
(5, 1, DATEADD(DAY, -10, @T),   0.00, 'Motor fault, waiting for spare part',   5);

/* =====================================================================
   8) SESSION, CLASS, PT_BOOKING
   Classes: sessions 1,2,3,6,7,9,10   PT bookings: sessions 4,5,8
   Session 7 and 8 have already been held. Session 9 has no room yet.
   Class 10 is cancelled (it does not block its room, trainer or equipment).
   ===================================================================== */
INSERT INTO dbo.[SESSION] (Session_Type, Room_ID, Trainer_ID, Start_Time, End_Time) VALUES
('Class', 1,    1, DATEADD(HOUR,  7, @d5), DATEADD(HOUR,  8, @d5)),   -- 1 Yoga Flow
('Class', 2,    2, DATEADD(HOUR, 18, @d5), DATEADD(HOUR, 19, @d5)),   -- 2 HIIT Burn (small, 3 seats)
('Class', 1,    1, DATEADD(HOUR,  7, @d6), DATEADD(HOUR,  8, @d6)),   -- 3 Yoga Flow
('PT',    3,    2, DATEADD(HOUR,  9, @d5), DATEADD(HOUR, 10, @d5)),   -- 4 PT
('PT',    3,    1, DATEADD(HOUR,  9, @d6), DATEADD(HOUR, 10, @d6)),   -- 5 PT
('Class', 2,    6, DATEADD(HOUR, 18, @d7), DATEADD(HOUR, 19, @d7)),   -- 6 Spinning
('Class', 1,    1, DATEADD(HOUR,  7, @p2), DATEADD(HOUR,  8, @p2)),   -- 7 Yoga Flow (already held)
('PT',    3,    2, DATEADD(HOUR,  9, @p2), DATEADD(HOUR, 10, @p2)),   -- 8 PT (already held)
('Class', NULL, 6, DATEADD(HOUR, 10, @d9), DATEADD(HOUR, 11, @d9)),   -- 9 Pilates Intro (room not assigned yet)
('Class', 2,    6, DATEADD(HOUR, 18, @d8), DATEADD(HOUR, 19, @d8));   -- 10 Zumba Party (cancelled)

INSERT INTO dbo.CLASS (Session_ID, Class_Name, Max_Capacity, Status) VALUES
(1,  'Yoga Flow',      15, 'Scheduled'),
(2,  'HIIT Burn',       3, 'Scheduled'),
(3,  'Yoga Flow',      15, 'Scheduled'),
(6,  'Spinning',       25, 'Scheduled'),
(7,  'Yoga Flow',      15, 'Completed'),
(9,  'Pilates Intro',  15, 'Scheduled'),
(10, 'Zumba Party',    20, 'Cancelled');

INSERT INTO dbo.PT_BOOKING (Session_ID, Member_ID, Booking_Status) VALUES
(4, 1, 'Scheduled'),
(5, 2, 'Scheduled'),
(8, 3, 'Completed');

/* 9) CLASS_REGISTRATION
   Class 2 (3 seats): 3 seats are taken ('Confirmed'); member 3 'Cancelled'
   does not hold a seat.
   Class 7 already took place: two members 'Attended', one 'Cancelled'. */
INSERT INTO dbo.CLASS_REGISTRATION (Session_ID, Member_ID, Registration_Date, Attendance_Status) VALUES
(1, 1, DATEADD(HOUR,  9, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(1, 2, DATEADD(HOUR, 10, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(1, 3, DATEADD(HOUR, 11, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(2, 1, DATEADD(HOUR,  9, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(2, 2, DATEADD(HOUR, 10, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(2, 4, DATEADD(HOUR, 12, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(2, 3, DATEADD(HOUR, 11, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Cancelled'),
(3, 4, DATEADD(HOUR, 12, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(6, 1, DATEADD(HOUR,  9, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(6, 2, DATEADD(HOUR, 10, CAST(DATEADD(DAY, -1, @T) AS DATETIME)), 'Confirmed'),
(7, 1, DATEADD(HOUR,  8, CAST(DATEADD(DAY, -4, @T) AS DATETIME)), 'Attended'),
(7, 2, DATEADD(HOUR,  8, CAST(DATEADD(DAY, -4, @T) AS DATETIME)), 'Attended'),
(7, 3, DATEADD(HOUR,  8, CAST(DATEADD(DAY, -4, @T) AS DATETIME)), 'Cancelled');

/* 10) SESSION_EQUIPMENT_USAGE (Active equipment only, inside the session time) */
INSERT INTO dbo.SESSION_EQUIPMENT_USAGE (Equipment_ID, Session_ID, Reserved_From, Reserved_To) VALUES
(3, 1, DATEADD(HOUR,  7, @d5), DATEADD(HOUR,  8, @d5)),   -- Yoga mats for class 1
(1, 2, DATEADD(HOUR, 18, @d5), DATEADD(HOUR, 19, @d5)),   -- Treadmill for class 2
(3, 3, DATEADD(HOUR,  7, @d6), DATEADD(HOUR,  8, @d6)),   -- Yoga mats for class 3
(6, 4, DATEADD(HOUR,  9, @d5), DATEADD(HOUR, 10, @d5)),   -- Barbell for PT 4
(6, 5, DATEADD(HOUR,  9, @d6), DATEADD(HOUR, 10, @d6)),   -- Barbell for PT 5
(2, 6, DATEADD(HOUR, 18, @d7), DATEADD(HOUR, 19, @d7)),   -- Spin bike for class 6
(3, 7, DATEADD(HOUR,  7, @p2), DATEADD(HOUR,  8, @p2));   -- Yoga mats for class 7
GO

/* =====================================================================
   Checks: expected row counts
   MEMBER 6, DAILY_PASS_TICKET 3, MEMBERSHIP_PLAN 3, MEMBERSHIP 6,
   BILLING_LOG 9, STAFF 6, TRAINER 3, RECEPTIONIST 2, ROOM 3, SESSION 10,
   CLASS 7, PT_BOOKING 3, CLASS_REGISTRATION 13, EQUIPMENT 6,
   MAINTENANCE_LOG 3, SESSION_EQUIPMENT_USAGE 7   (total 90 rows)
   ===================================================================== */
SELECT 'MEMBER' AS Table_Name, COUNT(*) AS Rows_Count FROM dbo.MEMBER
UNION ALL SELECT 'DAILY_PASS_TICKET',       COUNT(*) FROM dbo.DAILY_PASS_TICKET
UNION ALL SELECT 'MEMBERSHIP_PLAN',         COUNT(*) FROM dbo.MEMBERSHIP_PLAN
UNION ALL SELECT 'MEMBERSHIP',              COUNT(*) FROM dbo.MEMBERSHIP
UNION ALL SELECT 'BILLING_LOG',             COUNT(*) FROM dbo.BILLING_LOG
UNION ALL SELECT 'STAFF',                   COUNT(*) FROM dbo.STAFF
UNION ALL SELECT 'TRAINER',                 COUNT(*) FROM dbo.TRAINER
UNION ALL SELECT 'RECEPTIONIST',            COUNT(*) FROM dbo.RECEPTIONIST
UNION ALL SELECT 'ROOM',                    COUNT(*) FROM dbo.ROOM
UNION ALL SELECT 'SESSION',                 COUNT(*) FROM dbo.[SESSION]
UNION ALL SELECT 'CLASS',                   COUNT(*) FROM dbo.CLASS
UNION ALL SELECT 'PT_BOOKING',              COUNT(*) FROM dbo.PT_BOOKING
UNION ALL SELECT 'CLASS_REGISTRATION',      COUNT(*) FROM dbo.CLASS_REGISTRATION
UNION ALL SELECT 'EQUIPMENT',               COUNT(*) FROM dbo.EQUIPMENT
UNION ALL SELECT 'MAINTENANCE_LOG',         COUNT(*) FROM dbo.MAINTENANCE_LOG
UNION ALL SELECT 'SESSION_EQUIPMENT_USAGE', COUNT(*) FROM dbo.SESSION_EQUIPMENT_USAGE;
GO

-- Seats taken per class (every registration that is not 'Cancelled')
SELECT c.Session_ID, c.Class_Name, c.Max_Capacity,
       COUNT(r.Member_ID)                    AS Seats_Taken,
       c.Max_Capacity - COUNT(r.Member_ID)   AS Seats_Left
FROM dbo.CLASS c
LEFT JOIN dbo.CLASS_REGISTRATION r
       ON r.Session_ID = c.Session_ID AND r.Attendance_Status <> 'Cancelled'
GROUP BY c.Session_ID, c.Class_Name, c.Max_Capacity
ORDER BY c.Session_ID;
GO
