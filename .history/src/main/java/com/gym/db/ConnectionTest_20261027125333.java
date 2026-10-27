package com.gym.db;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/** Buoc A: chay file nay de kiem tra app noi duoc vao SQL Server. */
public class ConnectionTest {

    public static void main(String[] args) {
        try (Connection c = DbConnection.get();
             Statement st = c.createStatement()) {

            System.out.println("Ket noi thanh cong den: " + c.getCatalog());

            try (ResultSet rs = st.executeQuery(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'")) {
                rs.next();
                System.out.println("So bang trong database: " + rs.getInt(1) + " (ky vong 17)");
            }
        } catch (SQLException e) {
            System.out.println("KET NOI THAT BAI: " + e.getMessage());
        }
    }
}
