package com.library.app;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class FinesActivity extends AppCompatActivity {

    private LinearLayout llFinesList;
    private TextView btnBack;
    private DatabaseHelper dbHelper;
    private TextView tvTotalUnpaid;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_fines);

        dbHelper = new DatabaseHelper(this);
        llFinesList = findViewById(R.id.llFinesList);
        btnBack = findViewById(R.id.btnBack);

        btnBack.setOnClickListener(v -> finish());

        loadFines();
    }

    private void loadFines() {
        List<String[]> fines = dbHelper.getAllFines();
        llFinesList.removeAllViews();

        if (fines.isEmpty()) {
            View emptyView = LayoutInflater.from(this).inflate(R.layout.empty_fines, null);
            llFinesList.addView(emptyView);
            return;
        }

        double totalUnpaid = 0;

        for (String[] fine : fines) {
            View itemView = LayoutInflater.from(this).inflate(R.layout.item_fine_row, null);

            TextView tvStudentId = itemView.findViewById(R.id.tvFineStudentId);
            TextView tvBookId = itemView.findViewById(R.id.tvFineBookId);
            TextView tvAmount = itemView.findViewById(R.id.tvFineAmount);
            TextView tvStatus = itemView.findViewById(R.id.tvFineStatus);
            Button btnPay = itemView.findViewById(R.id.btnPayFine);

            final String studentId = fine[0];
            final String bookId = fine[1];
            final String amount = fine[2];
            final String status = fine[3];
            final String fineId = String.valueOf(System.currentTimeMillis());

            String studentName = getStudentName(studentId);
            String bookTitle = dbHelper.getBookTitle(bookId);

            tvStudentId.setText(studentId + " - " + studentName);
            tvBookId.setText(bookId + " - " + bookTitle);
            tvAmount.setText("ETB " + amount);
            tvStatus.setText(status);

            if (status.equals("Paid")) {
                tvStatus.setTextColor(getColor(R.color.success));
                tvStatus.setBackgroundResource(R.drawable.bg_status_available);
                btnPay.setEnabled(false);
                btnPay.setAlpha(0.5f);
                btnPay.setText("PAID");
            } else {
                tvStatus.setTextColor(getColor(R.color.error));
                tvStatus.setBackgroundResource(R.drawable.bg_status_issued);
                totalUnpaid += Double.parseDouble(amount);

                btnPay.setOnClickListener(v -> {
                    showPaymentDialog(studentId, studentName, bookTitle, amount, fineId);
                });
            }

            llFinesList.addView(itemView);
        }

        // Add total summary
        addSummaryView(totalUnpaid);
    }

    private void showPaymentDialog(String studentId, String studentName, String bookTitle, String amount, String fineId) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_payment, null);

        TextView tvStudentInfo = view.findViewById(R.id.tvPaymentStudent);
        TextView tvBookInfo = view.findViewById(R.id.tvPaymentBook);
        TextView tvAmountInfo = view.findViewById(R.id.tvPaymentAmount);
        Button btnConfirmPay = view.findViewById(R.id.btnConfirmPayment);
        Button btnCancel = view.findViewById(R.id.btnCancelPayment);

        tvStudentInfo.setText("Student: " + studentName + " (" + studentId + ")");
        tvBookInfo.setText("Book: " + bookTitle);
        tvAmountInfo.setText("Amount: ETB " + amount);

        builder.setView(view);
        AlertDialog dialog = builder.create();
        dialog.show();

        btnConfirmPay.setOnClickListener(v -> {
            // Process payment
            boolean paid = dbHelper.payFine(fineId);
            if (paid) {
                Toast.makeText(FinesActivity.this, "✓ Payment of ETB " + amount + " successful!", Toast.LENGTH_LONG).show();
                loadFines();
                dialog.dismiss();
            } else {
                Toast.makeText(FinesActivity.this, "Payment failed", Toast.LENGTH_SHORT).show();
            }
        });

        btnCancel.setOnClickListener(v -> dialog.dismiss());
    }

    private void addSummaryView(double totalUnpaid) {
        View summaryView = LayoutInflater.from(this).inflate(R.layout.fines_summary, null);
        TextView tvTotalUnpaid = summaryView.findViewById(R.id.tvTotalUnpaid);
        Button btnPayAll = summaryView.findViewById(R.id.btnPayAll);

        tvTotalUnpaid.setText("Total Unpaid: ETB " + String.format("%.2f", totalUnpaid));

        if (totalUnpaid > 0) {
            btnPayAll.setVisibility(View.VISIBLE);
            btnPayAll.setOnClickListener(v -> {
                Toast.makeText(this, "Pay all feature coming soon", Toast.LENGTH_SHORT).show();
            });
        } else {
            btnPayAll.setVisibility(View.GONE);
        }

        llFinesList.addView(summaryView);
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