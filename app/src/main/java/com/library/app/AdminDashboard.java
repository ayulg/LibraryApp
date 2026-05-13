package com.library.app;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import java.util.List;

public class AdminDashboard extends AppCompatActivity {

    private TextView tvAdminName, tvTotalBooks, tvTotalStudents, tvTotalIssued, tvTotalFines, tvOverdueCount, btnLogout, btnSettings;
    private CardView cardBooks, cardStudents, cardIssue, cardSearch, cardReservations, cardOverdue, cardFines, cardReports, cardDueSettings;
    private DatabaseHelper dbHelper;
    private String username;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_admin_dashboard);

        dbHelper = new DatabaseHelper(this);
        username = getIntent().getStringExtra("USERNAME");
        if (username == null) username = "Admin";

        // Initialize views
        tvAdminName = findViewById(R.id.tvAdminName);
        tvTotalBooks = findViewById(R.id.tvTotalBooks);
        tvTotalStudents = findViewById(R.id.tvTotalStudents);
        tvTotalIssued = findViewById(R.id.tvTotalIssued);
        tvTotalFines = findViewById(R.id.tvTotalFines);
        tvOverdueCount = findViewById(R.id.tvOverdueCount);
        btnLogout = findViewById(R.id.btnLogout);
        btnSettings = findViewById(R.id.btnSettings);

        cardBooks = findViewById(R.id.cardBooks);
        cardStudents = findViewById(R.id.cardStudents);
        cardIssue = findViewById(R.id.cardIssue);
        cardSearch = findViewById(R.id.cardSearch);
        cardReservations = findViewById(R.id.cardReservations);
        cardOverdue = findViewById(R.id.cardOverdue);
        cardFines = findViewById(R.id.cardFines);
        cardReports = findViewById(R.id.cardReports);
        cardDueSettings = findViewById(R.id.cardDueSettings);

        tvAdminName.setText("Welcome, " + username);

        // Set click listeners for all cards
        cardBooks.setOnClickListener(v -> startActivity(new Intent(AdminDashboard.this, ManageBooksActivity.class)));
        cardStudents.setOnClickListener(v -> startActivity(new Intent(AdminDashboard.this, ManageStudentsActivity.class)));
        cardIssue.setOnClickListener(v -> startActivity(new Intent(AdminDashboard.this, IssueReturnActivity.class)));
        cardSearch.setOnClickListener(v -> startActivity(new Intent(AdminDashboard.this, SearchBooksActivity.class)));
        cardReservations.setOnClickListener(v -> startActivity(new Intent(AdminDashboard.this, ReservationsActivity.class)));
        cardFines.setOnClickListener(v -> startActivity(new Intent(AdminDashboard.this, FinesActivity.class)));
        cardReports.setOnClickListener(v -> startActivity(new Intent(AdminDashboard.this, ReportsActivity.class)));
        cardOverdue.setOnClickListener(v -> checkOverdueBooks());
        cardDueSettings.setOnClickListener(v -> showDueDateSettingsDialog());

        btnLogout.setOnClickListener(v -> finish());
        btnSettings.setOnClickListener(v -> showSettingsDialog());

        updateStats();
    }

    private void showDueDateSettingsDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_due_settings, null);

        EditText etDueDays = view.findViewById(R.id.etDueDays);
        TextView tvPreview = view.findViewById(R.id.tvPreview);
        Button btnSave = view.findViewById(R.id.btnSaveDueSettings);

        int currentDays = dbHelper.getDueDays();
        etDueDays.setText(String.valueOf(currentDays));
        tvPreview.setText("Preview: Due date will be " + currentDays + " days from issue date");

        // Live preview with validation
        etDueDays.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                String text = s.toString();
                if (!TextUtils.isEmpty(text)) {
                    try {
                        int days = Integer.parseInt(text);
                        if (days >= 1 && days <= 365) {
                            tvPreview.setText("✓ Due date will be " + days + " days from issue date");
                            tvPreview.setTextColor(getColor(R.color.success));
                        } else {
                            tvPreview.setText("⚠️ Please enter a value between 1 and 365");
                            tvPreview.setTextColor(getColor(R.color.error));
                        }
                    } catch (NumberFormatException e) {
                        tvPreview.setText("❌ Please enter a valid number");
                        tvPreview.setTextColor(getColor(R.color.error));
                    }
                } else {
                    tvPreview.setText("📅 Enter number of days for book return period");
                    tvPreview.setTextColor(getColor(R.color.text_secondary));
                }
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });

        builder.setView(view);
        builder.setCancelable(true);
        AlertDialog dialog = builder.create();
        dialog.show();

        btnSave.setOnClickListener(v -> {
            String daysText = etDueDays.getText().toString().trim();
            if (TextUtils.isEmpty(daysText)) {
                Toast.makeText(AdminDashboard.this, "Please enter number of days", Toast.LENGTH_SHORT).show();
                return;
            }

            int days;
            try {
                days = Integer.parseInt(daysText);
            } catch (NumberFormatException e) {
                Toast.makeText(AdminDashboard.this, "Please enter a valid number", Toast.LENGTH_SHORT).show();
                return;
            }

            if (days < 1) {
                Toast.makeText(AdminDashboard.this, "Days must be at least 1", Toast.LENGTH_SHORT).show();
                return;
            }
            if (days > 365) {
                Toast.makeText(AdminDashboard.this, "Days cannot exceed 365", Toast.LENGTH_SHORT).show();
                return;
            }

            // Confirm before saving
            new AlertDialog.Builder(AdminDashboard.this)
                    .setTitle("Confirm Changes")
                    .setMessage("Are you sure you want to change the due date from " + currentDays + " days to " + days + " days?\n\n⚠️ Note: This will only affect NEW book issues. Existing issued books will keep their original due dates.")
                    .setPositiveButton("YES, UPDATE", (confirmDialog, which) -> {
                        if (dbHelper.updateDueDays(days)) {
                            Toast.makeText(AdminDashboard.this, "✓ Due date updated successfully!\nNew due period: " + days + " days", Toast.LENGTH_LONG).show();
                            dialog.dismiss();
                            updateStats();
                        } else {
                            Toast.makeText(AdminDashboard.this, "Failed to update settings", Toast.LENGTH_SHORT).show();
                        }
                    })
                    .setNegativeButton("CANCEL", null)
                    .show();
        });
    }

    private void showSettingsDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_settings, null);

        EditText etCurrentPassword = view.findViewById(R.id.etCurrentPassword);
        EditText etNewPassword = view.findViewById(R.id.etNewPassword);
        EditText etConfirmNewPassword = view.findViewById(R.id.etConfirmNewPassword);
        EditText etNewSecurityAnswer = view.findViewById(R.id.etNewSecurityAnswer);
        TextView tvSecurityQuestion = view.findViewById(R.id.tvSecurityQuestion);
        Button btnUpdateSettings = view.findViewById(R.id.btnUpdateSettings);

        String[] userInfo = dbHelper.getUserInfo(username);
        if (userInfo != null && userInfo.length > 2) {
            tvSecurityQuestion.setText(userInfo[2]);
        } else {
            tvSecurityQuestion.setText("What is your favorite book?");
        }

        builder.setView(view);
        AlertDialog dialog = builder.create();
        dialog.show();

        btnUpdateSettings.setOnClickListener(v -> {
            String currentPassword = etCurrentPassword.getText().toString().trim();
            String newPassword = etNewPassword.getText().toString().trim();
            String confirmPassword = etConfirmNewPassword.getText().toString().trim();
            String newSecurityAnswer = etNewSecurityAnswer.getText().toString().trim();

            if (!dbHelper.validateUser(username, currentPassword)) {
                Toast.makeText(AdminDashboard.this, "Current password is incorrect", Toast.LENGTH_SHORT).show();
                return;
            }

            if (!TextUtils.isEmpty(newPassword)) {
                if (newPassword.length() < 4) {
                    Toast.makeText(AdminDashboard.this, "New password must be at least 4 characters", Toast.LENGTH_SHORT).show();
                    return;
                }
                if (!newPassword.equals(confirmPassword)) {
                    Toast.makeText(AdminDashboard.this, "New passwords do not match", Toast.LENGTH_SHORT).show();
                    return;
                }
            }

            boolean updated = dbHelper.updateUserInfo(username,
                    TextUtils.isEmpty(newPassword) ? null : newPassword,
                    TextUtils.isEmpty(newSecurityAnswer) ? null : newSecurityAnswer);

            if (updated) {
                Toast.makeText(AdminDashboard.this, "✓ Settings updated successfully!", Toast.LENGTH_LONG).show();
                dialog.dismiss();
            } else {
                Toast.makeText(AdminDashboard.this, "Failed to update settings", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void updateStats() {
        List<String[]> books = dbHelper.getAllBooks();
        List<String[]> students = dbHelper.getAllStudents();
        List<String[]> issued = dbHelper.getAllIssues();
        List<String[]> fines = dbHelper.getAllFines();

        tvTotalBooks.setText(String.valueOf(books.size()));
        tvTotalStudents.setText(String.valueOf(students.size()));
        tvTotalIssued.setText(String.valueOf(issued.size()));

        List<String[]> overdue = dbHelper.getOverdueBooks();
        tvOverdueCount.setText(String.valueOf(overdue.size()));

        double totalFines = 0;
        for (String[] fine : fines) {
            if (fine.length > 3 && fine[3].equals("Unpaid")) {
                totalFines += Double.parseDouble(fine[2]);
            }
        }
        tvTotalFines.setText("ETB " + String.format("%.2f", totalFines));
    }

    private void checkOverdueBooks() {
        List<String[]> overdue = dbHelper.getOverdueBooks();
        if (overdue.isEmpty()) {
            Toast.makeText(this, "📚 No overdue books! All books returned on time.", Toast.LENGTH_LONG).show();
        } else {
            StringBuilder msg = new StringBuilder();
            msg.append("⚠️ OVERDUE BOOKS (").append(overdue.size()).append(")\n\n");
            for (String[] book : overdue) {
                String bookTitle = dbHelper.getBookTitle(book[0]);
                msg.append("📖 Book: ").append(bookTitle)
                        .append("\n👤 Student: ").append(book[1])
                        .append("\n📅 Due Date: ").append(book[2])
                        .append("\n━━━━━━━━━━━━━━━━━━\n");
            }

            new AlertDialog.Builder(this)
                    .setTitle("⚠️ Overdue Books Alert")
                    .setMessage(msg.toString())
                    .setPositiveButton("OK", null)
                    .setIcon(android.R.drawable.ic_dialog_alert)
                    .show();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateStats();
    }
}