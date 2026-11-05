/* =====================================================================
   Gym Membership & Personal Training Planner  -  Team Dong Vui (#9)
   INT1313 - Database Basics
   Phase 3 - Script 11 (DESIGN B): tests for the access rights (RBAC)

   Run after script 10, with an administrator login, on the sample data.
   Each test pretends to be one demo user (EXECUTE AS USER), tries one action
   inside a transaction, and then undoes everything (ROLLBACK), so the data
   is never changed.
   Expected = what the permissions of script 10 should do:
     allowed = the action works     denied = SQL Server refuses it
                                    (error 229, 230 or 262: permission denied)
   Any other error number is shown as "error <number>" and counts as FAIL.
   The last result grid lists every test with PASS or FAIL.
   ===================================================================== */

USE GymPlanner_dev;
GO

SET DATEFORMAT ymd;
SET NOCOUNT ON;

DECLARE @results TABLE (
    Test_No       INT,
    Test_User     VARCHAR(20),
    Action_Tested VARCHAR(60),
    Expected      VARCHAR(10),
    Actual        VARCHAR(20)
);
DECLARE @actual VARCHAR(20);
DECLARE @err    INT;
DECLARE @n      INT;

/* T1: gym_member - Read the view vw_Class_Schedule (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_member';
    SELECT @n = COUNT(*) FROM dbo.vw_Class_Schedule;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (1, 'gym_member', 'Read the view vw_Class_Schedule', 'allowed', @actual);

/* T2: gym_member - Read the view vw_Trainer_Public (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_member';
    SELECT @n = COUNT(*) FROM dbo.vw_Trainer_Public;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (2, 'gym_member', 'Read the view vw_Trainer_Public', 'allowed', @actual);

/* T3: gym_member - Read the table MEMBERSHIP_PLAN (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_member';
    SELECT @n = COUNT(*) FROM dbo.MEMBERSHIP_PLAN;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (3, 'gym_member', 'Read the table MEMBERSHIP_PLAN', 'allowed', @actual);

/* T4: gym_member - Read the table STAFF (salaries) (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_member';
    SELECT @n = COUNT(*) FROM dbo.STAFF;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (4, 'gym_member', 'Read the table STAFF (salaries)', 'denied', @actual);

/* T5: gym_member - Read the table BILLING_LOG (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_member';
    SELECT @n = COUNT(*) FROM dbo.BILLING_LOG;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (5, 'gym_member', 'Read the table BILLING_LOG', 'denied', @actual);

/* T6: gym_member - Insert a row into MEMBER (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_member';
    INSERT INTO dbo.MEMBER (Full_Name, Phone_Number, Registration_Date) VALUES ('Test User', '0999999999', CAST(GETDATE() AS DATE));
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (6, 'gym_member', 'Insert a row into MEMBER', 'denied', @actual);

/* T7: gym_reception - Read the table MEMBER (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_reception';
    SELECT @n = COUNT(*) FROM dbo.MEMBER;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (7, 'gym_reception', 'Read the table MEMBER', 'allowed', @actual);

/* T8: gym_reception - Read the table STAFF (salaries) (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_reception';
    SELECT @n = COUNT(*) FROM dbo.STAFF;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (8, 'gym_reception', 'Read the table STAFF (salaries)', 'denied', @actual);

/* T9: gym_reception - Delete from MEMBERSHIP (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_reception';
    DELETE FROM dbo.MEMBERSHIP WHERE Membership_ID = -1;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (9, 'gym_reception', 'Delete from MEMBERSHIP', 'denied', @actual);

/* T10: gym_reception - Record a payment: Billing_Status and Payment_Date (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_reception';
    UPDATE dbo.BILLING_LOG SET Billing_Status = 'Paid', Payment_Date = CAST(GETDATE() AS DATE) WHERE Bill_ID = 3;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (10, 'gym_reception', 'Record a payment: Billing_Status and Payment_Date', 'allowed', @actual);

/* T11: gym_reception - Change the Due_Date of a bill (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_reception';
    UPDATE dbo.BILLING_LOG SET Due_Date = '2030-01-01' WHERE Bill_ID = 3;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (11, 'gym_reception', 'Change the Due_Date of a bill', 'denied', @actual);

/* T12: gym_trainer - Read the table BILLING_LOG (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_trainer';
    SELECT @n = COUNT(*) FROM dbo.BILLING_LOG;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (12, 'gym_trainer', 'Read the table BILLING_LOG', 'denied', @actual);

/* T13: gym_trainer - Read the column MEMBER.Full_Name (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_trainer';
    SELECT @n = COUNT(Full_Name) FROM dbo.MEMBER;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (13, 'gym_trainer', 'Read the column MEMBER.Full_Name', 'allowed', @actual);

/* T14: gym_trainer - Read the column MEMBER.Phone_Number (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_trainer';
    SELECT @n = COUNT(Phone_Number) FROM dbo.MEMBER;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (14, 'gym_trainer', 'Read the column MEMBER.Phone_Number', 'denied', @actual);

/* T15: gym_trainer - Mark attendance: update Attendance_Status (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_trainer';
    UPDATE dbo.CLASS_REGISTRATION SET Attendance_Status = 'Attended' WHERE Session_ID = 1 AND Member_ID = 1;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (15, 'gym_trainer', 'Mark attendance: update Attendance_Status', 'allowed', @actual);

/* T16: gym_trainer - Change the member of a PT booking (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_trainer';
    UPDATE dbo.PT_BOOKING SET Member_ID = 2 WHERE Session_ID = 4;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (16, 'gym_trainer', 'Change the member of a PT booking', 'denied', @actual);

/* T17: gym_manager - Update a salary in STAFF (expect: allowed) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_manager';
    UPDATE dbo.STAFF SET Salary = Salary WHERE Staff_ID = 1;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (17, 'gym_manager', 'Update a salary in STAFF', 'allowed', @actual);

/* T18: gym_manager - Delete from BILLING_LOG (DENY) (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_manager';
    DELETE FROM dbo.BILLING_LOG WHERE Bill_ID = -1;
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (18, 'gym_manager', 'Delete from BILLING_LOG (DENY)', 'denied', @actual);

/* T19: gym_manager - Create a table (design change) (expect: denied) */
SET @actual = 'allowed';
BEGIN TRY
    BEGIN TRAN;
    EXECUTE AS USER = 'gym_manager';
    CREATE TABLE dbo.tmp_permission_check (a INT);
    REVERT;
    ROLLBACK;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    IF @@TRANCOUNT > 0 ROLLBACK;
    IF USER_NAME() LIKE 'gym[_]%' REVERT;
    SET @actual = CASE WHEN @err IN (229, 230, 262) THEN 'denied'
                       ELSE 'error ' + CAST(@err AS VARCHAR(10)) END;
END CATCH;
INSERT INTO @results VALUES (19, 'gym_manager', 'Create a table (design change)', 'denied', @actual);

/* ---- Result: one row per test, then the totals ---- */
SELECT
    Test_No,
    Test_User,
    Action_Tested,
    Expected,
    Actual,
    CASE WHEN Expected = Actual THEN 'PASS' ELSE 'FAIL' END AS Result
FROM @results
ORDER BY Test_No;

SELECT
    COUNT(*)                                              AS Tests,
    SUM(CASE WHEN Expected = Actual THEN 1 ELSE 0 END)    AS Passed,
    SUM(CASE WHEN Expected <> Actual THEN 1 ELSE 0 END)   AS Failed
FROM @results;
GO
