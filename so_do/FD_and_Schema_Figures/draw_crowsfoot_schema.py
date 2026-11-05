# Draws the Physical Database Schema (IE crow's foot notation) of the 16 tables, design B.
# Usage:  pip install matplotlib ; python draw_crowsfoot_schema.py
# Output: Schema_Fig1_Physical_CrowsFoot.png  (same folder)
# Column names, types, NULL / PK / FK come from sql/01_create_tables.sql.
import math
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

NAVY, GREY, EDGE = "#1f3864", "#6b7280", "#333333"
BW, GAP, ROWH, HEAD = 400, 60, 26, 36
COLX = [40 + i * (BW + GAP) for i in range(6)]
W, H = COLX[-1] + BW + 40, 1760

# name: (col, row_y, [(column, type, flags)])  flags: PK FK N(ull-able)
T = {
 "BILLING_LOG": (0, 60, [("Bill_ID","INT","PK"),("Membership_ID","INT","FK N"),("Ticket_ID","INT","FK N"),
     ("Invoice_Date","DATE",""),("Due_Date","DATE","N"),("Payment_Date","DATE","N"),("Amount_Paid","DECIMAL(10,2)",""),("Billing_Status","VARCHAR(20)","")]),
 "DAILY_PASS_TICKET": (0, 400, [("Ticket_ID","INT","PK"),("Guest_Name","VARCHAR(100)",""),("Guest_Phone","VARCHAR(20)",""),
     ("Visit_Date","DATE",""),("Daily_Rate","DECIMAL(10,2)","")]),
 "MEMBERSHIP": (1, 60, [("Membership_ID","INT","PK"),("Member_ID","INT","FK"),("Plan_ID","INT","FK"),
     ("Start_Date","DATE",""),("End_Date","DATE",""),("Status","VARCHAR(20)","")]),
 "MEMBER": (1, 400, [("Member_ID","INT","PK"),("Full_Name","VARCHAR(100)",""),("Phone_Number","VARCHAR(20)",""),("Email","VARCHAR(255)","N"),
     ("Birth_Date","DATE","N"),("Photo","VARBINARY(MAX)","N"),("Registration_Date","DATE","")]),
 "MEMBERSHIP_PLAN": (2, 60, [("Plan_ID","INT","PK"),("Plan_Name","VARCHAR(100)",""),("Duration_Months","INT",""),("Price","DECIMAL(10,2)",""),("Description","VARCHAR(255)","N")]),
 "CLASS_REGISTRATION": (2, 400, [("Session_ID","INT","PK FK"),("Member_ID","INT","PK FK"),("Registration_Date","DATETIME",""),("Attendance_Status","VARCHAR(20)","")]),
 "CLASS": (3, 400, [("Session_ID","INT","PK FK"),("Class_Name","VARCHAR(50)",""),("Max_Capacity","INT",""),("Status","VARCHAR(20)","")]),
 "PT_BOOKING": (1, 760, [("Session_ID","INT","PK FK"),("Member_ID","INT","FK"),("Booking_Status","VARCHAR(20)","")]),
 "SESSION_EQUIPMENT_USAGE": (2, 760, [("Usage_ID","INT","PK"),("Equipment_ID","INT","FK"),("Session_ID","INT","FK"),("Reserved_From","DATETIME",""),("Reserved_To","DATETIME","")]),
 "SESSION": (3, 760, [("Session_ID","INT","PK"),("Session_Type","VARCHAR(10)",""),("Room_ID","INT","FK N"),("Trainer_ID","INT","FK"),("Start_Time","DATETIME",""),("End_Time","DATETIME","")]),
 "TRAINER": (4, 760, [("Staff_ID","INT","PK FK"),("Specialty","VARCHAR(50)",""),("Certification","VARCHAR(100)","N")]),
 "EQUIPMENT": (2, 1120, [("Equipment_ID","INT","PK"),("Equipment_Name","VARCHAR(100)",""),("Room_ID","INT","FK N"),("Operational_Status","VARCHAR(20)",""),("Purchase_Date","DATE","N")]),
 "ROOM": (3, 1120, [("Room_ID","INT","PK"),("Room_Name","VARCHAR(50)",""),("Capacity","INT",""),("Floor_Location","VARCHAR(30)","N")]),
 "STAFF": (4, 1120, [("Staff_ID","INT","PK"),("Full_Name","VARCHAR(100)",""),("Phone","VARCHAR(15)",""),("Role","VARCHAR(30)",""),("Hire_Date","DATE",""),("Salary","DECIMAL(10,2)","")]),
 "RECEPTIONIST": (5, 1120, [("Staff_ID","INT","PK FK"),("Shift_Type","VARCHAR(20)","")]),
 "MAINTENANCE_LOG": (2, 1480, [("Equipment_ID","INT","PK FK"),("Log_no","INT","PK"),("Maintenance_Date","DATE",""),("Cost","DECIMAL(10,2)",""),("Description","VARCHAR(255)",""),("Logged_By","INT","FK")]),
}
pos = lambda n: (COLX[T[n][0]], T[n][1])
height = lambda n: HEAD + ROWH * len(T[n][2])
def rowy(n, col):
    i = [c[0] for c in T[n][2]].index(col)
    return pos(n)[1] + HEAD + ROWH * i + ROWH / 2
L = lambda n: pos(n)[0]
R = lambda n: pos(n)[0] + BW
TOP = lambda n: pos(n)[1]
BOT = lambda n: pos(n)[1] + height(n)

fig, ax = plt.subplots(figsize=(W / 100, H / 100), dpi=150)
fig.subplots_adjust(0, 0, 1, 1)
ax.set_xlim(0, W); ax.set_ylim(H, 0); ax.axis("off")
ax.text(W / 2, 30, "Physical Database Schema (IE crow's foot notation) - GymPlanner, 16 tables", ha="center", va="center", fontsize=22, fontweight="bold", color=NAVY)

def table(n):
    x, y = pos(n); h = height(n)
    ax.add_patch(Rectangle((x, y), BW, h, fc="white", ec=EDGE, lw=2, zorder=3))
    ax.add_patch(Rectangle((x, y), BW, HEAD, fc="#1f3864", ec=EDGE, lw=2, zorder=4))
    ax.text(x + BW / 2, y + HEAD / 2, n, ha="center", va="center", color="white", fontsize=12.5, fontweight="bold", zorder=5)
    for i, (c, t, f) in enumerate(T[n][2]):
        cy = y + HEAD + ROWH * i + ROWH / 2
        if "PK" in f: ax.add_patch(Rectangle((x + 1, cy - ROWH / 2), BW - 2, ROWH, fc="#fff4d6", ec="none", zorder=3.5))
        ax.text(x + 8, cy, " ".join(k for k in ("PK", "FK") if k in f), fontsize=8.5, color="#b45309" if "PK" in f else "#1d4ed8",
                fontweight="bold", va="center", zorder=5)
        ax.text(x + 62, cy, c, fontsize=10.5, va="center", zorder=5, fontweight="bold" if "PK" in f else "normal")
        ax.text(x + BW - 8, cy, t + (" NULL" if "N" in f.split() else ""), fontsize=8.5, color=GREY, ha="right", va="center", zorder=5)
        if i: ax.plot([x, x + BW], [cy - ROWH / 2] * 2, color="#cccccc", lw=.6, zorder=4.5)

def sym(p, d, kind):
    """crow's foot symbol at point p on a table edge; d = unit vector pointing away from the table."""
    px, py = p; dx, dy = d; nx, ny = -dy, dx
    pt = lambda a, b: (px + dx * a + nx * b, py + dy * a + ny * b)
    def seg(a, b, c, e): ax.plot([pt(a, b)[0], pt(c, e)[0]], [pt(a, b)[1], pt(c, e)[1]], color=EDGE, lw=1.8, zorder=2)
    def ring(a):
        cx, cy = pt(a, 0); ax.add_patch(plt.Circle((cx, cy), 6, fc="white", ec=EDGE, lw=1.8, zorder=6))
    if kind == "one": seg(14, -9, 14, 9); seg(23, -9, 23, 9)
    elif kind == "zero_one": seg(13, -9, 13, 9); ring(26)
    elif kind == "many0":
        for b in (-10, 0, 10): seg(22, 0, 0, b)
        ring(33)

def conn(path, kA, kB):
    xs, ys = [p[0] for p in path], [p[1] for p in path]
    ax.plot(xs, ys, color=EDGE, lw=1.6, zorder=2)
    u = lambda p, q: ((q[0] - p[0]) / (math.hypot(q[0] - p[0], q[1] - p[1]) or 1), (q[1] - p[1]) / (math.hypot(q[0] - p[0], q[1] - p[1]) or 1))
    sym(path[0], u(path[0], path[1]), kA); sym(path[-1], u(path[-1], path[-2]), kB)

def h(a, ca, b, cb, kA, kB):          # a on the right of b?  (a.left -> b.right) or (a.right -> b.left), with a jog
    ya, yb = rowy(a, ca), rowy(b, cb)
    if L(a) > L(b): xa, xb = L(a), R(b)
    else: xa, xb = R(a), L(b)
    m = (xa + xb) / 2
    conn([(xa, ya), (m, ya), (m, yb), (xb, yb)], kA, kB)

def v(a, b, x_off, kA, kB):           # a above b: a.bottom -> b.top at x = left edge + x_off
    conn([(L(a) + x_off, BOT(a)), (L(a) + x_off, TOP(b))], kA, kB) if TOP(a) < TOP(b) else \
    conn([(L(a) + x_off, TOP(a)), (L(a) + x_off, BOT(b))], kA, kB)

for n in T: table(n)
# parent end first, child end second.   "one" = exactly one, "zero_one" = zero or one, "many0" = zero or many
h("MEMBERSHIP_PLAN", "Plan_ID", "MEMBERSHIP", "Plan_ID", "one", "many0")
v("MEMBERSHIP", "MEMBER", 100, "many0", "one")
h("MEMBERSHIP", "Membership_ID", "BILLING_LOG", "Membership_ID", "zero_one", "zero_one")
v("BILLING_LOG", "DAILY_PASS_TICKET", 240, "zero_one", "zero_one")
v("TRAINER", "STAFF", 160, "zero_one", "one")
h("STAFF", "Staff_ID", "RECEPTIONIST", "Staff_ID", "one", "zero_one")
h("TRAINER", "Staff_ID", "SESSION", "Trainer_ID", "one", "many0")
v("SESSION", "ROOM", 220, "many0", "zero_one")
v("CLASS", "SESSION", 160, "zero_one", "one")
h("CLASS", "Session_ID", "CLASS_REGISTRATION", "Session_ID", "one", "many0")
h("MEMBER", "Member_ID", "CLASS_REGISTRATION", "Member_ID", "one", "many0")
v("MEMBER", "PT_BOOKING", 100, "one", "many0")
h("ROOM", "Room_ID", "EQUIPMENT", "Room_ID", "zero_one", "many0")
v("EQUIPMENT", "MAINTENANCE_LOG", 160, "one", "many0")
h("SESSION_EQUIPMENT_USAGE", "Session_ID", "SESSION", "Session_ID", "many0", "one")
v("SESSION_EQUIPMENT_USAGE", "EQUIPMENT", 160, "many0", "one")
# PT_BOOKING -> SESSION (goes under SESSION_EQUIPMENT_USAGE), STAFF -> MAINTENANCE_LOG (goes under ROOM)
conn([(L("PT_BOOKING") + 300, BOT("PT_BOOKING")), (L("PT_BOOKING") + 300, 1050), (L("SESSION") + 60, 1050), (L("SESSION") + 60, BOT("SESSION"))], "many0", "one")
conn([(L("STAFF") + 100, BOT("STAFF")), (L("STAFF") + 100, rowy("MAINTENANCE_LOG", "Logged_By")), (R("MAINTENANCE_LOG"), rowy("MAINTENANCE_LOG", "Logged_By"))], "one", "many0")

# legend
lx, ly = 60, 1150
ax.add_patch(Rectangle((lx - 20, ly - 20), 420, 170, fc="#fafafa", ec="#bbbbbb", lw=1, zorder=1))
ax.text(lx, ly, "Legend", fontsize=14, fontweight="bold", color=NAVY, va="center")
for i, (k, t) in enumerate([("one", "exactly one"), ("zero_one", "zero or one"), ("many0", "zero or many")]):
    y = ly + 40 + i * 38
    ax.plot([lx, lx + 120], [y, y], color=EDGE, lw=1.6); sym((lx + 120, y), (-1, 0), k)
    ax.text(lx + 150, y, t, fontsize=11.5, va="center")
fig.savefig("Schema_Fig1_Physical_CrowsFoot.png", dpi=150, facecolor="white")
print("saved Schema_Fig1_Physical_CrowsFoot.png")
