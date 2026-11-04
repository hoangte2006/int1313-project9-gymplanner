
/* =====================================================================
   Gym Membership & Personal Training Planner - Team Dong Vui (#9)
   INT1313 - Database Basics
   Phase 3 - Script 02: triggers for the business rules

   Domain: Membership & Billing
   Author: Nguyen Luu Trieu Quang
   Target: Microsoft SQL Server (T-SQL), run in SSMS

   Source:
   Report_Gym_Planner_Merged_Final.docx
   BR-MEM-01 to BR-MEM-13

   Run order:
   01_create_tables.sql
   -> 02_triggers.sql
   -> 06_stored_procedures.sql
   -> 03_sample_data.sql
   -> Other scripts / tests

   How every trigger below works:
   - SQL Server uses AFTER triggers for these validations.
   - "inserted" contains all new or updated rows.
   - Triggers check all affected rows, not just one row.
   - THROW rejects changes that violate a business rule.
   - Membership dates use [Start_Date, End_Date).
   - End_Date is exclusive.
   - No automatic billing is performed in this script.

   Rule -> Trigger Map

   BR-MEM-01  Optional Photo; no photo-required trigger.
   BR-MEM-03  Member and Plan foreign keys (script 01).
   BR-MEM-05  Membership Status CHECK (script 01).
   BR-MEM-06  trg_MEMBERSHIP_NoActiveOverlap
   BR-MEM-07  Ticket UNIQUE constraint (script 01).
   BR-MEM-08  trg_TICKET_NoActiveMembership
              trg_MEMBERSHIP_NoOverlappingTicket
              trg_MEMBER_Phone_NoAccessOverlap
   BR-MEM-09  Billing XOR CHECK (script 01).
   BR-MEM-10  Filtered UNIQUE indexes (script 01)
              and stored procedures with transactions.
   BR-MEM-11  Billing CHECK constraints (script 01).
   BR-MEM-12  ON DELETE NO ACTION foreign keys (script 01).
   BR-MEM-13  Payment and date access validation
              (stored procedure/application).

   Error numbers: 50106 - 50109
   ===================================================================== */

USE GymPlanner_dev;
GO


/* =====================================================================
   BR-MEM-06: Single Active Membership

   Rule:
   A member may have multiple historical Membership records,
   but two Active Memberships cannot have overlapping periods.

   Date interval:
   [Start_Date, End_Date)

   Two intervals overlap when:
   Start1 < End2 AND Start2 < End1

   Examples:
   Active [2026-11-01, 2026-12-01)
   Active [2026-11-20, 2026-12-20)
   -> REJECT

   Active [2026-11-01, 2026-12-01)
   Active [2026-12-01, 2027-01-01)
   -> ACCEPT
   ===================================================================== */

CREATE OR ALTER TRIGGER dbo.trg_MEMBERSHIP_NoActiveOverlap
ON dbo.MEMBERSHIP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS new_ms

        JOIN dbo.MEMBER AS member_row
            WITH (UPDLOCK, HOLDLOCK)
            ON member_row.Member_ID = new_ms.Member_ID

        JOIN dbo.MEMBERSHIP AS other_ms
            WITH (UPDLOCK, HOLDLOCK)
            ON other_ms.Member_ID = new_ms.Member_ID
           AND other_ms.Membership_ID <> new_ms.Membership_ID

        WHERE new_ms.Status = 'Active'
          AND other_ms.Status = 'Active'

          AND new_ms.Start_Date < other_ms.End_Date
          AND other_ms.Start_Date < new_ms.End_Date
    )
    BEGIN
        THROW 50106,
              'BR-MEM-06: overlapping active Membership.',
              1;
    END
END;
GO


/* =====================================================================
   BR-MEM-08 (Part 1):
   Daily Pass Ticket must not overlap an Active Membership.

   Rule:
   A guest cannot purchase a Daily Pass Ticket on a date
   already covered by an Active Membership for the same
   identifiable person.

   Identification:
   DAILY_PASS_TICKET.Guest_Phone
   = MEMBER.Phone_Number

   Important:
   End_Date is exclusive.

   Correct condition:
   Visit_Date >= Start_Date
   AND Visit_Date < End_Date
   ===================================================================== */

CREATE OR ALTER TRIGGER dbo.trg_TICKET_NoActiveMembership
ON dbo.DAILY_PASS_TICKET
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS new_ticket

        JOIN dbo.MEMBER AS member_row
            WITH (UPDLOCK, HOLDLOCK)
            ON member_row.Phone_Number = new_ticket.Guest_Phone

        JOIN dbo.MEMBERSHIP AS ms
            WITH (UPDLOCK, HOLDLOCK)
            ON ms.Member_ID = member_row.Member_ID

        WHERE ms.Status = 'Active'

          AND new_ticket.Visit_Date >= ms.Start_Date
          AND new_ticket.Visit_Date < ms.End_Date
    )
    BEGIN
        THROW 50107,
              'BR-MEM-08: Daily Pass Ticket overlaps an active Membership.',
              1;
    END
END;
GO


/* =====================================================================
   BR-MEM-08 (Part 2):
   Active Membership must not overlap an existing Daily Pass.

   Rule:
   If a guest purchases a Daily Pass Ticket first,
   a new Active Membership must start after the ticket
   validity period ends.

   Example:

   Daily Pass Visit_Date = 2026-11-23

   Membership:
   Start_Date = 2026-11-23
   -> REJECT

   Membership:
   Start_Date = 2026-11-24
   -> ACCEPT (if no other rule is violated)
   ===================================================================== */

CREATE OR ALTER TRIGGER dbo.trg_MEMBERSHIP_NoOverlappingTicket
ON dbo.MEMBERSHIP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted AS new_ms

        JOIN dbo.MEMBER AS member_row
            WITH (UPDLOCK, HOLDLOCK)
            ON member_row.Member_ID = new_ms.Member_ID

        JOIN dbo.DAILY_PASS_TICKET AS ticket_row
            WITH (UPDLOCK, HOLDLOCK)
            ON ticket_row.Guest_Phone = member_row.Phone_Number

        WHERE new_ms.Status = 'Active'

          AND ticket_row.Visit_Date >= new_ms.Start_Date
          AND ticket_row.Visit_Date < new_ms.End_Date
    )
    BEGIN
        THROW 50108,
              'BR-MEM-08: active Membership overlaps an existing Daily Pass Ticket.',
              1;
    END
END;
GO


/* =====================================================================
   BR-MEM-08 (Part 3):
   Changing MEMBER.Phone_Number must not bypass BR-MEM-08.

   Rule:
   A member cannot change their phone number to a number
   associated with a Daily Pass Ticket whose Visit_Date
   overlaps an existing Active Membership period.

   Example:
   Member M001 has an Active Membership on 2026-11-23.

   A Daily Pass Ticket already exists for phone 0901234567
   on 2026-11-23.

   Updating M001.Phone_Number to 0901234567
   -> REJECT
   ===================================================================== */

CREATE OR ALTER TRIGGER dbo.trg_MEMBER_Phone_NoAccessOverlap
ON dbo.MEMBER
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Phone_Number)
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted AS member_row

        JOIN dbo.MEMBERSHIP AS ms
            WITH (UPDLOCK, HOLDLOCK)
            ON ms.Member_ID = member_row.Member_ID

        JOIN dbo.DAILY_PASS_TICKET AS ticket_row
            WITH (UPDLOCK, HOLDLOCK)
            ON ticket_row.Guest_Phone = member_row.Phone_Number

        WHERE ms.Status = 'Active'

          AND ticket_row.Visit_Date >= ms.Start_Date
          AND ticket_row.Visit_Date < ms.End_Date
    )
    BEGIN
        THROW 50109,
              'BR-MEM-08: member phone update creates an access overlap.',
              1;
    END
END;
GO


/* =====================================================================
   BILLING IMPLEMENTATION

   BR-MEM-09:
   Every BILLING_LOG must reference exactly one source:
   either Membership_ID or Ticket_ID, never both.

   Enforced by:
   CK_BILL_Exclusive_Source in 01_create_tables.sql.

   BR-MEM-10:
   Each Membership and each Daily Pass Ticket must have
   exactly one associated BILLING_LOG record.

   Enforced partially by:
   - UX_BILL_Membership_NotNull
   - UX_BILL_Ticket_NotNull

   These unique indexes prevent duplicate billing records.

   To guarantee purchase + bill creation together, use
   stored procedures with explicit transactions:

   usp_PurchaseMembership
   usp_PurchaseDailyPass

   These procedures belong to a separate SQL script.

   BR-MEM-11:
   - Amount_Paid >= 0
   - Billing_Status IN ('Pending','Paid','Failed')
   - Paid requires Payment_Date
   - Pending/Failed require NULL Payment_Date

   Enforced by CHECK constraints in script 01.

   BR-MEM-13:
   Membership access requires:
   - Status = 'Active'
   - Start_Date <= Current_Date < End_Date
   - Related Billing_Status = 'Paid'

   This access validation belongs to application/procedure
   logic, not an automatic billing trigger.
   ===================================================================== */


-- Quick check: list Quang's triggers.

SELECT
    t.name AS Trigger_Name,
    OBJECT_NAME(t.parent_id) AS On_Table,
    t.is_disabled AS Is_Disabled
FROM sys.triggers AS t
WHERE t.parent_class = 1
  AND t.name IN (
      N'trg_MEMBERSHIP_NoActiveOverlap',
      N'trg_TICKET_NoActiveMembership',
      N'trg_MEMBERSHIP_NoOverlappingTicket',
      N'trg_MEMBER_Phone_NoAccessOverlap'
  )
ORDER BY OBJECT_NAME(t.parent_id), t.name;
GO

-- END OF SCRIPT 02 - NGUYEN LUU TRIEU QUANG
