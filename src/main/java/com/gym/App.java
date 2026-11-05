package com.gym;

import com.gym.ui.MainFrame;

import javax.swing.SwingUtilities;

/** Diem vao cua ung dung. Chay: mvn -q compile exec:java -Dexec.mainClass=com.gym.App */
public class App {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new MainFrame().setVisible(true));
    }
}
