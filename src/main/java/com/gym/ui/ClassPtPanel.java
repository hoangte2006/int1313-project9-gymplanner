package com.gym.ui;

import com.gym.service.ClassPtService;
import com.gym.service.DbErrorMessages;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.GridLayout;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.SwingWorker;
import javax.swing.table.DefaultTableModel;

public class ClassPtPanel extends JPanel {
    private JTable table;
    private DefaultTableModel tableModel;
    private JTextField txtMemberId;
    private JButton btnRefresh, btnRegisterClass, btnBookPT, btnNewPT;
    private ClassPtService service;

    public ClassPtPanel() {
        service = new ClassPtService();
        setLayout(new BorderLayout(10, 10));

        // 1. Toolbar
        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 5));
        topPanel.add(new JLabel("Member ID:"));
        txtMemberId = new JTextField("M001", 8);
        topPanel.add(txtMemberId);

        btnRefresh = new JButton("Refresh");
        btnRegisterClass = new JButton("Register for Class");
        btnBookPT = new JButton("Book PT Session");
        btnNewPT = new JButton("Create & book new PT...");

        topPanel.add(btnRefresh);
        topPanel.add(btnRegisterClass);
        topPanel.add(btnBookPT);
        topPanel.add(btnNewPT);
        add(topPanel, BorderLayout.NORTH);

        // 2. JTable columns
        String[] columns = {
            "Session ID", "Type", "Class / PT", "Start", 
            "End", "Room", "Trainer", "Capacity", "Status"
        };
        tableModel = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        // 3. Create the JTable and style it
        table = new JTable(tableModel);
        table.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        table.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 13));
        table.setRowHeight(24);

        table.getColumnModel().getColumn(2).setPreferredWidth(130);
        table.getColumnModel().getColumn(3).setPreferredWidth(140);
        table.getColumnModel().getColumn(4).setPreferredWidth(140);

        add(new JScrollPane(table), BorderLayout.CENTER);

        // 4. Button handlers
        btnRefresh.addActionListener(e -> loadData());

        btnRegisterClass.addActionListener(e -> {
            int row = table.getSelectedRow();
            if (row == -1) {
                JOptionPane.showMessageDialog(this, "Please select a class from the list.", "No class selected", JOptionPane.WARNING_MESSAGE);
                return;
            }
            String type = table.getValueAt(row, 1).toString();
            if (!"Class".equalsIgnoreCase(type)) {
                JOptionPane.showMessageDialog(this, "The selected row is a PT session. Use the 'Book PT Session' button.", "Wrong session type", JOptionPane.ERROR_MESSAGE);
                return;
            }
            String sessionId = table.getValueAt(row, 0).toString();
            String memberId = txtMemberId.getText().trim();
            try {
                service.registerClass(sessionId, memberId);
                JOptionPane.showMessageDialog(this, "Registered for the class.");
                loadData();
            } catch (Exception ex) {
                showError("Could not register for the class", ex);
            }
        });

        btnBookPT.addActionListener(e -> {
            int row = table.getSelectedRow();
            if (row == -1) {
                JOptionPane.showMessageDialog(this, "Please select a PT session from the list.", "No session selected", JOptionPane.WARNING_MESSAGE);
                return;
            }
            String type = table.getValueAt(row, 1).toString();
            if (!"PT".equalsIgnoreCase(type)) {
                JOptionPane.showMessageDialog(this, "The selected row is a class. Use the 'Register for Class' button.", "Wrong session type", JOptionPane.ERROR_MESSAGE);
                return;
            }
            String sessionId = table.getValueAt(row, 0).toString();
            String memberId = txtMemberId.getText().trim();
            try {
                service.bookPT(sessionId, memberId);
                JOptionPane.showMessageDialog(this, "PT session booked.");
                loadData();
            } catch (Exception ex) {
                showError("Could not book the PT session", ex);
            }
        });

        btnNewPT.addActionListener(e -> newPtSession());

        loadData();
    }

    /** Doc lich o luong nen (3000+ dong) de cua so khong bi dung, roi do vao bang. */
    private void loadData() {
        new SwingWorker<List<Object[]>, Void>() {
            @Override protected List<Object[]> doInBackground() throws Exception {
                return service.getScheduleList();
            }
            @Override protected void done() {
                try {
                    List<Object[]> list = get();
                    tableModel.setRowCount(0);
                    for (Object[] row : list) {
                        tableModel.addRow(row);
                    }
                } catch (Exception ex) {
                    showError("Could not load the schedule", ex);
                }
            }
        }.execute();
    }

    /** One choice in the room / trainer drop-down. */
    private record Option(int id, String label) {
        @Override public String toString() { return label; }
    }

    /** Create a new PT session and book it for the member typed in "Member ID", in one transaction. */
    private void newPtSession() {
        String memberId = txtMemberId.getText().trim();
        new SwingWorker<List<List<Object[]>>, Void>() {
            @Override protected List<List<Object[]>> doInBackground() throws Exception {
                return List.of(service.getRooms(), service.getTrainers());
            }
            @Override protected void done() {
                try {
                    List<List<Object[]>> lists = get();
                    showNewPtDialog(memberId, toOptions(lists.get(0)), toOptions(lists.get(1)));
                } catch (Exception ex) {
                    showError("Could not load rooms / trainers", ex);
                }
            }
        }.execute();
    }

    private static Option[] toOptions(List<Object[]> rows) {
        return rows.stream().map(r -> new Option((Integer) r[0], (String) r[1])).toArray(Option[]::new);
    }

    private void showNewPtDialog(String memberId, Option[] rooms, Option[] trainers) {
        JComboBox<Option> roomBox = new JComboBox<>(rooms);
        JComboBox<Option> trainerBox = new JComboBox<>(trainers);
        JTextField startField = new JTextField(
            LocalDateTime.now().plusDays(1).withHour(9).withMinute(0).withSecond(0).withNano(0)
                         .toString().replace('T', ' ').substring(0, 16), 14);
        JTextField minutesField = new JTextField("60", 14);

        JPanel form = new JPanel(new GridLayout(0, 2, 6, 6));
        form.add(new JLabel("Member:"));                  form.add(new JLabel(memberId));
        form.add(new JLabel("Room:"));                     form.add(roomBox);
        form.add(new JLabel("Trainer:"));           form.add(trainerBox);
        form.add(new JLabel("Start (yyyy-MM-dd HH:mm):")); form.add(startField);
        form.add(new JLabel("Duration (minutes):"));         form.add(minutesField);

        int ok = JOptionPane.showConfirmDialog(this, form, "Create & book new PT session",
            JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
        if (ok != JOptionPane.OK_OPTION) {
            return;
        }
        Option room = (Option) roomBox.getSelectedItem();
        Option trainer = (Option) trainerBox.getSelectedItem();
        LocalDateTime start = parseDateTime(startField.getText());
        int minutes = parseInt(minutesField.getText());

        new SwingWorker<Integer, Void>() {
            @Override protected Integer doInBackground() throws Exception {
                return service.bookNewPt(memberId, room == null ? null : room.id(),
                                         trainer == null ? null : trainer.id(), start, minutes);
            }
            @Override protected void done() {
                try {
                    int sessionId = get();
                    JOptionPane.showMessageDialog(ClassPtPanel.this,
                        "New PT session created and booked (session ID " + sessionId + ").");
                    loadData();
                } catch (Exception ex) {
                    showError("Could not book the new PT session", ex);
                }
            }
        }.execute();
    }

    private static LocalDateTime parseDateTime(String text) {
        try {
            return LocalDateTime.parse(text.trim().replace(' ', 'T'));
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static int parseInt(String text) {
        try {
            return Integer.parseInt(text.trim());
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    /** Unwrap the real error (SwingWorker wraps it in ExecutionException) and show a clear message. */
    private void showError(String title, Exception ex) {
        Throwable cause = ex.getCause() != null ? ex.getCause() : ex;
        JOptionPane.showMessageDialog(this, DbErrorMessages.explain(cause), title, JOptionPane.WARNING_MESSAGE);
    }
}
