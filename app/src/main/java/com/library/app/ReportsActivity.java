package com.library.app;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class ReportsActivity extends AppCompatActivity {

    private Button btnBookReport, btnIssueReport, btnFineReport;
    private TextView btnBack;
    private LinearLayout llReportContent;
    private DatabaseHelper dbHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_reports);

        dbHelper = new DatabaseHelper(this);

        btnBookReport = findViewById(R.id.btnBookReport);
        btnIssueReport = findViewById(R.id.btnIssueReport);
        btnFineReport = findViewById(R.id.btnFineReport);
        btnBack = findViewById(R.id.btnBack);
        llReportContent = findViewById(R.id.llReportContent);

        btnBack.setOnClickListener(v -> finish());
        btnBookReport.setOnClickListener(v -> showBookReport());
        btnIssueReport.setOnClickListener(v -> showIssueReport());
        btnFineReport.setOnClickListener(v -> showFineReport());
    }

    private void showBookReport() {
        llReportContent.removeAllViews();

        List<String[]> books = dbHelper.getAllBooks();

        View header = LayoutInflater.from(this).inflate(R.layout.report_header, null);
        TextView tvHeaderTitle = header.findViewById(R.id.tvReportHeaderTitle);
        TextView tvHeaderDate = header.findViewById(R.id.tvReportHeaderDate);
        tvHeaderTitle.setText("📚 BOOKS INVENTORY REPORT");
        tvHeaderDate.setText(new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US).format(new Date()));
        llReportContent.addView(header);

        int available = 0, issued = 0;

        for (String[] book : books) {
            View itemView = LayoutInflater.from(this).inflate(R.layout.report_book_item, null);

            TextView tvBookId = itemView.findViewById(R.id.tvReportBookId);
            TextView tvBookTitle = itemView.findViewById(R.id.tvReportBookTitle);
            TextView tvBookAuthor = itemView.findViewById(R.id.tvReportBookAuthor);
            TextView tvBookStatus = itemView.findViewById(R.id.tvReportBookStatus);
            TextView tvBookQuantity = itemView.findViewById(R.id.tvReportBookQuantity);

            int availableQty = dbHelper.getAvailableQuantity(book[0]);

            tvBookId.setText(book[0]);
            tvBookTitle.setText(book[1]);
            tvBookAuthor.setText(book[2]);

            if (availableQty > 0) {
                tvBookStatus.setText("AVAILABLE");
                tvBookStatus.setTextColor(getColor(R.color.success));
                available++;
            } else {
                tvBookStatus.setText("ISSUED");
                tvBookStatus.setTextColor(getColor(R.color.warning));
                issued++;
            }

            if (tvBookQuantity != null) {
                tvBookQuantity.setText("Qty: " + availableQty + "/10");
            }

            llReportContent.addView(itemView);
        }

        View footer = LayoutInflater.from(this).inflate(R.layout.report_footer, null);
        TextView tvSummary = footer.findViewById(R.id.tvReportSummary);
        tvSummary.setText("📊 Total: " + books.size() + " | ✅ Available: " + available + " | 📖 Issued: " + issued);
        llReportContent.addView(footer);

        Toast.makeText(this, "Books Report: " + books.size() + " books", Toast.LENGTH_SHORT).show();
    }

    private void showIssueReport() {
        llReportContent.removeAllViews();

        List<String[]> issues = dbHelper.getAllIssues();
        String today = new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());

        View header = LayoutInflater.from(this).inflate(R.layout.report_header, null);
        TextView tvHeaderTitle = header.findViewById(R.id.tvReportHeaderTitle);
        TextView tvHeaderDate = header.findViewById(R.id.tvReportHeaderDate);
        tvHeaderTitle.setText("📖 ACTIVE ISSUES REPORT");
        tvHeaderDate.setText(new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US).format(new Date()));
        llReportContent.addView(header);

        if (issues.isEmpty()) {
            View empty = LayoutInflater.from(this).inflate(R.layout.report_empty, null);
            TextView tvEmpty = empty.findViewById(R.id.tvReportEmpty);
            tvEmpty.setText("No active issues at this time");
            llReportContent.addView(empty);
            return;
        }

        int overdueCount = 0;

        for (String[] issue : issues) {
            View itemView = LayoutInflater.from(this).inflate(R.layout.report_issue_item, null);

            TextView tvBookId = itemView.findViewById(R.id.tvReportIssueBookId);
            TextView tvStudentId = itemView.findViewById(R.id.tvReportIssueStudentId);
            TextView tvIssueDate = itemView.findViewById(R.id.tvReportIssueDate);
            TextView tvDueDate = itemView.findViewById(R.id.tvReportDueDate);
            TextView tvStatus = itemView.findViewById(R.id.tvReportIssueStatus);

            String bookTitle = dbHelper.getBookTitle(issue[0]);
            String studentName = getStudentName(issue[1]);

            tvBookId.setText("📖 " + issue[0] + " - " + bookTitle);
            tvStudentId.setText("👤 " + issue[1] + " - " + studentName);
            tvIssueDate.setText("📅 Issued: " + issue[2]);
            tvDueDate.setText("⏰ Due: " + issue[3]);

            boolean isOverdue = issue[3].compareTo(today) < 0;
            if (isOverdue) {
                tvDueDate.setTextColor(getColor(R.color.error));
                tvStatus.setText("⚠️ OVERDUE");
                tvStatus.setTextColor(getColor(R.color.error));
                overdueCount++;
            } else {
                tvStatus.setText("✅ ON TIME");
                tvStatus.setTextColor(getColor(R.color.success));
            }

            llReportContent.addView(itemView);
        }

        View footer = LayoutInflater.from(this).inflate(R.layout.report_footer, null);
        TextView tvSummary = footer.findViewById(R.id.tvReportSummary);
        tvSummary.setText("📊 Total Active: " + issues.size() + " | ⚠️ Overdue: " + overdueCount);
        llReportContent.addView(footer);

        Toast.makeText(this, "Issues Report: " + issues.size() + " active issues", Toast.LENGTH_SHORT).show();
    }

    private void showFineReport() {
        llReportContent.removeAllViews();

        List<String[]> fines = dbHelper.getAllFines();

        View header = LayoutInflater.from(this).inflate(R.layout.report_header, null);
        TextView tvHeaderTitle = header.findViewById(R.id.tvReportHeaderTitle);
        TextView tvHeaderDate = header.findViewById(R.id.tvReportHeaderDate);
        tvHeaderTitle.setText("💰 FINES REPORT");
        tvHeaderDate.setText(new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US).format(new Date()));
        llReportContent.addView(header);

        if (fines.isEmpty()) {
            View empty = LayoutInflater.from(this).inflate(R.layout.report_empty, null);
            TextView tvEmpty = empty.findViewById(R.id.tvReportEmpty);
            tvEmpty.setText("No fine records found");
            llReportContent.addView(empty);
            return;
        }

        double totalUnpaid = 0;
        double totalPaid = 0;

        for (String[] fine : fines) {
            View itemView = LayoutInflater.from(this).inflate(R.layout.report_fine_item, null);

            TextView tvStudentId = itemView.findViewById(R.id.tvReportFineStudentId);
            TextView tvBookId = itemView.findViewById(R.id.tvReportFineBookId);
            TextView tvAmount = itemView.findViewById(R.id.tvReportFineAmount);
            TextView tvStatus = itemView.findViewById(R.id.tvReportFineStatus);

            String studentName = getStudentName(fine[0]);
            String bookTitle = dbHelper.getBookTitle(fine[1]);
            double amount = Double.parseDouble(fine[2]);

            tvStudentId.setText("👤 " + fine[0] + " - " + studentName);
            tvBookId.setText("📖 " + fine[1] + " - " + bookTitle);
            tvAmount.setText("ETB " + String.format("%.2f", amount));
            tvStatus.setText(fine[3]);

            if (fine[3].equals("Paid")) {
                tvStatus.setTextColor(getColor(R.color.success));
                totalPaid += amount;
            } else {
                tvStatus.setTextColor(getColor(R.color.error));
                totalUnpaid += amount;
            }

            llReportContent.addView(itemView);
        }

        View footer = LayoutInflater.from(this).inflate(R.layout.report_footer, null);
        TextView tvSummary = footer.findViewById(R.id.tvReportSummary);
        tvSummary.setText("📊 Unpaid: ETB " + String.format("%.2f", totalUnpaid) + " | ✅ Paid: ETB " + String.format("%.2f", totalPaid));
        llReportContent.addView(footer);

        Toast.makeText(this, "Fines Report: ETB " + String.format("%.2f", totalUnpaid) + " unpaid", Toast.LENGTH_SHORT).show();
    }

    private String getStudentName(String studentId) {
        List<String[]> students = dbHelper.getAllStudents();
        for (String[] student : students) {
            if (student[0].equals(studentId)) {
                return student[1];
            }
        }
        return "Unknown";
    }
}