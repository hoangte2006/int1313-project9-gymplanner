package com.gym.service;

import com.gym.dao.*;
import com.gym.db.DbConnection;
import com.gym.model.Plan;

import java.sql.*;
import java.time.LocalDate;
import java.math.BigDecimal;
import java.util.List;

public class PurchaseService {

    private final MemberDao memberDao = new MemberDao();
    private final PlanDao planDao = new PlanDao();
    private final MembershipDao membershipDao = new MembershipDao();
    private final DailyPassDao ticketDao = new DailyPassDao();
    private final BillingDao billingDao = new BillingDao();

    public record Receipt(
        int purchaseId,
        int billId,
        BigDecimal amount
    ) {}

    public List<Plan> getPlans() throws SQLException {
        try (Connection conn = DbConnection.get()) {
            return planDao.findAll(conn);
        }
    }

    public List<BillingDao.BillRow> getBills()
            throws SQLException {
        try (Connection conn = DbConnection.get()) {
            return billingDao.findAll(conn);
        }
    }

    // Buy a new Membership or renew a current Membership.
    public Receipt purchaseMembership(
            int memberId,
            int planId,
            LocalDate startDate,
            boolean renew
    ) throws SQLException {

        if (startDate == null) {
            throw new IllegalArgumentException(
                "Start date is required"
            );
        }

        try (Connection conn = DbConnection.get()) {
            conn.setTransactionIsolation(
                Connection.TRANSACTION_SERIALIZABLE
            );
            conn.setAutoCommit(false);

            try {
                // Verify member and lock the member row.
                String sql = """
                    SELECT Member_ID
                    FROM dbo.MEMBER WITH (UPDLOCK, HOLDLOCK)
                    WHERE Member_ID = ?
                    """;

                try (PreparedStatement ps =
                         conn.prepareStatement(sql)) {
                    ps.setInt(1, memberId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new SQLException(
                                "Member not found: " + memberId
                            );
                        }
                    }
                }

                // Read plan duration and price from SQL Server.
                Plan plan =
                    planDao.findByIdForPurchase(conn, planId);

                if (renew) {
                    startDate = membershipDao.nextRenewalDate(
                        conn, memberId
                    );
                }

                if (startDate.isBefore(LocalDate.now())) {
                    throw new IllegalArgumentException(
                        "Start date cannot be in the past"
                    );
                }

                LocalDate endDate = startDate.plusMonths(
                    plan.getDurationMonths()
                );

                // Step 1: Create Membership.
                int membershipId = membershipDao.insert(
                    conn, memberId, planId, startDate, endDate
                );

                // Step 2: Create its Bill in the SAME transaction.
                int billId = billingDao.createPending(
                    conn, membershipId, null, plan.getPrice()
                );

                conn.commit();

                return new Receipt(
                    membershipId, billId, plan.getPrice()
                );

            } catch (SQLException | RuntimeException ex) {
                try {
                    if (conn.getAutoCommit() == false
                            && !conn.isClosed()) {
                        conn.rollback();
                    }
                } catch (SQLException rollbackError) {
                    ex.addSuppressed(rollbackError);
                }
                throw ex;
            }
        }
    }

    // Buy a Daily Pass and create its Bill atomically.
    public Receipt purchaseDailyPass(
            String guestName,
            String guestPhone,
            LocalDate visitDate,
            BigDecimal dailyRate
    ) throws SQLException {

        if (guestName == null || guestName.isBlank()
                || guestPhone == null || guestPhone.isBlank()) {
            throw new IllegalArgumentException(
                "Guest name and phone are required"
            );
        }

        if (visitDate == null
                || visitDate.isBefore(LocalDate.now())) {
            throw new IllegalArgumentException(
                "Visit date cannot be in the past"
            );
        }

        if (dailyRate == null || dailyRate.signum() <= 0) {
            throw new IllegalArgumentException(
                "Daily rate must be positive"
            );
        }

        try (Connection conn = DbConnection.get()) {
            conn.setTransactionIsolation(
                Connection.TRANSACTION_SERIALIZABLE
            );
            conn.setAutoCommit(false);

            try {
                // Step 1: Create ticket.
                int ticketId = ticketDao.insert(
                    conn,
                    guestName.trim(),
                    guestPhone.trim(),
                    visitDate,
                    dailyRate
                );

                // Step 2: Create its Bill.
                int billId = billingDao.createPending(
                    conn, null, ticketId, dailyRate
                );

                conn.commit();

                return new Receipt(
                    ticketId, billId, dailyRate
                );

            } catch (SQLException | RuntimeException ex) {
                try {
                    if (!conn.getAutoCommit() && !conn.isClosed()) {
                        conn.rollback();
                    }
                } catch (SQLException rollbackError) {
                    ex.addSuppressed(rollbackError);
                }
                throw ex;
            }
        }
    }
}
