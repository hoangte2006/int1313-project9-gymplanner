package com.gym.ui;

import com.gym.service.ClassPtService;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.Font;
import java.sql.SQLException;
import java.util.List;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.table.DefaultTableModel;

public class ClassPtPanel extends JPanel {
    private JTable table;
    private DefaultTableModel tableModel;
    private JTextField txtMemberId;
    private JButton btnRefresh, btnRegisterClass, btnBookPT;
    private ClassPtService service;

    public ClassPtPanel() {
        service = new ClassPtService();
        setLayout(new BorderLayout(10, 10));

        // 1. Thanh công cụ phía trên
        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 10, 5));
        topPanel.add(new JLabel("Mã Hội Viên:"));
        txtMemberId = new JTextField("M001", 8);
        topPanel.add(txtMemberId);

        btnRefresh = new JButton("Refresh");
        btnRegisterClass = new JButton("Đăng ký Lớp");
        btnBookPT = new JButton("Đặt Buổi PT");

        topPanel.add(btnRefresh);
        topPanel.add(btnRegisterClass);
        topPanel.add(btnBookPT);
        add(topPanel, BorderLayout.NORTH);

        // 2. Cấu trúc các cột JTable
        String[] columns = {
            "Mã Buổi (ID)", "Loại", "Tên Lớp / PT", "Bắt Đầu", 
            "Kết Thúc", "Phòng", "HLV", "Sức Chứa", "Trạng Thái"
        };
        tableModel = new DefaultTableModel(columns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };

        // 3. Khởi tạo JTable và định dạng UI
        table = new JTable(tableModel);
        table.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        table.getTableHeader().setFont(new Font("Segoe UI", Font.BOLD, 13));
        table.setRowHeight(24);

        table.getColumnModel().getColumn(2).setPreferredWidth(130);
        table.getColumnModel().getColumn(3).setPreferredWidth(140);
        table.getColumnModel().getColumn(4).setPreferredWidth(140);

        add(new JScrollPane(table), BorderLayout.CENTER);

        // 4. Xử lý nút bấm
        btnRefresh.addActionListener(e -> loadData());

        btnRegisterClass.addActionListener(e -> {
            int row = table.getSelectedRow();
            if (row == -1) {
                JOptionPane.showMessageDialog(this, "Vui lòng chọn 1 lớp học từ danh sách!", "Thông báo", JOptionPane.WARNING_MESSAGE);
                return;
            }
            String type = table.getValueAt(row, 1).toString();
            if (!"Class".equalsIgnoreCase(type)) {
                JOptionPane.showMessageDialog(this, "Dòng được chọn là buổi PT, vui lòng chọn nút 'Đặt Buổi PT'!", "Lỗi", JOptionPane.ERROR_MESSAGE);
                return;
            }
            String sessionId = table.getValueAt(row, 0).toString();
            String memberId = txtMemberId.getText().trim();
            try {
                service.registerClass(sessionId, memberId);
                JOptionPane.showMessageDialog(this, "Đăng ký lớp thành công!");
                loadData();
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Lỗi đăng ký lớp: " + ex.getMessage(), "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        });

        btnBookPT.addActionListener(e -> {
            int row = table.getSelectedRow();
            if (row == -1) {
                JOptionPane.showMessageDialog(this, "Vui lòng chọn 1 buổi PT từ danh sách!", "Thông báo", JOptionPane.WARNING_MESSAGE);
                return;
            }
            String type = table.getValueAt(row, 1).toString();
            if (!"PT".equalsIgnoreCase(type)) {
                JOptionPane.showMessageDialog(this, "Dòng được chọn là Lớp học, vui lòng chọn nút 'Đăng ký Lớp'!", "Lỗi", JOptionPane.ERROR_MESSAGE);
                return;
            }
            String sessionId = table.getValueAt(row, 0).toString();
            String memberId = txtMemberId.getText().trim();
            try {
                service.bookPT(sessionId, memberId);
                JOptionPane.showMessageDialog(this, "Đặt buổi PT thành công!");
                loadData();
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, "Lỗi đặt buổi PT: " + ex.getMessage(), "Lỗi", JOptionPane.ERROR_MESSAGE);
            }
        });

        loadData();
    }

    private void loadData() {
        tableModel.setRowCount(0);
        try {
            List<Object[]> list = service.getScheduleList();
            for (Object[] row : list) {
                // Tự động sửa hiển thị phông chữ tiếng Việt cho cột Tên Lớp/PT
                if (row[2] != null) {
                    String className = row[2].toString();
                    if (className.contains("Bu?") || className.contains("Bu?i") || className.equalsIgnoreCase("Bu?i t?p PT")) {
                        row[2] = "Buổi tập PT";
                    }
                }
                tableModel.addRow(row);
            }
        } catch (SQLException ex) {
            JOptionPane.showMessageDialog(this, "Lỗi tải dữ liệu: " + ex.getMessage(), "Lỗi", JOptionPane.ERROR_MESSAGE);
        }
    }
}