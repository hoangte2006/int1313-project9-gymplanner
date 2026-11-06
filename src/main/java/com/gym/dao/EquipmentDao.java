package com.gym.dao;

import com.gym.db.DbConnection;
import com.gym.model.Equipment;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
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

    /** Doi trang thai may. Tra ve so dong bi doi (0 neu khong co thiet bi nay). */
    public int updateStatus(int equipmentId, String newStatus) throws SQLException {
        String sql = "UPDATE dbo.EQUIPMENT SET Operational_Status = ? WHERE Equipment_ID = ?";
        try (Connection c = DbConnection.get();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setInt(2, equipmentId);
            return ps.executeUpdate();
        }
    }

    /**
     * Them mot log bao tri. Log_no khong tu tang (khoa chinh la Equipment_ID + Log_no),
     * nen lay so lon nhat hien co cua may nay + 1 ngay trong cau INSERT (khoa dong de
     * hai nguoi khong lay trung so). Trigger trg_MLOG_SignerRole (BR-FAC-05) co the tu choi.
     */
    public int addMaintenanceLog(int equipmentId, LocalDate date, BigDecimal cost,
                                 String description, int loggedBy) throws SQLException {
        String sql = "INSERT INTO dbo.MAINTENANCE_LOG "
            + "(Equipment_ID, Log_no, Maintenance_Date, Cost, Description, Logged_By) "
            + "SELECT ?, ISNULL(MAX(Log_no), 0) + 1, ?, ?, ?, ? "
            + "FROM dbo.MAINTENANCE_LOG WITH (UPDLOCK, HOLDLOCK) WHERE Equipment_ID = ?";
        try (Connection c = DbConnection.get();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, equipmentId);
            ps.setObject(2, date);
            ps.setBigDecimal(3, cost);
            ps.setString(4, description);
            ps.setInt(5, loggedBy);
            ps.setInt(6, equipmentId);
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
