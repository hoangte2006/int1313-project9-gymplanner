package com.gym.dao;

import com.gym.db.DbConnection;
import com.gym.model.Staff;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/** Truy van bang dbo.STAFF (chi doc, khong lay luong). */
public class StaffDao {

    private static final String SELECT_ALL =
        "SELECT Staff_ID, Full_Name, Role FROM dbo.STAFF ORDER BY Role, Full_Name";

    public List<Staff> findAll() throws SQLException {
        List<Staff> list = new ArrayList<>();
        try (Connection c = DbConnection.get();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(SELECT_ALL)) {
            while (rs.next()) {
                list.add(new Staff(rs.getInt("Staff_ID"), rs.getString("Full_Name"), rs.getString("Role")));
            }
        }
        return list;
    }
}
