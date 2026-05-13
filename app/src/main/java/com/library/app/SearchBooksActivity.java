package com.library.app;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import java.util.List;

public class SearchBooksActivity extends AppCompatActivity {

    private EditText etSearch;
    private Button btnSearch;
    private TextView btnBack;
    private RadioGroup rgSearchType;
    private RadioButton rbTitle, rbAuthor, rbGenre;
    private LinearLayout llResults;
    private DatabaseHelper dbHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_search_books);

        dbHelper = new DatabaseHelper(this);

        etSearch = findViewById(R.id.etSearch);
        btnSearch = findViewById(R.id.btnSearch);
        btnBack = findViewById(R.id.btnBack);
        rgSearchType = findViewById(R.id.rgSearchType);
        rbTitle = findViewById(R.id.rbTitle);
        rbAuthor = findViewById(R.id.rbAuthor);
        rbGenre = findViewById(R.id.rbGenre);
        llResults = findViewById(R.id.llResults);

        btnBack.setOnClickListener(v -> finish());
        btnSearch.setOnClickListener(v -> searchBooks());
    }

    private void searchBooks() {
        String keyword = etSearch.getText().toString().trim();

        if (TextUtils.isEmpty(keyword)) {
            Toast.makeText(this, "Please enter search keyword", Toast.LENGTH_SHORT).show();
            return;
        }

        String searchType = "title";
        if (rbAuthor.isChecked()) searchType = "author";
        else if (rbGenre.isChecked()) searchType = "genre";

        List<String[]> results = dbHelper.searchBooks(keyword, searchType);
        displayResults(results, keyword);
    }

    private void displayResults(List<String[]> results, String keyword) {
        llResults.removeAllViews();

        if (results.isEmpty()) {
            TextView empty = new TextView(this);
            empty.setText("📚 No books found matching \"" + keyword + "\"");
            empty.setTextSize(14f);
            empty.setTextColor(0xFF8B7355);
            empty.setPadding(40, 80, 40, 80);
            empty.setGravity(android.view.Gravity.CENTER);
            llResults.addView(empty);
            return;
        }

        TextView countText = new TextView(this);
        countText.setText("Found " + results.size() + " book(s)");
        countText.setTextSize(12f);
        countText.setTextColor(0xFF7F8C8D);
        countText.setPadding(8, 0, 8, 16);
        llResults.addView(countText);

        for (String[] book : results) {
            View itemView = LayoutInflater.from(this).inflate(R.layout.item_search_result, null);

            TextView tvBookId = itemView.findViewById(R.id.tvSearchBookId);
            TextView tvTitle = itemView.findViewById(R.id.tvSearchTitle);
            TextView tvAuthor = itemView.findViewById(R.id.tvSearchAuthor);
            TextView tvGenre = itemView.findViewById(R.id.tvSearchGenre);
            TextView tvStatus = itemView.findViewById(R.id.tvSearchStatus);

            tvBookId.setText(book[0]);
            tvTitle.setText(book[1]);
            tvAuthor.setText("✍️ " + book[2]);
            tvGenre.setText("📚 " + book[3]);
            tvStatus.setText(book[4]);

            if (book[4].equals("Available")) {
                tvStatus.setTextColor(0xFF2E7D32);
                tvStatus.setBackgroundResource(R.drawable.bg_status_available);
            } else {
                tvStatus.setTextColor(0xFFE65100);
                tvStatus.setBackgroundResource(R.drawable.bg_status_issued);
            }

            // Make item clickable to show details
            itemView.setOnClickListener(v -> {
                new AlertDialog.Builder(SearchBooksActivity.this)
                        .setTitle("Book Details")
                        .setMessage("━━━━━━━━━━━━━━━━━━━━\n" +
                                "📌 ID: " + book[0] + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━\n" +
                                "📖 Title: " + book[1] + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━\n" +
                                "✍️ Author: " + book[2] + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━\n" +
                                "📚 Genre: " + book[3] + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━\n" +
                                "📊 Status: " + book[4] + "\n" +
                                "━━━━━━━━━━━━━━━━━━━━")
                        .setPositiveButton("OK", null)
                        .show();
            });

            llResults.addView(itemView);
        }
    }
}