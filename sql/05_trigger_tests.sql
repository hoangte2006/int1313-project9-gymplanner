/* =====================================================================
   Gym Membership & Personal Training Planner  -  Team Dong Vui (#9)
   INT1313 - Database Basics
   Script 05 (DESIGN B): trigger and constraint tests
   Database: GymPlanner_dev

   Run order: 01 -> 04 -> 02 -> 03 -> 05
   Run AFTER 04 (sample data) and 02 (triggers). Every test runs in its own
   transaction and is rolled back, so the data is never changed.

   T01-T22: must be BLOCKED. The Messages tab prints
            'Tnn PASS - blocked, error <number>' when the expected error comes.
   A01-A10: must be ACCEPTED. They print 'Ann PASS - accepted'.
   Anything else prints FAIL with the reason.
   Take the screenshot from the Messages tab.
   ===================================================================== */
USE GymPlanner_dev;
GO
SET DATEFORMAT ymd;
GO

-- T01: Membership overlaps an Active one of the same member (member 1)  (expected error 50001)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.MEMBERSHIP (Member_ID,Plan_ID,Start_Date,End_Date,Status) VALUES (1,1,@T,DATEADD(DAY,30,@T),'Active');
  PRINT 'T01 FAIL - not blocked: Membership overlaps an Active one of the same member (member 1)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50001
    PRINT 'T01 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T01 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50001): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T02: Daily pass on a day the same phone has an Active membership (member 1)  (expected error 50002)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.DAILY_PASS_TICKET (Guest_Name,Guest_Phone,Visit_Date,Daily_Rate) VALUES ('Test','0912000001',@T,15.00);
  PRINT 'T02 FAIL - not blocked: Daily pass on a day the same phone has an Active membership (member 1)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50002
    PRINT 'T02 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T02 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50002): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T03: Membership overlaps a daily pass of the same phone (member 6)  (expected error 50003)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.DAILY_PASS_TICKET (Guest_Name,Guest_Phone,Visit_Date,Daily_Rate) VALUES ('Giang Dang','0912000006',DATEADD(DAY,3,@T),15.00);
  INSERT INTO dbo.MEMBERSHIP (Member_ID,Plan_ID,Start_Date,End_Date,Status) VALUES (6,1,@T,DATEADD(DAY,30,@T),'Active');
  PRINT 'T03 FAIL - not blocked: Membership overlaps a daily pass of the same phone (member 6)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50003
    PRINT 'T03 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T03 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50003): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T04: Phone change makes member 3 overlap a daily pass (ticket 2)  (expected error 50004)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  UPDATE dbo.MEMBER SET Phone_Number='0912000008' WHERE Member_ID=3;
  PRINT 'T04 FAIL - not blocked: Phone change makes member 3 overlap a daily pass (ticket 2)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50004
    PRINT 'T04 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T04 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50004): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T05: PT booking by a member without an Active membership (member 5)  (expected error 50005)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('PT',3,6,DATEADD(HOUR,9,DATEADD(DAY,20,@T)),DATEADD(HOUR,10,DATEADD(DAY,20,@T)));
  INSERT INTO dbo.PT_BOOKING (Session_ID,Member_ID,Booking_Status) VALUES (SCOPE_IDENTITY(),5,'Scheduled');
  PRINT 'T05 FAIL - not blocked: PT booking by a member without an Active membership (member 5)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50005
    PRINT 'T05 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T05 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50005): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T06: Manager (staff 5) added as Trainer  (expected error 50026)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.TRAINER (Staff_ID,Specialty,Certification) VALUES (5,'Yoga',NULL);
  PRINT 'T06 FAIL - not blocked: Manager (staff 5) added as Trainer';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50026
    PRINT 'T06 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T06 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50026): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T07: Trainer (staff 1) also added as Receptionist (50008 or 50027)  (expected error 50008)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.RECEPTIONIST (Staff_ID,Shift_Type) VALUES (1,'Morning');
  PRINT 'T07 FAIL - not blocked: Trainer (staff 1) also added as Receptionist (50008 or 50027)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50008
    PRINT 'T07 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T07 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50008): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T08: Class Max_Capacity 10 is larger than room capacity 4 (PT Studio)  (expected error 50009)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',3,2,DATEADD(HOUR,14,DATEADD(DAY,20,@T)),DATEADD(HOUR,15,DATEADD(DAY,20,@T)));
  INSERT INTO dbo.CLASS (Session_ID,Class_Name,Max_Capacity,Status) VALUES (SCOPE_IDENTITY(),'Too big',10,'Scheduled');
  PRINT 'T08 FAIL - not blocked: Class Max_Capacity 10 is larger than room capacity 4 (PT Studio)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50009
    PRINT 'T08 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T08 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50009): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T09: Room 2 capacity lowered to 2, smaller than class 2 (Max_Capacity 3)  (expected error 50011)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  UPDATE dbo.ROOM SET Capacity=2 WHERE Room_ID=2;
  PRINT 'T09 FAIL - not blocked: Room 2 capacity lowered to 2, smaller than class 2 (Max_Capacity 3)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50011
    PRINT 'T09 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T09 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50011): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T10: Class 2 is full (3 seats); member 3 tries to take a seat again  (expected error 50012)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  UPDATE dbo.CLASS_REGISTRATION SET Attendance_Status='Confirmed' WHERE Session_ID=2 AND Member_ID=3;
  PRINT 'T10 FAIL - not blocked: Class 2 is full (3 seats); member 3 tries to take a seat again';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50012
    PRINT 'T10 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T10 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50012): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T11: Class registration by a member without an Active membership (member 5)  (expected error 50017)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.CLASS_REGISTRATION (Session_ID,Member_ID,Registration_Date,Attendance_Status) VALUES (6,5,GETDATE(),'Confirmed');
  PRINT 'T11 FAIL - not blocked: Class registration by a member without an Active membership (member 5)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50017
    PRINT 'T11 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T11 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50017): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T12: Session overlaps session 1 in the same room (room 1)  (expected error 50013)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',1,2,DATEADD(MINUTE,450,DATEADD(DAY,5,@T)),DATEADD(MINUTE,510,DATEADD(DAY,5,@T)));
  PRINT 'T12 FAIL - not blocked: Session overlaps session 1 in the same room (room 1)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50013
    PRINT 'T12 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T12 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50013): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T13: Session overlaps session 1 for the same trainer (trainer 1, room 2)  (expected error 50014)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',2,1,DATEADD(MINUTE,450,DATEADD(DAY,5,@T)),DATEADD(MINUTE,510,DATEADD(DAY,5,@T)));
  PRINT 'T13 FAIL - not blocked: Session overlaps session 1 for the same trainer (trainer 1, room 2)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50014
    PRINT 'T13 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T13 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50014): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T14: CLASS attached to a PT session (session 4)  (expected error 50018)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.CLASS (Session_ID,Class_Name,Max_Capacity,Status) VALUES (4,'Wrong type',3,'Scheduled');
  PRINT 'T14 FAIL - not blocked: CLASS attached to a PT session (session 4)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50018
    PRINT 'T14 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T14 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50018): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T15: PT booking attached to a Class session (session 1)  (expected error 50019)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.PT_BOOKING (Session_ID,Member_ID,Booking_Status) VALUES (1,3,'Scheduled');
  PRINT 'T15 FAIL - not blocked: PT booking attached to a Class session (session 1)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50019
    PRINT 'T15 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T15 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50019): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T16: Session type changed after it has a CLASS row (session 1 to PT)  (expected error 50020)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  UPDATE dbo.[SESSION] SET Session_Type='PT' WHERE Session_ID=1;
  PRINT 'T16 FAIL - not blocked: Session type changed after it has a CLASS row (session 1 to PT)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50020
    PRINT 'T16 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T16 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50020): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T17: Reserve equipment that is Under Maintenance (equipment 4)  (expected error 50021)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.SESSION_EQUIPMENT_USAGE (Equipment_ID,Session_ID,Reserved_From,Reserved_To) VALUES (4,4,DATEADD(HOUR,9,DATEADD(DAY,5,@T)),DATEADD(HOUR,10,DATEADD(DAY,5,@T)));
  PRINT 'T17 FAIL - not blocked: Reserve equipment that is Under Maintenance (equipment 4)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50021
    PRINT 'T17 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T17 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50021): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T18: Reservation outside the session time (50023 or 50024)  (expected error 50023)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.SESSION_EQUIPMENT_USAGE (Equipment_ID,Session_ID,Reserved_From,Reserved_To) VALUES (2,4,DATEADD(HOUR,8,DATEADD(DAY,5,@T)),DATEADD(HOUR,11,DATEADD(DAY,5,@T)));
  PRINT 'T18 FAIL - not blocked: Reservation outside the session time (50023 or 50024)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50023
    PRINT 'T18 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T18 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50023): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T19: Session moved so an existing reservation is outside it (session 1)  (expected error 50025)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  UPDATE dbo.[SESSION] SET Start_Time=DATEADD(HOUR,12,DATEADD(DAY,5,@T)), End_Time=DATEADD(HOUR,13,DATEADD(DAY,5,@T)) WHERE Session_ID=1;
  PRINT 'T19 FAIL - not blocked: Session moved so an existing reservation is outside it (session 1)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50025
    PRINT 'T19 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T19 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50025): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T20: Maintenance log signed by a Trainer (staff 1)  (expected error 50022)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.MAINTENANCE_LOG (Equipment_ID,Log_no,Maintenance_Date,Cost,Description,Logged_By) VALUES (2,1,@T,10.00,'Test',1);
  PRINT 'T20 FAIL - not blocked: Maintenance log signed by a Trainer (staff 1)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 50022
    PRINT 'T20 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T20 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 50022): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T21: Bill with NO source: Membership_ID and Ticket_ID both NULL (CHECK, error 547)  (expected error 547)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.BILLING_LOG (Membership_ID,Ticket_ID,Invoice_Date,Due_Date,Payment_Date,Amount_Paid,Billing_Status) VALUES (NULL,NULL,@T,@T,@T,10.00,'Paid');
  PRINT 'T21 FAIL - not blocked: Bill with NO source: Membership_ID and Ticket_ID both NULL (CHECK, error 547)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 547
    PRINT 'T21 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T21 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 547): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- T22: Second bill for membership 1 (unique index, error 2601)  (expected error 2601)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.BILLING_LOG (Membership_ID,Ticket_ID,Invoice_Date,Due_Date,Payment_Date,Amount_Paid,Billing_Status) VALUES (1,NULL,@T,@T,@T,10.00,'Paid');
  PRINT 'T22 FAIL - not blocked: Second bill for membership 1 (unique index, error 2601)';
  IF @@TRANCOUNT > 0 ROLLBACK;
END TRY
BEGIN CATCH
  IF ERROR_NUMBER() = 2601
    PRINT 'T22 PASS - blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  ELSE
    PRINT 'T22 CHECK - blocked by error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ' (expected 2601): ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A01: Member 6 buys a first Active membership (no overlap)  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.MEMBERSHIP (Member_ID,Plan_ID,Start_Date,End_Date,Status) VALUES (6,1,@T,DATEADD(DAY,30,@T),'Active');
  PRINT 'A01 PASS - accepted: Member 6 buys a first Active membership (no overlap)';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A01 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A02: Adjacent dates: member 4 renews exactly at End_Date of the Active one (T+10)  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.MEMBERSHIP (Member_ID,Plan_ID,Start_Date,End_Date,Status) VALUES (4,1,DATEADD(DAY,10,@T),DATEADD(DAY,40,@T),'Active');
  PRINT 'A02 PASS - accepted: Adjacent dates: member 4 renews exactly at End_Date of the Active one (T+10)';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A02 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A03: Daily pass for a phone with no membership  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.DAILY_PASS_TICKET (Guest_Name,Guest_Phone,Visit_Date,Daily_Rate) VALUES ('New Guest','0912000099',@T,15.00);
  PRINT 'A03 PASS - accepted: Daily pass for a phone with no membership';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A03 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A04: Class with NULL room (room not assigned yet)  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',NULL,2,DATEADD(HOUR,12,DATEADD(DAY,25,@T)),DATEADD(HOUR,13,DATEADD(DAY,25,@T)));
  PRINT 'A04 PASS - accepted: Class with NULL room (room not assigned yet)';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A04 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A05: Cancelled class (session 10, room 2) does not block a new session in the same room/time  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',2,1,DATEADD(HOUR,18,DATEADD(DAY,8,@T)),DATEADD(HOUR,19,DATEADD(DAY,8,@T)));
  PRINT 'A05 PASS - accepted: Cancelled class (session 10, room 2) does not block a new session in the same room/time';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A05 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A06: Member 1 (Active) books a PT session  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('PT',3,2,DATEADD(HOUR,9,DATEADD(DAY,20,@T)),DATEADD(HOUR,10,DATEADD(DAY,20,@T)));
  INSERT INTO dbo.PT_BOOKING (Session_ID,Member_ID,Booking_Status) VALUES (SCOPE_IDENTITY(),1,'Scheduled');
  PRINT 'A06 PASS - accepted: Member 1 (Active) books a PT session';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A06 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A07: BR-SCH-01: a new staff member with Role = Trainer becomes a TRAINER  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.STAFF (Full_Name,Phone,Role,Hire_Date,Salary) VALUES ('Test Trainer','0909999991','Trainer','2026-01-01',700.00);
  INSERT INTO dbo.TRAINER (Staff_ID,Specialty,Certification) VALUES (SCOPE_IDENTITY(),'Test',NULL);
  PRINT 'A07 PASS - accepted: BR-SCH-01: a new staff member with Role = Trainer becomes a TRAINER';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A07 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A08: BR-SCH-02: class Max_Capacity equal to the room Capacity (room 1, 20)  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',1,2,DATEADD(HOUR,6,DATEADD(DAY,30,@T)),DATEADD(HOUR,7,DATEADD(DAY,30,@T)));
  INSERT INTO dbo.CLASS (Session_ID,Class_Name,Max_Capacity,Status) VALUES (SCOPE_IDENTITY(),'Boundary class',20,'Scheduled');
  PRINT 'A08 PASS - accepted: BR-SCH-02: class Max_Capacity equal to the room Capacity (room 1, 20)';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A08 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A09: BR-SCH-04: back-to-back sessions of the same trainer (touching, no overlap)  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',1,1,DATEADD(HOUR,9,DATEADD(DAY,40,@T)),DATEADD(HOUR,10,DATEADD(DAY,40,@T)));
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',2,1,DATEADD(HOUR,10,DATEADD(DAY,40,@T)),DATEADD(HOUR,11,DATEADD(DAY,40,@T)));
  PRINT 'A09 PASS - accepted: BR-SCH-04: back-to-back sessions of the same trainer (touching, no overlap)';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A09 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO

-- A10: BR-SCH-06: CLASS attached to a Class session  (must be accepted)
BEGIN TRY
  BEGIN TRAN;
  DECLARE @T DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
  INSERT INTO dbo.[SESSION] (Session_Type,Room_ID,Trainer_ID,Start_Time,End_Time) VALUES ('Class',1,2,DATEADD(HOUR,15,DATEADD(DAY,35,@T)),DATEADD(HOUR,16,DATEADD(DAY,35,@T)));
  INSERT INTO dbo.CLASS (Session_ID,Class_Name,Max_Capacity,Status) VALUES (SCOPE_IDENTITY(),'Right type',10,'Scheduled');
  PRINT 'A10 PASS - accepted: BR-SCH-06: CLASS attached to a Class session';
  ROLLBACK;
END TRY
BEGIN CATCH
  PRINT 'A10 FAIL - wrongly blocked, error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
  IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH;
GO
