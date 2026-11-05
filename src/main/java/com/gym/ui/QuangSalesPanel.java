package com.gym.ui;

import com.gym.dao.BillingDao;
import com.gym.model.Member;
import com.gym.model.Plan;
import com.gym.service.MemberService;
import com.gym.service.PurchaseService;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.function.Consumer;

public class QuangSalesPanel extends JPanel {

    private final MemberService memberService =
        new MemberService();

    private final PurchaseService purchaseService =
        new PurchaseService();

    private final JComboBox<Member> memberBox =
        new JComboBox<>();

    private final JComboBox<Plan> planBox =
        new JComboBox<>();

    private final JTextField startDateField =
        new JTextField(LocalDate.now().toString(), 12);

    private final JTextField guestNameField =
        new JTextField(18);

    private final JTextField guestPhoneField =
        new JTextField(15);

    private final JTextField visitDateField =
        new JTextField(LocalDate.now().toString(), 12);

    private final JTextField rateField =
        new JTextField("100000", 12);

    private final DefaultTableModel invoiceModel =
        new DefaultTableModel(
            new String[] {
                "Bill ID", "Type", "Purchase ID",
                "Customer", "Invoice Date",
                "Amount", "Status"
            }, 0
        ) {
            @Override
            public boolean isCellEditable(int row, int col) {
                return false;
            }
        };

    @FunctionalInterface
    private interface DbTask<T> {
        T execute() throws Exception;
    }

    public QuangSalesPanel() {
        setLayout(new BorderLayout());

        JTabbedPane tabs = new JTabbedPane();
        tabs.addTab("Membership / Renewal", membershipTab());
        tabs.addTab("Daily Pass", dailyPassTab());
        tabs.addTab("Invoices", invoiceTab());

        add(tabs, BorderLayout.CENTER);

        refreshMembers();
        refreshPlans();
        refreshInvoices();
    }

    private JPanel row(Component... components) {
        JPanel panel = new JPanel(
            new FlowLayout(FlowLayout.LEFT, 10, 8)
        );

        for (Component component : components) {
            panel.add(component);
        }

        return panel;
    }

    private JPanel page() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));

        panel.setBorder(
            BorderFactory.createEmptyBorder(
                15, 15, 15, 15
            )
        );
        return panel;
    }

    private void showError(Throwable error) {
        Throwable root = error;

        while (root.getCause() != null) {
            root = root.getCause();
        }

        JOptionPane.showMessageDialog(
            this,
            root.getMessage(),
            "Error",
            JOptionPane.ERROR_MESSAGE
        );
    }

    // Run SQL outside Swing's Event Dispatch Thread.
    private <T> void runAsync(
            JButton button,
            DbTask<T> task,
            Consumer<T> onSuccess
    ) {
        if (button != null) {
            button.setEnabled(false);
        }

        new SwingWorker<T, Void>() {
            @Override
            protected T doInBackground() throws Exception {
                return task.execute();
            }

            @Override
            protected void done() {
                if (button != null) {
                    button.setEnabled(true);
                }

                try {
                    onSuccess.accept(get());
                } catch (Exception ex) {
                    showError(ex);
                }
            }
        }.execute();
    }

    // =========================================================
    // MEMBERSHIP PURCHASE / RENEWAL
    // =========================================================

    private JPanel membershipTab() {
        JPanel panel = page();

        JPanel form = new JPanel(
            new GridLayout(0, 2, 12, 12)
        );

        form.add(new JLabel("Member:"));
        form.add(memberBox);

        form.add(new JLabel("Membership Plan:"));
        form.add(planBox);

        form.add(new JLabel("Start Date (YYYY-MM-DD):"));
        form.add(startDateField);

        JButton purchaseButton =
            new JButton("Purchase Membership");

        JButton renewButton =
            new JButton("Renew Membership");

        JButton refreshButton =
            new JButton("Refresh Members / Plans");

        purchaseButton.addActionListener(
            e -> purchaseMembership(false, purchaseButton)
        );

        renewButton.addActionListener(
            e -> purchaseMembership(true, renewButton)
        );

        refreshButton.addActionListener(e -> {
            refreshMembers();
            refreshPlans();
        });

        JTextArea info = new JTextArea(
            "Purchase: create a new Membership and Bill.\n"
            + "Renew: create a new Membership period and Bill.\n"
            + "The previous Membership remains in history.\n"
            + "A new Bill starts with status Pending."
        );

        info.setEditable(false);
        info.setOpaque(false);

        panel.add(form, BorderLayout.NORTH);

        JPanel bottom = new JPanel(new BorderLayout());

        bottom.add(
            row(purchaseButton, renewButton, refreshButton),
            BorderLayout.NORTH
        );

        bottom.add(info, BorderLayout.CENTER);
        panel.add(bottom, BorderLayout.CENTER);

        return panel;
    }

    private void refreshMembers() {
        runAsync(
            null,
            () -> memberService.getMembers(""),
            members -> {
                memberBox.removeAllItems();

                for (Member member : members) {
                    memberBox.addItem(member);
                }
            }
        );
    }

    private void refreshPlans() {
        runAsync(
            null,
            purchaseService::getPlans,
            plans -> {
                planBox.removeAllItems();

                for (Plan plan : plans) {
                    planBox.addItem(plan);
                }
            }
        );
    }

    private void purchaseMembership(
            boolean renew,
            JButton button
    ) {
        Member member =
            (Member) memberBox.getSelectedItem();

        Plan plan =
            (Plan) planBox.getSelectedItem();

        if (member == null || plan == null) {
            showError(new IllegalArgumentException(
                "Please select Member and Membership Plan"
            ));
            return;
        }

        final LocalDate startDate;

        try {
            startDate = LocalDate.parse(
                startDateField.getText().trim()
            );
        } catch (Exception ex) {
            showError(new IllegalArgumentException(
                "Start date must be YYYY-MM-DD"
            ));
            return;
        }

        runAsync(
            button,
            () -> purchaseService.purchaseMembership(
                member.getMemberId(),
                plan.getPlanId(),
                startDate,
                renew
            ),
            receipt -> {
                JOptionPane.showMessageDialog(
                    this,
                    "Membership created successfully!\n"
                    + "Membership ID: "
                    + receipt.purchaseId()
                    + "\nBill ID: " + receipt.billId()
                    + "\nAmount: " + receipt.amount()
                    + "\nBilling Status: Pending"
                );

                refreshInvoices();
            }
        );
    }

    // =========================================================
    // DAILY PASS
    // =========================================================

    private JPanel dailyPassTab() {
        JPanel panel = page();

        JPanel form = new JPanel(
            new GridLayout(0, 2, 12, 12)
        );

        form.add(new JLabel("Guest Name:"));
        form.add(guestNameField);

        form.add(new JLabel("Guest Phone:"));
        form.add(guestPhoneField);

        form.add(new JLabel("Visit Date (YYYY-MM-DD):"));
        form.add(visitDateField);

        form.add(new JLabel("Daily Rate (VND):"));
        form.add(rateField);

        JButton buyButton =
            new JButton("Purchase Daily Pass");

        buyButton.addActionListener(
            e -> purchaseDailyPass(buyButton)
        );

        panel.add(form, BorderLayout.NORTH);
        panel.add(row(buyButton), BorderLayout.CENTER);

        return panel;
    }

    private void purchaseDailyPass(JButton button) {
        final LocalDate visitDate;
        final BigDecimal rate;

        try {
            visitDate = LocalDate.parse(
                visitDateField.getText().trim()
            );

            rate = new BigDecimal(
                rateField.getText().trim()
            );
        } catch (Exception ex) {
            showError(new IllegalArgumentException(
                "Check Visit Date and Daily Rate"
            ));
            return;
        }

        String name = guestNameField.getText();
        String phone = guestPhoneField.getText();

        runAsync(
            button,
            () -> purchaseService.purchaseDailyPass(
                name, phone, visitDate, rate
            ),
            receipt -> {
                JOptionPane.showMessageDialog(
                    this,
                    "Daily Pass created successfully!\n"
                    + "Ticket ID: " + receipt.purchaseId()
                    + "\nBill ID: " + receipt.billId()
                    + "\nAmount: " + receipt.amount()
                    + "\nBilling Status: Pending"
                );

                refreshInvoices();
            }
        );
    }

    // =========================================================
    // INVOICES
    // =========================================================

    private JPanel invoiceTab() {
        JPanel panel = page();

        JTable invoiceTable = new JTable(invoiceModel);
        invoiceTable.setRowHeight(26);
        invoiceTable.setAutoCreateRowSorter(true);

        JButton refreshButton =
            new JButton("Refresh Invoices");

        refreshButton.addActionListener(
            e -> refreshInvoices()
        );

        panel.add(
            row(refreshButton),
            BorderLayout.NORTH
        );

        panel.add(
            new JScrollPane(invoiceTable),
            BorderLayout.CENTER
        );

        return panel;
    }

    private void refreshInvoices() {
        runAsync(
            null,
            purchaseService::getBills,
            bills -> {
                invoiceModel.setRowCount(0);

                for (BillingDao.BillRow bill : bills) {
                    invoiceModel.addRow(new Object[] {
                        bill.billId(),
                        bill.sourceType(),
                        bill.purchaseId(),
                        bill.customer(),
                        bill.invoiceDate(),
                        bill.amount(),
                        bill.status()
                    });
                }
            }
        );
    }
}
