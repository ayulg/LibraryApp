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

public class ReservationsActivity extends AppCompatActivity {

    private LinearLayout llReservationsList;
    private TextView btnBack;
    private DatabaseHelper dbHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_reservations);

        dbHelper = new DatabaseHelper(this);
        llReservationsList = findViewById(R.id.llReservationsList);
        btnBack = findViewById(R.id.btnBack);

        btnBack.setOnClickListener(v -> finish());

        loadReservations();
    }

    private void loadReservations() {
        List<String[]> reservations = dbHelper.getAllReservations();
        llReservationsList.removeAllViews();

        if (reservations.isEmpty()) {
            View emptyView = LayoutInflater.from(this).inflate(R.layout.empty_reservations, null);
            llReservationsList.addView(emptyView);
            return;
        }

        for (String[] res : reservations) {
            View itemView = LayoutInflater.from(this).inflate(R.layout.item_reservation_row, null);

            TextView tvBookId = itemView.findViewById(R.id.tvResBookId);
            TextView tvBookName = itemView.findViewById(R.id.tvResBookName);
            TextView tvStudentId = itemView.findViewById(R.id.tvResStudentId);
            TextView tvStudentName = itemView.findViewById(R.id.tvResStudentName);
            TextView tvResDate = itemView.findViewById(R.id.tvResDate);
            Button btnCancel = itemView.findViewById(R.id.btnCancelResAdmin);

            final String bookId = res[0];
            final String studentId = res[1];
            final String resDate = res[2];
            final String reservationId = res[3];
            final String bookTitle = dbHelper.getBookTitle(bookId);
            final String studentName = getStudentName(studentId);

            tvBookId.setText(bookId);
            tvBookName.setText(bookTitle);
            tvStudentId.setText(studentId);
            tvStudentName.setText(studentName);
            tvResDate.setText(resDate);

            btnCancel.setOnClickListener(v -> {
                new AlertDialog.Builder(ReservationsActivity.this)
                        .setTitle("Cancel Reservation")
                        .setMessage("Cancel reservation for \"" + bookTitle + "\" by student " + studentName + "?")
                        .setPositiveButton("CANCEL", (dialog, which) -> {
                            if (dbHelper.cancelReservation(reservationId)) {
                                Toast.makeText(ReservationsActivity.this, "Reservation cancelled", Toast.LENGTH_SHORT).show();
                                loadReservations();
                                // Send notification to student using 4 parameters
                                sendCancellationNotification(studentId, bookTitle);
                            } else {
                                Toast.makeText(ReservationsActivity.this, "Failed to cancel", Toast.LENGTH_SHORT).show();
                            }
                        })
                        .setNegativeButton("NO", null)
                        .show();
            });

            itemView.setOnClickListener(v -> {
                new AlertDialog.Builder(ReservationsActivity.this)
                        .setTitle("Reservation Details")
                        .setMessage("━━━━━━━━━━━━━━━━━━━━\n" +
                                "📖 Book: " + bookTitle + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━\n" +
                                "📌 Book ID: " + bookId + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━\n" +
                                "👤 Student: " + studentName + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━\n" +
                                "📅 Reserved On: " + resDate + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━")
                        .setPositiveButton("OK", null)
                        .show();
            });

            llReservationsList.addView(itemView);
        }
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

    private void sendCancellationNotification(String studentId, String bookTitle) {
        // Store notification in database using 4 parameters
        String title = "Reservation Cancelled";
        String message = "❌ Your reservation for \"" + bookTitle + "\" has been cancelled by admin.";
        String type = "CANCELLED";

        boolean sent = dbHelper.addNotification(studentId, title, message, type);
        if (sent) {
            Toast.makeText(this, "Notification sent to student", Toast.LENGTH_SHORT).show();
        } else {
            Toast.makeText(this, "Failed to send notification", Toast.LENGTH_SHORT).show();
        }
    }
}