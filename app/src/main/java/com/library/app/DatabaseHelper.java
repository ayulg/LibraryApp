package com.library.app;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class DatabaseHelper extends SQLiteOpenHelper {

    private static final String DB_NAME = "library.db";
    private static final int VERSION = 3;

    public DatabaseHelper(Context context) {
        super(context, DB_NAME, null, VERSION);
    }

    private String getToday() {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    }

    // ==================== DUE DATE SETTINGS METHODS ====================

    public int getDueDays() {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("settings", new String[]{"value"},
                "key=?", new String[]{"due_days"}, null, null, null);
        int days = 14;
        if (cursor.moveToFirst()) {
            try {
                days = Integer.parseInt(cursor.getString(0));
            } catch (NumberFormatException e) {
                days = 14;
            }
        }
        cursor.close();
        db.close();
        return days;
    }

    public boolean updateDueDays(int days) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("value", String.valueOf(days));
        int result = db.update("settings", values, "key=?", new String[]{"due_days"});
        db.close();
        return result > 0;
    }

    public String getDueDate() {
        int days = getDueDays();
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DAY_OF_MONTH, days);
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(c.getTime());
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        // Users Table
        db.execSQL("CREATE TABLE users (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "username TEXT UNIQUE," +
                "password TEXT NOT NULL," +
                "user_type TEXT NOT NULL," +
                "security_question TEXT," +
                "security_answer TEXT)");

        // Students Table
        db.execSQL("CREATE TABLE students (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "student_id TEXT UNIQUE," +
                "name TEXT NOT NULL," +
                "email TEXT," +
                "phone TEXT," +
                "department TEXT," +
                "registration_date TEXT)");

        // Books Table with Quantity (10 copies each)
        db.execSQL("CREATE TABLE books (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "book_id TEXT UNIQUE," +
                "title TEXT NOT NULL," +
                "author TEXT NOT NULL," +
                "genre TEXT," +
                "total_quantity INTEGER DEFAULT 10," +
                "available_quantity INTEGER DEFAULT 10)");

        // Issues Table
        db.execSQL("CREATE TABLE issues (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "book_id TEXT NOT NULL," +
                "student_id TEXT NOT NULL," +
                "issue_date TEXT NOT NULL," +
                "due_date TEXT NOT NULL," +
                "return_date TEXT," +
                "returned INTEGER DEFAULT 0)");

        // Reservations Table
        db.execSQL("CREATE TABLE reservations (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "book_id TEXT NOT NULL," +
                "student_id TEXT NOT NULL," +
                "res_date TEXT NOT NULL," +
                "active INTEGER DEFAULT 1)");

        // Fines Table
        db.execSQL("CREATE TABLE fines (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "student_id TEXT NOT NULL," +
                "book_id TEXT NOT NULL," +
                "amount REAL NOT NULL," +
                "paid INTEGER DEFAULT 0)");

        // Notifications Table
        db.execSQL("CREATE TABLE notifications (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "user_id TEXT NOT NULL," +
                "title TEXT NOT NULL," +
                "message TEXT NOT NULL," +
                "type TEXT NOT NULL," +
                "date TEXT NOT NULL," +
                "is_read INTEGER DEFAULT 0)");

        // Settings Table
        db.execSQL("CREATE TABLE settings (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "key TEXT UNIQUE," +
                "value TEXT NOT NULL)");

        insertDefaultData(db);
    }

    private void insertDefaultData(SQLiteDatabase db) {
        // Admin User
        ContentValues admin = new ContentValues();
        admin.put("username", "admin");
        admin.put("password", "admin123");
        admin.put("user_type", "admin");
        admin.put("security_question", "What is your favorite book?");
        admin.put("security_answer", "admin");
        db.insert("users", null, admin);

        // Default Settings
        ContentValues settings = new ContentValues();
        settings.put("key", "due_days");
        settings.put("value", "14");
        db.insert("settings", null, settings);

        // Sample Books with 10 copies each
        String[][] books = {
                {"B001", "Clean Code: A Handbook of Agile Software Craftsmanship", "Robert C. Martin", "Programming", "10", "10"},
                {"B002", "Atomic Habits: An Easy & Proven Way to Build Good Habits", "James Clear", "Self-Help", "10", "10"},
                {"B003", "Crime and Punishment", "Fyodor Dostoevsky", "Classic", "10", "10"},
                {"B004", "The Pragmatic Programmer", "David Thomas", "Programming", "10", "10"},
                {"B005", "The 7 Habits of Highly Effective People", "Stephen R. Covey", "Self-Help", "10", "10"},
                {"B006", "The Idiot", "Fyodor Dostoevsky", "Classic", "10", "10"},
                {"B007", "Introduction to Algorithms", "Thomas H. Cormen", "Computer Science", "10", "10"},
                {"B008", "Think and Grow Rich", "Napoleon Hill", "Self-Help", "10", "10"},
                {"B009", "Notes from Underground", "Fyodor Dostoevsky", "Classic", "10", "10"},
                {"B010", "Design Patterns: Elements of Reusable OO Software", "Erich Gamma", "Programming", "10", "10"}
        };

        for (String[] book : books) {
            ContentValues values = new ContentValues();
            values.put("book_id", book[0]);
            values.put("title", book[1]);
            values.put("author", book[2]);
            values.put("genre", book[3]);
            values.put("total_quantity", book[4]);
            values.put("available_quantity", book[5]);
            db.insert("books", null, values);
        }

        // Sample Students
        String[][] students = {
                {"S001", "Ayantu Le", "iu@gmail.com", "1234567890", "SWE"},
                {"S002", "Mohammed", "mohammed@gmail.com", "1234567891", "Software Engineering"},
                {"S003", "Ruth L", "ruth@wku.com", "1234567892", "Information Technology"}
        };

        for (String[] student : students) {
            ContentValues sv = new ContentValues();
            sv.put("student_id", student[0]);
            sv.put("name", student[1]);
            sv.put("email", student[2]);
            sv.put("phone", student[3]);
            sv.put("department", student[4]);
            sv.put("registration_date", getToday());
            db.insert("students", null, sv);

            ContentValues uv = new ContentValues();
            uv.put("username", student[0]);
            uv.put("password", "student123");
            uv.put("user_type", "student");
            uv.put("security_question", "What is your favorite book?");
            uv.put("security_answer", "book");
            db.insert("users", null, uv);
        }
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        db.execSQL("DROP TABLE IF EXISTS users");
        db.execSQL("DROP TABLE IF EXISTS students");
        db.execSQL("DROP TABLE IF EXISTS books");
        db.execSQL("DROP TABLE IF EXISTS issues");
        db.execSQL("DROP TABLE IF EXISTS reservations");
        db.execSQL("DROP TABLE IF EXISTS fines");
        db.execSQL("DROP TABLE IF EXISTS notifications");
        db.execSQL("DROP TABLE IF EXISTS settings");
        onCreate(db);
    }

    // ==================== USER METHODS ====================

    public boolean validateUser(String username, String password) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("users", null, "username=? AND password=?",
                new String[]{username, password}, null, null, null);
        boolean isValid = cursor.getCount() > 0;
        cursor.close();
        db.close();
        return isValid;
    }

    public String getUserType(String username) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("users", new String[]{"user_type"}, "username=?",
                new String[]{username}, null, null, null);
        String type = "student";
        if (cursor.moveToFirst()) {
            type = cursor.getString(0);
        }
        cursor.close();
        db.close();
        return type;
    }

    public boolean registerUserWithSecurity(String username, String password, String userType,
                                            String name, String email, String phone, String department, String securityAnswer) {
        SQLiteDatabase db = this.getWritableDatabase();

        Cursor check = db.query("users", null, "username=?", new String[]{username}, null, null, null);
        if (check.getCount() > 0) {
            check.close();
            db.close();
            return false;
        }
        check.close();

        ContentValues uv = new ContentValues();
        uv.put("username", username);
        uv.put("password", password);
        uv.put("user_type", userType);
        uv.put("security_question", "What is your favorite book?");
        uv.put("security_answer", securityAnswer.toLowerCase().trim());
        long result = db.insert("users", null, uv);

        if (userType.equals("student") && result != -1) {
            ContentValues sv = new ContentValues();
            sv.put("student_id", username);
            sv.put("name", name);
            sv.put("email", email);
            sv.put("phone", phone);
            sv.put("department", department);
            sv.put("registration_date", getToday());
            db.insert("students", null, sv);
        }

        db.close();
        return result != -1;
    }

    public boolean registerUser(String username, String password, String userType,
                                String name, String email, String phone, String department) {
        return registerUserWithSecurity(username, password, userType, name, email, phone, department, "book");
    }

    public boolean verifySecurityAnswer(String username, String answer) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("users", new String[]{"security_answer"},
                "username=?", new String[]{username}, null, null, null);
        boolean isValid = false;
        if (cursor.moveToFirst()) {
            String storedAnswer = cursor.getString(0);
            isValid = storedAnswer != null && answer != null && storedAnswer.equalsIgnoreCase(answer.trim());
        }
        cursor.close();
        db.close();
        return isValid;
    }

    public boolean updatePassword(String username, String newPassword) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("password", newPassword);
        int result = db.update("users", values, "username=?", new String[]{username});
        db.close();
        return result > 0;
    }

    public boolean userExists(String username) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("users", new String[]{"username"}, "username=?",
                new String[]{username}, null, null, null);
        boolean exists = cursor.getCount() > 0;
        cursor.close();
        db.close();
        return exists;
    }

    public String getSecurityQuestion(String username) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("users", new String[]{"security_question"},
                "username=?", new String[]{username}, null, null, null);
        String question = "What is your favorite book?";
        if (cursor.moveToFirst()) {
            String storedQuestion = cursor.getString(0);
            if (storedQuestion != null && !storedQuestion.isEmpty()) {
                question = storedQuestion;
            }
        }
        cursor.close();
        db.close();
        return question;
    }

    public boolean updateUserInfo(String username, String newPassword, String newSecurityAnswer) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        if (newPassword != null && !newPassword.isEmpty()) {
            values.put("password", newPassword);
        }
        if (newSecurityAnswer != null && !newSecurityAnswer.isEmpty()) {
            values.put("security_answer", newSecurityAnswer);
        }
        int result = db.update("users", values, "username=?", new String[]{username});
        db.close();
        return result > 0;
    }

    public String[] getUserInfo(String username) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("users", new String[]{"username", "password", "security_question", "security_answer"},
                "username=?", new String[]{username}, null, null, null);
        String[] userInfo = new String[4];
        if (cursor.moveToFirst()) {
            userInfo[0] = cursor.getString(0);
            userInfo[1] = cursor.getString(1);
            userInfo[2] = cursor.getString(2);
            userInfo[3] = cursor.getString(3);
        }
        cursor.close();
        db.close();
        return userInfo;
    }

    // ==================== BOOK QUANTITY METHODS ====================

    public int getAvailableQuantity(String bookId) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("books", new String[]{"available_quantity"},
                "book_id=?", new String[]{bookId}, null, null, null);
        int quantity = 0;
        if (cursor.moveToFirst()) {
            quantity = cursor.getInt(0);
        }
        cursor.close();
        db.close();
        return quantity;
    }

    public int getTotalQuantity(String bookId) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("books", new String[]{"total_quantity"},
                "book_id=?", new String[]{bookId}, null, null, null);
        int quantity = 0;
        if (cursor.moveToFirst()) {
            quantity = cursor.getInt(0);
        }
        cursor.close();
        db.close();
        return quantity;
    }

    public boolean decreaseBookQuantity(String bookId) {
        SQLiteDatabase db = this.getWritableDatabase();
        String sql = "UPDATE books SET available_quantity = available_quantity - 1 WHERE book_id = ? AND available_quantity > 0";
        db.execSQL(sql, new String[]{bookId});
        db.close();
        return true;
    }

    public boolean increaseBookQuantity(String bookId) {
        SQLiteDatabase db = this.getWritableDatabase();
        String sql = "UPDATE books SET available_quantity = available_quantity + 1 WHERE book_id = ?";
        db.execSQL(sql, new String[]{bookId});
        db.close();
        return true;
    }

    public boolean isBookAvailable(String bookId) {
        return getAvailableQuantity(bookId) > 0;
    }

    public String getBookAvailabilityStatus(String bookId) {
        int available = getAvailableQuantity(bookId);
        if (available > 0) {
            return available + " copy" + (available > 1 ? "s" : "") + " available";
        } else {
            return "Out of stock";
        }
    }

    // ==================== BOOK METHODS ====================

    public List<String[]> getAllBooks() {
        List<String[]> books = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("books", null, null, null, null, null, "title ASC");

        while (cursor.moveToNext()) {
            String[] book = new String[6];
            book[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            book[1] = cursor.getString(cursor.getColumnIndexOrThrow("title"));
            book[2] = cursor.getString(cursor.getColumnIndexOrThrow("author"));
            book[3] = cursor.getString(cursor.getColumnIndexOrThrow("genre"));
            int available = cursor.getInt(cursor.getColumnIndexOrThrow("available_quantity"));
            book[4] = available > 0 ? "Available" : "Issued";
            book[5] = String.valueOf(available);
            books.add(book);
        }
        cursor.close();
        db.close();
        return books;
    }

    public List<String[]> getAvailableBooks() {
        List<String[]> books = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("books", null, "available_quantity > 0", null, null, null, "title ASC");

        while (cursor.moveToNext()) {
            String[] book = new String[6];
            book[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            book[1] = cursor.getString(cursor.getColumnIndexOrThrow("title"));
            book[2] = cursor.getString(cursor.getColumnIndexOrThrow("author"));
            book[3] = cursor.getString(cursor.getColumnIndexOrThrow("genre"));
            int available = cursor.getInt(cursor.getColumnIndexOrThrow("available_quantity"));
            book[4] = "Available";
            book[5] = String.valueOf(available);
            books.add(book);
        }
        cursor.close();
        db.close();
        return books;
    }

    public List<String[]> searchBooks(String keyword, String searchType) {
        List<String[]> books = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        String column = "title";
        if (searchType.equals("author")) column = "author";
        else if (searchType.equals("genre")) column = "genre";

        Cursor cursor = db.query("books", null, column + " LIKE ?",
                new String[]{"%" + keyword + "%"}, null, null, "title ASC");

        while (cursor.moveToNext()) {
            String[] book = new String[6];
            book[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            book[1] = cursor.getString(cursor.getColumnIndexOrThrow("title"));
            book[2] = cursor.getString(cursor.getColumnIndexOrThrow("author"));
            book[3] = cursor.getString(cursor.getColumnIndexOrThrow("genre"));
            int available = cursor.getInt(cursor.getColumnIndexOrThrow("available_quantity"));
            book[4] = available > 0 ? "Available" : "Issued";
            book[5] = String.valueOf(available);
            books.add(book);
        }
        cursor.close();
        db.close();
        return books;
    }

    public boolean addBook(String bookId, String title, String author, String genre) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("book_id", bookId);
        values.put("title", title);
        values.put("author", author);
        values.put("genre", genre);
        values.put("total_quantity", 10);
        values.put("available_quantity", 10);
        long result = db.insert("books", null, values);
        db.close();
        return result != -1;
    }

    public boolean deleteBook(String bookId) {
        SQLiteDatabase db = this.getWritableDatabase();
        int result = db.delete("books", "book_id=? AND available_quantity=10", new String[]{bookId});
        db.close();
        return result > 0;
    }

    public String getBookTitle(String bookId) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("books", new String[]{"title"}, "book_id=?",
                new String[]{bookId}, null, null, null);
        String title = bookId;
        if (cursor.moveToFirst()) {
            title = cursor.getString(0);
        }
        cursor.close();
        db.close();
        return title;
    }

    // ==================== STUDENT METHODS ====================

    public List<String[]> getAllStudents() {
        List<String[]> students = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("students", null, null, null, null, null, "name ASC");

        while (cursor.moveToNext()) {
            String[] student = new String[5];
            student[0] = cursor.getString(cursor.getColumnIndexOrThrow("student_id"));
            student[1] = cursor.getString(cursor.getColumnIndexOrThrow("name"));
            student[2] = cursor.getString(cursor.getColumnIndexOrThrow("email"));
            student[3] = cursor.getString(cursor.getColumnIndexOrThrow("phone"));
            student[4] = cursor.getString(cursor.getColumnIndexOrThrow("department"));
            students.add(student);
        }
        cursor.close();
        db.close();
        return students;
    }

    public boolean addStudent(String studentId, String name, String email, String phone, String department) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("student_id", studentId);
        values.put("name", name);
        values.put("email", email);
        values.put("phone", phone);
        values.put("department", department);
        values.put("registration_date", getToday());
        long result = db.insert("students", null, values);
        db.close();
        return result != -1;
    }

    public boolean deleteStudent(String studentId) {
        SQLiteDatabase db = this.getWritableDatabase();
        int result = db.delete("students", "student_id=?", new String[]{studentId});
        db.close();
        return result > 0;
    }

    // ==================== ISSUE/RETURN METHODS ====================

    public boolean issueBook(String bookId, String studentId, String issueDate, String dueDate) {
        SQLiteDatabase db = this.getWritableDatabase();

        // Check if book has available copies
        Cursor checkBook = db.query("books", new String[]{"available_quantity"},
                "book_id=?", new String[]{bookId}, null, null, null);
        if (!checkBook.moveToFirst() || checkBook.getInt(0) <= 0) {
            checkBook.close();
            db.close();
            return false;
        }
        checkBook.close();

        // Create issue record
        ContentValues values = new ContentValues();
        values.put("book_id", bookId);
        values.put("student_id", studentId);
        values.put("issue_date", issueDate);
        values.put("due_date", dueDate);
        values.put("returned", 0);
        long result = db.insert("issues", null, values);

        if (result != -1) {
            // Decrease available quantity
            decreaseBookQuantity(bookId);

            // Add notification for student
            String bookTitle = getBookTitle(bookId);
            addNotification(studentId, "Book Issued", "You have successfully issued \"" + bookTitle + "\". Due date: " + dueDate, "ISSUE");
        }

        db.close();
        return result != -1;
    }

    public boolean returnBook(String bookId, String studentId, String returnDate) {
        SQLiteDatabase db = this.getWritableDatabase();

        ContentValues values = new ContentValues();
        values.put("return_date", returnDate);
        values.put("returned", 1);
        int result = db.update("issues", values,
                "book_id=? AND student_id=? AND returned=0",
                new String[]{bookId, studentId});

        if (result > 0) {
            // Increase available quantity
            increaseBookQuantity(bookId);

            // Add notification for student
            String bookTitle = getBookTitle(bookId);
            addNotification(studentId, "Book Returned", "You have successfully returned \"" + bookTitle + "\". Thank you!", "RETURN");

            // Check if any reservations exist for this book
            checkAndNotifyReservations(bookId);
        }

        db.close();
        return result > 0;
    }

    public List<String[]> getStudentIssues(String studentId) {
        List<String[]> issues = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("issues", null, "student_id=? AND returned=0",
                new String[]{studentId}, null, null, "due_date ASC");

        while (cursor.moveToNext()) {
            String[] issue = new String[3];
            issue[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            issue[1] = cursor.getString(cursor.getColumnIndexOrThrow("issue_date"));
            issue[2] = cursor.getString(cursor.getColumnIndexOrThrow("due_date"));
            issues.add(issue);
        }
        cursor.close();
        db.close();
        return issues;
    }

    public List<String[]> getOverdueBooks() {
        List<String[]> overdue = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        String today = getToday();
        Cursor cursor = db.query("issues", null, "returned=0 AND due_date < ?",
                new String[]{today}, null, null, null);

        while (cursor.moveToNext()) {
            String[] issue = new String[3];
            issue[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            issue[1] = cursor.getString(cursor.getColumnIndexOrThrow("student_id"));
            issue[2] = cursor.getString(cursor.getColumnIndexOrThrow("due_date"));
            overdue.add(issue);
        }
        cursor.close();
        db.close();
        return overdue;
    }

    public List<String[]> getAllIssues() {
        List<String[]> issues = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("issues", null, "returned=0", null, null, null, "due_date ASC");

        while (cursor.moveToNext()) {
            String[] issue = new String[5];
            issue[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            issue[1] = cursor.getString(cursor.getColumnIndexOrThrow("student_id"));
            issue[2] = cursor.getString(cursor.getColumnIndexOrThrow("issue_date"));
            issue[3] = cursor.getString(cursor.getColumnIndexOrThrow("due_date"));
            issue[4] = cursor.getString(cursor.getColumnIndexOrThrow("returned"));
            issues.add(issue);
        }
        cursor.close();
        db.close();
        return issues;
    }

    // ==================== RESERVATION METHODS ====================

    public boolean reserveBook(String bookId, String studentId, String reservationDate) {
        SQLiteDatabase db = this.getWritableDatabase();

        Cursor checkRes = db.query("reservations", null,
                "book_id=? AND student_id=? AND active=1",
                new String[]{bookId, studentId}, null, null, null);
        if (checkRes.getCount() > 0) {
            checkRes.close();
            db.close();
            return false;
        }
        checkRes.close();

        ContentValues values = new ContentValues();
        values.put("book_id", bookId);
        values.put("student_id", studentId);
        values.put("res_date", reservationDate);
        values.put("active", 1);
        long result = db.insert("reservations", null, values);
        db.close();
        return result != -1;
    }

    public List<String[]> getStudentReservations(String studentId) {
        List<String[]> reservations = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("reservations", null, "student_id=? AND active=1",
                new String[]{studentId}, null, null, "res_date ASC");

        while (cursor.moveToNext()) {
            String[] res = new String[3];
            res[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            res[1] = cursor.getString(cursor.getColumnIndexOrThrow("res_date"));
            res[2] = String.valueOf(cursor.getInt(cursor.getColumnIndexOrThrow("id")));
            reservations.add(res);
        }
        cursor.close();
        db.close();
        return reservations;
    }

    public List<String[]> getAllReservations() {
        List<String[]> reservations = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("reservations", null, "active=1", null, null, null, "res_date ASC");

        while (cursor.moveToNext()) {
            String[] res = new String[4];
            res[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            res[1] = cursor.getString(cursor.getColumnIndexOrThrow("student_id"));
            res[2] = cursor.getString(cursor.getColumnIndexOrThrow("res_date"));
            res[3] = String.valueOf(cursor.getInt(cursor.getColumnIndexOrThrow("id")));
            reservations.add(res);
        }
        cursor.close();
        db.close();
        return reservations;
    }

    public boolean cancelReservation(String reservationId) {
        SQLiteDatabase db = this.getWritableDatabase();
        int result = db.delete("reservations", "id=?", new String[]{reservationId});
        db.close();
        return result > 0;
    }

    public void checkAndNotifyReservations(String bookId) {
        List<String[]> reservations = getAllReservations();
        String bookTitle = getBookTitle(bookId);
        int availableQty = getAvailableQuantity(bookId);

        for (String[] res : reservations) {
            if (res[0].equals(bookId) && availableQty > 0) {
                addNotification(res[1], "Book Available", "The book \"" + bookTitle + "\" you reserved is now available for pickup! " + availableQty + " copies left.", "AVAILABLE");
            }
        }
    }

    // ==================== FINE METHODS ====================

    public List<String[]> getStudentFines(String studentId) {
        List<String[]> fines = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("fines", null, "student_id=? AND paid=0",
                new String[]{studentId}, null, null, null);

        while (cursor.moveToNext()) {
            String[] fine = new String[3];
            fine[0] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            fine[1] = String.valueOf(cursor.getDouble(cursor.getColumnIndexOrThrow("amount")));
            fine[2] = String.valueOf(cursor.getInt(cursor.getColumnIndexOrThrow("id")));
            fines.add(fine);
        }
        cursor.close();
        db.close();
        return fines;
    }

    public List<String[]> getAllFines() {
        List<String[]> fines = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("fines", null, null, null, null, null, null);

        while (cursor.moveToNext()) {
            String[] fine = new String[4];
            fine[0] = cursor.getString(cursor.getColumnIndexOrThrow("student_id"));
            fine[1] = cursor.getString(cursor.getColumnIndexOrThrow("book_id"));
            fine[2] = String.valueOf(cursor.getDouble(cursor.getColumnIndexOrThrow("amount")));
            fine[3] = cursor.getInt(cursor.getColumnIndexOrThrow("paid")) == 0 ? "Unpaid" : "Paid";
            fines.add(fine);
        }
        cursor.close();
        db.close();
        return fines;
    }

    public boolean addFine(String studentId, String bookId, double amount) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("student_id", studentId);
        values.put("book_id", bookId);
        values.put("amount", amount);
        values.put("paid", 0);
        long result = db.insert("fines", null, values);
        db.close();
        return result != -1;
    }

    public boolean payFine(String fineId) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("paid", 1);
        int result = db.update("fines", values, "id=?", new String[]{fineId});
        db.close();
        return result > 0;
    }

    public double calculateFine(String bookId, String studentId, String returnDate) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("issues", new String[]{"due_date"},
                "book_id=? AND student_id=? AND returned=0",
                new String[]{bookId, studentId}, null, null, null);

        double fine = 0;
        if (cursor.moveToFirst()) {
            String dueDate = cursor.getString(0);
            try {
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
                Date due = sdf.parse(dueDate);
                Date ret = sdf.parse(returnDate);
                if (ret != null && due != null && ret.after(due)) {
                    long diff = ret.getTime() - due.getTime();
                    long daysLate = diff / (24 * 60 * 60 * 1000);
                    fine = daysLate * 50;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        cursor.close();
        db.close();
        return fine;
    }

    public boolean processFineOnReturn(String bookId, String studentId, String returnDate) {
        double fineAmount = calculateFine(bookId, studentId, returnDate);
        if (fineAmount > 0) {
            return addFine(studentId, bookId, fineAmount);
        }
        return true;
    }

    public double getTotalUnpaidFines(String studentId) {
        double total = 0;
        List<String[]> fines = getStudentFines(studentId);
        for (String[] fine : fines) {
            total += Double.parseDouble(fine[1]);
        }
        return total;
    }

    // ==================== NOTIFICATION METHODS ====================

    public boolean addNotification(String userId, String title, String message, String type) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("user_id", userId);
        values.put("title", title);
        values.put("message", message);
        values.put("type", type);
        values.put("date", getToday());
        values.put("is_read", 0);
        long result = db.insert("notifications", null, values);
        db.close();
        return result != -1;
    }

    public List<String[]> getUserNotifications(String userId) {
        List<String[]> notifications = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("notifications", null, "user_id=?",
                new String[]{userId}, null, null, "date DESC");

        while (cursor.moveToNext()) {
            String[] notification = new String[6];
            notification[0] = String.valueOf(cursor.getInt(cursor.getColumnIndexOrThrow("id")));
            notification[1] = cursor.getString(cursor.getColumnIndexOrThrow("title"));
            notification[2] = cursor.getString(cursor.getColumnIndexOrThrow("message"));
            notification[3] = cursor.getString(cursor.getColumnIndexOrThrow("type"));
            notification[4] = cursor.getString(cursor.getColumnIndexOrThrow("date"));
            notification[5] = String.valueOf(cursor.getInt(cursor.getColumnIndexOrThrow("is_read")));
            notifications.add(notification);
        }
        cursor.close();
        db.close();
        return notifications;
    }

    public void markNotificationAsRead(int notificationId) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put("is_read", 1);
        db.update("notifications", values, "id=?", new String[]{String.valueOf(notificationId)});
        db.close();
    }

    public void clearAllNotifications(String userId) {
        SQLiteDatabase db = this.getWritableDatabase();
        db.delete("notifications", "user_id=?", new String[]{userId});
        db.close();
    }

    public int getUnreadNotificationCount(String userId) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query("notifications", new String[]{"COUNT(*)"},
                "user_id=? AND is_read=0", new String[]{userId}, null, null, null);
        int count = 0;
        if (cursor.moveToFirst()) {
            count = cursor.getInt(0);
        }
        cursor.close();
        db.close();
        return count;
    }
}