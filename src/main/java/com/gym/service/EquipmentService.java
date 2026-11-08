package com.gym.service;

import com.gym.dao.EquipmentDao;
import com.gym.dao.StaffDao;
import com.gym.model.Equipment;
import com.gym.model.SessionSlot;
import com.gym.model.Staff;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Lop Service: noi dat logic nghiep vu cua phan thiet bi (loc, dem...).
 * Giao dien (UI) chi goi Service, khong goi thang DAO; DAO chi lo cau SQL.
 */
public class EquipmentService {

    /** Ba trang thai hop le cua may (khop CHECK CK_EQUIP_Status trong CSDL). */
    public static final List<String> STATUSES = List.of("Active", "Under Maintenance", "Broken");

    private final EquipmentDao dao = new EquipmentDao();
    private final StaffDao staffDao = new StaffDao();

    /** Tat ca thiet bi, sap theo Equipment_ID. */
    public List<Equipment> getAll() throws SQLException {
        return dao.findAll();
    }

    /** Thiet bi theo trang thai; status = null hoac "All" thi tra tat ca. */
    public List<Equipment> getByStatus(String status) throws SQLException {
        List<Equipment> all = getAll();
        if (status == null || status.equals("All")) {
            return all;
        }
        return all.stream()
                  .filter(e -> e.getOperationalStatus().equals(status))
                  .collect(Collectors.toList());
    }

    /** So may theo tung trang thai, vi du {Active=6, Under Maintenance=2, Broken=2}. */
    public Map<String, Long> countByStatus() throws SQLException {
        List<Equipment> all = getAll();
        Map<String, Long> result = new LinkedHashMap<>();
        for (String s : STATUSES) {
            result.put(s, all.stream().filter(e -> e.getOperationalStatus().equals(s)).count());
        }
        return result;
    }

    /** Nhan vien co the ky log bao tri (hien ca Trainer de thay luat BR-FAC-05 chan). */
    public List<Staff> getSigners() throws SQLException {
        return staffDao.findAll();
    }

    /**
     * Mot hanh dong duy nhat cho may: doi trang thai va/hoac ghi log bao tri.
     * - Sang Under Maintenance / Broken: BAT BUOC co nguoi ky va mo ta (de biet ai chiu trach nhiem).
     * - Giu nguyen trang thai hoac ve Active: chi ghi log neu nguoi dung nhap mo ta cong viec da lam.
     * Luat BR-FAC-05 (nguoi ky phai la Le tan hoac Quan ly) do trigger trong CSDL kiem tra.
     */
    public void updateMachine(int equipmentId, String currentStatus, String newStatus, LocalDate date,
                              BigDecimal cost, String description, Staff signer) throws SQLException {
        if (!STATUSES.contains(newStatus)) {
            throw new IllegalArgumentException("Invalid status. Choose Active, Under Maintenance or Broken.");
        }
        boolean statusChanges = !newStatus.equals(currentStatus);
        boolean hasDescription = description != null && !description.trim().isEmpty();
        boolean logRequired = statusChanges && !"Active".equals(newStatus);
        boolean writeLog = logRequired || hasDescription;

        if (!statusChanges && !writeLog) {
            throw new IllegalArgumentException(
                "Nothing to save. Change the status, or describe the maintenance work that was done.");
        }
        if (writeLog) {
            if (signer == null) {
                throw new IllegalArgumentException("Please choose who is responsible (Signed off by).");
            }
            if (!hasDescription) {
                throw new IllegalArgumentException("Please describe the work or the reason, for example \"Belt is worn out\".");
            }
            if (description.trim().length() > 255) {
                throw new IllegalArgumentException("The description is too long (maximum 255 characters).");
            }
            if (date == null) {
                throw new IllegalArgumentException("Please enter the date as yyyy-MM-dd, for example 2026-11-06.");
            }
            if (cost == null || cost.signum() < 0) {
                throw new IllegalArgumentException("The cost must be a number that is 0 or more.");
            }
        }
        dao.updateStatusAndLog(equipmentId,
            statusChanges ? newStatus : null,
            date, cost,
            writeLog ? description.trim() : null,
            writeLog ? signer.getStaffId() : null);
    }

    /** Cac buoi tap co the dat may (lop va PT chua ket thuc, khong tinh buoi da huy). */
    public List<SessionSlot> getReservableSessions() throws SQLException {
        return dao.findReservableSessions();
    }

    /** Dat may cho buoi tap. Gio nam trong buoi, may Active, khong trung gio: do trigger kiem tra. */
    public void reserveForSession(int equipmentId, SessionSlot session,
                                  LocalDateTime from, LocalDateTime to) throws SQLException {
        if (session == null) {
            throw new IllegalArgumentException("Please choose a session.");
        }
        if (from == null || to == null) {
            throw new IllegalArgumentException(
                "Please enter the start and end time as yyyy-MM-dd HH:mm, for example 2026-11-09 07:15.");
        }
        if (!to.isAfter(from)) {
            throw new IllegalArgumentException("The end time must be after the start time.");
        }
        dao.reserveForSession(equipmentId, session.getSessionId(), from, to);
    }
}
