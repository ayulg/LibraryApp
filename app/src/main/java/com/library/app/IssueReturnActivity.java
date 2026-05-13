package com.library.app;

import android.os.Bundle;
import android.text.TextUtils;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;
import java.util.List;
import java.util.ArrayList;

public class IssueReturnActivity extends AppCompatActivity {

    private EditText etIssueBookId, etIssueStudentId;
    private EditText etReturnBookId, etReturnStudentId;
    private Button btnIssue, btnReturn;
    private TextView btnBack;
    private DatabaseHelper dbHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_issue_return);

        dbHelper = new DatabaseHelper(this);

        etIssueBookId = findViewById(R.id.etIssueBookId);
        etIssueStudentId = findViewById(R.id.etIssueStudentId);
        etReturnBookId = findViewById(R.id.etReturnBookId);
        etReturnStudentId = findViewById(R.id.etReturnStudentId);
        btnIssue = findViewById(R.id.btnIssue);
        btnReturn = findViewById(R.id.btnReturn);
        btnBack = findViewById(R.id.btnBack);

        btnBack.setOnClickListener(v -> finish());
        btnIssue.setOnClickListener(v -> issueBook());
        btnReturn.setOnClickListener(v -> returnBook());
    }

    private String getTodayDate() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    }

    private String getDueDate() {
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DAY_OF_MONTH, 14);
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(c.getTime());
    }

    private void issueBook() {
        String bookId = etIssueBookId.getText().toString().trim().toUpperCase();
        String studentId = etIssueStudentId.getText().toString().trim().toUpperCase();

        if (TextUtils.isEmpty(bookId)) {
            etIssueBookId.setError("Book ID required");
            etIssueBookId.requestFocus();
            return;
        }
        if (TextUtils.isEmpty(studentId)) {
            etIssueStudentId.setError("Student ID required");
            etIssueStudentId.requestFocus();
            return;
        }

        // Check if book exists and is available
        List<String[]> books = dbHelper.getAllBooks();
        boolean bookExists = false;
        boolean isAvailable = false;
        String bookTitle = "";

        for (String[] book : books) {
            if (book[0].equals(bookId)) {
                bookExists = true;
                isAvailable = book[4].equals("Available");
                bookTitle = book[1];
                break;
            }
        }

        if (!bookExists) {
            Toast.makeText(this, "Book ID not found!", Toast.LENGTH_SHORT).show();
            return;
        }

        if (!isAvailable) {
            Toast.makeText(this, "Book is not available for issue!", Toast.LENGTH_SHORT).show();
            return;
        }

        // Check if student exists
        List<String[]> students = dbHelper.getAllStudents();
        boolean studentExists = false;
        for (String[] student : students) {
            if (student[0].equals(studentId)) {
                studentExists = true;
                break;
            }
        }

        if (!studentExists) {
            Toast.makeText(this, "Student ID not found!", Toast.LENGTH_SHORT).show();
            return;
        }

        new AlertDialog.Builder(this)
                .setTitle("Issue Book")
                .setMessage("Issue \"" + bookTitle + "\" to student " + studentId + "?\n\nDue Date: " + getDueDate())
                .setPositiveButton("ISSUE", (dialog, which) -> {
                    if (dbHelper.issueBook(bookId, studentId, getTodayDate(), getDueDate())) {
                        Toast.makeText(this, "✓ Book Issued Successfully!\nDue Date: " + getDueDate(), Toast.LENGTH_LONG).show();
                        etIssueBookId.setText("");
                        etIssueStudentId.setText("");
                    } else {
                        Toast.makeText(this, "Failed to issue book", Toast.LENGTH_SHORT).show();
                    }
                })
                .setNegativeButton("CANCEL", null)
                .show();
    }

    private void returnBook() {
        String bookId = etReturnBookId.getText().toString().trim().toUpperCase();
        String studentId = etReturnStudentId.getText().toString().trim().toUpperCase();

        if (TextUtils.isEmpty(bookId)) {
            etReturnBookId.setError("Book ID required");
            etReturnBookId.requestFocus();
            return;
        }
        if (TextUtils.isEmpty(studentId)) {
            etReturnStudentId.setError("Student ID required");
            etReturnStudentId.requestFocus();
            return;
        }

        // Check if book was issued to this student
        List<String[]> issues = dbHelper.getStudentIssues(studentId);
        boolean found = false;
        String bookTitle = "";

        for (String[] issue : issues) {
            if (issue[0].equals(bookId)) {
                found = true;
                bookTitle = dbHelper.getBookTitle(bookId);
                break;
            }
        }

        if (!found) {
            Toast.makeText(this, "This book was not issued to this student!", Toast.LENGTH_SHORT).show();
            return;
        }

        new AlertDialog.Builder(this)
                .setTitle("Return Book")
                .setMessage("Return \"" + bookTitle + "\" from student " + studentId + "?")
                .setPositiveButton("RETURN", (dialog, which) -> {
                    if (dbHelper.returnBook(bookId, studentId, getTodayDate())) {
                        Toast.makeText(this, "✓ Book Returned Successfully!", Toast.LENGTH_SHORT).show();
                        etReturnBookId.setText("");
                        etReturnStudentId.setText("");
                    } else {
                        Toast.makeText(this, "Failed to return book", Toast.LENGTH_SHORT).show();
                    }
                })
                .setNegativeButton("CANCEL", null)
                .show();
    }
}