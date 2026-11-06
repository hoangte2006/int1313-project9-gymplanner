package com.gym.service;

import com.gym.dao.EquipmentDao;
import com.gym.dao.StaffDao;
import com.gym.model.Equipment;
import com.gym.model.Staff;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
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

    /** Bao hong / doi trang thai may. Kiem tra dau vao truoc khi ghi. */
    public void changeStatus(int equipmentId, String newStatus) throws SQLException {
        if (!STATUSES.contains(newStatus)) {
            throw new IllegalArgumentException("Invalid status. Choose Active, Under Maintenance or Broken.");
        }
        if (dao.updateStatus(equipmentId, newStatus) == 0) {
            throw new IllegalArgumentException("This machine no longer exists. Press Refresh and try again.");
        }
    }

    /** Them log bao tri. Luat BR-FAC-05 (nguoi ky) do trigger trong CSDL kiem tra. */
    public void addMaintenanceLog(int equipmentId, LocalDate date, BigDecimal cost,
                                  String description, Staff signer) throws SQLException {
        if (date == null) {
            throw new IllegalArgumentException("Please enter the date as yyyy-MM-dd, for example 2026-11-06.");
        }
        if (cost == null || cost.signum() < 0) {
            throw new IllegalArgumentException("The cost must be a number that is 0 or more.");
        }
        if (description == null || description.trim().isEmpty()) {
            throw new IllegalArgumentException("Please describe the maintenance work.");
        }
        if (description.trim().length() > 255) {
            throw new IllegalArgumentException("The description is too long (maximum 255 characters).");
        }
        if (signer == null) {
            throw new IllegalArgumentException("Please choose who signs off the log.");
        }
        dao.addMaintenanceLog(equipmentId, date, cost, description.trim(), signer.getStaffId());
    }
}
