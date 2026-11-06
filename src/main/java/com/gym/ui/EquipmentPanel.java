package com.gym.ui;

import com.gym.model.Equipment;
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

        JButton changeStatus = new JButton("Change status...");
        changeStatus.setToolTipText("Select a machine, then report it broken, under maintenance, or active again");
        changeStatus.addActionListener(e -> changeStatus());
        JButton addLog = new JButton("Add maintenance log...");
        addLog.setToolTipText("Select a machine, then record a maintenance job");
        addLog.addActionListener(e -> addMaintenanceLog());
        top.add(changeStatus);
        top.add(addLog);

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

    /** Bao hong / doi trang thai may dang chon. */
    private void changeStatus() {
        int row = selectedModelRow();
        if (row < 0) {
            return;
        }
        int id = (Integer) model.getValueAt(row, 0);
        String name = String.valueOf(model.getValueAt(row, 1));
        JComboBox<String> box = new JComboBox<>(EquipmentService.STATUSES.toArray(new String[0]));
        box.setSelectedItem(model.getValueAt(row, STATUS_COL));

        int ok = JOptionPane.showConfirmDialog(this,
            new Object[] {"Machine: " + name, "New status:", box},
            "Change status", JOptionPane.OK_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE);
        if (ok != JOptionPane.OK_OPTION) {
            return;
        }
        String newStatus = (String) box.getSelectedItem();
        runWrite(() -> service.changeStatus(id, newStatus),
                 name + " is now \"" + newStatus + "\".");
    }

    /** Them log bao tri cho may dang chon. Danh sach nguoi ky doc tu CSDL truoc khi hien hop thoai. */
    private void addMaintenanceLog() {
        int row = selectedModelRow();
        if (row < 0) {
            return;
        }
        int id = (Integer) model.getValueAt(row, 0);
        String name = String.valueOf(model.getValueAt(row, 1));
        new SwingWorker<List<Staff>, Void>() {
            @Override protected List<Staff> doInBackground() throws Exception {
                return service.getSigners();
            }
            @Override protected void done() {
                try {
                    showLogDialog(id, name, get());
                } catch (Exception ex) {
                    showError(ex);
                }
            }
        }.execute();
    }

    private void showLogDialog(int id, String name, List<Staff> signers) {
        JTextField dateField = new JTextField(LocalDate.now().toString(), 12);
        JTextField costField = new JTextField("0", 12);
        JTextField descField = new JTextField(28);
        JComboBox<Staff> signerBox = new JComboBox<>(signers.toArray(new Staff[0]));

        JPanel form = new JPanel(new GridLayout(0, 2, 6, 6));
        form.add(new JLabel("Date (yyyy-MM-dd):")); form.add(dateField);
        form.add(new JLabel("Cost:"));              form.add(costField);
        form.add(new JLabel("Description:"));       form.add(descField);
        form.add(new JLabel("Signed off by:"));     form.add(signerBox);

        int ok = JOptionPane.showConfirmDialog(this,
            new Object[] {"Machine: " + name, form},
            "Add maintenance log", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
        if (ok != JOptionPane.OK_OPTION) {
            return;
        }
        LocalDate date = parseDate(dateField.getText());
        BigDecimal cost = parseCost(costField.getText());
        String description = descField.getText();
        Staff signer = (Staff) signerBox.getSelectedItem();
        runWrite(() -> service.addMaintenanceLog(id, date, cost, description, signer),
                 "Maintenance log saved for " + name + ".");
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
