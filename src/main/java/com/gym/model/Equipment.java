package com.gym.model;

import java.time.LocalDate;

/** Mot dong cua bang dbo.EQUIPMENT. roomId va purchaseDate co the null. */
public class Equipment {

    private final int equipmentId;
    private final String equipmentName;
    private final Integer roomId;
    private final String operationalStatus;
    private final LocalDate purchaseDate;

    public Equipment(int equipmentId, String equipmentName, Integer roomId,
                     String operationalStatus, LocalDate purchaseDate) {
        this.equipmentId = equipmentId;
        this.equipmentName = equipmentName;
        this.roomId = roomId;
        this.operationalStatus = operationalStatus;
        this.purchaseDate = purchaseDate;
    }

    public int getEquipmentId() { return equipmentId; }
    public String getEquipmentName() { return equipmentName; }
    public Integer getRoomId() { return roomId; }
    public String getOperationalStatus() { return operationalStatus; }
    public LocalDate getPurchaseDate() { return purchaseDate; }

    @Override
    public String toString() {
        return equipmentId + " | " + equipmentName + " | room=" + roomId
             + " | " + operationalStatus + " | " + purchaseDate;
    }
}
