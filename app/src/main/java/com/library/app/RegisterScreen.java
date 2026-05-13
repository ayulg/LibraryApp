package com.library.app;

import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.RadioButton;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class RegisterScreen extends AppCompatActivity {

    private EditText etStudentId, etFullName, etEmail, etPhone, etDepartment;
    private EditText etAdminUsername, etAdminFullName, etAdminEmail, etAdminCode;
    private EditText etPassword, etConfirmPassword, etSecurityAnswer;
    private Button btnRegister, btnGoogleSignUp;
    private TextView tvBackToLogin, tvSecurityQuestion;
    private ProgressBar progressBar;
    private LinearLayout studentFields, adminFields;
    private View layoutStudent, layoutAdmin;
    private DatabaseHelper dbHelper;
    private boolean isStudentSelected = true;
    private static final String ADMIN_SECRET_CODE = "ADMIN2024";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_register);

        dbHelper = new DatabaseHelper(this);

        initViews();
        setupListeners();
        setupUserTypeSelection();
    }

    private void initViews() {
        etStudentId = findViewById(R.id.etStudentId);
        etFullName = findViewById(R.id.etFullName);
        etEmail = findViewById(R.id.etEmail);
        etPhone = findViewById(R.id.etPhone);
        etDepartment = findViewById(R.id.etDepartment);
        etAdminUsername = findViewById(R.id.etAdminUsername);
        etAdminFullName = findViewById(R.id.etAdminFullName);
        etAdminEmail = findViewById(R.id.etAdminEmail);
        etAdminCode = findViewById(R.id.etAdminCode);
        etPassword = findViewById(R.id.etPassword);
        etConfirmPassword = findViewById(R.id.etConfirmPassword);
        etSecurityAnswer = findViewById(R.id.etSecurityAnswer);
        tvSecurityQuestion = findViewById(R.id.tvSecurityQuestion);
        btnRegister = findViewById(R.id.btnRegister);
        btnGoogleSignUp = findViewById(R.id.btnGoogleSignUp);
        tvBackToLogin = findViewById(R.id.tvBackToLogin);
        progressBar = findViewById(R.id.progressBar);
        studentFields = findViewById(R.id.studentFields);
        adminFields = findViewById(R.id.adminFields);
        layoutStudent = findViewById(R.id.layoutStudent);
        layoutAdmin = findViewById(R.id.layoutAdmin);

        // Set security question
        tvSecurityQuestion.setText("What is your favorite book?");
    }

    private void setupListeners() {
        btnRegister.setOnClickListener(v -> register());
        btnGoogleSignUp.setOnClickListener(v ->
                Toast.makeText(this, "Google Sign Up - Coming Soon", Toast.LENGTH_SHORT).show());
        tvBackToLogin.setOnClickListener(v -> finish());
    }

    private void setupUserTypeSelection() {
        layoutStudent.setOnClickListener(v -> selectUserType(true));
        layoutAdmin.setOnClickListener(v -> selectUserType(false));
    }

    private void selectUserType(boolean isStudent) {
        isStudentSelected = isStudent;
        layoutStudent.setSelected(isStudent);
        layoutAdmin.setSelected(!isStudent);

        if (isStudent) {
            studentFields.setVisibility(View.VISIBLE);
            adminFields.setVisibility(View.GONE);
        } else {
            studentFields.setVisibility(View.GONE);
            adminFields.setVisibility(View.VISIBLE);
        }
    }

    private void register() {
        String password = etPassword.getText().toString().trim();
        String confirmPassword = etConfirmPassword.getText().toString().trim();
        String securityAnswer = etSecurityAnswer.getText().toString().trim();

        if (password.isEmpty() || password.length() < 4) {
            etPassword.setError("Password must be at least 4 characters");
            return;
        }
        if (!password.equals(confirmPassword)) {
            etConfirmPassword.setError("Passwords do not match");
            return;
        }
        if (securityAnswer.isEmpty()) {
            etSecurityAnswer.setError("Security answer is required for password recovery");
            return;
        }

        if (isStudentSelected) {
            registerStudent(password, securityAnswer);
        } else {
            registerAdmin(password, securityAnswer);
        }
    }

    private void registerStudent(String password, String securityAnswer) {
        String studentId = etStudentId.getText().toString().trim().toUpperCase();
        String fullName = etFullName.getText().toString().trim();
        String email = etEmail.getText().toString().trim();
        String phone = etPhone.getText().toString().trim();
        String department = etDepartment.getText().toString().trim();

        if (studentId.isEmpty() || fullName.isEmpty()) {
            Toast.makeText(this, "Please fill all fields", Toast.LENGTH_SHORT).show();
            return;
        }

        showLoading(true);
        new Handler().postDelayed(() -> {
            if (dbHelper.registerUserWithSecurity(studentId, password, "student", fullName, email, phone, department, securityAnswer)) {
                Toast.makeText(RegisterScreen.this, "Account created! Please login.", Toast.LENGTH_LONG).show();
                finish();
            } else {
                Toast.makeText(RegisterScreen.this, "Student ID already exists", Toast.LENGTH_SHORT).show();
                showLoading(false);
            }
        }, 500);
    }

    private void registerAdmin(String password, String securityAnswer) {
        String username = etAdminUsername.getText().toString().trim();
        String fullName = etAdminFullName.getText().toString().trim();
        String email = etAdminEmail.getText().toString().trim();
        String adminCode = etAdminCode.getText().toString().trim();

        if (username.isEmpty() || fullName.isEmpty()) {
            Toast.makeText(this, "Please fill all fields", Toast.LENGTH_SHORT).show();
            return;
        }
        if (!ADMIN_SECRET_CODE.equals(adminCode)) {
            etAdminCode.setError("Invalid admin code");
            return;
        }

        showLoading(true);
        new Handler().postDelayed(() -> {
            if (dbHelper.registerUserWithSecurity(username, password, "admin", fullName, email, "", "", securityAnswer)) {
                Toast.makeText(RegisterScreen.this, "Admin account created!", Toast.LENGTH_LONG).show();
                finish();
            } else {
                Toast.makeText(RegisterScreen.this, "Username already exists", Toast.LENGTH_SHORT).show();
                showLoading(false);
            }
        }, 500);
    }

    private void showLoading(boolean isLoading) {
        if (isLoading) {
            progressBar.setVisibility(ProgressBar.VISIBLE);
            btnRegister.setEnabled(false);
            btnRegister.setText("");
        } else {
            progressBar.setVisibility(ProgressBar.GONE);
            btnRegister.setEnabled(true);
            btnRegister.setText("SIGN UP");
        }
    }
}