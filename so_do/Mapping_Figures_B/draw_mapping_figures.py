# Draws the five Mapping Figures of the report (design B, no VISITOR) with matplotlib.
# Usage:  pip install matplotlib ; python draw_mapping_figures.py
# Output: Mapping_Fig1_STAFF.png ... Mapping_Fig5_REGISTER.png  (same folder)
import math
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Ellipse, Polygon, Circle, Arc, FancyArrowPatch

NAVY, GREY, BLUE, CELL, ORANGE, PINK = "#1f3864", "#6b7280", "#b0d4f1", "#e6f0fa", "#fbc06a", "#f5b5b5"
EDGE = "#333333"

class Fig:
    def __init__(self, title, subtitle, w=1500, h=1450):
        self.fig, self.ax = plt.subplots(figsize=(w / 100, h / 100), dpi=150)
        self.ax.set_xlim(0, w); self.ax.set_ylim(h, 0); self.ax.axis("off")
        self.w = w
        self.ax.text(w / 2, 45, title, ha="center", fontsize=26, fontweight="bold", color=NAVY)
        self.ax.text(w / 2, 90, subtitle, ha="center", fontsize=15, style="italic", color=GREY)

    # ---- small helpers -------------------------------------------------
    def label(self, x, y, t, size=17, color=GREY, bold=True, italic=False, ha="left"):
        self.ax.text(x, y, t, fontsize=size, color=color, ha=ha, va="center",
                     fontweight="bold" if bold else "normal", style="italic" if italic else "normal")

    def line(self, p, q, lw=1.4, z=1, dbl=False):
        if not dbl:
            self.ax.plot([p[0], q[0]], [p[1], q[1]], color=EDGE, lw=lw, zorder=z)
            return
        # total participation: exactly two parallel lines
        dx, dy = q[0] - p[0], q[1] - p[1]; n = math.hypot(dx, dy)
        ox, oy = -dy / n * 3.2, dx / n * 3.2
        for k in (1, -1):
            self.ax.plot([p[0] + k * ox, q[0] + k * ox], [p[1] + k * oy, q[1] + k * oy], color=EDGE, lw=1.3, zorder=z)

    def ent(self, cx, cy, w, t, weak=False):
        h = 52
        self.ax.add_patch(Rectangle((cx - w / 2, cy - h / 2), w, h, fc=BLUE, ec=EDGE, lw=2, zorder=3))
        if weak:
            self.ax.add_patch(Rectangle((cx - w / 2 + 7, cy - h / 2 + 7), w - 14, h - 14, fc="none", ec=EDGE, lw=1.5, zorder=3))
        self.ax.text(cx, cy, t, ha="center", va="center", fontsize=17, fontweight="bold", zorder=4)
        return {"top": (cx, cy - h / 2), "bottom": (cx, cy + h / 2), "left": (cx - w / 2, cy), "right": (cx + w / 2, cy)}

    def att(self, cx, cy, t, to, pk=False, partial=False):
        w = len(t) * 13.5 + 50
        self.ax.add_patch(Ellipse((cx, cy), w, 44, fc="white", ec=EDGE, lw=1.8, zorder=3))
        self.ax.text(cx, cy, t, ha="center", va="center", fontsize=13, zorder=4)
        if pk or partial:
            self.ax.plot([cx - len(t) * 4.6, cx + len(t) * 4.6], [cy + 12, cy + 12], color="k", lw=1.6, zorder=4,
                         ls="--" if partial else "-")
        # line from the ellipse border to the entity
        dx, dy = to[0] - cx, to[1] - cy; n = math.hypot(dx, dy)
        self.line((cx + dx / n * 22, cy + dy / n * 22), to) if False else self.line((cx, cy), to, z=1)

    def row_attrs(self, y, names, to, center, pks=(), partials=()):
        widths = [len(t) * 13.5 + 50 for t in names]
        total = sum(widths) + 28 * (len(names) - 1)
        x = center - total / 2
        for t, w in zip(names, widths):
            self.att(x + w / 2, y, t, to, pk=t in pks, partial=t in partials)
            x += w + 28

    def diamond(self, cx, cy, t, weak=False, w=210, h=110):
        pts = [(cx, cy - h / 2), (cx + w / 2, cy), (cx, cy + h / 2), (cx - w / 2, cy)]
        self.ax.add_patch(Polygon(pts, fc=PINK if weak else ORANGE, ec=EDGE, lw=2, zorder=3))
        if weak:
            k = 0.82
            self.ax.add_patch(Polygon([(cx, cy - h / 2 * k), (cx + w / 2 * k, cy), (cx, cy + h / 2 * k), (cx - w / 2 * k, cy)],
                                      fc="none", ec=EDGE, lw=1.4, zorder=3))
        self.ax.text(cx, cy, t, ha="center", va="center", fontsize=13, zorder=4)

    def mapping_arrow(self, x, y, text):
        self.ax.add_patch(FancyArrowPatch((x, y), (x, y + 70), arrowstyle="-|>", mutation_scale=30, color=NAVY, lw=3.5))
        self.ax.text(x + 35, y + 35, text, fontsize=16, fontweight="bold", color=NAVY, va="center")

    def table(self, x, y, name, cols, pk=(0,), notes=None, partial_pk=(), name_below=False):
        """Draws a table; returns the cell rectangles {col: (x0, x1, ymid)}"""
        self.ax.text(x, y + (140 if name_below else -6), name, fontsize=17, fontweight="bold", color=NAVY, va="center")
        if pk == (0,): pk = (cols[0],)          # default: first column is the primary key
        cx, cells = x, {}
        for c in cols:
            w = len(c) * 13 + 36
            self.ax.add_patch(Rectangle((cx, y + 20), w, 52, fc=CELL, ec=EDGE, lw=1.8))
            self.ax.text(cx + w / 2, y + 46, c, ha="center", va="center", fontsize=13)
            if c in pk:
                self.ax.plot([cx + w / 2 - len(c) * 4.9, cx + w / 2 + len(c) * 4.9], [y + 60, y + 60], color="k", lw=1.8)
            if notes and c in notes:
                self.ax.text(cx + w / 2, y + 92, notes[c], ha="center", fontsize=12, style="italic", color=GREY)
            cells[c] = (cx, cx + w, y + 46)
            cx += w
        return cells

    def fk(self, src, dst, route_x):
        """elbow arrow from the left edge of cell src to the left edge of cell dst, going round x = route_x"""
        sx, _, sy = src; dx, _, dy = dst
        self.ax.plot([sx, route_x, route_x, dx - 2], [sy, sy, dy, dy], color=NAVY, lw=2.6)
        self.ax.add_patch(FancyArrowPatch((dx - 22, dy), (dx, dy), arrowstyle="-|>", mutation_scale=22, color=NAVY, lw=0))

    def fk_down_right(self, src_bottom_x, src_y, dst_cell, via_y):
        pass

    def save(self, name):
        self.fig.savefig(name, bbox_inches="tight", pad_inches=0.25, facecolor="white")
        plt.close(self.fig)

def subset_arc(f, p_from, p_to, t=0.80):
    px = p_from[0] + (p_to[0] - p_from[0]) * t; py = p_from[1] + (p_to[1] - p_from[1]) * t
    ang = math.degrees(math.atan2(p_to[1] - p_from[1], p_to[0] - p_from[0]))
    f.ax.add_patch(Arc((px, py), 34, 34, angle=ang, theta1=-90, theta2=90, ec=EDGE, lw=2, zorder=5))

# ======================= Figure 1: STAFF =======================================
def fig1():
    f = Fig("Mapping 1: STAFF specialization", "Partial, disjoint specialization (d): a Manager has no extra attributes, so it has no subclass row")
    f.label(40, 145, "EER diagram (fragment)")
    staff = f.ent(750, 340, 190, "STAFF")
    f.row_attrs(230, ["Staff_ID", "Full_Name", "Phone", "Role", "Hire_Date", "Salary"], staff["top"], 750, pks=("Staff_ID",))
    d = (750, 450); f.ax.add_patch(Circle(d, 26, fc="#dddddd", ec=EDGE, lw=2, zorder=4)); f.ax.text(*d, "d", ha="center", va="center", fontsize=17, zorder=5)
    f.line(staff["bottom"], (750, 424))
    tr = f.ent(380, 640, 180, "TRAINER"); rc = f.ent(1130, 640, 260, "RECEPTIONIST")
    f.line((750, 476), tr["top"]); f.line((750, 476), rc["top"])
    subset_arc(f, (750, 476), tr["top"]); subset_arc(f, (750, 476), rc["top"])
    f.row_attrs(770, ["Specialty", "Certification"], tr["bottom"], 380)
    f.row_attrs(770, ["Shift_Type"], rc["bottom"], 1130)
    f.mapping_arrow(750, 850, "Mapping: Step 8, Option 8A")
    f.label(40, 985, "Relational schema")
    s = f.table(110, 1050, "STAFF", ["Staff_ID", "Full_Name", "Phone", "Role", "Hire_Date", "Salary"])
    t = f.table(110, 1200, "TRAINER", ["Staff_ID", "Specialty", "Certification"], notes={"Staff_ID": "PK, FK"})
    r = f.table(110, 1350, "RECEPTIONIST", ["Staff_ID", "Shift_Type"], notes={"Staff_ID": "PK, FK"})
    f.fk(t["Staff_ID"], s["Staff_ID"], 70); f.fk(r["Staff_ID"], s["Staff_ID"], 50)
    f.label(40, 1500, "Underline = primary key. Arrow = foreign key to STAFF(Staff_ID). Single line to the circle = partial participation.",
            size=13.5, bold=False, italic=True)
    f.ax.set_ylim(1540, 0)
    f.save("Mapping_Fig1_STAFF.png")

# ======================= Figure 2: MEMBER and DAILY_PASS_TICKET ================
def fig2():
    f = Fig("Mapping 2: MEMBER and DAILY_PASS_TICKET (Step 1)",
            "Two independent strong entities: each keeps its own key, there is no VISITOR superclass", w=1560, h=1300)
    f.label(40, 145, "EER diagram (fragment)")
    me = f.ent(330, 360, 200, "MEMBER")
    for i, t in enumerate(["Member_ID", "Full_Name", "Phone_Number", "Email"]):
        f.att(115, 240 + i * 70, t, (230, 360), pk=(t == "Member_ID"))
    for i, t in enumerate(["Birth_Date", "Photo", "Registration_Date"]):
        f.att(620, 260 + i * 80, t, (430, 360))
    dp = f.ent(1190, 360, 340, "DAILY_PASS_TICKET")
    for i, t in enumerate(["Ticket_ID", "Guest_Name", "Guest_Phone"]):
        f.att(880, 260 + i * 80, t, (1020, 360), pk=(t == "Ticket_ID"))
    for i, t in enumerate(["Visit_Date", "Daily_Rate"]):
        f.att(1440, 270 + i * 180, t, (1360, 360))
    f.mapping_arrow(780, 520, "Mapping: Step 1 (strong entity types)")
    f.label(40, 665, "Relational schema")
    f.table(40, 740, "MEMBER", ["Member_ID", "Full_Name", "Phone_Number", "Email", "Birth_Date", "Photo", "Registration_Date"], notes={"Member_ID": "PK"})
    f.label(40, 872, "UNIQUE(Phone_Number); Email is unique when it is not NULL", size=13, bold=False, italic=True)
    f.table(40, 950, "DAILY_PASS_TICKET", ["Ticket_ID", "Guest_Name", "Guest_Phone", "Visit_Date", "Daily_Rate"], notes={"Ticket_ID": "PK"})
    f.label(40, 1082, "UNIQUE(Guest_Phone, Visit_Date); CHECK(Daily_Rate > 0)", size=13, bold=False, italic=True)
    f.label(40, 1160, "Underline = primary key. Neither relation has a foreign key to the other. A guest who later becomes a member", size=13.5, bold=False, italic=True)
    f.label(40, 1192, "is matched by phone number (Guest_Phone = Phone_Number): a business rule enforced by triggers, not by a shared key.", size=13.5, bold=False, italic=True)
    f.ax.set_ylim(1230, 0)
    f.save("Mapping_Fig2_MEMBER_DAILY_PASS.png")

# ======================= Figure 3: SESSION =====================================
def fig3():
    f = Fig("Mapping 3: SESSION specialization", "Total, disjoint specialization (d): every session is a CLASS or a PT_BOOKING, never both", h=1780)
    f.label(40, 145, "EER diagram (fragment)")
    se = f.ent(750, 340, 190, "SESSION")
    f.row_attrs(230, ["Session_ID", "Session_Type", "Start_Time", "End_Time"], se["top"], 750, pks=("Session_ID",))
    d = (750, 470); f.ax.add_patch(Circle(d, 26, fc="#dddddd", ec=EDGE, lw=2, zorder=4)); f.ax.text(*d, "d", ha="center", va="center", fontsize=17, zorder=5)
    f.line(se["bottom"], (750, 444), dbl=True)
    cl = f.ent(330, 680, 170, "CLASS"); pt = f.ent(1000, 680, 300, "PT_BOOKING")
    f.line((750, 496), cl["top"]); f.line((750, 496), pt["top"])
    subset_arc(f, (750, 496), cl["top"]); subset_arc(f, (750, 496), pt["top"])
    f.row_attrs(810, ["Class_Name", "Max_Capacity"], cl["bottom"], 330)
    f.att(820, 810, "Booking_Status", (940, 706))
    f.diamond(1130, 830, "BOOKS_PT", w=200, h=100)
    f.line((1130, 706), (1130, 780)); f.ax.text(1150, 745, "N", fontsize=14, fontweight="bold")
    me = f.ent(1130, 960, 170, "MEMBER"); f.line((1130, 880), me["top"]); f.ax.text(1150, 915, "1", fontsize=14, fontweight="bold")
    f.mapping_arrow(750, 1020, "Mapping: Step 8, Option 8A")
    f.label(40, 1150, "Relational schema")
    s = f.table(110, 1210, "SESSION", ["Session_ID", "Session_Type", "Room_ID", "Trainer_ID", "Start_Time", "End_Time"],
                notes={"Room_ID": "FK, NULL", "Trainer_ID": "FK"})
    c = f.table(110, 1380, "CLASS", ["Session_ID", "Class_Name", "Max_Capacity"], notes={"Session_ID": "PK, FK"})
    p = f.table(110, 1530, "PT_BOOKING", ["Session_ID", "Member_ID", "Booking_Status"], pk=("Session_ID",),
                notes={"Session_ID": "PK, FK", "Member_ID": "FK to MEMBER"})
    f.fk(c["Session_ID"], s["Session_ID"], 70); f.fk(p["Session_ID"], s["Session_ID"], 50)
    f.label(40, 1700, "Underline = primary key. Arrow = foreign key to SESSION(Session_ID). Session_Type tells which subclass table holds the session.",
            size=13.5, bold=False, italic=True)
    f.label(40, 1732, "Room_ID references ROOM(Room_ID) and may be NULL (room not assigned yet). Trainer_ID references TRAINER(Staff_ID).",
            size=13.5, bold=False, italic=True)
    f.ax.set_ylim(1770, 0)
    f.save("Mapping_Fig3_SESSION.png")

# ======================= Figure 4: MAINTENANCE_LOG =============================
def fig4():
    f = Fig("Mapping 4: weak entity MAINTENANCE_LOG (Step 2)",
            "MAINTENANCE_LOG depends on EQUIPMENT: its key is the owner key plus the partial key Log_no", h=1250)
    f.label(40, 145, "EER diagram (fragment)")
    eq = f.ent(300, 400, 200, "EQUIPMENT")
    for (x, y, t) in [(210, 250, "Equipment_ID"), (470, 250, "Equipment_Name"), (200, 320, "Operational_Status"), (520, 320, "Purchase_Date")]:
        f.att(x, y, t, (eq["top"][0] + (x - 300) * 0.15, eq["top"][1]), pk=(t == "Equipment_ID"))
    f.diamond(780, 400, "LOGGED_FOR", weak=True, w=250, h=120)
    f.line(eq["right"], (655, 400)); f.ax.text(610, 378, "1", fontsize=14, fontweight="bold")
    ml = f.ent(1220, 400, 350, "MAINTENANCE_LOG", weak=True)
    f.line((905, 400), ml["left"], lw=3.5); f.ax.text(985, 378, "N", fontsize=14, fontweight="bold")
    for (x, y, t, pa) in [(1090, 250, "Log_no", True), (1350, 250, "Maintenance_Date", False), (1110, 320, "Description", False), (1380, 320, "Cost", False)]:
        f.att(x, y, t, (1220 + (x - 1220) * 0.15, 374), partial=pa)
    f.mapping_arrow(750, 520, "Mapping: Step 2 (weak entity type)")
    f.label(40, 680, "Relational schema")
    e = f.table(110, 740, "EQUIPMENT", ["Equipment_ID", "Equipment_Name", "Operational_Status", "Purchase_Date"])
    m = f.table(110, 920, "MAINTENANCE_LOG", ["Equipment_ID", "Log_no", "Maintenance_Date", "Cost", "Description"], pk=("Equipment_ID", "Log_no"),
                notes={"Equipment_ID": "PK, FK", "Log_no": "PK"})
    f.fk(m["Equipment_ID"], e["Equipment_ID"], 70)
    f.label(40, 1080, "Underline = primary key. Dashed underline = partial key. Arrow = foreign key to EQUIPMENT(Equipment_ID), ON DELETE CASCADE.",
            size=13.5, bold=False, italic=True)
    f.label(40, 1112, "Room_ID (relationship HOSTS) and Logged_By (relationship SIGNS) are added in Step 4.", size=13.5, bold=False, italic=True)
    f.ax.set_ylim(1150, 0)
    f.save("Mapping_Fig4_MAINTENANCE_LOG.png")

# ======================= Figure 5: REGISTER ====================================
def fig5():
    f = Fig("Mapping 5: M:N relationship REGISTER (Step 5)",
            "A member can join many classes and a class has many members: the relationship becomes its own table", h=1350)
    f.label(40, 145, "EER diagram (fragment)")
    cl = f.ent(380, 420, 170, "CLASS"); me = f.ent(1230, 420, 170, "MEMBER")
    f.att(250, 290, "Session_ID", (360, 394), pk=True); f.att(470, 240, "Class_Name", (400, 394))
    f.att(150, 420, "Max_Capacity", cl["left"])
    f.att(1230, 290, "Member_ID", (1230, 394), pk=True); f.att(1400, 345, "Email", (1280, 394))
    f.ax.text(1370, 255, "...", fontsize=22, ha="center", va="center")
    f.diamond(790, 420, "REGISTER", w=230, h=110)
    f.line(cl["right"], (675, 420)); f.ax.text(560, 398, "N", fontsize=14, fontweight="bold")
    f.line((905, 420), me["left"]); f.ax.text(1090, 398, "M", fontsize=14, fontweight="bold")
    f.att(640, 300, "Registration_Date", (770, 366)); f.att(930, 300, "Attendance_Status", (820, 368))
    f.mapping_arrow(750, 540, "Mapping: Step 5 (binary M:N relationship type)")
    f.label(40, 700, "Relational schema")
    c = f.table(110, 760, "CLASS", ["Session_ID", "Class_Name", "Max_Capacity"])
    m = f.table(900, 760, "MEMBER", ["Member_ID", "Email", "..."])
    r = f.table(250, 1010, "CLASS_REGISTRATION", ["Session_ID", "Member_ID", "Registration_Date", "Attendance_Status"],
                pk=("Session_ID", "Member_ID"), notes={"Session_ID": "PK, FK", "Member_ID": "PK, FK"}, name_below=True)
    f.fk(r["Session_ID"], c["Session_ID"], 70)
    mx = (r["Member_ID"][0] + r["Member_ID"][1]) / 2          # second foreign key: Member_ID cell -> MEMBER table
    tx = (m["Member_ID"][0] + m["Member_ID"][1]) / 2
    f.ax.plot([mx, mx, tx, tx], [1030, 950, 950, 840], color=NAVY, lw=2.6)
    f.ax.add_patch(FancyArrowPatch((tx, 862), (tx, 832), arrowstyle="-|>", mutation_scale=22, color=NAVY, lw=0))
    f.label(40, 1230, "Underline = primary key (the two foreign keys together). Arrows = foreign keys, both ON DELETE CASCADE.", size=13.5, bold=False, italic=True)
    f.label(40, 1262, "The attributes of the relationship (Registration_Date, Attendance_Status) become columns of the new table.", size=13.5, bold=False, italic=True)
    f.ax.set_ylim(1300, 0)
    f.save("Mapping_Fig5_REGISTER.png")

if __name__ == "__main__":
    fig1(); fig2(); fig3(); fig4(); fig5()
    print("done")
