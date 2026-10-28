package com.gym.service;

import com.gym.dao.EquipmentDao;
import com.gym.model.Equipment;

import java.sql.SQLException;
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
}
