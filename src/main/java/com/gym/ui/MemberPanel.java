package com.gym.ui;

import com.gym.model.Member;
import com.gym.service.MemberService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.List;

public class MemberPanel extends JPanel {

    private final MemberService service = new MemberService();

    private final JTextField searchField = new JTextField(20);

    private final DefaultTableModel tableModel =
        new DefaultTableModel(
            new String[] {
                "Member ID",
                "Full Name",
                "Phone Number",
                "Email",
                "Registration Date"
            }, 0
        ) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

    private final JTable memberTable = new JTable(tableModel);

    public MemberPanel() {

        setLayout(new BorderLayout(10, 10));

        setBorder(
            BorderFactory.createEmptyBorder(15, 15, 15, 15)
        );

        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));

        JButton searchButton = new JButton("Search");
        JButton refreshButton = new JButton("Refresh");
        JButton addButton = new JButton("Add Member");

        topPanel.add(new JLabel("Search:"));
        topPanel.add(searchField);
        topPanel.add(searchButton);
        topPanel.add(refreshButton);
        topPanel.add(addButton);

        add(topPanel, BorderLayout.NORTH);
        add(new JScrollPane(memberTable), BorderLayout.CENTER);

        memberTable.setRowHeight(26);
        memberTable.setAutoCreateRowSorter(true);

        searchButton.addActionListener(e ->
            loadMembers(searchField.getText())
        );

        refreshButton.addActionListener(e -> {
            searchField.setText("");
            loadMembers("");
        });

        addButton.addActionListener(e -> showAddMemberDialog());

        loadMembers("");
    }

    private void loadMembers(String keyword) {

        new SwingWorker<List<Member>, Void>() {

            @Override
            protected List<Member> doInBackground() throws Exception {
                return service.getMembers(keyword);
            }

            @Override
            protected void done() {

                try {
                    List<Member> members = get();

                    tableModel.setRowCount(0);

                    for (Member m : members) {
                        tableModel.addRow(new Object[] {
                            m.getMemberId(),
                            m.getFullName(),
                            m.getPhoneNumber(),
                            m.getEmail(),
                            m.getRegistrationDate()
                        });
                    }

                } catch (Exception e) {
                    showError(e);
                }
            }

        }.execute();
    }

    private void showAddMemberDialog() {

        JTextField nameField = new JTextField();
        JTextField phoneField = new JTextField();
        JTextField emailField = new JTextField();

        JPanel form = new JPanel(new GridLayout(3, 2, 10, 10));

        form.add(new JLabel("Full Name:"));
        form.add(nameField);

        form.add(new JLabel("Phone Number:"));
        form.add(phoneField);

        form.add(new JLabel("Email (optional):"));
        form.add(emailField);

        int result = JOptionPane.showConfirmDialog(
            this,
            form,
            "Register New Member",
            JOptionPane.OK_CANCEL_OPTION
        );

        if (result != JOptionPane.OK_OPTION) {
            return;
        }

        new SwingWorker<Integer, Void>() {

            @Override
            protected Integer doInBackground() throws Exception {
                return service.addMember(
                    nameField.getText(),
                    phoneField.getText(),
                    emailField.getText()
                );
            }

            @Override
            protected void done() {

                try {
                    int newId = get();

                    JOptionPane.showMessageDialog(
                        MemberPanel.this,
                        "Member created successfully!\n"
                        + "Member ID: " + newId
                    );

                    loadMembers("");

                } catch (Exception e) {
                    showError(e);
                }
            }

        }.execute();
    }

    private void showError(Exception e) {

        Throwable cause =
            e.getCause() != null ? e.getCause() : e;

        JOptionPane.showMessageDialog(
            this,
            cause.getMessage(),
            "Error",
            JOptionPane.ERROR_MESSAGE
        );
    }
}
