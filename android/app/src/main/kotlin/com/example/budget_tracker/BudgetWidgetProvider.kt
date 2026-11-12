package com.example.budget_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BudgetWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.budget_widget).apply {
                // Balance
                val balanceText = widgetData.getString("balance_text", "0.00 EGP") ?: "0.00 EGP"
                val isNegative = try {
                    widgetData.getBoolean("balance_is_negative", false)
                } catch (e: Exception) {
                    false
                }
                setTextViewText(R.id.widget_balance_text, balanceText)
                if (isNegative) {
                    setTextColor(R.id.widget_balance_text, Color.parseColor("#F43F5E"))
                } else {
                    setTextColor(R.id.widget_balance_text, Color.parseColor("#FFFFFF"))
                }

                // Budget Status
                val budgetStatusText = widgetData.getString("budget_status_text", "Budget: No limit set") ?: "Budget: No limit set"
                val progress = try {
                    widgetData.getInt("budget_progress_percent", 0)
                } catch (e: ClassCastException) {
                    try {
                        widgetData.getLong("budget_progress_percent", 0L).toInt()
                    } catch (e2: Exception) {
                        0
                    }
                } catch (e: Exception) {
                    0
                }
                setTextViewText(R.id.widget_budget_status_text, budgetStatusText)
                setProgressBar(R.id.widget_budget_progress, 100, progress.coerceIn(0, 100), false)

                // PendingIntent: Clicking the container opens the app
                val homeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("budgettracker://home")
                )
                setOnClickPendingIntent(R.id.widget_container, homeIntent)

                // PendingIntent: Clicking "+ Expense" opens the app directly to add expense
                val addExpenseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("budgettracker://add-expense")
                )
                setOnClickPendingIntent(R.id.widget_btn_add_expense, addExpenseIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
