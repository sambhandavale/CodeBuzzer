package com.example.codebuzzer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class ContestWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val jsonString = prefs.getString("all_contests", "[]")
            
            var tomorrowCount = 0
            try {
                if (jsonString != null && jsonString != "null") {
                    val array = JSONArray(jsonString)
                    val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault())
                    val tomorrow = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) }
                    
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        val startStr = obj.optString("start_time", "")
                        if (startStr.isNotEmpty()) {
                            val date = format.parse(startStr)
                            if (date != null) {
                                val c = Calendar.getInstance().apply { time = date }
                                if (c.get(Calendar.YEAR) == tomorrow.get(Calendar.YEAR) &&
                                    c.get(Calendar.DAY_OF_YEAR) == tomorrow.get(Calendar.DAY_OF_YEAR)) {
                                    tomorrowCount++
                                }
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            views.setTextViewText(R.id.empty_title, "No Contest Today")
            if (tomorrowCount > 0) {
                views.setTextViewText(R.id.empty_subtitle, "$tomorrowCount contests tomorrow")
                views.setViewVisibility(R.id.empty_subtitle, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.empty_subtitle, android.view.View.GONE)
            }

            // Set up RemoteViewsService for ListView
            val intent = Intent(context, WidgetRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME)) // To prevent intent caching
            }
            views.setRemoteAdapter(R.id.widget_list_view, intent)

            // Set empty view
            views.setEmptyView(R.id.widget_list_view, R.id.empty_view)

            // Pending intent for opening app when clicking a list item
            val clickIntentTemplate = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
            }
            val clickPendingIntentTemplate = PendingIntent.getActivity(context, 0, clickIntentTemplate, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setPendingIntentTemplate(R.id.widget_list_view, clickPendingIntentTemplate)

            // Also clicking the title/root opens the app
            val titleIntent = Intent(context, MainActivity::class.java)
            val titlePendingIntent = PendingIntent.getActivity(context, 0, titleIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_root, titlePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list_view)
        }
    }
}
