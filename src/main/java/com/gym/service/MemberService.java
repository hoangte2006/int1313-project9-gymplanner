package com.gym.service;

import com.gym.dao.MemberDao;
import com.gym.db.DbConnection;
import com.gym.model.Member;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;

public class MemberService {

    private final MemberDao memberDao = new MemberDao();

    public List<Member> getMembers(String keyword)
            throws SQLException {

        try (Connection conn = DbConnection.get()) {
            return memberDao.findAll(conn, keyword);
        }
    }

    public int addMember(String name, String phone, String email)
            throws SQLException {

        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException(
                "Full name cannot be empty."
            );
        }

        if (phone == null || phone.isBlank()) {
            throw new IllegalArgumentException(
                "Phone number cannot be empty."
            );
        }

        try (Connection conn = DbConnection.get()) {

            return memberDao.insert(
                conn,
                name.trim(),
                phone.trim(),
                email
            );
        }
    }
}
