package com.gym.dao;

import com.gym.db.DbConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ClassPtDao {

    public List<Object[]> findAllSchedule() throws SQLException {
        List<Object[]> list = new ArrayList<>();
        String sql = "SELECT s.Session_ID, s.Session_Type, ISNULL(c.Class_Name, N'Buổi tập PT') AS Title, " +
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

    // 1. Đăng ký Lớp học
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
                throw new Exception("Hội viên này đã đăng ký lớp học này rồi!");
            }
            throw ex;
        }
    }

    // 2. Đặt Buổi PT
    public void bookPT(String sessionIdStr, String memberIdStr) throws Exception {
        int sessionId = Integer.parseInt(sessionIdStr.trim());
        int memberId = Integer.parseInt(memberIdStr.toUpperCase().replace("M", "").trim());

        String sql = "INSERT INTO dbo.PT_BOOKING (Session_ID, Member_ID, Booking_Status) VALUES (?, ?, 'Confirmed')";

        try (Connection conn = DbConnection.get();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, sessionId);
            stmt.setInt(2, memberId);
            stmt.executeUpdate();
        } catch (SQLException ex) {
            if (ex.getErrorCode() == 2627 || ex.getErrorCode() == 2601) {
                throw new Exception("Buổi PT này đã được đặt rồi, vui lòng chọn buổi khác!");
            }
            throw ex;
        }
    }
}