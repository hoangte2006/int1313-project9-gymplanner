/* =====================================================================
   Gym Membership & Personal Training Planner  -  Team Dong Vui (#9)
   INT1313 - Database Basics
   Phase 3 - Script 07 (DESIGN B): checks at scale (run after 06_bulk_data.sql)

   Part A: the rules still work with thousands of rows (each test is rolled back).
   Part B: typical queries, with and without the index (compare logical reads).
   Part C: how long a rule-checked INSERT takes on the large tables.
   Dates are computed from today, like the data of script 06.
   ===================================================================== */
USE GymPlanner_dev;
GO

-- Read date literals as year-month-day on every server language setting
SET DATEFORMAT ymd;
GO

/* ---------------- PART A: rules at scale ---------------- */
-- Each test must END with an error (that is the expected result).
-- The expected error number is written in the comment above each test.

-- A1. Expected: error 50013 (BR-SCH-03, room already used)
BEGIN TRAN;
BEGIN TRY
    DECLARE @r INT, @t INT, @s DATETIME, @e DATETIME;
    SELECT TOP 1 @r = s.Room_ID, @s = s.Start_Time, @e = s.End_Time
    FROM dbo.[SESSION] AS s
    INNER JOIN dbo.CLASS AS c ON c.Session_ID = s.Session_ID
    WHERE s.Session_ID >= 1001 AND c.Status = 'Scheduled'
    ORDER BY s.Session_ID;
    -- a trainer who is free at that time: the last trainer of the bulk data is used,
    -- the room is the one that is already busy
    SELECT TOP 1 @t = Staff_ID FROM dbo.TRAINER WHERE Staff_ID >= 1001 ORDER BY Staff_ID DESC;
    INSERT INTO dbo.[SESSION] (Session_Type, Room_ID, Trainer_ID, Start_Time, End_Time) VALUES ('Class', @r, @t, @s, @e);
    PRINT 'A1 WRONG: the insert was accepted';
END TRY
BEGIN CATCH
    PRINT 'A1 ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- A2. Expected: error 50001 (second Active membership with overlapping dates, BR-MEM-06)
BEGIN TRAN;
BEGIN TRY
    DECLARE @m INT;
    SELECT TOP 1 @m = Member_ID FROM dbo.MEMBERSHIP WHERE Membership_ID >= 1001 AND Status = 'Active';
    INSERT INTO dbo.MEMBERSHIP (Member_ID, Plan_ID, Start_Date, End_Date, Status)
    VALUES (@m, 1, CAST(GETDATE() AS DATE), DATEADD(DAY, 30, CAST(GETDATE() AS DATE)), 'Active');
    PRINT 'A2 WRONG: the insert was accepted';
END TRY
BEGIN CATCH
    PRINT 'A2 ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- A3. Expected: error 50012 (BR-SCH-02, class is full)
-- Fills one class to Max_Capacity, then adds one more member.
BEGIN TRAN;
BEGIN TRY
    DECLARE @c INT, @max INT;
    SELECT TOP 1 @c = c.Session_ID, @max = c.Max_Capacity
    FROM dbo.CLASS AS c WHERE c.Session_ID >= 1001 AND c.Status = 'Scheduled' ORDER BY c.Session_ID;
    -- remove current registrations of this class, then fill every seat
    DELETE FROM dbo.CLASS_REGISTRATION WHERE Session_ID = @c;
    INSERT INTO dbo.CLASS_REGISTRATION (Session_ID, Member_ID, Attendance_Status)
    SELECT TOP (@max) @c, Member_ID, 'Confirmed' FROM dbo.MEMBERSHIP
    WHERE Membership_ID >= 1001 AND Status = 'Active' ORDER BY Member_ID;
    -- one more member -> must fail
    INSERT INTO dbo.CLASS_REGISTRATION (Session_ID, Member_ID, Attendance_Status)
    SELECT TOP 1 @c, Member_ID, 'Confirmed' FROM dbo.MEMBERSHIP
    WHERE Membership_ID >= 1001 AND Status = 'Active' ORDER BY Member_ID DESC;
    PRINT 'A3 WRONG: the insert was accepted';
END TRY
BEGIN CATCH
    PRINT 'A3 ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- A4. Expected: error 50017 (BR-SCH-05, member has no active membership)
BEGIN TRAN;
BEGIN TRY
    DECLARE @cl INT, @v INT;
    SELECT TOP 1 @cl = Session_ID FROM dbo.CLASS WHERE Session_ID >= 1001 AND Status = 'Scheduled' ORDER BY Session_ID DESC;
    SELECT TOP 1 @v = mb.Member_ID FROM dbo.MEMBER AS mb
    WHERE mb.Member_ID >= 1001
      AND NOT EXISTS (SELECT 1 FROM dbo.MEMBERSHIP AS ms WHERE ms.Member_ID = mb.Member_ID AND ms.Status = 'Active');
    INSERT INTO dbo.CLASS_REGISTRATION (Session_ID, Member_ID) VALUES (@cl, @v);
    PRINT 'A4 WRONG: the insert was accepted';
END TRY
BEGIN CATCH
    PRINT 'A4 ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- A5. Expected: error 50002 (BR-MEM-08, daily pass on a day when the same phone has an Active membership)
BEGIN TRAN;
BEGIN TRY
    DECLARE @ph VARCHAR(20);
    SELECT TOP 1 @ph = mb.Phone_Number
    FROM dbo.MEMBER AS mb
    INNER JOIN dbo.MEMBERSHIP AS ms ON ms.Member_ID = mb.Member_ID AND ms.Status = 'Active'
    WHERE mb.Member_ID >= 1001
    ORDER BY mb.Member_ID;
    INSERT INTO dbo.DAILY_PASS_TICKET (Guest_Name, Guest_Phone, Visit_Date, Daily_Rate)
    VALUES ('Test Guest', @ph, CAST(GETDATE() AS DATE), 15.00);
    PRINT 'A5 WRONG: the insert was accepted';
END TRY
BEGIN CATCH
    PRINT 'A5 ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- A6. Expected: error 50021 (BR-FAC-06, equipment not Active)
BEGIN TRAN;
BEGIN TRY
    DECLARE @eq INT, @ss INT, @f DATETIME, @tt DATETIME;
    SELECT TOP 1 @eq = Equipment_ID FROM dbo.EQUIPMENT WHERE Equipment_ID >= 1001 AND Operational_Status = 'Broken';
    SELECT TOP 1 @ss = Session_ID, @f = Start_Time, @tt = End_Time FROM dbo.[SESSION] WHERE Session_ID >= 1001 ORDER BY Session_ID DESC;
    INSERT INTO dbo.SESSION_EQUIPMENT_USAGE (Equipment_ID, Session_ID, Reserved_From, Reserved_To) VALUES (@eq, @ss, @f, @tt);
    PRINT 'A6 WRONG: the insert was accepted';
END TRY
BEGIN CATCH
    PRINT 'A6 ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

/* ---------------- PART B: speed of typical queries ---------------- */
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- B1. Timetable of one room for one week (starting today), WITH the index IX_SESSION_Room_Time
SELECT Session_ID, Session_Type, Trainer_ID, Start_Time, End_Time
FROM dbo.[SESSION] WITH (INDEX(IX_SESSION_Room_Time))
WHERE Room_ID = 1001
  AND Start_Time >= CAST(CAST(GETDATE() AS DATE) AS DATETIME)
  AND Start_Time <  DATEADD(DAY, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME))
ORDER BY Start_Time;
GO
-- B1 again, WITHOUT the index (full scan of the table)
SELECT Session_ID, Session_Type, Trainer_ID, Start_Time, End_Time
FROM dbo.[SESSION] WITH (INDEX(0))
WHERE Room_ID = 1001
  AND Start_Time >= CAST(CAST(GETDATE() AS DATE) AS DATETIME)
  AND Start_Time <  DATEADD(DAY, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME))
ORDER BY Start_Time;
GO

-- B2. Weekly schedule of one trainer, WITH and WITHOUT the index
SELECT Session_ID, Room_ID, Start_Time
FROM dbo.[SESSION] WITH (INDEX(IX_SESSION_Trainer_Time))
WHERE Trainer_ID = 1001
  AND Start_Time >= CAST(CAST(GETDATE() AS DATE) AS DATETIME)
  AND Start_Time <  DATEADD(DAY, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
GO
SELECT Session_ID, Room_ID, Start_Time
FROM dbo.[SESSION] WITH (INDEX(0))
WHERE Trainer_ID = 1001
  AND Start_Time >= CAST(CAST(GETDATE() AS DATE) AS DATETIME)
  AND Start_Time <  DATEADD(DAY, 7, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
GO

-- B3. All classes of one member, WITH and WITHOUT the index IX_CLASS_REG_Member
SELECT r.Session_ID, r.Attendance_Status
FROM dbo.CLASS_REGISTRATION AS r WITH (INDEX(IX_CLASS_REG_Member))
WHERE r.Member_ID = 1001;
GO
SELECT r.Session_ID, r.Attendance_Status
FROM dbo.CLASS_REGISTRATION AS r WITH (INDEX(0))
WHERE r.Member_ID = 1001;
GO

-- B4. Report: seats taken per class (join of 3 tables, 2,600 classes)
SELECT TOP 10 c.Session_ID, c.Class_Name, c.Max_Capacity,
       COUNT(r.Member_ID) AS Seats_Taken
FROM dbo.CLASS AS c
JOIN dbo.CLASS_REGISTRATION AS r ON r.Session_ID = c.Session_ID AND r.Attendance_Status <> 'Cancelled'
GROUP BY c.Session_ID, c.Class_Name, c.Max_Capacity
ORDER BY Seats_Taken DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

/* ---------------- PART C: INSERT with all triggers on, at scale ---------------- */
-- Inserts 200 valid sessions 400 days from today (a free period; rolled back afterwards).
-- Every row goes through trg_SESSION_NoOverlap and the other session triggers.
BEGIN TRAN;
DECLARE @t0 DATETIME2 = SYSDATETIME();
DECLARE @base DATETIME = DATEADD(DAY, 400, CAST(CAST(GETDATE() AS DATE) AS DATETIME));
;WITH n AS (SELECT TOP (200) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS k FROM sys.all_objects)
INSERT INTO dbo.[SESSION] (Session_Type, Room_ID, Trainer_ID, Start_Time, End_Time)
SELECT 'Class', 1001 + (k % 8), 1001 + (k % 25),
       DATEADD(HOUR, 1 + (k / 8), @base),
       DATEADD(HOUR, 2 + (k / 8), @base)
FROM n;
SELECT 200 AS Rows_Inserted, DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS Milliseconds;
ROLLBACK;
GO
