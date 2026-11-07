package com.gym.service;

import com.gym.dao.ClassPtDao;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;

public class ClassPtService {
    private ClassPtDao dao = new ClassPtDao();

    public List<Object[]> getScheduleList() throws SQLException {
        return dao.findAllSchedule();
    }

    public void registerClass(String sessionId, String memberId) throws Exception {
        dao.registerClass(sessionId, memberId);
    }

    public void bookPT(String sessionId, String memberId) throws Exception {
        dao.bookPT(sessionId, memberId);
    }

    public List<Object[]> getRooms() throws SQLException {
        return dao.findRooms();
    }

    public List<Object[]> getTrainers() throws SQLException {
        return dao.findTrainers();
    }

    /** Tao buoi PT moi va dat cho hoi vien. Kiem tra dau vao truoc, luat nghiep vu do trigger kiem tra. */
    public int bookNewPt(String memberId, Integer roomId, Integer trainerId,
                         LocalDateTime start, int minutes) throws SQLException {
        if (memberId == null || memberId.trim().isEmpty()) {
            throw new IllegalArgumentException("Hãy nhập mã hội viên.");
        }
        if (roomId == null || trainerId == null) {
            throw new IllegalArgumentException("Hãy chọn phòng và huấn luyện viên.");
        }
        if (start == null) {
            throw new IllegalArgumentException("Hãy nhập giờ bắt đầu dạng yyyy-MM-dd HH:mm, ví dụ 2026-11-20 09:00.");
        }
        if (minutes <= 0 || minutes > 480) {
            throw new IllegalArgumentException("Thời lượng phải từ 1 đến 480 phút.");
        }
        if (start.isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("Giờ bắt đầu phải ở tương lai.");
        }
        try {
            return dao.bookNewPt(memberId, roomId, trainerId, start, start.plusMinutes(minutes));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Mã hội viên không hợp lệ. Hãy nhập số, ví dụ 1 hoặc M001.");
        }
    }
}
