package com.gym.dao;

import java.sql.*;
import java.time.LocalDate;
import java.math.BigDecimal;

public class DailyPassDao {

    public int insert(
            Connection conn,
            String guestName,
            String guestPhone,
            LocalDate visitDate,
            BigDecimal dailyRate
    ) throws SQLException {

        String sql = """
            SET NOCOUNT ON;

            DECLARE @NewIds TABLE (ID INT);

            INSERT INTO dbo.DAILY_PASS_TICKET
                (Guest_Name, Guest_Phone, Visit_Date, Daily_Rate)
            OUTPUT INSERTED.Ticket_ID INTO @NewIds(ID)
            VALUES (?, ?, ?, ?);

            SELECT ID FROM @NewIds;
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, guestName);
            ps.setString(2, guestPhone);
            ps.setDate(3, Date.valueOf(visitDate));
            ps.setBigDecimal(4, dailyRate);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException(
                        "Cannot retrieve Ticket_ID"
                    );
                }

                return rs.getInt(1);
            }
        }
    }
}
