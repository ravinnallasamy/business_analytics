package com.business.analytics.business_analytics_chat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider as BaseHomeWidgetProvider

class HomeWidgetProvider : BaseHomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val isLoggedIn = widgetData.getBoolean("is_logged_in", false)
                
                if (!isLoggedIn) {
                    // Show ONLY "Please login"
                    setTextViewText(R.id.widget_title, "Please login")
                    setViewVisibility(R.id.widget_title, android.view.View.VISIBLE)
                    setViewVisibility(R.id.widget_image, android.view.View.GONE)
                    setViewVisibility(R.id.widget_flipper, android.view.View.GONE)
                } else {
                    // Logged in, show cached image (value + graph)
                    val imagePath = widgetData.getString("widget_image", null)
                    
                    if (imagePath != null) {
                        val file = java.io.File(imagePath)
                        if (file.exists()) {
                            val bitmap = android.graphics.BitmapFactory.decodeFile(file.absolutePath)
                            if (bitmap != null) {
                                setImageViewBitmap(R.id.widget_image, bitmap)
                                setViewVisibility(R.id.widget_image, android.view.View.VISIBLE)
                                setViewVisibility(R.id.widget_flipper, android.view.View.GONE)
                                setViewVisibility(R.id.widget_title, android.view.View.GONE)
                            } else {
                                showFallback(this)
                            }
                        } else {
                            showFallback(this)
                        }
                    } else {
                        showFallback(this)
                    }
                }

                // Pending Intent to launch the app
                val intent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("homeWidget://chat/new") // Routes to new chat
                )
                setOnClickPendingIntent(R.id.widget_flipper, intent)
                setOnClickPendingIntent(R.id.widget_image, intent)
                setOnClickPendingIntent(R.id.widget_title, intent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun showFallback(views: RemoteViews) {
        views.apply {
            setTextViewText(R.id.widget_message_1, "---")
            setTextViewText(R.id.widget_message_2, "---")
            setViewVisibility(R.id.widget_image, android.view.View.GONE)
            setViewVisibility(R.id.widget_flipper, android.view.View.VISIBLE)
            setViewVisibility(R.id.widget_title, android.view.View.VISIBLE)
            setTextViewText(R.id.widget_title, "Business Analytics")
        }
    }
}
