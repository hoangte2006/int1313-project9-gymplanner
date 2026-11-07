package com.gym.service;

import com.gym.dao.ClassPtDao;
import java.sql.SQLException;
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
}