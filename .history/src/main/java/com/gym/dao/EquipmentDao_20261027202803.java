package com.gym.dao;

import com.gym.db.DbConnection;
import com.gym.model.Equipment;

import java.sql.Connection;
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
             ResultSet rs = st.executeQuery(SELECT_ALL)) {
            while (rs.next()) {
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
