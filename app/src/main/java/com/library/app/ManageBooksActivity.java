package com.library.app;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.util.List;
import java.util.UUID;

public class ManageBooksActivity extends AppCompatActivity {

    private EditText etTitle, etAuthor, etGenre;
    private Button btnAddBook;
    private TextView btnBack;
    private LinearLayout llBooksList;
    private DatabaseHelper dbHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_manage_books);

        dbHelper = new DatabaseHelper(this);

        etTitle = findViewById(R.id.etTitle);
        etAuthor = findViewById(R.id.etAuthor);
        etGenre = findViewById(R.id.etGenre);
        btnAddBook = findViewById(R.id.btnAddBook);
        btnBack = findViewById(R.id.btnBack);
        llBooksList = findViewById(R.id.llBooksList);

        btnBack.setOnClickListener(v -> finish());
        btnAddBook.setOnClickListener(v -> addBook());

        loadBooks();
    }

    private void addBook() {
        String title = etTitle.getText().toString().trim();
        String author = etAuthor.getText().toString().trim();
        String genre = etGenre.getText().toString().trim();

        if (TextUtils.isEmpty(title)) {
            etTitle.setError("Book title is required");
            etTitle.requestFocus();
            return;
        }
        if (TextUtils.isEmpty(author)) {
            etAuthor.setError("Author name is required");
            etAuthor.requestFocus();
            return;
        }

        String bookId = "B" + UUID.randomUUID().toString().substring(0, 4).toUpperCase();

        boolean isAdded = dbHelper.addBook(bookId, title, author, genre);

        if (isAdded) {
            Toast.makeText(this, "✓ Book Added Successfully!\nID: " + bookId, Toast.LENGTH_LONG).show();
            etTitle.setText("");
            etAuthor.setText("");
            etGenre.setText("");
            loadBooks();
        } else {
            Toast.makeText(this, "Failed to add book. Please try again.", Toast.LENGTH_SHORT).show();
        }
    }

    private void loadBooks() {
        List<String[]> books = dbHelper.getAllBooks();
        llBooksList.removeAllViews();

        if (books == null || books.isEmpty()) {
            TextView emptyView = new TextView(this);
            emptyView.setText("📚 No books in library\n\nClick 'ADD BOOK' to add your first book");
            emptyView.setTextSize(14f);
            emptyView.setTextColor(getColor(R.color.text_secondary));
            emptyView.setPadding(40, 80, 40, 80);
            emptyView.setGravity(android.view.Gravity.CENTER);
            llBooksList.addView(emptyView);
            return;
        }

        for (String[] book : books) {
            View bookItem = LayoutInflater.from(this).inflate(R.layout.item_book_row, null);

            TextView tvBookId = bookItem.findViewById(R.id.tvBookRowId);
            TextView tvBookTitle = bookItem.findViewById(R.id.tvBookRowTitle);
            TextView tvBookAuthor = bookItem.findViewById(R.id.tvBookRowAuthor);
            TextView tvBookGenre = bookItem.findViewById(R.id.tvBookRowGenre);
            TextView tvBookStatus = bookItem.findViewById(R.id.tvBookRowStatus);
            View btnDelete = bookItem.findViewById(R.id.btnDeleteBook);
            View btnViewDetail = bookItem.findViewById(R.id.btnViewBookDetail);

            final String bookId = book[0];
            final String title = book[1];
            final String author = book[2];
            final String genre = book[3];
            final String status = book[4];

            tvBookId.setText(bookId);
            tvBookTitle.setText(title);
            tvBookAuthor.setText("by " + (author != null && !author.isEmpty() ? author : "Unknown"));
            tvBookGenre.setText(genre != null && !genre.isEmpty() ? genre : "General");

            if (status.equals("Available")) {
                tvBookStatus.setText("AVAILABLE");
                tvBookStatus.setTextColor(0xFF2E7D32);
                tvBookStatus.setBackgroundResource(R.drawable.bg_status_available);
            } else {
                tvBookStatus.setText("ISSUED");
                tvBookStatus.setTextColor(0xFFE65100);
                tvBookStatus.setBackgroundResource(R.drawable.bg_status_issued);
            }

            if (btnViewDetail != null) {
                btnViewDetail.setOnClickListener(v -> showBookDetails(bookId, title, author, genre, status));
            }

            btnDelete.setOnClickListener(v -> {
                if (status.equals("Available")) {
                    new AlertDialog.Builder(ManageBooksActivity.this)
                            .setTitle("Delete Book")
                            .setMessage("Delete \"" + title + "\"?")
                            .setPositiveButton("DELETE", (dialog, which) -> {
                                if (dbHelper.deleteBook(bookId)) {
                                    Toast.makeText(ManageBooksActivity.this, "✓ Book deleted", Toast.LENGTH_SHORT).show();
                                    loadBooks();
                                } else {
                                    Toast.makeText(ManageBooksActivity.this, "Failed to delete book", Toast.LENGTH_SHORT).show();
                                }
                            })
                            .setNegativeButton("CANCEL", null)
                            .show();
                } else {
                    Toast.makeText(ManageBooksActivity.this, "Cannot delete issued book", Toast.LENGTH_SHORT).show();
                }
            });

            bookItem.setOnClickListener(v -> showBookDetails(bookId, title, author, genre, status));

            llBooksList.addView(bookItem);
        }
    }

    private void showBookDetails(String bookId, String title, String author, String genre, String status) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);

        View dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_book_details, null);

        TextView tvDialogBookId = dialogView.findViewById(R.id.dialogBookId);
        TextView tvDialogTitle = dialogView.findViewById(R.id.dialogBookTitle);
        TextView tvDialogAuthor = dialogView.findViewById(R.id.dialogBookAuthor);
        TextView tvDialogGenre = dialogView.findViewById(R.id.dialogBookGenre);
        TextView tvDialogStatus = dialogView.findViewById(R.id.dialogBookStatus);
        Button btnClose = dialogView.findViewById(R.id.btnCloseDialog);
        Button btnIssuedInfo = dialogView.findViewById(R.id.btnIssuedInfo);

        tvDialogBookId.setText(bookId);
        tvDialogTitle.setText(title);
        tvDialogAuthor.setText(author);
        tvDialogGenre.setText(genre);
        tvDialogStatus.setText(status);

        if (status.equals("Issued")) {
            tvDialogStatus.setTextColor(0xFFE65100);
            tvDialogStatus.setBackgroundResource(R.drawable.bg_status_issued);
            btnIssuedInfo.setVisibility(View.VISIBLE);
        } else {
            tvDialogStatus.setTextColor(0xFF2E7D32);
            tvDialogStatus.setBackgroundResource(R.drawable.bg_status_available);
            btnIssuedInfo.setVisibility(View.GONE);
        }

        builder.setView(dialogView);
        builder.setCancelable(true);

        AlertDialog dialog = builder.create();
        dialog.show();

        btnClose.setOnClickListener(v -> dialog.dismiss());

        btnIssuedInfo.setOnClickListener(v -> {
            dialog.dismiss();
            showBookIssuedInfoDialog(bookId, title);
        });
    }

    private void showBookIssuedInfoDialog(String bookId, String title) {
        List<String[]> issues = dbHelper.getAllIssues();
        String issuedTo = "Not issued";
        String issueDate = "";
        String dueDate = "";
        String studentName = "";

        for (String[] issue : issues) {
            if (issue[0].equals(bookId)) {
                issuedTo = issue[1];
                issueDate = issue[2];
                dueDate = issue[3];
                List<String[]> students = dbHelper.getAllStudents();
                for (String[] student : students) {
                    if (student[0].equals(issuedTo)) {
                        studentName = student[1];
                        break;
                    }
                }
                break;
            }
        }

        View dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_issued_info, null);

        TextView tvBookTitle = dialogView.findViewById(R.id.issuedBookTitle);
        TextView tvStudentInfo = dialogView.findViewById(R.id.issuedStudentInfo);
        TextView tvIssueDate = dialogView.findViewById(R.id.issuedDate);
        TextView tvDueDate = dialogView.findViewById(R.id.issuedDueDate);
        Button btnClose = dialogView.findViewById(R.id.btnCloseIssuedDialog);

        tvBookTitle.setText(title);
        tvStudentInfo.setText(studentName + " (" + issuedTo + ")");
        tvIssueDate.setText(issueDate);
        tvDueDate.setText(dueDate);

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setView(dialogView);
        builder.setCancelable(true);

        AlertDialog dialog = builder.create();
        dialog.show();

        btnClose.setOnClickListener(v -> dialog.dismiss());
    }
}