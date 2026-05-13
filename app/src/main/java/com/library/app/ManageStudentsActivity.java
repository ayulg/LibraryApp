package com.library.app;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentValues;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.text.TextUtils;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

public class ManageStudentsActivity extends AppCompatActivity {

    private LinearLayout llStudentsList;
    private TextView btnBack;
    private Button btnAddStudent;
    private DatabaseHelper dbHelper;
    private CardView cardAddStudent;
    private EditText etStudentId, etStudentName, etStudentEmail, etStudentPhone, etStudentDepartment;
    private EditText etStudentPassword;
    private Button btnSubmitStudent;
    private TextView btnCloseForm;

    // Search views
    private EditText etSearchStudent;
    private TextView tvStudentCount, btnClearSearch;

    private List<String[]> allStudents = new ArrayList<>();
    private List<String[]> filteredStudents = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_manage_students);

        dbHelper = new DatabaseHelper(this);

        llStudentsList = findViewById(R.id.llStudentsList);
        btnBack = findViewById(R.id.btnBack);
        btnAddStudent = findViewById(R.id.btnAddStudent);
        cardAddStudent = findViewById(R.id.cardAddStudent);
        etStudentId = findViewById(R.id.etStudentId);
        etStudentName = findViewById(R.id.etStudentName);
        etStudentEmail = findViewById(R.id.etStudentEmail);
        etStudentPhone = findViewById(R.id.etStudentPhone);
        etStudentDepartment = findViewById(R.id.etStudentDepartment);
        etStudentPassword = findViewById(R.id.etStudentPassword);
        btnSubmitStudent = findViewById(R.id.btnSubmitStudent);
        btnCloseForm = findViewById(R.id.btnCloseForm);

        // Search views
        etSearchStudent = findViewById(R.id.etSearchStudent);
        tvStudentCount = findViewById(R.id.tvStudentCount);
        btnClearSearch = findViewById(R.id.btnClearSearch);

        btnBack.setOnClickListener(v -> finish());

        btnAddStudent.setOnClickListener(v -> {
            if (cardAddStudent.getVisibility() == View.GONE) {
                cardAddStudent.setVisibility(View.VISIBLE);
                btnAddStudent.setText("✖ CANCEL");
            } else {
                cardAddStudent.setVisibility(View.GONE);
                btnAddStudent.setText("+ ADD STUDENT");
                clearForm();
            }
        });

        if (btnCloseForm != null) {
            btnCloseForm.setOnClickListener(v -> {
                cardAddStudent.setVisibility(View.GONE);
                btnAddStudent.setText("+ ADD STUDENT");
                clearForm();
            });
        }

        btnSubmitStudent.setOnClickListener(v -> addStudent());

        // Setup search
        setupSearch();

        loadStudents();
    }

    private void setupSearch() {
        etSearchStudent.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                String query = s.toString().trim();
                if (query.isEmpty()) {
                    btnClearSearch.setVisibility(View.GONE);
                    displayStudents(allStudents);
                    tvStudentCount.setText(String.valueOf(allStudents.size()));
                } else {
                    btnClearSearch.setVisibility(View.VISIBLE);
                    filterStudents(query);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });

        btnClearSearch.setOnClickListener(v -> {
            etSearchStudent.setText("");
            btnClearSearch.setVisibility(View.GONE);
        });
    }

    private void filterStudents(String query) {
        filteredStudents.clear();
        String lowerQuery = query.toLowerCase();

        for (String[] student : allStudents) {
            if (student != null && student.length >= 5) {
                if (student[0].toLowerCase().contains(lowerQuery) || // ID
                        student[1].toLowerCase().contains(lowerQuery) || // Name
                        (student[2] != null && student[2].toLowerCase().contains(lowerQuery))) { // Email
                    filteredStudents.add(student);
                }
            }
        }

        displayStudents(filteredStudents);
        tvStudentCount.setText(String.valueOf(filteredStudents.size()));
    }

    private void addStudent() {
        String studentId = etStudentId.getText().toString().trim().toUpperCase();
        String name = etStudentName.getText().toString().trim();
        String email = etStudentEmail.getText().toString().trim();
        String phone = etStudentPhone.getText().toString().trim();
        String department = etStudentDepartment.getText().toString().trim();
        String password = etStudentPassword.getText().toString().trim();

        if (TextUtils.isEmpty(studentId)) {
            etStudentId.setError("Student ID required");
            etStudentId.requestFocus();
            return;
        }
        if (TextUtils.isEmpty(name)) {
            etStudentName.setError("Name required");
            etStudentName.requestFocus();
            return;
        }
        if (TextUtils.isEmpty(email)) {
            etStudentEmail.setError("Email required");
            etStudentEmail.requestFocus();
            return;
        }
        if (!isValidEmail(email)) {
            etStudentEmail.setError("Invalid email");
            etStudentEmail.requestFocus();
            return;
        }

        if (TextUtils.isEmpty(password)) {
            password = "student123";
        }
        if (password.length() < 4) {
            etStudentPassword.setError("Password must be at least 4 characters");
            etStudentPassword.requestFocus();
            return;
        }

        List<String[]> existingStudents = dbHelper.getAllStudents();
        if (existingStudents != null) {
            for (String[] student : existingStudents) {
                if (student != null && student.length > 0 && student[0].equals(studentId)) {
                    Toast.makeText(this, "Student ID already exists!", Toast.LENGTH_SHORT).show();
                    return;
                }
            }
        }

        String securityAnswer = "book";
        boolean isAdded = dbHelper.registerUserWithSecurity(studentId, password, "student",
                name, email, phone, department, securityAnswer);

        if (isAdded) {
            Toast.makeText(this, "✓ Student Added Successfully!\nID: " + studentId + "\nPassword: " + password, Toast.LENGTH_LONG).show();
            clearForm();
            cardAddStudent.setVisibility(View.GONE);
            btnAddStudent.setText("+ ADD STUDENT");
            loadStudents();
        } else {
            Toast.makeText(this, "Failed to add student. Please try again.", Toast.LENGTH_SHORT).show();
        }
    }

    private void loadStudents() {
        try {
            allStudents = dbHelper.getAllStudents();
            llStudentsList.removeAllViews();

            if (allStudents == null) {
                showErrorView("Database error: Students list is null");
                return;
            }

            if (allStudents.isEmpty()) {
                showEmptyView();
                tvStudentCount.setText("0");
                return;
            }

            tvStudentCount.setText(String.valueOf(allStudents.size()));
            displayStudents(allStudents);

        } catch (Exception e) {
            e.printStackTrace();
            showErrorView("Error: " + e.getMessage());
        }
    }

    private void displayStudents(List<String[]> students) {
        llStudentsList.removeAllViews();

        if (students == null || students.isEmpty()) {
            if (allStudents != null && !allStudents.isEmpty()) {
                TextView noResultView = new TextView(this);
                noResultView.setText("🔍 No matching students found");
                noResultView.setTextSize(14f);
                noResultView.setTextColor(getColor(R.color.text_secondary));
                noResultView.setGravity(android.view.Gravity.CENTER);
                noResultView.setPadding(40, 80, 40, 80);
                llStudentsList.addView(noResultView);
            }
            return;
        }

        for (String[] student : students) {
            if (student == null || student.length < 5) {
                continue;
            }

            View studentItem = LayoutInflater.from(this).inflate(R.layout.item_student_row, llStudentsList, false);

            TextView tvStudentId = studentItem.findViewById(R.id.tvStudentRowId);
            TextView tvStudentName = studentItem.findViewById(R.id.tvStudentRowName);
            TextView tvStudentEmail = studentItem.findViewById(R.id.tvStudentRowEmail);
            TextView tvStudentPhone = studentItem.findViewById(R.id.tvStudentRowPhone);
            TextView tvStudentDepartment = studentItem.findViewById(R.id.tvStudentRowDepartment);

            TextView btnViewPassword = studentItem.findViewById(R.id.btnViewPassword);
            TextView btnReset = studentItem.findViewById(R.id.btnResetPasswordStudent);
            LinearLayout btnEdit = studentItem.findViewById(R.id.btnEditStudent);
            LinearLayout btnDelete = studentItem.findViewById(R.id.btnDeleteStudent);

            final String studentId = student[0];
            final String name = student[1];
            final String email = student[2] != null ? student[2] : "N/A";
            final String phone = student[3] != null && !TextUtils.isEmpty(student[3]) ? student[3] : "N/A";
            final String department = student[4] != null && !TextUtils.isEmpty(student[4]) ? student[4] : "N/A";

            tvStudentId.setText(studentId);
            tvStudentName.setText(name);
            tvStudentEmail.setText(email);
            tvStudentPhone.setText(phone);
            tvStudentDepartment.setText(department);

            // View Password - Shows full student info with password
            if (btnViewPassword != null) {
                btnViewPassword.setOnClickListener(v -> showStudentInfoDialog(studentId, name, email, phone, department));
            }

            if (btnReset != null) {
                btnReset.setOnClickListener(v -> showResetPasswordDialog(studentId, name));
            }

            if (btnEdit != null) {
                btnEdit.setOnClickListener(v -> showEditDialog(studentId, name, email, phone, department));
            }

            if (btnDelete != null) {
                btnDelete.setOnClickListener(v -> {
                    new AlertDialog.Builder(ManageStudentsActivity.this)
                            .setTitle("Delete Student")
                            .setMessage("Delete student \"" + name + "\" (ID: " + studentId + ")?\n\nThis will also remove all their book records.")
                            .setPositiveButton("DELETE", (dialog, which) -> {
                                if (dbHelper.deleteStudent(studentId)) {
                                    deleteUser(studentId);
                                    Toast.makeText(ManageStudentsActivity.this, "Student deleted successfully", Toast.LENGTH_SHORT).show();
                                    loadStudents();
                                } else {
                                    Toast.makeText(ManageStudentsActivity.this, "Failed to delete student", Toast.LENGTH_SHORT).show();
                                }
                            })
                            .setNegativeButton("CANCEL", null)
                            .show();
                });
            }

            // Click to show student info with password
            studentItem.setOnClickListener(v -> showStudentInfoDialog(studentId, name, email, phone, department));

            llStudentsList.addView(studentItem);
        }
    }

    // NEW METHOD: Show complete student info with password
    private void showStudentInfoDialog(String studentId, String name, String email, String phone, String department) {
        // Get password from database
        String[] userInfo = dbHelper.getUserInfo(studentId);
        String password = "Not set";
        if (userInfo != null && userInfo.length > 1 && userInfo[1] != null) {
            password = userInfo[1];
        }

        final String finalPassword = password;

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("👨‍🎓 Student Information");
        builder.setMessage("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
                        "📌 Student ID: " + studentId + "\n" +
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
                        "👤 Name: " + name + "\n" +
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
                        "📧 Email: " + email + "\n" +
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
                        "📞 Phone: " + phone + "\n" +
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
                        "🏛 Department: " + department + "\n" +
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
                        "🔑 Password: " + password + "\n" +
                        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" +
                        "💡 Click COPY to copy password")
                .setPositiveButton("OK", null)
                .setNeutralButton("📋 COPY PASSWORD", (dialog, which) -> {
                    try {
                        ClipboardManager clipboard = (ClipboardManager) getSystemService(CLIPBOARD_SERVICE);
                        ClipData clip = ClipData.newPlainText("student_password", finalPassword);
                        clipboard.setPrimaryClip(clip);
                        Toast.makeText(this, "✓ Password copied to clipboard", Toast.LENGTH_SHORT).show();
                    } catch (Exception e) {
                        Toast.makeText(this, "Failed to copy password", Toast.LENGTH_SHORT).show();
                    }
                })
                .setIcon(android.R.drawable.ic_dialog_info);

        AlertDialog dialog = builder.create();
        dialog.show();

        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setTextColor(getColor(R.color.accent));
        if (dialog.getButton(AlertDialog.BUTTON_NEUTRAL) != null) {
            dialog.getButton(AlertDialog.BUTTON_NEUTRAL).setTextColor(getColor(R.color.primary));
        }
    }

    private void showEmptyView() {
        TextView emptyView = new TextView(this);
        emptyView.setText("👥\n\nNo Students Found\n\nClick '+ ADD' to add your first student");
        emptyView.setTextSize(14f);
        emptyView.setTextColor(getColor(R.color.text_secondary));
        emptyView.setGravity(android.view.Gravity.CENTER);
        emptyView.setPadding(40, 80, 40, 80);
        llStudentsList.addView(emptyView);
    }

    private void showErrorView(String errorMessage) {
        LinearLayout errorLayout = new LinearLayout(this);
        errorLayout.setOrientation(LinearLayout.VERTICAL);
        errorLayout.setGravity(android.view.Gravity.CENTER);
        errorLayout.setPadding(40, 80, 40, 80);

        TextView errorIcon = new TextView(this);
        errorIcon.setText("⚠️");
        errorIcon.setTextSize(48f);
        errorIcon.setGravity(android.view.Gravity.CENTER);

        TextView errorTitle = new TextView(this);
        errorTitle.setText("Unable to Load Students");
        errorTitle.setTextSize(16f);
        errorTitle.setTypeface(null, android.graphics.Typeface.BOLD);
        errorTitle.setTextColor(getColor(R.color.error));
        errorTitle.setGravity(android.view.Gravity.CENTER);
        errorTitle.setPadding(0, 20, 0, 10);

        TextView errorMsg = new TextView(this);
        errorMsg.setText(errorMessage);
        errorMsg.setTextSize(12f);
        errorMsg.setTextColor(getColor(R.color.text_secondary));
        errorMsg.setGravity(android.view.Gravity.CENTER);

        Button retryButton = new Button(this);
        retryButton.setText("RETRY");
        retryButton.setTextColor(getColor(R.color.text_white));
        retryButton.setBackgroundResource(R.drawable.btn_primary);
        retryButton.setPadding(40, 12, 40, 12);
        retryButton.setOnClickListener(v -> loadStudents());

        errorLayout.addView(errorIcon);
        errorLayout.addView(errorTitle);
        errorLayout.addView(errorMsg);
        errorLayout.addView(retryButton);

        llStudentsList.addView(errorLayout);
    }

    private void showResetPasswordDialog(final String studentId, final String name) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_reset_password, null);

        EditText etNewPassword = view.findViewById(R.id.etNewPassword);
        EditText etConfirmPassword = view.findViewById(R.id.etConfirmPassword);
        Button btnReset = view.findViewById(R.id.btnResetPassword);

        builder.setView(view);
        final AlertDialog dialog = builder.create();
        dialog.show();

        btnReset.setOnClickListener(v -> {
            String newPassword = etNewPassword.getText().toString().trim();
            String confirmPassword = etConfirmPassword.getText().toString().trim();

            if (TextUtils.isEmpty(newPassword)) {
                etNewPassword.setError("Password required");
                return;
            }
            if (newPassword.length() < 4) {
                etNewPassword.setError("Password must be at least 4 characters");
                return;
            }
            if (!newPassword.equals(confirmPassword)) {
                etConfirmPassword.setError("Passwords do not match");
                return;
            }

            if (dbHelper.updatePassword(studentId, newPassword)) {
                Toast.makeText(ManageStudentsActivity.this, "✓ Password reset for " + name + "\nNew Password: " + newPassword, Toast.LENGTH_LONG).show();
                dialog.dismiss();
            } else {
                Toast.makeText(ManageStudentsActivity.this, "Failed to reset password", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void deleteUser(String studentId) {
        try {
            SQLiteDatabase db = dbHelper.getWritableDatabase();
            db.delete("users", "username=?", new String[]{studentId});
            db.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void showEditDialog(final String studentId, final String oldName,
                                final String oldEmail, final String oldPhone,
                                final String oldDepartment) {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_edit_student, null);

        EditText etName = view.findViewById(R.id.etEditName);
        EditText etEmail = view.findViewById(R.id.etEditEmail);
        EditText etPhone = view.findViewById(R.id.etEditPhone);
        EditText etDepartment = view.findViewById(R.id.etEditDepartment);

        etName.setText(oldName);
        etEmail.setText(oldEmail);
        etPhone.setText(oldPhone);
        etDepartment.setText(oldDepartment);

        builder.setView(view);
        builder.setPositiveButton("SAVE", (dialog, which) -> {
            String newName = etName.getText().toString().trim();
            String newEmail = etEmail.getText().toString().trim();
            String newPhone = etPhone.getText().toString().trim();
            String newDepartment = etDepartment.getText().toString().trim();

            if (TextUtils.isEmpty(newName)) {
                Toast.makeText(this, "Name cannot be empty", Toast.LENGTH_SHORT).show();
                return;
            }

            if (!isValidEmail(newEmail)) {
                Toast.makeText(this, "Invalid email format", Toast.LENGTH_SHORT).show();
                return;
            }

            updateStudent(studentId, newName, newEmail, newPhone, newDepartment);
        });
        builder.setNegativeButton("CANCEL", null);

        AlertDialog dialog = builder.create();
        dialog.show();
    }

    private boolean isValidEmail(String email) {
        if (email == null) return false;
        String emailPattern = "[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}";
        return Pattern.matches(emailPattern, email);
    }

    private void updateStudent(String studentId, String name, String email, String phone, String department) {
        try {
            SQLiteDatabase db = dbHelper.getWritableDatabase();
            ContentValues values = new ContentValues();
            values.put("name", name);
            values.put("email", email);
            values.put("phone", phone);
            values.put("department", department);

            int result = db.update("students", values, "student_id=?", new String[]{studentId});
            db.close();

            if (result > 0) {
                Toast.makeText(this, "✓ Student updated successfully", Toast.LENGTH_SHORT).show();
                loadStudents();
            } else {
                Toast.makeText(this, "Failed to update student", Toast.LENGTH_SHORT).show();
            }
        } catch (Exception e) {
            e.printStackTrace();
            Toast.makeText(this, "Error updating student", Toast.LENGTH_SHORT).show();
        }
    }

    private void clearForm() {
        etStudentId.setText("");
        etStudentName.setText("");
        etStudentEmail.setText("");
        etStudentPhone.setText("");
        etStudentDepartment.setText("");
        etStudentPassword.setText("");
    }
}