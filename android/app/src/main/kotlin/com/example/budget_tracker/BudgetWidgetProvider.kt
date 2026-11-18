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

                // 1. Tap the container: open app home
                val homeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("budgettracker://home")
                )
                setOnClickPendingIntent(R.id.widget_container, homeIntent)

                // 2. Tap "+ Income": open add income sheet
                val addIncomeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("budgettracker://add?kind=income")
                )
                setOnClickPendingIntent(R.id.widget_btn_add_income, addIncomeIntent)

                // 3. Tap "+ Expense": open add expense sheet
                val addExpenseIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("budgettracker://add?kind=expense")
                )
                setOnClickPendingIntent(R.id.widget_btn_add_expense, addExpenseIntent)

                // 4. Quick Category Chips
                val chipIds = intArrayOf(R.id.widget_chip_0, R.id.widget_chip_1, R.id.widget_chip_2)
                var hasChips = false

                for (i in 0 until 3) {
                    val catId = try {
                        widgetData.getInt("cat_${i}_id", -1)
                    } catch (e: Exception) {
                        -1
                    }
                    val catName = widgetData.getString("cat_${i}_name", "") ?: ""

                    if (catId > 0 && catName.isNotEmpty()) {
                        hasChips = true
                        setViewVisibility(chipIds[i], View.VISIBLE)
                        setTextViewText(chipIds[i], "+ $catName")

                        val chipIntent = HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("budgettracker://add?kind=expense&categoryId=$catId")
                        )
                        setOnClickPendingIntent(chipIds[i], chipIntent)
                    } else {
                        setViewVisibility(chipIds[i], View.GONE)
                    }
                }

                setViewVisibility(
                    R.id.widget_category_chips_row,
                    if (hasChips) View.VISIBLE else View.GONE
                )
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
