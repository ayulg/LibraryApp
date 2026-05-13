package com.library.app;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class MyBooksFragment extends Fragment {

    private LinearLayout llIssuedBooks, llReservations;
    private DatabaseHelper dbHelper;
    private String studentId;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_my_books, container, false);

        dbHelper = new DatabaseHelper(getActivity());

        if (getArguments() != null) {
            studentId = getArguments().getString("STUDENT_ID");
        }

        llIssuedBooks = view.findViewById(R.id.llIssuedBooks);
        llReservations = view.findViewById(R.id.llReservations);

        loadIssuedBooks();
        loadReservations();

        return view;
    }

    public void refreshData() {
        if (getActivity() != null) {
            getActivity().runOnUiThread(() -> {
                loadIssuedBooks();
                loadReservations();
            });
        }
    }

    private String getToday() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    }

    private void loadIssuedBooks() {
        if (getActivity() == null) return;

        List<String[]> issuedBooks = dbHelper.getStudentIssues(studentId);

        if (llIssuedBooks == null) return;
        llIssuedBooks.removeAllViews();

        if (issuedBooks == null || issuedBooks.isEmpty()) {
            TextView empty = new TextView(getActivity());
            empty.setText("📖 No books issued yet");
            empty.setTextSize(14f);
            empty.setTextColor(0xFF8B7355);
            empty.setPadding(40, 40, 40, 40);
            empty.setGravity(android.view.Gravity.CENTER);
            llIssuedBooks.addView(empty);
            return;
        }

        String today = getToday();

        for (String[] book : issuedBooks) {
            View itemView = LayoutInflater.from(getActivity()).inflate(R.layout.item_issued_book, null);

            TextView tvBookId = itemView.findViewById(R.id.tvBookId);
            TextView tvBookTitle = itemView.findViewById(R.id.tvBookTitle);
            TextView tvDueDate = itemView.findViewById(R.id.tvDueDate);
            TextView tvStatus = itemView.findViewById(R.id.tvStatus);
            Button btnReturn = itemView.findViewById(R.id.btnReturnBook);

            final String bookId = book[0];
            final String dueDate = book[2];
            final String bookTitle = dbHelper.getBookTitle(bookId);

            tvBookId.setText(bookId);
            tvBookTitle.setText(bookTitle);
            tvDueDate.setText("Due: " + dueDate);

            boolean isOverdue = dueDate.compareTo(today) < 0;
            if (isOverdue) {
                tvStatus.setText("OVERDUE");
                tvStatus.setTextColor(0xFFC62828);
                tvStatus.setBackgroundResource(R.drawable.bg_status_overdue);
            } else {
                tvStatus.setText("ON TIME");
                tvStatus.setTextColor(0xFF2E7D32);
                tvStatus.setBackgroundResource(R.drawable.bg_status_available);
            }

            btnReturn.setOnClickListener(v -> {
                new AlertDialog.Builder(getActivity())
                        .setTitle("Return Book")
                        .setMessage("Return \"" + bookTitle + "\"?")
                        .setPositiveButton("RETURN", (dialog, which) -> {
                            if (dbHelper.returnBook(bookId, studentId, getToday())) {
                                Toast.makeText(getActivity(), "✓ Book returned successfully", Toast.LENGTH_SHORT).show();
                                refreshData();
                                if (getActivity() instanceof StudentDashboard) {
                                    ((StudentDashboard) getActivity()).refreshData();
                                }
                            } else {
                                Toast.makeText(getActivity(), "Failed to return book", Toast.LENGTH_SHORT).show();
                            }
                        })
                        .setNegativeButton("CANCEL", null)
                        .show();
            });

            llIssuedBooks.addView(itemView);
        }
    }

    private void loadReservations() {
        if (getActivity() == null) return;

        List<String[]> reservations = dbHelper.getStudentReservations(studentId);

        if (llReservations == null) return;
        llReservations.removeAllViews();

        if (reservations == null || reservations.isEmpty()) {
            TextView empty = new TextView(getActivity());
            empty.setText("🔖 No active reservations");
            empty.setTextSize(14f);
            empty.setTextColor(0xFF8B7355);
            empty.setPadding(40, 40, 40, 40);
            empty.setGravity(android.view.Gravity.CENTER);
            llReservations.addView(empty);
            return;
        }

        for (String[] res : reservations) {
            View itemView = LayoutInflater.from(getActivity()).inflate(R.layout.item_reservation, null);

            TextView tvBookId = itemView.findViewById(R.id.tvBookId);
            TextView tvBookTitle = itemView.findViewById(R.id.tvBookTitle);
            TextView tvReservedDate = itemView.findViewById(R.id.tvReservedDate);
            Button btnCancel = itemView.findViewById(R.id.btnCancelReservation);

            final String bookId = res[0];
            final String reservedDate = res[1];
            final String reservationId = res[2];
            final String bookTitle = dbHelper.getBookTitle(bookId);

            tvBookId.setText(bookId);
            tvBookTitle.setText(bookTitle);
            tvReservedDate.setText("Reserved: " + reservedDate);

            btnCancel.setOnClickListener(v -> {
                new AlertDialog.Builder(getActivity())
                        .setTitle("Cancel Reservation")
                        .setMessage("Cancel reservation for \"" + bookTitle + "\"?")
                        .setPositiveButton("CANCEL", (dialog, which) -> {
                            if (dbHelper.cancelReservation(reservationId)) {
                                Toast.makeText(getActivity(), "✓ Reservation cancelled", Toast.LENGTH_SHORT).show();
                                refreshData();
                                if (getActivity() instanceof StudentDashboard) {
                                    ((StudentDashboard) getActivity()).refreshData();
                                }
                            } else {
                                Toast.makeText(getActivity(), "Failed to cancel reservation", Toast.LENGTH_SHORT).show();
                            }
                        })
                        .setNegativeButton("NO", null)
                        .show();
            });

            llReservations.addView(itemView);
        }
    }
}