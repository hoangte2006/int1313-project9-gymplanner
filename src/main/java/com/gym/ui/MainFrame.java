package com.gym.ui;

import com.gym.service.EquipmentService;

import javax.swing.JFrame;
import javax.swing.JTabbedPane;

/**
 * Cua so chinh: moi nguoi them MOT TAB cho phan cua minh o day.
 * Vi du Quang them: tabs.addTab("Members", new MemberPanel(new MemberService()));
 */
public class MainFrame extends JFrame {

    public MainFrame() {
        super("Gym Membership & Personal Training Planner");
        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Equipment", new EquipmentPanel(new EquipmentService()));   // Te
        // tabs.addTab("Members", ...);     // Quang: them tab o day
        // tabs.addTab("Classes & PT", ...); // Phuong: them tab o day
        add(tabs);

        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(760, 460);
        setLocationRelativeTo(null);
    }
}
