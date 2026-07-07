package com.example.codebuzzer

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class WidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return WidgetRemoteViewsFactory(this.applicationContext)
    }
}

class WidgetRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var contestsList: List<JSONObject> = ArrayList()

    override fun onCreate() {
        // Inits
    }

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val jsonString = prefs.getString("all_contests", "[]")

        val parsedList = ArrayList<JSONObject>()
        try {
            if (jsonString != null && jsonString != "null") {
                val array = JSONArray(jsonString)
                val today = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) } // offset by 1 day for testing
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    try {
                        val startStr = obj.optString("start_time", "")
                        if (startStr.isNotEmpty()) {
                            val date = format.parse(startStr)
                            if (date != null) {
                                val c = Calendar.getInstance().apply { time = date }
                                if (c.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
                                    c.get(Calendar.DAY_OF_YEAR) == today.get(Calendar.DAY_OF_YEAR)) {
                                    parsedList.add(obj)
                                }
                            }
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        contestsList = parsedList
    }
    override fun onDestroy() {
        contestsList = ArrayList()
    }

    override fun getCount(): Int {
        return contestsList.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_contest_item)
        val contest = contestsList[position]

        val name = contest.optString("name", "Contest")
        val site = contest.optString("site", "Platform")
        val startTimeStr = contest.optString("start_time", "")

        views.setTextViewText(R.id.item_title, name)
        views.setTextViewText(R.id.item_platform, site)

        // Set platform badge color and text color
        val siteLower = site.lowercase(Locale.ROOT)
        val bgRes = when (siteLower) {
            "leetcode" -> R.drawable.badge_bg_leetcode
            "codeforces" -> R.drawable.badge_bg_codeforces
            "codechef" -> R.drawable.badge_bg_codechef
            "codingninjas" -> R.drawable.badge_bg_codingninjas
            else -> R.drawable.badge_bg_default
        }
        views.setInt(R.id.item_platform, "setBackgroundResource", bgRes)
        
        val platformColorInt = when (siteLower) {
            "leetcode" -> android.graphics.Color.parseColor("#ED8936")
            "codeforces" -> android.graphics.Color.parseColor("#3182CE")
            "codechef" -> android.graphics.Color.parseColor("#975A16")
            "codingninjas" -> android.graphics.Color.parseColor("#F15A24")
            else -> android.graphics.Color.parseColor("#1CD065")
        }
        
        views.setTextColor(R.id.item_platform, platformColorInt)

        val isActive = contest.optBoolean("is_alarm_active", true)

        if (isActive) {
            views.setInt(R.id.item_active_dot, "setBackgroundResource", R.drawable.dot_active)
            views.setTextColor(R.id.item_time, android.graphics.Color.WHITE)
            views.setImageViewResource(R.id.item_clock_icon, R.drawable.ic_clock)
        } else {
            views.setInt(R.id.item_active_dot, "setBackgroundResource", R.drawable.dot_inactive)
            views.setTextColor(R.id.item_time, android.graphics.Color.parseColor("#888888"))
            views.setImageViewResource(R.id.item_clock_icon, R.drawable.ic_clock_grey)
        }

        if (startTimeStr.isNotEmpty()) {
            try {
                val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                val date = format.parse(startTimeStr)
                if (date != null) {
                    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                    val dateFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
                    
                    val timeStr = timeFormat.format(date)
                    val dateStr = dateFormat.format(date)
                    views.setTextViewText(R.id.item_time, timeStr)
                    views.setTextViewText(R.id.item_date, dateStr)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        // Fill intent to trigger app open
        val fillInIntent = Intent()
        views.setOnClickFillInIntent(R.id.item_root, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? {
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
}
