/* =====================================================================
   Script 06b (DESIGN B): remove the bulk data added by 06_bulk_data.sql
   Deletes only rows whose ID is 1001 or higher; sample data (04) stays.
   Database: GymPlanner_dev
   ===================================================================== */
USE GymPlanner_dev;
GO
DELETE FROM dbo.SESSION_EQUIPMENT_USAGE WHERE Usage_ID >= 1001;
DELETE FROM dbo.CLASS_REGISTRATION      WHERE Session_ID >= 1001;
DELETE FROM dbo.PT_BOOKING              WHERE Session_ID >= 1001;
DELETE FROM dbo.CLASS                   WHERE Session_ID >= 1001;
DELETE FROM dbo.[SESSION]               WHERE Session_ID >= 1001;
DELETE FROM dbo.MAINTENANCE_LOG         WHERE Equipment_ID >= 1001;
DELETE FROM dbo.EQUIPMENT               WHERE Equipment_ID >= 1001;
DELETE FROM dbo.ROOM                    WHERE Room_ID >= 1001;
DELETE FROM dbo.RECEPTIONIST            WHERE Staff_ID >= 1001;
DELETE FROM dbo.TRAINER                 WHERE Staff_ID >= 1001;
DELETE FROM dbo.STAFF                   WHERE Staff_ID >= 1001;
DELETE FROM dbo.BILLING_LOG             WHERE Bill_ID >= 1001;
DELETE FROM dbo.MEMBERSHIP              WHERE Membership_ID >= 1001;
DELETE FROM dbo.DAILY_PASS_TICKET       WHERE Ticket_ID >= 1001;
DELETE FROM dbo.MEMBER                  WHERE Member_ID >= 1001;
GO
-- After the delete, the IDENTITY counters stay high. To make the next
-- sample rows start from the old numbers again, run DBCC CHECKIDENT with RESEED.
