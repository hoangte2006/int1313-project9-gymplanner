/* =====================================================================
   Gym Membership & Personal Training Planner  -  Team Dong Vui (#9)
   INT1313 - Database Basics
   Phase 3 - Script 03 (DESIGN B): indexes

   Run after 01_create_tables.sql, 04_sample_data.sql and 02_triggers.sql.
   PRIMARY KEY and UNIQUE constraints already create their own indexes;
   the ones below are extra.
   ===================================================================== */

USE GymPlanner_dev;
GO

/* ---------------------------------------------------------------------
   BR-MEM-06 (one active membership per member) is enforced by the trigger
   trg_MEMBERSHIP_NoActiveOverlap in script 02, not by an index, because the
   rule compares date ranges. BR-MEM-10 (one bill per purchase) is enforced
   by the filtered unique indexes UX_BILL_Membership_NotNull and
   UX_BILL_Ticket_NotNull, which script 01 already creates.
   --------------------------------------------------------------------- */

/* ---------------------------------------------------------------------
   NFR-PER: speed up the overlap checks of BR-SCH-03 and BR-SCH-04, which
   search SESSION by room or trainer and by time range.
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_SESSION_Room_Time
    ON dbo.[SESSION] (Room_ID, Start_Time, End_Time);
GO

CREATE NONCLUSTERED INDEX IX_SESSION_Trainer_Time
    ON dbo.[SESSION] (Trainer_ID, Start_Time, End_Time);
GO

/* ---------------------------------------------------------------------
   Foreign-key columns that are searched often but are not the first column
   of a primary key: "classes of a member", "PT bookings of a member",
   "reservations of a session".
   --------------------------------------------------------------------- */
CREATE NONCLUSTERED INDEX IX_CLASS_REG_Member
    ON dbo.CLASS_REGISTRATION (Member_ID);
GO

CREATE NONCLUSTERED INDEX IX_PT_BOOKING_Member
    ON dbo.PT_BOOKING (Member_ID);
GO

CREATE NONCLUSTERED INDEX IX_SEU_Session
    ON dbo.SESSION_EQUIPMENT_USAGE (Session_ID);
GO

-- List the indexes that were created by this script
SELECT OBJECT_NAME(i.object_id) AS On_Table, i.name AS Index_Name,
       i.is_unique, i.has_filter, i.filter_definition
FROM sys.indexes i
WHERE i.name IN ('IX_SESSION_Room_Time', 'IX_SESSION_Trainer_Time',
                 'IX_CLASS_REG_Member', 'IX_PT_BOOKING_Member', 'IX_SEU_Session')
ORDER BY On_Table, Index_Name;
GO
