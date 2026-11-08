package com.gym.service;

import java.sql.SQLException;

/**
 * Doi loi cua SQL Server (trigger, CHECK, FK...) thanh cau de hieu cho nguoi dung.
 * Trigger trong 02_triggers.sql dung THROW voi so loi 50001 tro len va ma luat "BR-...".
 * Loi la dang khac thi tra ve dung thong bao goc de van thay duoc nguyen nhan.
 */
public final class DbErrorMessages {

    private DbErrorMessages() { }

    public static String explain(Throwable error) {
        if (error instanceof IllegalArgumentException) {
            return error.getMessage();   // loi nhap lieu do Service tu kiem tra
        }
        if (error instanceof SQLException) {
            return explain((SQLException) error);
        }
        // loi da duoc lop DAO/Service viet san thanh cau cho nguoi dung
        return error.getMessage() != null ? error.getMessage() : "Unexpected error: " + error;
    }

    private static String explain(SQLException e) {
        String raw = String.valueOf(e.getMessage());
        switch (e.getErrorCode()) {
            case 50022:   // BR-FAC-05
                return "Nothing was saved.\n"
                     + "A maintenance log must be signed off by a Receptionist or a Manager.\n"
                     + "Please choose a different person in \"Signed off by\".";
            case 50005:   // BR-SCH-05 (PT)
            case 50017:   // BR-SCH-05 (class)
                return "This member has no active membership, so they cannot book a PT session or register for a class.";
            case 50012:   // BR-SCH-02
                return "This class is full. Choose another class.";
            case 50009:
            case 50010:
            case 50011:
                return "The room is too small for this class capacity (BR-SCH-02).";
            case 50013:   // BR-SCH-03
            case 50015:
                return "The room is already used during this time. Choose another room or another time.";
            case 50014:   // BR-SCH-04
            case 50016:
                return "The trainer is already busy during this time. Choose another trainer or another time.";
            case 50021:   // BR-FAC-06
                return "This machine cannot be reserved for a session.\n"
                     + "Only machines with status Active can be reserved; this one is Broken or Under Maintenance.";
            case 50023:   // BR-FAC-09
            case 50025:
                return "The reserved time must lie inside the time of the session.\n"
                     + "Choose a start and end time within the session hours.";
            case 50024:   // BR-FAC-10
                return "This machine is already reserved by another session during this time.\n"
                     + "Choose a different time or a different machine.";
            case 547:     // CHECK / FOREIGN KEY
                if (raw.contains("CK_SEU_Time")) {
                    return "The end time must be after the start time.";
                }
                if (raw.contains("FK_SEU_SESSION")) {
                    return "This session no longer exists. Press Refresh and try again.";
                }
                if (raw.contains("FK_SEU_EQUIPMENT")) {
                    return "This machine no longer exists. Press Refresh and try again.";
                }
                if (raw.contains("CK_MLOG_Cost")) {
                    return "The cost cannot be negative.";
                }
                if (raw.contains("CK_EQUIP_Status")) {
                    return "Invalid status. Choose Active, Under Maintenance or Broken.";
                }
                if (raw.contains("FK_MLOG_STAFF")) {
                    return "The staff member who signs the log does not exist.";
                }
                if (raw.contains("FK_MLOG_EQUIPMENT")) {
                    return "This machine no longer exists. Press Refresh and try again.";
                }
                break;
            case 2627:    // trung khoa chinh
            case 2601:
                return "This record already exists (duplicate key). Press Refresh and try again.";
            default:
                break;
        }
        if (raw.contains("BR-")) {
            // luat nghiep vu khac cua nhom, chua co cau rieng: hien nguyen cau cua trigger
            return "A business rule was violated:\n" + raw;
        }
        return "Database error (" + e.getErrorCode() + "):\n" + raw;
    }
}
