package com.gym.model;

/** Mot nhan vien (bang dbo.STAFF), dung de chon nguoi ky log bao tri. */
public class Staff {

    private final int staffId;
    private final String fullName;
    private final String role;

    public Staff(int staffId, String fullName, String role) {
        this.staffId = staffId;
        this.fullName = fullName;
        this.role = role;
    }

    public int getStaffId() { return staffId; }
    public String getFullName() { return fullName; }
    public String getRole() { return role; }

    /** JComboBox hien chuoi nay. */
    @Override
    public String toString() {
        return fullName + " (" + role + ")";
    }
}
