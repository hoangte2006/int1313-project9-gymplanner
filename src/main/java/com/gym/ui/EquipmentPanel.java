package com.gym.ui;

import com.gym.model.Equipment;
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
import javax.swing.SwingWorker;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.FlowLayout;
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

    public EquipmentPanel(EquipmentService service) {
        super(new BorderLayout());
        this.service = service;

        JTable table = new JTable(model);
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
