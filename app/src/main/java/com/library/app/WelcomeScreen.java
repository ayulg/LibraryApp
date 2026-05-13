package com.library.app;

import android.app.AlertDialog;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.os.Handler;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;

public class WelcomeScreen extends AppCompatActivity {

    private EditText etUsername, etPassword;
    private Button btnLogin, btnGoogleLogin;
    private TextView tvRegister, tvForgotPassword;
    private ProgressBar progressBar;
    private DatabaseHelper dbHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_welcome);

        dbHelper = new DatabaseHelper(this);

        etUsername = findViewById(R.id.etUsername);
        etPassword = findViewById(R.id.etPassword);
        btnLogin = findViewById(R.id.btnLogin);
        btnGoogleLogin = findViewById(R.id.btnGoogleLogin);
        tvRegister = findViewById(R.id.tvRegister);
        tvForgotPassword = findViewById(R.id.tvForgotPassword);
        progressBar = findViewById(R.id.progressBar);

        btnLogin.setOnClickListener(v -> login());
        btnGoogleLogin.setOnClickListener(v ->
                Toast.makeText(this, "Google Login - Coming Soon", Toast.LENGTH_SHORT).show());
        tvRegister.setOnClickListener(v ->
                startActivity(new Intent(WelcomeScreen.this, RegisterScreen.class)));
        tvForgotPassword.setOnClickListener(v -> showForgotPasswordDialog());
    }

    private void login() {
        String username = etUsername.getText().toString().trim();
        String password = etPassword.getText().toString().trim();

        if (username.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Enter Username and Password", Toast.LENGTH_SHORT).show();
            return;
        }

        progressBar.setVisibility(ProgressBar.VISIBLE);
        btnLogin.setEnabled(false);
        btnLogin.setText("");

        new Handler().postDelayed(() -> {
            if (dbHelper.validateUser(username, password)) {
                String userType = dbHelper.getUserType(username);
                Toast.makeText(WelcomeScreen.this, "Welcome " + username + "!", Toast.LENGTH_SHORT).show();

                if (userType.equals("admin")) {
                    Intent intent = new Intent(WelcomeScreen.this, AdminDashboard.class);
                    intent.putExtra("USERNAME", username);
                    startActivity(intent);
                } else {
                    Intent intent = new Intent(WelcomeScreen.this, StudentDashboard.class);
                    intent.putExtra("USERNAME", username);
                    startActivity(intent);
                }
                finish();
            } else {
                Toast.makeText(WelcomeScreen.this, "Invalid Username or Password", Toast.LENGTH_SHORT).show();
                progressBar.setVisibility(ProgressBar.GONE);
                btnLogin.setEnabled(true);
                btnLogin.setText("LOGIN");
            }
        }, 500);
    }

    private void showForgotPasswordDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_forgot_password, null);

        EditText etResetUsername = view.findViewById(R.id.etResetUsername);
        EditText etSecurityAnswer = view.findViewById(R.id.etSecurityAnswer);
        EditText etNewPassword = view.findViewById(R.id.etNewPassword);
        EditText etConfirmNewPassword = view.findViewById(R.id.etConfirmNewPassword);
        Button btnResetPassword = view.findViewById(R.id.btnResetPassword);
        TextView tvSecurityQuestion = view.findViewById(R.id.tvSecurityQuestion);

        tvSecurityQuestion.setText("What is your favorite book?");

        etResetUsername.setOnFocusChangeListener((v, hasFocus) -> {
            if (!hasFocus) {
                String username = etResetUsername.getText().toString().trim();
                if (!TextUtils.isEmpty(username)) {
                    if (userExists(username)) {
                        tvSecurityQuestion.setText("What is your favorite book?");
                    } else {
                        Toast.makeText(WelcomeScreen.this, "Username not found!", Toast.LENGTH_SHORT).show();
                        etResetUsername.setError("Username not found");
                    }
                }
            }
        });

        btnResetPassword.setOnClickListener(v -> {
            String username = etResetUsername.getText().toString().trim();
            String answer = etSecurityAnswer.getText().toString().trim();
            String newPassword = etNewPassword.getText().toString().trim();
            String confirmPassword = etConfirmNewPassword.getText().toString().trim();

            if (TextUtils.isEmpty(username)) {
                Toast.makeText(WelcomeScreen.this, "Enter username", Toast.LENGTH_SHORT).show();
                return;
            }

            if (TextUtils.isEmpty(answer)) {
                Toast.makeText(WelcomeScreen.this, "Enter security answer", Toast.LENGTH_SHORT).show();
                return;
            }

            if (newPassword.length() < 4) {
                Toast.makeText(WelcomeScreen.this, "Password must be at least 4 characters", Toast.LENGTH_SHORT).show();
                return;
            }

            if (!newPassword.equals(confirmPassword)) {
                Toast.makeText(WelcomeScreen.this, "Passwords do not match", Toast.LENGTH_SHORT).show();
                return;
            }

            if (dbHelper.verifySecurityAnswer(username, answer)) {
                if (dbHelper.updatePassword(username, newPassword)) {
                    Toast.makeText(WelcomeScreen.this, "✓ Password reset successfully!\nPlease login with your new password.", Toast.LENGTH_LONG).show();
                    builder.create().dismiss();
                } else {
                    Toast.makeText(WelcomeScreen.this, "Failed to reset password", Toast.LENGTH_SHORT).show();
                }
            } else {
                Toast.makeText(WelcomeScreen.this, "Incorrect security answer", Toast.LENGTH_SHORT).show();
            }
        });

        builder.setView(view);
        AlertDialog dialog = builder.create();
        dialog.show();
    }

    private boolean userExists(String username) {
        SQLiteDatabase db = dbHelper.getReadableDatabase();
        Cursor cursor = db.query("users", new String[]{"username"}, "username=?",
                new String[]{username}, null, null, null);
        boolean exists = cursor.getCount() > 0;
        cursor.close();
        db.close();
        return exists;
    }
}