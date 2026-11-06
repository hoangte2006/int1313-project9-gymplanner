package com.gym.dao;

import com.gym.model.Plan;
import java.sql.*;
import java.util.*;

public class PlanDao {

    public List<Plan> findAll(Connection conn)
            throws SQLException {

        List<Plan> plans = new ArrayList<>();

        String sql = """
            SELECT Plan_ID, Plan_Name, Duration_Months, Price
            FROM dbo.MEMBERSHIP_PLAN
            ORDER BY Plan_ID
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                plans.add(new Plan(
                    rs.getInt("Plan_ID"),
                    rs.getString("Plan_Name"),
                    rs.getInt("Duration_Months"),
                    rs.getBigDecimal("Price")
                ));
            }
        }

        return plans;
    }

    public Plan findByIdForPurchase(Connection conn, int planId)
            throws SQLException {

        String sql = """
            SELECT Plan_ID, Plan_Name, Duration_Months, Price
            FROM dbo.MEMBERSHIP_PLAN WITH (UPDLOCK, HOLDLOCK)
            WHERE Plan_ID = ?
            """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, planId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException(
                        "Membership plan not found: " + planId
                    );
                }

                return new Plan(
                    rs.getInt("Plan_ID"),
                    rs.getString("Plan_Name"),
                    rs.getInt("Duration_Months"),
                    rs.getBigDecimal("Price")
                );
            }
        }
    }
}
