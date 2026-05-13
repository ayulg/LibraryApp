package com.library.app;

import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.viewpager2.widget.ViewPager2;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;
import java.util.List;

public class StudentDashboard extends AppCompatActivity {

    private TextView tvStudentName, tvIssuedCount, tvReservationsCount, tvFinesAmount, btnLogout, btnSettings, btnNotifications;
    private DatabaseHelper dbHelper;
    private String username;
    private ViewPager2 viewPager;
    private TabLayout tabLayout;
    private StudentPagerAdapter adapter;
    private AvailableBooksFragment availableBooksFragment;
    private MyBooksFragment myBooksFragment;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_student_dashboard);

        dbHelper = new DatabaseHelper(this);
        username = getIntent().getStringExtra("USERNAME");
        if (username == null) username = "Student";

        // Initialize views
        tvStudentName = findViewById(R.id.tvStudentName);
        tvIssuedCount = findViewById(R.id.tvIssuedCount);
        tvReservationsCount = findViewById(R.id.tvReservationsCount);
        tvFinesAmount = findViewById(R.id.tvFinesAmount);
        btnLogout = findViewById(R.id.btnLogout);
        btnSettings = findViewById(R.id.btnSettings);
        btnNotifications = findViewById(R.id.btnNotifications);
        viewPager = findViewById(R.id.viewPager);
        tabLayout = findViewById(R.id.tabLayout);

        tvStudentName.setText("Welcome, " + username);

        // Button click listeners
        btnLogout.setOnClickListener(v -> finish());

        if (btnSettings != null) {
            btnSettings.setOnClickListener(v -> showSettingsDialog());
        }

        // Notification bell click
        if (btnNotifications != null) {
            btnNotifications.setOnClickListener(v -> {
                Intent intent = new Intent(StudentDashboard.this, NotificationsActivity.class);
                intent.putExtra("USER_ID", username);
                startActivity(intent);
            });
        }

        setupViewPager();
        updateStats();
        updateNotificationBadge();
    }

    private void updateNotificationBadge() {
        if (btnNotifications != null) {
            int unreadCount = dbHelper.getUnreadNotificationCount(username);
            if (unreadCount > 0) {
                btnNotifications.setText("🔔(" + unreadCount + ")");
            } else {
                btnNotifications.setText("🔔");
            }
        }
    }

    private void setupViewPager() {
        adapter = new StudentPagerAdapter(this, username);
        viewPager.setAdapter(adapter);

        new TabLayoutMediator(tabLayout, viewPager, (tab, position) -> {
            if (position == 0) {
                tab.setText("📚 Available Books");
            } else {
                tab.setText("📖 My Books");
            }
        }).attach();

        availableBooksFragment = (AvailableBooksFragment) adapter.getFragment(0);
        myBooksFragment = (MyBooksFragment) adapter.getFragment(1);
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
                Toast.makeText(StudentDashboard.this, "Current password is incorrect", Toast.LENGTH_SHORT).show();
                return;
            }

            if (!TextUtils.isEmpty(newPassword)) {
                if (newPassword.length() < 4) {
                    Toast.makeText(StudentDashboard.this, "New password must be at least 4 characters", Toast.LENGTH_SHORT).show();
                    return;
                }
                if (!newPassword.equals(confirmPassword)) {
                    Toast.makeText(StudentDashboard.this, "New passwords do not match", Toast.LENGTH_SHORT).show();
                    return;
                }
            }

            boolean updated = dbHelper.updateUserInfo(username,
                    TextUtils.isEmpty(newPassword) ? null : newPassword,
                    TextUtils.isEmpty(newSecurityAnswer) ? null : newSecurityAnswer);

            if (updated) {
                Toast.makeText(StudentDashboard.this, "✓ Settings updated successfully!", Toast.LENGTH_LONG).show();
                dialog.dismiss();
            } else {
                Toast.makeText(StudentDashboard.this, "Failed to update settings", Toast.LENGTH_SHORT).show();
            }
        });
    }

    public void refreshData() {
        updateStats();
        updateNotificationBadge();
        if (availableBooksFragment != null) {
            availableBooksFragment.refreshBooks();
        }
        if (myBooksFragment != null) {
            myBooksFragment.refreshData();
        }
    }

    public void refreshMyBooks() {
        updateStats();
        updateNotificationBadge();
        if (myBooksFragment != null) {
            myBooksFragment.refreshData();
        }
        if (availableBooksFragment != null) {
            availableBooksFragment.refreshBooks();
        }
    }

    private void updateStats() {
        List<String[]> issued = dbHelper.getStudentIssues(username);
        List<String[]> reservations = dbHelper.getStudentReservations(username);
        List<String[]> fines = dbHelper.getStudentFines(username);

        tvIssuedCount.setText(String.valueOf(issued.size()));
        tvReservationsCount.setText(String.valueOf(reservations.size()));

        double total = 0;
        for (String[] f : fines) {
            try {
                total += Double.parseDouble(f[1]);
            } catch (NumberFormatException e) {
                // Handle error
            }
        }
        tvFinesAmount.setText("ETB " + String.format("%.2f", total));
    }
}