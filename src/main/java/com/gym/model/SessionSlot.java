package com.gym.model;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/** Mot buoi tap (lop hoac PT) co the dat may vao. Dung cho o chon buoi tap. */
public class SessionSlot {

    private static final DateTimeFormatter DAY = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final DateTimeFormatter HOUR = DateTimeFormatter.ofPattern("HH:mm");

    private final int sessionId;
    private final String title;
    private final String roomName;
    private final LocalDateTime start;
    private final LocalDateTime end;

    public SessionSlot(int sessionId, String title, String roomName, LocalDateTime start, LocalDateTime end) {
        this.sessionId = sessionId;
        this.title = title;
        this.roomName = roomName;
        this.start = start;
        this.end = end;
    }

    public int getSessionId() { return sessionId; }
    public LocalDateTime getStart() { return start; }
    public LocalDateTime getEnd() { return end; }

    /** JComboBox hien chuoi nay, vi du: #12  Yoga Flow | Yoga Room | 2026-11-09 07:00-08:00 */
    @Override
    public String toString() {
        return "#" + sessionId + "  " + title + "  |  " + (roomName == null ? "no room" : roomName)
             + "  |  " + start.format(DAY) + "-" + end.format(HOUR);
    }
}
