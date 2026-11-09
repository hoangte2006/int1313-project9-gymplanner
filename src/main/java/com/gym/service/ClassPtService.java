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
            throw new IllegalArgumentException("Please enter the member ID.");
        }
        if (roomId == null || trainerId == null) {
            throw new IllegalArgumentException("Please choose a room and a trainer.");
        }
        if (start == null) {
            throw new IllegalArgumentException("Please enter the start time as yyyy-MM-dd HH:mm, for example 2026-11-20 09:00.");
        }
        if (minutes <= 0 || minutes > 480) {
            throw new IllegalArgumentException("The duration must be between 1 and 480 minutes.");
        }
        if (start.isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("The start time must be in the future.");
        }
        try {
            return dao.bookNewPt(memberId, roomId, trainerId, start, start.plusMinutes(minutes));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid member ID. Enter a number, for example 1 or M001.");
        }
    }
}
