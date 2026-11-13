# Gym Membership & Personal Training Planner (Project #9)

Database design project for the course **INT1313 - Database Basics**,
Posts and Telecommunications Institute of Technology, Ho Chi Minh City campus (PTIT HCM),
Semester 1, academic year 2026-2027.

The project designs and implements a SQL Server database for a gym: members, membership
plans, daily-pass guests, billing, staff (trainers, receptionists, managers), rooms, group
classes, 1-on-1 personal training (PT) sessions, equipment, maintenance logs and equipment
reservations. Business rules are enforced with constraints and triggers, and a small Java
Swing application works on the database through JDBC.

## Project information

| Item | Value |
|---|---|
| Project | #9: Gym Membership & Personal Training Planner |
| Course | INT1313 - Database Basics |
| Instructor | Lê Hà Thanh (lehathanh@ptithcm.edu.vn) |
| School | PTIT HCM |
| Semester | Semester 1, 2026-2027 |
| Team name | Đồng Vui |
| Repository | https://github.com/hoangte2006/int1313-project9-gymplanner (branch `main`) |
| Detailed report | [docs/Report_Gym_Planner.pdf](docs/Report_Gym_Planner.pdf) (Word version: [docs/Report_Gym_Planner.docx](docs/Report_Gym_Planner.docx)) |
| Task plan | [Google Sheets - task assignment](https://docs.google.com/spreadsheets/d/1WJ7M7tDn2BU7JbkWXyqd3dUhDNl1oipwcD2o-M5TgnY/edit?gid=14#gid=14) |

## Team members

| Full name | Student ID | Class | Cohort | Email |
|---|---|---|---|---|
| Trần Đức Phương | N24DCCN154 | D24CQCN02-N | 2024 | n24dccn154@student.ptithcm.edu.vn |
| Nguyễn Lưu Triệu Quang | N24DCCN158 | D24CQCN02-N | 2024 | n24dccn158@student.ptithcm.edu.vn |
| Nguyễn Văn Hoàng Te | N24DCCN071 | D24CQCN01-N | 2024 | n24dccn071@student.ptithcm.edu.vn |

Contributions (details per task in the task plan sheet and in the script headers):

| Member | Report | SQL | Java application |
|---|---|---|---|
| Trần Đức Phương | Scheduling domain: business rules BR-SCH, mapping, normalization and data dictionary of STAFF, TRAINER, RECEPTIONIST, ROOM, SESSION, CLASS, CLASS_REGISTRATION, PT_BOOKING | - | Classes & PT tab |
| Nguyễn Lưu Triệu Quang | Member domain: business rules BR-MEM, mapping, normalization and data dictionary of MEMBER, DAILY_PASS_TICKET, MEMBERSHIP_PLAN, MEMBERSHIP, BILLING_LOG | Tables 1-5 (script 01), BR-MEM triggers (script 02) | Members tab, Membership & Billing tab |
| Nguyễn Văn Hoàng Te | Equipment domain (BR-FAC), EER diagram, security (RBAC), report assembly | Tables 6-16 (script 01), BR-SCH and BR-FAC triggers (script 02), sample and bulk data, tests, indexes, views, queries, security scripts | Application structure, Equipment tab |

## Repository contents

```
README.md                  this file: project information, setup and run guide
docs/
  Report_Gym_Planner.pdf   detailed project report (final version)
  Report_Gym_Planner.docx  same report in Word format
sql/                       12 SQL Server scripts (DDL, triggers, indexes, data, tests, queries, security)
src/main/java/com/gym/     Java Swing application (ui -> service -> dao -> db)
src/main/resources/        db.properties.example (connection settings template)
pom.xml                    Maven build file (dependency: Microsoft JDBC driver for SQL Server)
so_do/                     diagrams used in the report (EER, mapping, normalization, crow's foot schema)
                           and the Python scripts that draw them
anh_kiem_chung/            screenshots of the script results and of the application (evidence)
HUONG_DAN_JAVA.md          internal team guide for adding a screen to the Java application (Vietnamese)
```

## Data sets

- `sql/04_sample_data.sql`: small, hand-written sample data for all 16 tables. It is used by the
  tests (script 05), the queries (script 09) and the screenshots in the report. Dates are written
  relative to the day the script is run (`GETDATE()`).
- `sql/06_bulk_data.sql`: 36,998 generated rows (IDs from 1001) for the performance tests of
  report Section 4.2.2. `sql/06b_remove_bulk_data.sql` removes them again.

## Requirements

- Microsoft SQL Server 2016 SP1 or newer (tested on SQL Server 2022 Express, version 16.0)
  and SQL Server Management Studio (SSMS).
- JDK 17 or newer and Maven 3.8 or newer (Maven downloads the JDBC driver on the first build).

## 1. Install the database

Open each script in SSMS and run it (F5) in this order. All scripts use the database
`GymPlanner_dev`, which script 01 creates.

| Step | Script | What it does |
|---|---|---|
| 1 | `01_create_tables.sql` | Creates the database and the 16 tables with PK, FK, UNIQUE, CHECK and DEFAULT constraints |
| 2 | `04_sample_data.sql` | Inserts the sample data (loaded before the triggers exist) |
| 3 | `02_triggers.sql` | Creates the 24 triggers of the business rules |
| 4 | `03_indexes.sql` | Creates 5 extra indexes |
| 5 | `08_views.sql` | Creates the 5 views |
| 6 | `05_trigger_tests.sql` | Runs 37 rule tests, prints PASS/FAIL (each test is rolled back) |
| 7 | `09_advanced_queries.sql` | Runs the 13 advanced queries of report Section 4.2.1 |
| 8 | `10_security_rbac.sql` | Creates 4 demo logins, users and roles with GRANT / DENY / REVOKE |
| 9 | `11_security_tests.sql` | Runs 19 access tests as the demo users (each test is rolled back) |

Optional (large data set): `06_bulk_data.sql`, then `07_scale_checks.sql`, then
`06b_remove_bulk_data.sql` to go back to the sample data.

Notes:
- Run scripts 04, 05 and 09 on the same day. The sample data is relative to the current date,
  so on another day some tests of script 05 can report FAIL. To reset, drop the database
  `GymPlanner_dev` and run the steps again.
- Script 10 creates server logins, so it needs a login with the `sysadmin` (or
  `securityadmin`) role.

## 2. Create a login for the Java application

The application connects with SQL Server Authentication. In SQL Server Configuration Manager
enable TCP/IP (port 1433), and in SSMS set the server to "SQL Server and Windows
Authentication mode" (server Properties > Security), then restart the SQL Server service.
Create a login for the application (change the password):

```sql
USE master;
CREATE LOGIN gym_dev WITH PASSWORD = N'ChangeThisPassword1', DEFAULT_DATABASE = GymPlanner_dev;
GO
USE GymPlanner_dev;
CREATE USER gym_dev FOR LOGIN gym_dev;
ALTER ROLE db_datareader ADD MEMBER gym_dev;
ALTER ROLE db_datawriter ADD MEMBER gym_dev;
GO
```

## 3. Configure and run the Java application

1. Copy `src/main/resources/db.properties.example` to `src/main/resources/db.properties`
   and fill in the URL, user and password (the file is git-ignored).
2. Test the connection (expected output: 16 tables):

   ```bash
   mvn -q compile exec:java -Dexec.mainClass=com.gym.db.ConnectionTest
   ```

3. Start the application:

   ```bash
   mvn -q compile exec:java -Dexec.mainClass=com.gym.App
   ```

## 4. Using the application

| Tab | Functions |
|---|---|
| Equipment | List and filter machines; change a machine's status and write a maintenance log (BR-FAC-05); reserve a machine for a session (BR-FAC-06, -09, -10) |
| Members | Search, list and add members |
| Membership & Billing | Purchase or renew a membership, sell a daily pass, list invoices (BR-MEM-06, -08, -10) |
| Classes & PT | View the schedule, register a member for a class, book a PT session or create a new one (BR-SCH-02 to -05) |

When a change breaks a business rule, the trigger rejects it, the transaction is rolled back
and the application shows an error message that names the rule.
Screenshots are in `anh_kiem_chung/` and in report Section 4.3.
