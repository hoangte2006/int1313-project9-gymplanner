/* =====================================================================
   Team Dong Vui (#9) - Script 03b: delete ALL sample data in GymPlanner_dev
   and reset the IDENTITY counters, so 03_sample_data.sql can be run again.
   Tables and triggers are NOT touched. Only use on the dev database.
   ===================================================================== */
USE GymPlanner_dev;
GO

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
DELETE FROM dbo.VISITOR;
DBCC CHECKIDENT ('dbo.SESSION_EQUIPMENT_USAGE', RESEED, 0);
DBCC CHECKIDENT ('dbo.EQUIPMENT', RESEED, 0);
DBCC CHECKIDENT ('dbo.[SESSION]', RESEED, 0);
DBCC CHECKIDENT ('dbo.ROOM', RESEED, 0);
DBCC CHECKIDENT ('dbo.STAFF', RESEED, 0);
DBCC CHECKIDENT ('dbo.BILLING_LOG', RESEED, 0);
DBCC CHECKIDENT ('dbo.MEMBERSHIP', RESEED, 0);
DBCC CHECKIDENT ('dbo.MEMBERSHIP_PLAN', RESEED, 0);
DBCC CHECKIDENT ('dbo.VISITOR', RESEED, 0);
GO
GO
