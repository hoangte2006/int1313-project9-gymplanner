package com.gym.ui;

import com.gym.service.ClassPtService;
import com.gym.service.EquipmentService;
import javax.swing.JFrame;
import javax.swing.JTabbedPane;

public class MainFrame extends JFrame {

    public MainFrame() {
        super("Gym Membership & Personal Training Planner");
        JTabbedPane tabs = new JTabbedPane();

        tabs.addTab("Equipment", new EquipmentPanel(new EquipmentService()));
        tabs.addTab("Classes & PT", new ClassPtPanel());

        add(tabs);

        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setSize(760, 460);
        setLocationRelativeTo(null);
    }
}