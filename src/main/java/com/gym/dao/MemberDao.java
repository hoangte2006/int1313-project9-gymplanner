package com.gym.dao;

import com.gym.model.Member;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MemberDao {

    // Get all members or search by name/phone.
    public List<Member> findAll(Connection conn, String keyword)
            throws SQLException {

        List<Member> members = new ArrayList<>();

        String sql = """
            SELECT
                Member_ID,
                Full_Name,
                Phone_Number,
                Email,
                Registration_Date
            FROM dbo.MEMBER
            WHERE (
                ? = ''
                OR Full_Name LIKE ?
                OR Phone_Number LIKE ?
            )
            ORDER BY Member_ID DESC
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {

            String search = keyword == null ? "" : keyword.trim();

            ps.setString(1, search);
            ps.setString(2, "%" + search + "%");
            ps.setString(3, "%" + search + "%");

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Member member = new Member(
                        rs.getInt("Member_ID"),
                        rs.getString("Full_Name"),
                        rs.getString("Phone_Number"),
                        rs.getString("Email"),
                        rs.getDate("Registration_Date").toLocalDate()
                    );

                    members.add(member);
                }
            }
        }

        return members;
    }

    // Add a new Member.
    public int insert(Connection conn,
                      String fullName,
                      String phoneNumber,
                      String email)
            throws SQLException {

        String sql = """
            SET NOCOUNT ON;

            INSERT INTO dbo.MEMBER (
                Full_Name,
                Phone_Number,
                Email,
                Birth_Date,
                Photo,
                Registration_Date
            )
            VALUES (?, ?, ?, NULL, NULL, CAST(GETDATE() AS DATE));

            SELECT CAST(SCOPE_IDENTITY() AS INT);
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, fullName);
            ps.setString(2, phoneNumber);

            if (email == null || email.isBlank()) {
                ps.setNull(3, Types.VARCHAR);
            } else {
                ps.setString(3, email.trim());
            }

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }

        throw new SQLException("Failed to create Member.");
    }
}
