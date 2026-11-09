package com.gym.dao;

import com.gym.db.DbConnection;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class ClassPtDao {

    public List<Object[]> findAllSchedule() throws SQLException {
        List<Object[]> list = new ArrayList<>();
        String sql = "SELECT s.Session_ID, s.Session_Type, ISNULL(c.Class_Name, N'PT session') AS Title, " +
                     "s.Start_Time, s.End_Time, r.Room_Name, st.Full_Name AS Trainer_Name, " +
                     "ISNULL(CAST(c.Max_Capacity AS VARCHAR), 'N/A') AS Capacity, " +
                     "ISNULL(c.Status, 'Scheduled') AS Status " +
                     "FROM dbo.SESSION s " +
                     "LEFT JOIN dbo.CLASS c ON s.Session_ID = c.Session_ID " +
                     "LEFT JOIN dbo.ROOM r ON s.Room_ID = r.Room_ID " +
                     "LEFT JOIN dbo.STAFF st ON s.Trainer_ID = st.Staff_ID " +
                     "ORDER BY s.Start_Time DESC";

        try (Connection c = DbConnection.get();
             PreparedStatement stmt = c.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                list.add(new Object[]{
                    rs.getString("Session_ID"),
                    rs.getString("Session_Type"),
                    rs.getString("Title"),
                    rs.getTimestamp("Start_Time"),
                    rs.getTimestamp("End_Time"),
                    rs.getString("Room_Name"),
                    rs.getString("Trainer_Name"),
                    rs.getString("Capacity"),
                    rs.getString("Status")
                });
            }
        }
        return list;
    }

    // 1. Register for a class
    public void registerClass(String sessionIdStr, String memberIdStr) throws Exception {
        int sessionId = Integer.parseInt(sessionIdStr.trim());
        int memberId = Integer.parseInt(memberIdStr.toUpperCase().replace("M", "").trim());

        String sql = "INSERT INTO dbo.CLASS_REGISTRATION (Session_ID, Member_ID) VALUES (?, ?)";

        try (Connection conn = DbConnection.get();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, sessionId);
            stmt.setInt(2, memberId);
            stmt.executeUpdate();
        } catch (SQLException ex) {
            if (ex.getErrorCode() == 2627 || ex.getErrorCode() == 2601) {
                throw new Exception("This member is already registered for this class.");
            }
            throw ex;
        }
    }

    // 2. Book a PT session
    public void bookPT(String sessionIdStr, String memberIdStr) throws Exception {
        int sessionId = Integer.parseInt(sessionIdStr.trim());
        int memberId = Integer.parseInt(memberIdStr.toUpperCase().replace("M", "").trim());

        String sql = "INSERT INTO dbo.PT_BOOKING (Session_ID, Member_ID, Booking_Status) VALUES (?, ?, 'Scheduled')";

        try (Connection conn = DbConnection.get();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, sessionId);
            stmt.setInt(2, memberId);
            stmt.executeUpdate();
        } catch (SQLException ex) {
            if (ex.getErrorCode() == 2627 || ex.getErrorCode() == 2601) {
                throw new Exception("This PT session is already booked. Please choose another session.");
            }
            throw ex;
        }
    }

    /** Danh sach phong de chon: moi dong {Room_ID, "Ten (suc chua N)"}. */
    public List<Object[]> findRooms() throws SQLException {
        return findOptions("SELECT Room_ID, Room_Name + ' (capacity ' + CAST(Capacity AS VARCHAR) + ')' "
                         + "FROM dbo.ROOM ORDER BY Room_Name");
    }

    /** Danh sach huan luyen vien de chon: moi dong {Staff_ID, "Ten (chuyen mon)"}. */
    public List<Object[]> findTrainers() throws SQLException {
        return findOptions("SELECT t.Staff_ID, s.Full_Name + ' (' + t.Specialty + ')' "
                         + "FROM dbo.TRAINER t JOIN dbo.STAFF s ON s.Staff_ID = t.Staff_ID ORDER BY s.Full_Name");
    }

    private List<Object[]> findOptions(String sql) throws SQLException {
        List<Object[]> list = new ArrayList<>();
        try (Connection c = DbConnection.get();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                list.add(new Object[] {rs.getInt(1), rs.getString(2)});
            }
        }
        return list;
    }

    /**
     * Tao buoi PT moi VA dat cho hoi vien trong cung mot transaction: neu trigger tu choi
     * (hoi vien khong con goi tap, trung phong, trung gio HLV...) thi buoi tap cung khong duoc tao.
     */
    public int bookNewPt(String memberIdStr, int roomId, int trainerId,
                         LocalDateTime start, LocalDateTime end) throws SQLException {
        int memberId = Integer.parseInt(memberIdStr.toUpperCase().replace("M", "").trim());
        try (Connection c = DbConnection.get()) {
            c.setAutoCommit(false);
            try {
                int sessionId;
                String insertSession = "INSERT INTO dbo.[SESSION] (Session_Type, Room_ID, Trainer_ID, Start_Time, End_Time) "
                                     + "VALUES ('PT', ?, ?, ?, ?)";
                try (PreparedStatement ps = c.prepareStatement(insertSession, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, roomId);
                    ps.setInt(2, trainerId);
                    ps.setTimestamp(3, Timestamp.valueOf(start));
                    ps.setTimestamp(4, Timestamp.valueOf(end));
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        sessionId = keys.getInt(1);
                    }
                }
                try (PreparedStatement ps = c.prepareStatement(
                        "INSERT INTO dbo.PT_BOOKING (Session_ID, Member_ID, Booking_Status) VALUES (?, ?, 'Scheduled')")) {
                    ps.setInt(1, sessionId);
                    ps.setInt(2, memberId);
                    ps.executeUpdate();
                }
                c.commit();
                return sessionId;
            } catch (SQLException ex) {
                try {
                    c.rollback();   // trigger co the da huy transaction, khi do lenh nay khong con tac dung
                } catch (SQLException ignored) { }
                throw ex;
            }
        }
    }
}
