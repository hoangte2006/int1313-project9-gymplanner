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

            System.out.println("Connected successfully to: " + c.getCatalog());

            try (ResultSet rs = st.executeQuery(
                    "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME <> 'sysdiagrams'")) {
                rs.next();
                System.out.println("Number of tables in the database: " + rs.getInt(1) + " (expected 16)");
            }
        } catch (SQLException e) {
            System.out.println("CONNECTION FAILED: " + e.getMessage());
        }
    }
}
