package com.gym.dao;

import com.gym.db.DbConnection;
import com.gym.model.Equipment;
import com.gym.model.SessionSlot;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/** Truy van bang dbo.EQUIPMENT. */
public class EquipmentDao {

    private static final String SELECT_ALL =
        "SELECT Equipment_ID, Equipment_Name, Room_ID, Operational_Status, Purchase_Date "
        + "FROM dbo.EQUIPMENT ORDER BY Equipment_ID";

    public List<Equipment> findAll() throws SQLException {
        List<Equipment> list = new ArrayList<>();
        try (Connection c = DbConnection.get();
             Statement st = c.createStatement(); // Tao statement có nghĩa là : "tao 1 câu lệnh SQL để gửi cho SQL Server"
             ResultSet rs = st.executeQuery(SELECT_ALL)) { // Thực hiện câu lệnh SQL và nhận kết quả trả về (ResultSet)
            while (rs.next()) { // Di chuyển con trỏ xuống dòng tiếp theo (ban đầu con trỏ đứng trước dòng đầu tiên)
                list.add(new Equipment(
                    rs.getInt("Equipment_ID"),
                    rs.getString("Equipment_Name"),
                    rs.getObject("Room_ID", Integer.class),
                    rs.getString("Operational_Status"),
                    rs.getObject("Purchase_Date", LocalDate.class)));
            }
        }
        return list;
    }

    /**
     * Cap nhat mot may trong MOT transaction: doi trang thai (neu newStatus khac null) va/hoac
     * ghi mot log bao tri (neu description khac null). Log_no khong tu tang (khoa chinh la
     * Equipment_ID + Log_no) nen lay so lon nhat hien co cua may nay + 1 ngay trong cau INSERT.
     * Neu trigger tu choi (vi du nguoi ky la Trainer, BR-FAC-05) thi ca trang thai cung KHONG bi doi.
     */
    public void updateStatusAndLog(int equipmentId, String newStatus, LocalDate date, BigDecimal cost,
                                   String description, Integer loggedBy) throws SQLException {
        try (Connection c = DbConnection.get()) {
            c.setAutoCommit(false);
            try {
                if (newStatus != null) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "UPDATE dbo.EQUIPMENT SET Operational_Status = ? WHERE Equipment_ID = ?")) {
                        ps.setString(1, newStatus);
                        ps.setInt(2, equipmentId);
                        if (ps.executeUpdate() == 0) {
                            throw new IllegalArgumentException("This machine no longer exists. Press Refresh and try again.");
                        }
                    }
                }
                if (description != null) {
                    String insertLog = "INSERT INTO dbo.MAINTENANCE_LOG "
                        + "(Equipment_ID, Log_no, Maintenance_Date, Cost, Description, Logged_By) "
                        + "SELECT ?, ISNULL(MAX(Log_no), 0) + 1, ?, ?, ?, ? "
                        + "FROM dbo.MAINTENANCE_LOG WITH (UPDLOCK, HOLDLOCK) WHERE Equipment_ID = ?";
                    try (PreparedStatement ps = c.prepareStatement(insertLog)) {
                        ps.setInt(1, equipmentId);
                        ps.setObject(2, date);
                        ps.setBigDecimal(3, cost);
                        ps.setString(4, description);
                        ps.setInt(5, loggedBy);
                        ps.setInt(6, equipmentId);
                        ps.executeUpdate();
                    }
                }
                c.commit();
            } catch (SQLException | RuntimeException ex) {
                try {
                    c.rollback();   // trigger co the da huy transaction, khi do lenh nay khong con tac dung
                } catch (SQLException ignored) { }
                throw ex;
            }
        }
    }

    /**
     * Cac buoi tap chua ket thuc de chon dat may: lop (ten lop) va PT, bo lop da huy
     * va PT da huy. Lay toi da 500 buoi gan nhat theo gio bat dau.
     */
    public List<SessionSlot> findReservableSessions() throws SQLException {
        String sql = "SELECT TOP 500 s.Session_ID, COALESCE(c.Class_Name, 'PT session') AS Title, "
            + "r.Room_Name, s.Start_Time, s.End_Time "
            + "FROM dbo.[SESSION] AS s "
            + "LEFT JOIN dbo.CLASS AS c ON c.Session_ID = s.Session_ID "
            + "LEFT JOIN dbo.PT_BOOKING AS p ON p.Session_ID = s.Session_ID "
            + "LEFT JOIN dbo.ROOM AS r ON r.Room_ID = s.Room_ID "
            + "WHERE s.End_Time >= GETDATE() "
            + "AND ISNULL(c.Status, '') <> 'Cancelled' "
            + "AND ISNULL(p.Booking_Status, '') <> 'Cancelled' "
            + "ORDER BY s.Start_Time, s.Session_ID";
        List<SessionSlot> list = new ArrayList<>();
        try (Connection c = DbConnection.get();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                list.add(new SessionSlot(
                    rs.getInt("Session_ID"),
                    rs.getString("Title"),
                    rs.getString("Room_Name"),
                    rs.getTimestamp("Start_Time").toLocalDateTime(),
                    rs.getTimestamp("End_Time").toLocalDateTime()));
            }
        }
        return list;
    }

    /**
     * Dat may cho mot buoi tap. Trigger kiem tra: may phai Active (BR-FAC-06), gio nam
     * trong buoi tap (BR-FAC-09), khong trung gio voi buoi khac (BR-FAC-10).
     */
    public int reserveForSession(int equipmentId, int sessionId, LocalDateTime from, LocalDateTime to)
            throws SQLException {
        String sql = "INSERT INTO dbo.SESSION_EQUIPMENT_USAGE (Equipment_ID, Session_ID, Reserved_From, Reserved_To) "
                   + "VALUES (?, ?, ?, ?)";
        try (Connection c = DbConnection.get();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, equipmentId);
            ps.setInt(2, sessionId);
            ps.setTimestamp(3, Timestamp.valueOf(from));
            ps.setTimestamp(4, Timestamp.valueOf(to));
            return ps.executeUpdate();
        }
    }

    /** Main thu: in danh sach thiet bi ra man hinh. */
    public static void main(String[] args) {
        try {
            List<Equipment> all = new EquipmentDao().findAll();
            System.out.println("So thiet bi: " + all.size());
            all.forEach(System.out::println);
        } catch (SQLException e) {
            System.out.println("LOI: " + e.getMessage());
        }
    }
}
