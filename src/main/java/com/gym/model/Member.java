package com.gym.model;

import java.time.LocalDate;

public class Member {

    private int memberId;
    private String fullName;
    private String phoneNumber;
    private String email;
    private LocalDate registrationDate;

    public Member(int memberId, String fullName,
                  String phoneNumber, String email,
                  LocalDate registrationDate) {

        this.memberId = memberId;
        this.fullName = fullName;
        this.phoneNumber = phoneNumber;
        this.email = email;
        this.registrationDate = registrationDate;
    }

    public int getMemberId() {
        return memberId;
    }

    public String getFullName() {
        return fullName;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public String getEmail() {
        return email;
    }

    public LocalDate getRegistrationDate() {
        return registrationDate;
    }

    @Override
    public String toString() {
        return memberId + " - " + fullName;
    }
}
