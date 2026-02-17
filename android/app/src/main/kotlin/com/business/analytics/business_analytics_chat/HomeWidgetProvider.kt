package com.business.analytics.business_analytics_chat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("title", "Business Analytics")
                val message = widgetData.getString("message", "No recent insights")
                
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_message, message)

                // Pending Intent to launch the app
                val intent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homeWidget://chat/last") // Custom scheme to be handled
                )
                setOnClickPendingIntent(R.id.widget_message, intent)
                setOnClickPendingIntent(R.id.widget_title, intent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
