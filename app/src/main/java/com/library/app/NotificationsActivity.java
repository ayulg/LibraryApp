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
import java.util.List;

public class NotificationsActivity extends AppCompatActivity {

    private LinearLayout llNotificationsList;
    private TextView btnBack;
    private Button btnClearAll;
    private DatabaseHelper dbHelper;
    private String userId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_notifications);

        dbHelper = new DatabaseHelper(this);
        llNotificationsList = findViewById(R.id.llNotificationsList);
        btnBack = findViewById(R.id.btnBack);
        btnClearAll = findViewById(R.id.btnClearAll);

        userId = getIntent().getStringExtra("USER_ID");
        if (userId == null) userId = "admin";

        btnBack.setOnClickListener(v -> finish());
        btnClearAll.setOnClickListener(v -> clearAllNotifications());

        loadNotifications();
    }

    private void loadNotifications() {
        List<String[]> notifications = dbHelper.getUserNotifications(userId);
        llNotificationsList.removeAllViews();

        if (notifications.isEmpty()) {
            View emptyView = LayoutInflater.from(this).inflate(R.layout.empty_notifications, null);
            llNotificationsList.addView(emptyView);
            return;
        }

        for (String[] notif : notifications) {
            View itemView = LayoutInflater.from(this).inflate(R.layout.notification_item, null);

            TextView tvTitle = itemView.findViewById(R.id.tvNotificationTitle);
            TextView tvMessage = itemView.findViewById(R.id.tvNotificationMessage);
            TextView tvTime = itemView.findViewById(R.id.tvNotificationTime);
            Button btnAction = itemView.findViewById(R.id.btnNotificationAction);

            final int notifId = Integer.parseInt(notif[0]);
            final String title = notif[1];
            final String message = notif[2];
            final String type = notif[3];
            final String date = notif[4];

            // Set notification type icon
            String icon = "🔔";
            if (type.equals("ISSUE")) icon = "📖";
            else if (type.equals("RETURN")) icon = "✅";
            else if (type.equals("AVAILABLE")) icon = "🟢";
            else if (type.equals("REMINDER")) icon = "⏰";

            tvTitle.setText(icon + " " + title);
            tvMessage.setText(message);
            tvTime.setText(date);

            // Mark as read when clicked
            itemView.setOnClickListener(v -> {
                dbHelper.markNotificationAsRead(notifId);
                loadNotifications();
                Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
            });

            btnAction.setText("MARK READ");
            btnAction.setOnClickListener(v -> {
                dbHelper.markNotificationAsRead(notifId);
                loadNotifications();
                Toast.makeText(this, "Notification marked as read", Toast.LENGTH_SHORT).show();
            });

            llNotificationsList.addView(itemView);
        }

        btnClearAll.setEnabled(true);
    }

    private void clearAllNotifications() {
        new AlertDialog.Builder(this)
                .setTitle("Clear Notifications")
                .setMessage("Are you sure you want to clear all notifications?")
                .setPositiveButton("CLEAR", (dialog, which) -> {
                    dbHelper.clearAllNotifications(userId);
                    loadNotifications();
                    Toast.makeText(this, "All notifications cleared", Toast.LENGTH_SHORT).show();
                })
                .setNegativeButton("CANCEL", null)
                .show();
    }
}