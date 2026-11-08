package com.gym.ui;

import com.gym.model.Equipment;
import com.gym.model.SessionSlot;
import com.gym.model.Staff;
import com.gym.service.DbErrorMessages;
import com.gym.service.EquipmentService;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.SwingWorker;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.FlowLayout;
import java.awt.GridLayout;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Map;

/**
 * Tab danh sach thiet bi (Swing). Chi lo hien thi; du lieu lay qua EquipmentService.
 * Doc CSDL chay trong SwingWorker de cua so khong bi dung khi cho SQL Server tra loi.
 */
public class EquipmentPanel extends JPanel {

    private static final String[] COLUMNS = {"ID", "Name", "Room", "Status", "Purchase date"};
    private static final int STATUS_COL = 3;

    private final EquipmentService service;
    private final DefaultTableModel model = new DefaultTableModel(COLUMNS, 0) {
        @Override public boolean isCellEditable(int row, int col) { return false; }
    };
    private final JComboBox<String> statusBox = new JComboBox<>(
        new String[] {"All", "Active", "Under Maintenance", "Broken"});
    private final JLabel summary = new JLabel(" ");
    private static final DateTimeFormatter MINUTES = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private final JTable table = new JTable(model);

    /** Mot thao tac ghi CSDL (chay trong SwingWorker). */
    private interface DbAction { void run() throws Exception; }

    public EquipmentPanel(EquipmentService service) {
        super(new BorderLayout());
        this.service = service;

        table.setRowHeight(24);
        table.setAutoCreateRowSorter(true);
        table.getColumnModel().getColumn(0).setMaxWidth(60);
        table.getColumnModel().getColumn(STATUS_COL).setCellRenderer(new StatusRenderer());

        JButton refresh = new JButton("Refresh");
        refresh.addActionListener(e -> load());
        statusBox.addActionListener(e -> load());

        JPanel top = new JPanel(new FlowLayout(FlowLayout.LEFT));
        top.add(new JLabel("Status:"));
        top.add(statusBox);
        top.add(refresh);

        JButton update = new JButton("Status & maintenance log...");
        update.setToolTipText("Select a machine: send it to maintenance, report it broken, record work done, or set it Active again");
        update.addActionListener(e -> updateMachine());
        JButton reserve = new JButton("Reserve for session...");
        reserve.setToolTipText("Select a machine, then reserve it for a class or PT session");
        reserve.addActionListener(e -> reserveForSession());
        top.add(update);
        top.add(reserve);

        JPanel bottom = new JPanel(new FlowLayout(FlowLayout.LEFT));
        bottom.setBorder(BorderFactory.createEmptyBorder(2, 8, 2, 8));
        bottom.add(summary);

        add(top, BorderLayout.NORTH);
        add(new JScrollPane(table), BorderLayout.CENTER);
        add(bottom, BorderLayout.SOUTH);

        load();
    }

    /** Doc danh sach theo trang thai dang chon, roi do vao bang. */
    private void load() {
        String status = (String) statusBox.getSelectedItem();
        summary.setText("Loading...");
        new SwingWorker<Object[], Void>() {
            @Override protected Object[] doInBackground() throws Exception {
                List<Equipment> rows = service.getByStatus(status);
                Map<String, Long> counts = service.countByStatus();
                return new Object[] {rows, counts};
            }
            @Override @SuppressWarnings("unchecked") protected void done() {
                try {
                    Object[] r = get();
                    show((List<Equipment>) r[0], (Map<String, Long>) r[1]);
                } catch (Exception ex) {
                    Throwable cause = ex.getCause() != null ? ex.getCause() : ex;
                    summary.setText("Error");
                    JOptionPane.showMessageDialog(SwingUtilities.getWindowAncestor(EquipmentPanel.this),
                        "Cannot read equipment from the database:\n" + cause.getMessage(),
                        "Database error", JOptionPane.ERROR_MESSAGE);
                }
            }
        }.execute();
    }

    /** Dong dang chon trong bang (chi so cua model); -1 va nhac nguoi dung neu chua chon. */
    private int selectedModelRow() {
        int viewRow = table.getSelectedRow();
        if (viewRow < 0) {
            JOptionPane.showMessageDialog(this, "Select a machine in the table first.",
                "No machine selected", JOptionPane.INFORMATION_MESSAGE);
            return -1;
        }
        return table.convertRowIndexToModel(viewRow);   // bang co the dang duoc sap xep
    }

    /**
     * Mot nut cho moi viec ve tinh trang may: doi trang thai va/hoac ghi log bao tri.
     * Danh sach nguoi ky doc tu CSDL truoc khi hien hop thoai.
     */
    private void updateMachine() {
        int row = selectedModelRow();
        if (row < 0) {
            return;
        }
        int id = (Integer) model.getValueAt(row, 0);
        String name = String.valueOf(model.getValueAt(row, 1));
        String current = String.valueOf(model.getValueAt(row, STATUS_COL));
        new SwingWorker<List<Staff>, Void>() {
            @Override protected List<Staff> doInBackground() throws Exception {
                return service.getSigners();
            }
            @Override protected void done() {
                try {
                    showUpdateDialog(id, name, current, get());
                } catch (Exception ex) {
                    showError(ex);
                }
            }
        }.execute();
    }

    private void showUpdateDialog(int id, String name, String current, List<Staff> signers) {
        JComboBox<String> statusChoice = new JComboBox<>(EquipmentService.STATUSES.toArray(new String[0]));
        statusChoice.setSelectedItem(current);
        JComboBox<Staff> signerBox = new JComboBox<>(signers.toArray(new Staff[0]));
        JTextField dateField = new JTextField(LocalDate.now().toString(), 12);
        JTextField costField = new JTextField("0", 12);
        JTextField descField = new JTextField(28);
        JLabel hint = new JLabel(" ");
        hint.setForeground(Color.DARK_GRAY);

        // Chuyen sang Under Maintenance / Broken: bat buoc co nguoi chiu trach nhiem va mo ta.
        // Giu nguyen hoac ve Active: mo ta de trong thi chi doi trang thai, khong ghi log.
        String[] lastDefault = {""};
        Runnable refresh = () -> {
            String chosen = (String) statusChoice.getSelectedItem();
            boolean changes = !chosen.equals(current);
            boolean required = changes && !"Active".equals(chosen);
            hint.setText(required
                ? "Required: who is responsible and a description (saved as a maintenance log)."
                : "Optional: fill Description only to record work that was done (with its cost).");
            String suggestion = !changes ? ""
                              : "Broken".equals(chosen) ? "Reported broken"
                              : "Under Maintenance".equals(chosen) ? "Sent for maintenance" : "";
            if (descField.getText().isEmpty() || descField.getText().equals(lastDefault[0])) {
                descField.setText(suggestion);
            }
            lastDefault[0] = suggestion;
        };
        statusChoice.addActionListener(e -> refresh.run());
        refresh.run();

        JPanel form = new JPanel(new GridLayout(0, 2, 6, 6));
        form.add(new JLabel("New status:"));          form.add(statusChoice);
        form.add(new JLabel("Date (yyyy-MM-dd):"));   form.add(dateField);
        form.add(new JLabel("Signed off by:"));       form.add(signerBox);
        form.add(new JLabel("Description:"));         form.add(descField);
        form.add(new JLabel("Cost:"));                form.add(costField);

        int ok = JOptionPane.showConfirmDialog(this,
            new Object[] {"Machine: " + name + "  (now: " + current + ")", form, hint},
            "Status & maintenance log", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
        if (ok != JOptionPane.OK_OPTION) {
            return;
        }
        String newStatus = (String) statusChoice.getSelectedItem();
        LocalDate date = parseDate(dateField.getText());
        BigDecimal cost = parseCost(costField.getText());
        String description = descField.getText();
        Staff signer = (Staff) signerBox.getSelectedItem();
        boolean hasDescription = !description.trim().isEmpty();
        String message = name + ": "
            + (newStatus.equals(current) ? "status unchanged" : "status is now " + newStatus)
            + (hasDescription || (!newStatus.equals(current) && !"Active".equals(newStatus))
                ? ". Maintenance log saved, signed off by " + signer + "." : ".");
        runWrite(() -> service.updateMachine(id, current, newStatus, date, cost, description, signer), message);
    }

    /** Dat may dang chon cho mot buoi tap. Danh sach buoi tap doc tu CSDL truoc khi hien hop thoai. */
    private void reserveForSession() {
        int row = selectedModelRow();
        if (row < 0) {
            return;
        }
        int id = (Integer) model.getValueAt(row, 0);
        String name = String.valueOf(model.getValueAt(row, 1));
        String status = String.valueOf(model.getValueAt(row, STATUS_COL));
        // bao ngay khi bam nut, khong bat nguoi dung chon buoi roi moi bi tu choi
        // (trigger BR-FAC-06 trong CSDL van la lop chan chinh thuc, day chi de tien cho nguoi dung)
        if (!"Active".equals(status)) {
            JOptionPane.showMessageDialog(this,
                name + " is \"" + status + "\" and cannot be reserved.\n"
                + "Only machines with status Active can be reserved for a session.\n"
                + "Use \"Status & maintenance log...\" to set it back to Active when it is repaired.",
                "Machine not available", JOptionPane.WARNING_MESSAGE);
            return;
        }
        new SwingWorker<List<SessionSlot>, Void>() {
            @Override protected List<SessionSlot> doInBackground() throws Exception {
                return service.getReservableSessions();
            }
            @Override protected void done() {
                try {
                    showReserveDialog(id, name, get());
                } catch (Exception ex) {
                    showError(ex);
                }
            }
        }.execute();
    }

    private void showReserveDialog(int id, String name, List<SessionSlot> sessions) {
        if (sessions.isEmpty()) {
            JOptionPane.showMessageDialog(this, "There is no upcoming session to reserve a machine for.",
                "No sessions", JOptionPane.INFORMATION_MESSAGE);
            return;
        }
        JComboBox<SessionSlot> sessionBox = new JComboBox<>(sessions.toArray(new SessionSlot[0]));
        sessionBox.setPrototypeDisplayValue(sessions.get(0));
        JTextField fromField = new JTextField(16);
        JTextField toField = new JTextField(16);
        // gio mac dinh = gio cua buoi tap dang chon; nguoi dung co the sua (de thu luat BR-FAC-09)
        Runnable fillTimes = () -> {
            SessionSlot picked = (SessionSlot) sessionBox.getSelectedItem();
            if (picked != null) {
                fromField.setText(picked.getStart().format(MINUTES));
                toField.setText(picked.getEnd().format(MINUTES));
            }
        };
        sessionBox.addActionListener(e -> fillTimes.run());
        fillTimes.run();

        JPanel form = new JPanel(new GridLayout(0, 2, 6, 6));
        form.add(new JLabel("Session:"));                      form.add(sessionBox);
        form.add(new JLabel("Start (yyyy-MM-dd HH:mm):"));     form.add(fromField);
        form.add(new JLabel("End (yyyy-MM-dd HH:mm):"));       form.add(toField);

        int ok = JOptionPane.showConfirmDialog(this,
            new Object[] {"Machine: " + name, form},
            "Reserve for session", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
        if (ok != JOptionPane.OK_OPTION) {
            return;
        }
        SessionSlot session = (SessionSlot) sessionBox.getSelectedItem();
        LocalDateTime from = parseDateTime(fromField.getText());
        LocalDateTime to = parseDateTime(toField.getText());
        runWrite(() -> service.reserveForSession(id, session, from, to),
                 name + " is reserved for session #" + (session == null ? "?" : session.getSessionId()) + ".");
    }

    /** null neu nhap sai; Service se bao loi de hieu. */
    private static LocalDateTime parseDateTime(String text) {
        try {
            return LocalDateTime.parse(text.trim().replace(' ', 'T'));
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    /** null neu nhap sai; Service se bao loi de hieu. */
    private static LocalDate parseDate(String text) {
        try {
            return LocalDate.parse(text.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static BigDecimal parseCost(String text) {
        try {
            return new BigDecimal(text.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** Chay thao tac ghi CSDL o luong nen; xong thi nap lai bang, loi thi hien hop thoai de hieu. */
    private void runWrite(DbAction action, String successMessage) {
        new SwingWorker<Void, Void>() {
            @Override protected Void doInBackground() throws Exception {
                action.run();
                return null;
            }
            @Override protected void done() {
                try {
                    get();
                    load();
                    JOptionPane.showMessageDialog(EquipmentPanel.this, successMessage,
                        "Saved", JOptionPane.INFORMATION_MESSAGE);
                } catch (Exception ex) {
                    showError(ex);
                }
            }
        }.execute();
    }

    /** Lay loi goc (SwingWorker boc loi trong ExecutionException) roi hien cau de hieu. */
    private void showError(Exception ex) {
        Throwable cause = ex.getCause() != null ? ex.getCause() : ex;
        JOptionPane.showMessageDialog(this, DbErrorMessages.explain(cause),
            "Cannot save", JOptionPane.WARNING_MESSAGE);
    }

    private void show(List<Equipment> rows, Map<String, Long> counts) {
        model.setRowCount(0);
        for (Equipment e : rows) {
            model.addRow(new Object[] {
                e.getEquipmentId(),
                e.getEquipmentName(),
                e.getRoomId() == null ? "-" : e.getRoomId(),
                e.getOperationalStatus(),
                e.getPurchaseDate() == null ? "-" : e.getPurchaseDate()});
        }
        summary.setText("Showing " + rows.size() + " machine(s)   |   Active: " + counts.get("Active")
            + "   Under Maintenance: " + counts.get("Under Maintenance")
            + "   Broken: " + counts.get("Broken"));
    }

    /** To mau o Status: xanh = Active, vang = Under Maintenance, do = Broken. */
    private static class StatusRenderer extends DefaultTableCellRenderer {
        @Override
        public Component getTableCellRendererComponent(JTable t, Object v, boolean sel,
                                                       boolean focus, int row, int col) {
            Component c = super.getTableCellRendererComponent(t, v, sel, focus, row, col);
            if (!sel) {
                String s = String.valueOf(v);
                c.setBackground(s.equals("Active") ? new Color(0xD5F0D8)
                              : s.equals("Under Maintenance") ? new Color(0xFFF0C2)
                              : s.equals("Broken") ? new Color(0xF8D0D0) : Color.WHITE);
            }
            return c;
        }
    }
}
