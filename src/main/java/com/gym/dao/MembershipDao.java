package com.gym.dao;

import java.sql.*;
import java.time.LocalDate;

public class MembershipDao {

    public int insert(
            Connection conn,
            int memberId,
            int planId,
            LocalDate startDate,
            LocalDate endDate
    ) throws SQLException {

        String sql = """
            SET NOCOUNT ON;

            DECLARE @NewIds TABLE (ID INT);

            INSERT INTO dbo.MEMBERSHIP
                (Member_ID, Plan_ID, Start_Date, End_Date, Status)
            OUTPUT INSERTED.Membership_ID INTO @NewIds(ID)
            VALUES (?, ?, ?, ?, 'Active');

            SELECT ID FROM @NewIds;
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, memberId);
            ps.setInt(2, planId);
            ps.setDate(3, Date.valueOf(startDate));
            ps.setDate(4, Date.valueOf(endDate));

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException(
                        "Cannot retrieve Membership_ID"
                    );
                }

                return rs.getInt(1);
            }
        }
    }

    public LocalDate nextRenewalDate(
            Connection conn, int memberId
    ) throws SQLException {

        String sql = """
            SELECT MAX(End_Date)
            FROM dbo.MEMBERSHIP WITH (UPDLOCK, HOLDLOCK)
            WHERE Member_ID = ?
              AND Status = 'Active'
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, memberId);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();

                Date lastEnd = rs.getDate(1);
                LocalDate today = LocalDate.now();

                if (lastEnd == null) {
                    return today;
                }

                LocalDate end = lastEnd.toLocalDate();
                return end.isAfter(today) ? end : today;
            }
        }
    }
}
