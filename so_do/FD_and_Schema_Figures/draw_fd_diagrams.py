# Draws the FD diagrams (Normalization Figures 1-7) of the report, design B (16 tables).
# Usage:  pip install matplotlib ; python draw_fd_diagrams.py
# Output: Norm_Fig1_...png ... Norm_Fig7_BILLING_LOG.png (same folder)
# Notation: one cell per attribute, primary key underlined, each FD = a line that starts under
# its left side and ends with arrowheads under its right side.
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

NAVY, GREY, CELL, EDGE, FDC = "#1f3864", "#555555", "#f2f2f2", "#555555", "#333333"
W = 1500
CH, FS = 60, 11.5                    # cell height, font size
FKS = {"MEMBERSHIP": ["Member_ID", "Plan_ID"], "SESSION": ["Room_ID", "Trainer_ID"], "CLASS_REGISTRATION": ["Session_ID", "Member_ID"],
       "CLASS": ["Session_ID"], "PT_BOOKING": ["Session_ID", "Member_ID"], "TRAINER": ["Staff_ID"], "RECEPTIONIST": ["Staff_ID"],
       "EQUIPMENT": ["Room_ID"], "MAINTENANCE_LOG": ["Equipment_ID", "Logged_By"],
       "SESSION_EQUIPMENT_USAGE": ["Equipment_ID", "Session_ID"], "BILLING_LOG": ["Membership_ID", "Ticket_ID"]}
wrap = lambda t: t.replace("_", "_\n", 1) if len(t) > 9 and "_" in t else t   # break after the first underscore
CW = lambda t: max(len(l) for l in wrap(t).split("\n")) * 9.2 + 22

class Canvas:
    def __init__(self, title, blocks, sub=None):
        self.blocks = blocks
        self.H = 60 + sum(self.height(b) for b in blocks)
        self.fig, self.ax = plt.subplots(figsize=(W / 100, self.H / 100), dpi=150)
        self.fig.subplots_adjust(0, 0, 1, 1); self.ax.set_xlim(0, W); self.ax.set_ylim(self.H, 0); self.ax.axis("off")

    def height(self, b):
        if b[0] == "text": return 50
        return 40 + 14 + CH + 30 + 30 * len(b[3]) + 30

    def run(self, out):
        y = 30
        for b in self.blocks:
            if b[0] == "rel": self.rel(y, *b[1:])
            else: self.ax.text(90, y + 25, b[1][0].strip(), fontsize=11.5, color=GREY, style="italic", va="center")
            y += self.height(b)
        self.fig.savefig(out, dpi=150, facecolor="white"); plt.close(self.fig)
        print("saved", out)

    def rel(self, y, name, cols, pk, fds, notes=()):
        x0 = 90
        short = name.split()[0]
        t = self.ax.text(x0, y + 12, short, fontsize=12.5, fontweight="bold", color=NAVY, va="center")
        rest = name[len(short):].strip()
        remark = "   ".join(([rest] if rest else []) + list(notes))
        if remark:
            self.ax.text(x0 + len(short) * 12.5 + 14, y + 12, remark, fontsize=10.5, color=GREY, style="italic", va="center")
        top = y + 40 + 14
        centers, x = {}, x0
        for c in cols:
            w = CW(c)
            self.ax.add_patch(Rectangle((x, top), w, CH, fc=CELL, ec=EDGE, lw=1.2))
            self.ax.text(x + w / 2, top + CH / 2, wrap(c), ha="center", va="center", fontsize=FS, linespacing=1.15)
            if c in pk:
                self.ax.plot([x + 6, x + w - 6], [top + CH / 2 + (23 if "\n" in wrap(c) else 11)] * 2, color="k", lw=1)
            if c in FKS.get(short, []):
                self.ax.text(x + w / 2, top - 7, "F.K.", ha="center", va="center", fontsize=7.5, color=GREY, style="italic")
            centers[c] = x + w / 2; x += w
        bot = top + CH
        for i, (lhs, rhs, label, rem) in enumerate(fds):
            yl = bot + 18 + 30 * i
            xs = [centers[a] for a in lhs] + [centers[a] for a in rhs]
            self.ax.plot([min(xs), max(xs)], [yl, yl], color=FDC, lw=1.2)
            for a in lhs:
                self.ax.plot([centers[a]] * 2, [bot, yl], color=FDC, lw=1.2)
            for a in rhs:
                self.ax.annotate("", xy=(centers[a], bot + 1), xytext=(centers[a], yl),
                                 arrowprops=dict(arrowstyle="-|>", color=FDC, lw=1.2, mutation_scale=9, shrinkA=0, shrinkB=0))
            self.ax.text(x0 - 12, yl, label, ha="right", va="center", fontsize=9, color=GREY)
            if rem:
                self.ax.text(max(xs) + 12, yl, rem, ha="left", va="center", fontsize=9.5, color=GREY, style="italic")

# ---------------------------------------------------------------- Fig 1
def fig1():
    wide = ["Session_ID", "Member_ID", "Registration_Date", "Attendance_Status", "Class_Name", "Max_Capacity"]
    Canvas("Normalization Figure 1", [
        ("rel", "CLASS_REG_WIDE   (1NF, not 2NF)", wide, ["Session_ID", "Member_ID"], [
            (["Session_ID", "Member_ID"], ["Registration_Date", "Attendance_Status"], "FD1", ""),
            (["Session_ID"], ["Class_Name", "Max_Capacity"], "FD2", "partial dependency")]),
        ("text", ["        ▼   move FD2 into its own relation   ▼"]),
        ("rel", "CLASS_REGISTRATION", ["Session_ID", "Member_ID", "Registration_Date", "Attendance_Status"],
         ["Session_ID", "Member_ID"], [(["Session_ID", "Member_ID"], ["Registration_Date", "Attendance_Status"], "FD1", "")]),
        ("rel", "CLASS", ["Session_ID", "Class_Name", "Max_Capacity"], ["Session_ID"],
         [(["Session_ID"], ["Class_Name", "Max_Capacity"], "FD2", "")]),
    ], "1NF but not 2NF, decomposed into CLASS_REGISTRATION and CLASS").run("Norm_Fig1_CLASS_REG_WIDE_2NF.png")

# ---------------------------------------------------------------- Fig 2
def fig2():
    wide = ["Membership_ID", "Member_ID", "Plan_ID", "Start_Date", "End_Date", "Status",
            "Plan_Name", "Duration_Months", "Price", "Description"]
    Canvas("Normalization Figure 2", [
        ("rel", "MEMBERSHIP_WIDE   (2NF, not 3NF)", wide, ["Membership_ID"], [
            (["Membership_ID"], ["Member_ID", "Plan_ID", "Start_Date", "End_Date", "Status"], "FD1", ""),
            (["Plan_ID"], ["Plan_Name", "Duration_Months", "Price", "Description"], "FD2", "left side is not a superkey")],
         ["Membership_ID -> Plan_ID -> Price is a transitive dependency"]),
        ("text", ["        ▼   move FD2 into its own relation   ▼"]),
        ("rel", "MEMBERSHIP", ["Membership_ID", "Member_ID", "Plan_ID", "Start_Date", "End_Date", "Status"],
         ["Membership_ID"], [(["Membership_ID"], ["Member_ID", "Plan_ID", "Start_Date", "End_Date", "Status"], "FD1", "")]),
        ("rel", "MEMBERSHIP_PLAN", ["Plan_ID", "Plan_Name", "Duration_Months", "Price", "Description"],
         ["Plan_ID"], [(["Plan_ID"], ["Plan_Name", "Duration_Months", "Price", "Description"], "FD2", "")]),
    ], "2NF but not 3NF, decomposed into MEMBERSHIP and MEMBERSHIP_PLAN").run("Norm_Fig2_MEMBERSHIP_WIDE_3NF.png")

# ---------------------------------------------------------------- Fig 3
def fig3():
    Canvas("Normalization Figure 3", [
        ("rel", "MEMBER", ["Member_ID", "Full_Name", "Phone_Number", "Email", "Birth_Date", "Photo", "Registration_Date"],
         ["Member_ID"], [(["Member_ID"], ["Full_Name", "Phone_Number", "Email", "Birth_Date", "Photo", "Registration_Date"], "FD1", "")]),
        ("rel", "DAILY_PASS_TICKET", ["Ticket_ID", "Guest_Name", "Guest_Phone", "Visit_Date", "Daily_Rate"], ["Ticket_ID"], [
            (["Ticket_ID"], ["Guest_Name", "Guest_Phone", "Visit_Date", "Daily_Rate"], "FD1", ""),
            (["Guest_Phone", "Visit_Date"], ["Ticket_ID", "Guest_Name", "Daily_Rate"], "FD2", "alternative key")]),
        ("rel", "STAFF", ["Staff_ID", "Full_Name", "Phone", "Role", "Hire_Date", "Salary"], ["Staff_ID"], [
            (["Staff_ID"], ["Full_Name", "Phone", "Role", "Hire_Date", "Salary"], "FD1", ""),
            (["Phone"], ["Staff_ID"], "FD2", "alternative key")]),
        ("rel", "TRAINER", ["Staff_ID", "Specialty", "Certification"], ["Staff_ID"],
         [(["Staff_ID"], ["Specialty", "Certification"], "FD1", "")]),
        ("rel", "RECEPTIONIST", ["Staff_ID", "Shift_Type"], ["Staff_ID"], [(["Staff_ID"], ["Shift_Type"], "FD1", "")]),
    ], "MEMBER, DAILY_PASS_TICKET, STAFF, TRAINER, RECEPTIONIST").run("Norm_Fig3_MEMBER_DAILYPASS_STAFF.png")

# ---------------------------------------------------------------- Fig 4
def fig4():
    Canvas("Normalization Figure 4", [
        ("rel", "MEMBERSHIP_PLAN", ["Plan_ID", "Plan_Name", "Duration_Months", "Price", "Description"], ["Plan_ID"], [
            (["Plan_ID"], ["Plan_Name", "Duration_Months", "Price", "Description"], "FD1", ""),
            (["Plan_Name"], ["Plan_ID", "Duration_Months", "Price", "Description"], "FD2", "alternative key")]),
        ("rel", "MEMBERSHIP", ["Membership_ID", "Member_ID", "Plan_ID", "Start_Date", "End_Date", "Status"], ["Membership_ID"],
         [(["Membership_ID"], ["Member_ID", "Plan_ID", "Start_Date", "End_Date", "Status"], "FD1", "")],
         ["Member_ID and Plan_ID are foreign keys; nothing inside MEMBERSHIP depends on them."]),
    ], "MEMBERSHIP_PLAN and MEMBERSHIP").run("Norm_Fig4_PLAN_MEMBERSHIP.png")

# ---------------------------------------------------------------- Fig 5
def fig5():
    Canvas("Normalization Figure 5", [
        ("rel", "ROOM", ["Room_ID", "Room_Name", "Capacity", "Floor_Location"], ["Room_ID"], [
            (["Room_ID"], ["Room_Name", "Capacity", "Floor_Location"], "FD1", ""),
            (["Room_Name"], ["Room_ID", "Capacity", "Floor_Location"], "FD2", "alternative key")]),
        ("rel", "SESSION", ["Session_ID", "Session_Type", "Room_ID", "Trainer_ID", "Start_Time", "End_Time"], ["Session_ID"],
         [(["Session_ID"], ["Session_Type", "Room_ID", "Trainer_ID", "Start_Time", "End_Time"], "FD1", "")],
         ["Room_ID and Trainer_ID are foreign keys; no attribute of SESSION depends on them (no transitive arrow)."]),
        ("rel", "CLASS", ["Session_ID", "Class_Name", "Max_Capacity"], ["Session_ID"],
         [(["Session_ID"], ["Class_Name", "Max_Capacity"], "FD1", "")]),
        ("rel", "PT_BOOKING", ["Session_ID", "Member_ID", "Booking_Status"], ["Session_ID"],
         [(["Session_ID"], ["Member_ID", "Booking_Status"], "FD1", "")]),
        ("rel", "CLASS_REGISTRATION", ["Session_ID", "Member_ID", "Registration_Date", "Attendance_Status"],
         ["Session_ID", "Member_ID"], [(["Session_ID", "Member_ID"], ["Registration_Date", "Attendance_Status"], "FD1", "")]),
    ], "ROOM, SESSION, CLASS, PT_BOOKING, CLASS_REGISTRATION").run("Norm_Fig5_ROOM_SESSION_CLASS_PT.png")

# ---------------------------------------------------------------- Fig 6
def fig6():
    Canvas("Normalization Figure 6", [
        ("rel", "EQUIPMENT", ["Equipment_ID", "Equipment_Name", "Room_ID", "Operational_Status", "Purchase_Date"], ["Equipment_ID"],
         [(["Equipment_ID"], ["Equipment_Name", "Room_ID", "Operational_Status", "Purchase_Date"], "FD1", "")],
         ["Room_ID is a foreign key; the room details stay in ROOM."]),
        ("rel", "MAINTENANCE_LOG", ["Equipment_ID", "Log_no", "Maintenance_Date", "Cost", "Description", "Logged_By"],
         ["Equipment_ID", "Log_no"],
         [(["Equipment_ID", "Log_no"], ["Maintenance_Date", "Cost", "Description", "Logged_By"], "FD1", "whole key")],
         ["Nothing depends on Equipment_ID alone: one machine has many service records."]),
        ("rel", "SESSION_EQUIPMENT_USAGE", ["Usage_ID", "Equipment_ID", "Session_ID", "Reserved_From", "Reserved_To"], ["Usage_ID"],
         [(["Usage_ID"], ["Equipment_ID", "Session_ID", "Reserved_From", "Reserved_To"], "FD1", "")]),
    ], "EQUIPMENT, MAINTENANCE_LOG, SESSION_EQUIPMENT_USAGE").run("Norm_Fig6_EQUIPMENT_MLOG_SEU.png")

# ---------------------------------------------------------------- Fig 7
def fig7():
    Canvas("Normalization Figure 7", [
        ("rel", "BILLING_LOG", ["Bill_ID", "Membership_ID", "Ticket_ID", "Invoice_Date", "Due_Date", "Payment_Date", "Amount_Paid", "Billing_Status"],
         ["Bill_ID"], [(["Bill_ID"], ["Membership_ID", "Ticket_ID", "Invoice_Date", "Due_Date", "Payment_Date", "Amount_Paid", "Billing_Status"], "FD1", "")],
         ["CHECK (XOR): exactly one of Membership_ID and Ticket_ID is NOT NULL.",
          "Filtered UNIQUE indexes: at most one bill per non-NULL Membership_ID and per non-NULL Ticket_ID."]),
    ], "BILLING_LOG: one invoice key, two mutually exclusive purchase sources").run("Norm_Fig7_BILLING_LOG.png")

if __name__ == "__main__":
    fig1(); fig2(); fig3(); fig4(); fig5(); fig6(); fig7()
