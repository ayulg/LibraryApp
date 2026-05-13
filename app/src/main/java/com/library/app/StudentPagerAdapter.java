package com.library.app;

import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import java.util.HashMap;
import java.util.Map;

public class StudentPagerAdapter extends FragmentStateAdapter {

    private String studentId;
    private Map<Integer, Fragment> fragmentMap = new HashMap<>();

    public StudentPagerAdapter(@NonNull FragmentActivity fragmentActivity, String studentId) {
        super(fragmentActivity);
        this.studentId = studentId;
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        Bundle args = new Bundle();
        args.putString("STUDENT_ID", studentId);

        Fragment fragment;
        if (position == 0) {
            fragment = new AvailableBooksFragment();
        } else {
            fragment = new MyBooksFragment();
        }
        fragment.setArguments(args);
        fragmentMap.put(position, fragment);
        return fragment;
    }

    @Override
    public int getItemCount() {
        return 2;
    }

    public Fragment getFragment(int position) {
        return fragmentMap.get(position);
    }
}