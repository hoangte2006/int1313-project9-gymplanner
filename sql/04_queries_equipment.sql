/* =====================================================================
   Team Dong Vui (#9) - Script 04: sample queries (Equipment & Maintenance)
   Draft: the schema is not final yet, so these queries may change.
   Run after 01_create_tables.sql, 02_triggers.sql, 03_sample_data.sql.
   Screenshots of the results: anh_kiem_chung/te_05 ... te_10.
   ===================================================================== */

USE GymPlanner_dev;
GO

-- Q1. Which equipment is currently under maintenance or broken?
SELECT Equipment_ID,
       Equipment_Name,
       Room_ID,
       Operational_Status
FROM   dbo.EQUIPMENT
WHERE  Operational_Status <> 'Active'
ORDER BY Operational_Status, Equipment_ID;
GO

-- Q2a. Total maintenance cost per equipment (LEFT JOIN: keeps equipment with no log, cost = 0).
SELECT Eq.Equipment_ID,
       Eq.Equipment_Name,
       ISNULL(SUM(Mg.Cost), 0) AS Total_Maintenance_Cost
FROM   dbo.EQUIPMENT AS Eq
LEFT JOIN dbo.MAINTENANCE_LOG AS Mg ON Eq.Equipment_ID = Mg.Equipment_ID
GROUP BY Eq.Equipment_ID, Eq.Equipment_Name;
GO

-- Q2b. Same query with INNER JOIN (equipment with no log disappears: 6 rows instead of 10).
SELECT Eq.Equipment_ID,
       Eq.Equipment_Name,
       ISNULL(SUM(Mg.Cost), 0) AS Total_Maintenance_Cost
FROM   dbo.EQUIPMENT AS Eq
INNER JOIN dbo.MAINTENANCE_LOG AS Mg ON Eq.Equipment_ID = Mg.Equipment_ID
GROUP BY Eq.Equipment_ID, Eq.Equipment_Name;
GO

-- Q3. Maintenance history of equipment 1, with who signed each log, newest first.
SELECT Mg.Equipment_ID,
       Mg.Log_no,
       Mg.Maintenance_Date,
       Mg.Cost,
       Mg.Description,
       St.Full_Name AS Logged_By_Name
FROM   dbo.MAINTENANCE_LOG AS Mg
JOIN   dbo.STAFF AS St ON St.Staff_ID = Mg.Logged_By
WHERE  Mg.Equipment_ID = 1
ORDER BY Mg.Maintenance_Date DESC;
GO

-- Q4. Which equipment has a total maintenance cost above X? (X = 200)
SELECT e.Equipment_ID,
       e.Equipment_Name,
       SUM(m.Cost) AS Total_Cost
FROM   dbo.EQUIPMENT e
JOIN   dbo.MAINTENANCE_LOG m ON m.Equipment_ID = e.Equipment_ID
GROUP BY e.Equipment_ID, e.Equipment_Name
HAVING SUM(m.Cost) > 200      -- X
ORDER BY Total_Cost DESC;
GO

-- Q5. List equipment reserved across sessions, with the booking times.
SELECT S.Session_ID,
       S.Session_Type,
       E.Equipment_Name,
       SEU.Reserved_From,
       SEU.Reserved_To
FROM   dbo.SESSION_EQUIPMENT_USAGE AS SEU
JOIN   dbo.EQUIPMENT AS E ON SEU.Equipment_ID = E.Equipment_ID
JOIN   dbo.[SESSION] AS S ON SEU.Session_ID = S.Session_ID
ORDER BY S.Session_ID, SEU.Reserved_From;
GO
