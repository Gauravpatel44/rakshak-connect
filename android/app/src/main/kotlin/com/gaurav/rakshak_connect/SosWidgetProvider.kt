package com.gaurav.rakshak_connect

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SosWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.sos_widget_layout).apply {
                // Read custom status from widgetData
                val statusText = widgetData.getString("widget_status_text", "● Ready")
                setTextViewText(R.id.widget_status_text, statusText)

                // 1. SOS Button click -> Launches App directly with deep link uri "rakshak://sos"
                val sosPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("rakshak://sos")
                )
                setOnClickPendingIntent(R.id.btn_widget_sos, sosPendingIntent)

                // 2. Siren Button click -> Launches App with deep link uri "rakshak://siren"
                val sirenPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("rakshak://siren")
                )
                setOnClickPendingIntent(R.id.btn_widget_siren, sirenPendingIntent)

                // 3. Fake Call Button click -> Launches App with deep link uri "rakshak://fake_call"
                val fakeCallPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("rakshak://fake_call")
                )
                setOnClickPendingIntent(R.id.btn_widget_fake_call, fakeCallPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
