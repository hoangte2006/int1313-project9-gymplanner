package com.gym.dao;

import java.sql.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class BillingDao {

    public record BillRow(
        int billId,
        String sourceType,
        int purchaseId,
        String customer,
        LocalDate invoiceDate,
        BigDecimal amount,
        String status
    ) {}

    public int createPending(
            Connection conn,
            Integer membershipId,
            Integer ticketId,
            BigDecimal amount
    ) throws SQLException {

        // Exactly one source is required.
        if ((membershipId == null) == (ticketId == null)) {
            throw new IllegalArgumentException(
                "Bill must reference exactly one purchase"
            );
        }

        String sql = """
            SET NOCOUNT ON;

            DECLARE @NewIds TABLE (ID INT);

            INSERT INTO dbo.BILLING_LOG
                (Membership_ID, Ticket_ID, Invoice_Date,
                 Due_Date, Payment_Date, Amount_Paid,
                 Billing_Status)
            OUTPUT INSERTED.Bill_ID INTO @NewIds(ID)
            VALUES (?, ?, ?, NULL, NULL, ?, 'Pending');

            SELECT ID FROM @NewIds;
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            if (membershipId == null) {
                ps.setNull(1, Types.INTEGER);
            } else {
                ps.setInt(1, membershipId);
            }

            if (ticketId == null) {
                ps.setNull(2, Types.INTEGER);
            } else {
                ps.setInt(2, ticketId);
            }

            ps.setDate(3, Date.valueOf(LocalDate.now()));
            ps.setBigDecimal(4, amount);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException(
                        "Cannot retrieve Bill_ID"
                    );
                }
                return rs.getInt(1);
            }
        }
    }

    public List<BillRow> findAll(Connection conn)
            throws SQLException {

        String sql = """
            SELECT
                b.Bill_ID,
                CASE WHEN b.Membership_ID IS NOT NULL
                     THEN 'Membership'
                     ELSE 'Daily Pass' END AS Source_Type,
                COALESCE(b.Membership_ID, b.Ticket_ID)
                    AS Purchase_ID,
                CASE WHEN b.Membership_ID IS NOT NULL
                     THEN m.Full_Name
                     ELSE t.Guest_Name END AS Customer,
                b.Invoice_Date,
                b.Amount_Paid,
                b.Billing_Status
            FROM dbo.BILLING_LOG b
            LEFT JOIN dbo.MEMBERSHIP ms
                ON ms.Membership_ID = b.Membership_ID
            LEFT JOIN dbo.MEMBER m
                ON m.Member_ID = ms.Member_ID
            LEFT JOIN dbo.DAILY_PASS_TICKET t
                ON t.Ticket_ID = b.Ticket_ID
            ORDER BY b.Bill_ID DESC
            """;

        List<BillRow> result = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                result.add(new BillRow(
                    rs.getInt("Bill_ID"),
                    rs.getString("Source_Type"),
                    rs.getInt("Purchase_ID"),
                    rs.getString("Customer"),
                    rs.getDate("Invoice_Date").toLocalDate(),
                    rs.getBigDecimal("Amount_Paid"),
                    rs.getString("Billing_Status")
                ));
            }
        }
        return result;
    }
}
