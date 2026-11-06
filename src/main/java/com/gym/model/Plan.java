package com.gym.model;

import java.math.BigDecimal;

public class Plan {
    private final int planId;
    private final String planName;
    private final int durationMonths;
    private final BigDecimal price;

    public Plan(int planId, String planName,
                int durationMonths, BigDecimal price) {
        this.planId = planId;
        this.planName = planName;
        this.durationMonths = durationMonths;
        this.price = price;
    }

    public int getPlanId() {
        return planId;
    }

    public String getPlanName() {
        return planName;
    }

    public int getDurationMonths() {
        return durationMonths;
    }

    public BigDecimal getPrice() {
        return price;
    }

    @Override
    public String toString() {
        return planName + " - " + durationMonths
            + " month(s) - " + price + " VND";
    }
}
