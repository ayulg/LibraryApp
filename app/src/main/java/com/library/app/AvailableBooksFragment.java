package com.library.app;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;

public class AvailableBooksFragment extends Fragment {

    private RecyclerView rvAvailableBooks;
    private EditText etSearchBooks;
    private Button btnSearchBooks;
    private DatabaseHelper dbHelper;
    private AvailableBooksAdapter adapter;
    private List<String[]> booksList;
    private String studentId;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_available_books, container, false);

        dbHelper = new DatabaseHelper(getActivity());

        if (getArguments() != null) {
            studentId = getArguments().getString("STUDENT_ID");
        }

        rvAvailableBooks = view.findViewById(R.id.rvAvailableBooks);
        etSearchBooks = view.findViewById(R.id.etSearchBooks);
        btnSearchBooks = view.findViewById(R.id.btnSearchBooks);

        rvAvailableBooks.setLayoutManager(new LinearLayoutManager(getActivity()));
        rvAvailableBooks.setHasFixedSize(true);

        loadAvailableBooks();

        btnSearchBooks.setOnClickListener(v -> {
            String keyword = etSearchBooks.getText().toString().trim();
            if (keyword.isEmpty()) {
                loadAvailableBooks();
            } else {
                searchBooks(keyword);
            }
        });

        return view;
    }

    public void refreshBooks() {
        if (getActivity() != null) {
            getActivity().runOnUiThread(() -> {
                loadAvailableBooks();
            });
        }
    }

    private void loadAvailableBooks() {
        booksList = dbHelper.getAvailableBooks();
        adapter = new AvailableBooksAdapter(booksList, studentId);
        rvAvailableBooks.setAdapter(adapter);
    }

    private void searchBooks(String keyword) {
        booksList = dbHelper.searchBooks(keyword, "title");
        if (booksList.isEmpty()) {
            booksList = dbHelper.searchBooks(keyword, "author");
        }
        if (booksList.isEmpty()) {
            booksList = dbHelper.searchBooks(keyword, "genre");
        }
        adapter = new AvailableBooksAdapter(booksList, studentId);
        rvAvailableBooks.setAdapter(adapter);

        if (booksList.isEmpty()) {
            Toast.makeText(getActivity(), "No books found matching \"" + keyword + "\"", Toast.LENGTH_SHORT).show();
        }
    }

    private String getTodayDate() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Calendar.getInstance().getTime());
    }

    // Dynamic due date - uses admin settings
    private String getDueDate() {
        return dbHelper.getDueDate();
    }

    private int getDueDays() {
        return dbHelper.getDueDays();
    }

    private void refreshDashboard() {
        if (getActivity() instanceof StudentDashboard) {
            ((StudentDashboard) getActivity()).refreshMyBooks();
        }
    }

    // ==================== ADAPTER CLASS ====================

    class AvailableBooksAdapter extends RecyclerView.Adapter<AvailableBooksAdapter.BookViewHolder> {

        private List<String[]> books;
        private String studentId;

        AvailableBooksAdapter(List<String[]> books, String studentId) {
            this.books = books;
            this.studentId = studentId;
        }

        @NonNull
        @Override
        public BookViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_available_book, parent, false);
            return new BookViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull BookViewHolder holder, int position) {
            String[] book = books.get(position);
            String bookId = book[0];

            // Get available quantity from database
            int availableQty = dbHelper.getAvailableQuantity(bookId);
            int dueDays = getDueDays();

            holder.tvBookId.setText(bookId);
            holder.tvBookTitle.setText(book[1]);
            holder.tvBookAuthor.setText("by " + book[2]);
            holder.tvBookGenre.setText(book[3]);

            boolean alreadyIssued = checkIfStudentHasBook(bookId, studentId);
            boolean alreadyReserved = checkIfStudentReserved(bookId, studentId);

            // Show availability with quantity
            if (availableQty > 0 && !alreadyIssued) {
                // Available book - show ISSUE button with quantity
                if (availableQty > 1) {
                    holder.tvStatus.setText(availableQty + " copies available");
                } else {
                    holder.tvStatus.setText("AVAILABLE");
                }
                holder.tvStatus.setTextColor(0xFF2E7D32);
                holder.tvStatus.setBackgroundResource(R.drawable.bg_status_available);
                holder.btnIssueBook.setEnabled(true);
                holder.btnIssueBook.setAlpha(1.0f);
                holder.btnIssueBook.setVisibility(View.VISIBLE);
                holder.btnReserveBook.setVisibility(View.GONE);
            } else {
                // Book not available
                if (alreadyIssued) {
                    holder.tvStatus.setText("ALREADY ISSUED");
                } else if (availableQty == 0) {
                    holder.tvStatus.setText("OUT OF STOCK");
                } else {
                    holder.tvStatus.setText("ISSUED");
                }
                holder.tvStatus.setTextColor(0xFFE65100);
                holder.tvStatus.setBackgroundResource(R.drawable.bg_status_issued);
                holder.btnIssueBook.setEnabled(false);
                holder.btnIssueBook.setAlpha(0.5f);
                holder.btnIssueBook.setVisibility(View.GONE);

                // Show reserve button only if book is out of stock and not already reserved
                if (!alreadyReserved && !alreadyIssued && availableQty == 0) {
                    holder.btnReserveBook.setVisibility(View.VISIBLE);
                } else if (alreadyReserved) {
                    holder.btnReserveBook.setVisibility(View.GONE);
                    holder.tvStatus.setText("RESERVED");
                    holder.tvStatus.setTextColor(0xFF1976D2);
                    holder.tvStatus.setBackgroundResource(R.drawable.bg_status_available);
                } else {
                    holder.btnReserveBook.setVisibility(View.GONE);
                }
            }

            // Issue button click - uses dynamic due date
            holder.btnIssueBook.setOnClickListener(v -> {
                String dueDate = getDueDate();
                String message = "Do you want to issue \"" + book[1] + "\"?\n\n";
                message += "Due date: " + dueDays + " days from today (" + dueDate + ")\n";
                message += "Available copies: " + availableQty;

                new AlertDialog.Builder(getActivity())
                        .setTitle("Issue Book")
                        .setMessage(message)
                        .setPositiveButton("ISSUE", (dialog, which) -> {
                            if (dbHelper.issueBook(bookId, studentId, getTodayDate(), dueDate)) {
                                Toast.makeText(getActivity(), "✓ Book Issued Successfully!\nDue Date: " + dueDate + "\nReturn within " + dueDays + " days", Toast.LENGTH_LONG).show();
                                loadAvailableBooks();
                                refreshDashboard();
                            } else {
                                Toast.makeText(getActivity(), "Failed to issue book", Toast.LENGTH_SHORT).show();
                            }
                        })
                        .setNegativeButton("CANCEL", null)
                        .show();
            });

            // Reserve button click
            holder.btnReserveBook.setOnClickListener(v -> {
                new AlertDialog.Builder(getActivity())
                        .setTitle("Reserve Book")
                        .setMessage("Do you want to reserve \"" + book[1] + "\"?\n\nYou will be notified when it becomes available.")
                        .setPositiveButton("RESERVE", (dialog, which) -> {
                            if (dbHelper.reserveBook(bookId, studentId, getTodayDate())) {
                                Toast.makeText(getActivity(), "✓ Book Reserved Successfully!", Toast.LENGTH_SHORT).show();
                                loadAvailableBooks();
                                refreshDashboard();
                            } else {
                                Toast.makeText(getActivity(), "Failed to reserve book", Toast.LENGTH_SHORT).show();
                            }
                        })
                        .setNegativeButton("CANCEL", null)
                        .show();
            });
        }

        private boolean checkIfStudentHasBook(String bookId, String studentId) {
            List<String[]> studentIssues = dbHelper.getStudentIssues(studentId);
            for (String[] issue : studentIssues) {
                if (issue[0].equals(bookId)) {
                    return true;
                }
            }
            return false;
        }

        private boolean checkIfStudentReserved(String bookId, String studentId) {
            List<String[]> reservations = dbHelper.getStudentReservations(studentId);
            for (String[] res : reservations) {
                if (res[0].equals(bookId)) {
                    return true;
                }
            }
            return false;
        }

        @Override
        public int getItemCount() {
            return books.size();
        }

        class BookViewHolder extends RecyclerView.ViewHolder {
            TextView tvBookId, tvBookTitle, tvBookAuthor, tvBookGenre, tvStatus;
            Button btnIssueBook, btnReserveBook;

            BookViewHolder(@NonNull View itemView) {
                super(itemView);
                tvBookId = itemView.findViewById(R.id.tvBookId);
                tvBookTitle = itemView.findViewById(R.id.tvBookTitle);
                tvBookAuthor = itemView.findViewById(R.id.tvBookAuthor);
                tvBookGenre = itemView.findViewById(R.id.tvBookGenre);
                tvStatus = itemView.findViewById(R.id.tvStatus);
                btnIssueBook = itemView.findViewById(R.id.btnIssueBook);
                btnReserveBook = itemView.findViewById(R.id.btnReserveBook);
            }
        }
    }
}