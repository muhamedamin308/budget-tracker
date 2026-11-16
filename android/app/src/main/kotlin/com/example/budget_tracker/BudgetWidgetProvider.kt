package com.example.budget_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.view.View
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
                setTextColor(
                    R.id.widget_balance_text,
                    Color.parseColor(if (isNegative) "#FB7185" else "#FFFFFF")
                )

                // Budget status
                val budgetStatusText = widgetData.getString(
                    "budget_status_text", "Budget: No limit set"
                ) ?: "Budget: No limit set"
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
                val over = progress >= 100
                val clamped = progress.coerceIn(0, 100)

                setTextViewText(R.id.widget_budget_status_text, budgetStatusText)
                setTextViewText(R.id.widget_budget_percent_text, "$progress%")
                setTextColor(
                    R.id.widget_budget_percent_text,
                    Color.parseColor(if (over) "#FB7185" else "#34D399")
                )

                setProgressBar(R.id.widget_budget_progress, 100, clamped, false)
                setProgressBar(R.id.widget_budget_progress_over, 100, clamped, false)
                setViewVisibility(
                    R.id.widget_budget_progress,
                    if (over) View.GONE else View.VISIBLE
                )
                setViewVisibility(
                    R.id.widget_budget_progress_over,
                    if (over) View.VISIBLE else View.GONE
                )

                // Tap the card: open the app
                val homeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("budgettracker://home")
                )
                setOnClickPendingIntent(R.id.widget_container, homeIntent)

                // Tap "+ Expense": open the add-expense form
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