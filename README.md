# 🏋️‍♂️ #9: Gym Membership & Personal Training Planner

Database design project for the course **INT1313 - Database Basics**.  
*Semester 1 — Academic year 2026-2027*

---

## 👥 Team: ĐÔNG VUI
*   **Instructor:** Mr. Lê Hà Thanh
*   **Members:**
    1.  **Trần Đức Phương** - Student ID: `N24DCCN154` (Class: *D24CQCN02-N*) — Scheduling & Conflicts
    2.  **Nguyễn Lưu Triệu Quang** - Student ID: `N24DCCN158` (Class: *D24CQCN02-N*) — Members & Plans
    3.  **Nguyễn Văn Hoàng Te** - Student ID: `N24DCCN071` (Class: *D24CQCN01-N*) — Equipment & Maintenance

---

## 📌 Plan & task assignment

Project tracking sheet (maintained by Te): [Google Sheets – task assignment](https://docs.google.com/spreadsheets/d/1WJ7M7tDn2BU7JbkWXyqd3dUhDNl1oipwcD2o-M5TgnY/edit?gid=14#gid=14)

---

## 📂 Folder structure

```
docs/Report_Gym_Planner.docx   ← project report (the only report file)
docs/                          ← images used in the report
README.md                      ← short description + plan link + how to run SQL
sql/                           ← 01_create_tables.sql, 02_triggers.sql, ... (numbered by run order)
so_do/                         ← ER and EER diagrams (.png)
anh_kiem_chung/                ← screenshots of execution results
src/                           ← Java app (JDBC) connecting to SQL Server
```

## ▶️ How to run the SQL

Run the files in `sql/` **in numeric order** (`01_create_tables.sql` → `02_triggers.sql` → ...) on the same database (Microsoft SQL Server, e.g. in SSMS). Screenshots of each step are saved in `anh_kiem_chung/`.

## ☕ How to run the Java app

Requires JDK 17+, Maven, and the database created by the SQL scripts above.

1. Copy `src/main/resources/db.properties.example` to `src/main/resources/db.properties` and fill in your own connection details (this file is git-ignored).
2. Test the connection:

```bash
mvn -q compile exec:java -Dexec.mainClass=com.gym.db.ConnectionTest
```

3. List all equipment:

```bash
mvn -q compile exec:java -Dexec.mainClass=com.gym.dao.EquipmentDao
```
