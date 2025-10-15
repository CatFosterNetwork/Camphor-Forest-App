package social.swu.camphor_forest

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.GridLayout
import android.view.View
import android.util.Log
import org.json.JSONObject
import java.util.*
import io.flutter.embedding.android.FlutterActivity

/**
 * 课表小组件提供者
 * 显示 3x5 的课表网格（周一、周三、周五，1-5节课）
 */
class ClassTableWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // 首次添加小组件时调用
        Log.d("ClassTableWidget", "Widget enabled, scheduling updates")
        scheduleUpdates(context)
    }

    override fun onDisabled(context: Context) {
        // 最后一个小组件被移除时调用
        Log.d("ClassTableWidget", "Widget disabled, canceling updates")
        cancelUpdates(context)
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.class_table_widget)

            // 读取课表数据
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val classTableDataJson = prefs.getString("class_table_data", null)
            val currentWeek = prefs.getInt("current_week", 1)
            val currentWeekday = getCurrentWeekday()

            Log.d("ClassTableWidget", "Updating widget - Weekday: $currentWeekday, Week: $currentWeek")
            Log.d("ClassTableWidget", "Has data: ${classTableDataJson != null}")

            // 设置日期和星期
            val calendar = Calendar.getInstance()
            val month = calendar.get(Calendar.MONTH) + 1
            val day = calendar.get(Calendar.DAY_OF_MONTH)
            views.setTextViewText(R.id.widget_weekday, "${month}月${day}日")
            views.setTextViewText(R.id.widget_status, getWeekdayName(currentWeekday))

            // 设置点击事件 - 点击小组件打开应用
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // 如果有课表数据，更新课程列表
            if (classTableDataJson != null && classTableDataJson != "null") {
                try {
                    updateCourseList(context, views, classTableDataJson, currentWeekday)
                } catch (e: Exception) {
                    Log.e("ClassTableWidget", "Error updating course list", e)
                    e.printStackTrace()
                    showNoDataMessage(views, "数据加载失败")
                }
            } else {
                // 没有数据时显示提示
                Log.w("ClassTableWidget", "No class table data found in SharedPreferences")
                showNoDataMessage(views, "打开应用查看课表")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /**
         * 更新课程列表
         */
        private fun updateCourseList(
            context: Context,
            views: RemoteViews,
            classTableDataJson: String,
            currentWeekday: Int
        ) {
            val weekData = JSONObject(classTableDataJson)
            val dayKey = "day_$currentWeekday"
            
            Log.d("ClassTableWidget", "Looking for courses on $dayKey")
            
            // 隐藏所有课程容器
            for (i in 1..5) {
                views.setViewVisibility(getContainerId(i), View.GONE)
            }

            // 获取今天的课程
            if (weekData.has(dayKey)) {
                val courses = weekData.getJSONArray(dayKey)
                var displayedCount = 0
                
                // 获取当前节次（用于区分已上和未上的课）
                val currentSection = getCurrentSection()
                
                Log.d("ClassTableWidget", "Found ${courses.length()} courses for today, current section: $currentSection")

                // 显示所有今天的课程（最多5个）
                for (i in 0 until courses.length()) {
                    if (displayedCount >= 5) break
                    
                    val course = courses.getJSONObject(i)
                    val name = course.optString("name", "")
                    val location = course.optString("location", "")
                    val startSection = course.optInt("startSection", 1)
                    val endSection = course.optInt("endSection", 1)

                    Log.d("ClassTableWidget", "Course $i: $name, sections: $startSection-$endSection")

                    displayedCount++
                    
                    // 判断课程状态
                    val isFinished = endSection < currentSection
                    val isActive = !isFinished && startSection >= currentSection
                    val isOngoing = isCourseOngoing(startSection, endSection)
                    
                    // 获取上课时间
                    val timeText = getCourseTime(startSection, endSection)
                    
                    // 设置课程信息
                    setCourseData(
                        context,
                        views, 
                        displayedCount, 
                        name, 
                        location, 
                        timeText,
                        isFinished,
                        isActive,
                        isOngoing
                    )
                }

                // 如果有课程，隐藏"没有课程"提示
                if (displayedCount > 0) {
                    views.setViewVisibility(R.id.no_course_message, View.GONE)
                    Log.d("ClassTableWidget", "Displayed $displayedCount courses")
                } else {
                    views.setViewVisibility(R.id.no_course_message, View.VISIBLE)
                    views.setTextViewText(R.id.no_course_message, "今天没有课程")
                    Log.d("ClassTableWidget", "No courses for today")
                }
            } else {
                views.setViewVisibility(R.id.no_course_message, View.VISIBLE)
                views.setTextViewText(R.id.no_course_message, "今天没有课程")
                Log.d("ClassTableWidget", "No courses found for $dayKey")
            }
        }
        
        /**
         * 设置单个课程的数据
         */
        private fun setCourseData(
            context: Context,
            views: RemoteViews,
            index: Int,
            name: String,
            location: String,
            timeText: String,
            isFinished: Boolean,
            isActive: Boolean,
            isOngoing: Boolean
        ) {
            // 显示容器
            views.setViewVisibility(getContainerId(index), View.VISIBLE)
            
            // 设置课程名称
            views.setTextViewText(getNameId(index), name)
            
            // 设置时间
            views.setTextViewText(getTimeId(index), timeText)
            
            // 设置地点
            views.setTextViewText(getLocationId(index), location)
            
            // 使用系统Material Design颜色资源
            val textPrimaryColor = context.resources.getColor(R.color.widget_text_primary, null)
            val textSecondaryColor = context.resources.getColor(R.color.widget_text_secondary, null)
            val outlineColor = context.resources.getColor(R.color.widget_outline, null)
            val primaryColor = context.resources.getColor(R.color.widget_primary, null)
            
            // 根据状态设置文本颜色
            val nameColor = if (isFinished) outlineColor else textPrimaryColor
            val detailColor = if (isFinished) outlineColor else textSecondaryColor
            
            views.setTextColor(getNameId(index), nameColor)
            views.setTextColor(getTimeId(index), detailColor)
            views.setTextColor(getLocationId(index), detailColor)
            
            // 设置指示线颜色 - 使用系统主题色
            val indicatorColor = if (isOngoing || isActive) {
                primaryColor // 使用系统主题色（正在上课或未开始）
            } else {
                outlineColor // 使用轮廓色（已结束）
            }
            views.setInt(getIndicatorId(index), "setBackgroundColor", indicatorColor)
        }
        
        /**
         * 获取课程时间文本
         */
        private fun getCourseTime(startSection: Int, endSection: Int): String {
            // 课程时间对照表（与应用内一致）
            val timeMap = mapOf(
                1 to "08:00-08:45",
                2 to "08:55-09:40",
                3 to "10:00-10:45",
                4 to "10:55-11:40",
                5 to "12:10-12:55",
                6 to "13:05-13:50",
                7 to "14:00-14:45",
                8 to "14:55-15:40",
                9 to "15:50-16:35",
                10 to "16:55-17:40",
                11 to "17:50-18:35",
                12 to "19:20-20:05",
                13 to "20:15-21:00",
                14 to "21:10-21:55"
            )
            
            val startTime = timeMap[startSection]?.split("-")?.get(0) ?: "00:00"
            val endTime = timeMap[endSection]?.split("-")?.get(1) ?: "00:00"
            
            return "$startTime-$endTime"
        }
        
        /**
         * 获取容器ID
         */
        private fun getContainerId(index: Int): Int = when(index) {
            1 -> R.id.course_container_1
            2 -> R.id.course_container_2
            3 -> R.id.course_container_3
            4 -> R.id.course_container_4
            5 -> R.id.course_container_5
            else -> R.id.course_container_1
        }
        
        /**
         * 获取名称ID
         */
        private fun getNameId(index: Int): Int = when(index) {
            1 -> R.id.course_name_1
            2 -> R.id.course_name_2
            3 -> R.id.course_name_3
            4 -> R.id.course_name_4
            5 -> R.id.course_name_5
            else -> R.id.course_name_1
        }
        
        /**
         * 获取时间ID
         */
        private fun getTimeId(index: Int): Int = when(index) {
            1 -> R.id.course_time_1
            2 -> R.id.course_time_2
            3 -> R.id.course_time_3
            4 -> R.id.course_time_4
            5 -> R.id.course_time_5
            else -> R.id.course_time_1
        }
        
        /**
         * 获取地点ID
         */
        private fun getLocationId(index: Int): Int = when(index) {
            1 -> R.id.course_location_1
            2 -> R.id.course_location_2
            3 -> R.id.course_location_3
            4 -> R.id.course_location_4
            5 -> R.id.course_location_5
            else -> R.id.course_location_1
        }
        
        /**
         * 获取指示线ID
         */
        private fun getIndicatorId(index: Int): Int = when(index) {
            1 -> R.id.course_indicator_1
            2 -> R.id.course_indicator_2
            3 -> R.id.course_indicator_3
            4 -> R.id.course_indicator_4
            5 -> R.id.course_indicator_5
            else -> R.id.course_indicator_1
        }
        
        /**
         * 获取当前节次
         * 根据当前时间判断是第几节课
         */
        private fun getCurrentSection(): Int {
            val calendar = Calendar.getInstance()
            val hour = calendar.get(Calendar.HOUR_OF_DAY)
            val minute = calendar.get(Calendar.MINUTE)
            val timeInMinutes = hour * 60 + minute
            
            // 课程时间表（分钟）- 与应用内一致
            // 1节: 08:00-08:45 (480-525)
            // 2节: 08:55-09:40 (535-580)
            // 3节: 10:00-10:45 (600-645)
            // 4节: 10:55-11:40 (655-700)
            // 5节: 12:10-12:55 (730-775)
            // 6节: 13:05-13:50 (785-830)
            // 7节: 14:00-14:45 (840-885)
            // 8节: 14:55-15:40 (895-940)
            // 9节: 15:50-16:35 (950-995)
            // 10节: 16:55-17:40 (1015-1060)
            // 11节: 17:50-18:35 (1070-1115)
            // 12节: 19:20-20:05 (1160-1205)
            // 13节: 20:15-21:00 (1215-1260)
            // 14节: 21:10-21:55 (1270-1315)
            
            return when {
                timeInMinutes < 525 -> 1   // 第1节期间
                timeInMinutes < 580 -> 2   // 第2节期间
                timeInMinutes < 645 -> 3   // 第3节期间
                timeInMinutes < 700 -> 4   // 第4节期间
                timeInMinutes < 775 -> 5   // 第5节期间
                timeInMinutes < 830 -> 6   // 第6节期间
                timeInMinutes < 885 -> 7   // 第7节期间
                timeInMinutes < 940 -> 8   // 第8节期间
                timeInMinutes < 995 -> 9   // 第9节期间
                timeInMinutes < 1060 -> 10 // 第10节期间
                timeInMinutes < 1115 -> 11 // 第11节期间
                timeInMinutes < 1205 -> 12 // 第12节期间
                timeInMinutes < 1260 -> 13 // 第13节期间
                timeInMinutes < 1315 -> 14 // 第14节期间
                else -> 15  // 所有课程结束
            }
        }

        /**
         * 判断课程是否正在进行中
         */
        private fun isCourseOngoing(startSection: Int, endSection: Int): Boolean {
            val calendar = Calendar.getInstance()
            val hour = calendar.get(Calendar.HOUR_OF_DAY)
            val minute = calendar.get(Calendar.MINUTE)
            val currentMinutes = hour * 60 + minute
            
            // 课程时间对照表（与应用内一致）
            val timeMap = mapOf(
                1 to Pair(480, 525),   // 08:00-08:45
                2 to Pair(535, 580),   // 08:55-09:40
                3 to Pair(600, 645),   // 10:00-10:45
                4 to Pair(655, 700),   // 10:55-11:40
                5 to Pair(730, 775),   // 12:10-12:55
                6 to Pair(785, 830),   // 13:05-13:50
                7 to Pair(840, 885),   // 14:00-14:45
                8 to Pair(895, 940),   // 14:55-15:40
                9 to Pair(950, 995),   // 15:50-16:35
                10 to Pair(1015, 1060), // 16:55-17:40
                11 to Pair(1070, 1115), // 17:50-18:35
                12 to Pair(1160, 1205), // 19:20-20:05
                13 to Pair(1215, 1260), // 20:15-21:00
                14 to Pair(1270, 1315)  // 21:10-21:55
            )
            
            val startTime = timeMap[startSection]?.first ?: return false
            val endTime = timeMap[endSection]?.second ?: return false
            
            // 当前时间在课程时间段内
            return currentMinutes >= startTime && currentMinutes < endTime
        }

        /**
         * 显示无数据提示
         */
        private fun showNoDataMessage(views: RemoteViews, message: String) {
            // 隐藏所有课程容器
            for (i in 1..5) {
                views.setViewVisibility(getContainerId(i), View.GONE)
            }
            
            views.setViewVisibility(R.id.no_course_message, View.VISIBLE)
            views.setTextViewText(R.id.no_course_message, message)
        }

        /**
         * 获取当前星期几（1=周一，7=周日）
         */
        private fun getCurrentWeekday(): Int {
            val calendar = Calendar.getInstance()
            val weekday = calendar.get(Calendar.DAY_OF_WEEK)
            // Calendar.DAY_OF_WEEK: 1=Sunday, 2=Monday, ..., 7=Saturday
            // 转换为: 1=Monday, 2=Tuesday, ..., 7=Sunday
            return if (weekday == 1) 7 else weekday - 1
        }

        /**
         * 获取星期名称
         */
        private fun getWeekdayName(weekday: Int): String {
            return when (weekday) {
                1 -> "周一"
                2 -> "周二"
                3 -> "周三"
                4 -> "周四"
                5 -> "周五"
                6 -> "周六"
                7 -> "周日"
                else -> "周一"
            }
        }
        
        /**
         * 设置定时更新（在每节课结束时更新）
         */
        private fun scheduleUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ClassTableWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // 获取下一个课程结束时间
            val nextUpdateTime = getNextCourseEndTime()
            
            // 设置在下一节课结束时更新
            alarmManager.setRepeating(
                AlarmManager.RTC,
                nextUpdateTime,
                30 * 60 * 1000L, // 每30分钟检查一次
                pendingIntent
            )
            
            Log.d("ClassTableWidget", "Scheduled next update at ${Date(nextUpdateTime)}")
        }
        
        /**
         * 取消定时更新
         */
        private fun cancelUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ClassTableWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
        
        /**
         * 获取下一个课程结束时间
         */
        private fun getNextCourseEndTime(): Long {
            val calendar = Calendar.getInstance()
            val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
            val currentMinute = calendar.get(Calendar.MINUTE)
            val currentTimeInMinutes = currentHour * 60 + currentMinute
            
            // 课程结束时间点（分钟）
            val courseEndTimes = listOf(
                9 * 60 + 40,   // 9:40 - 第2节结束
                11 * 60 + 40,  // 11:40 - 第4节结束
                15 * 60 + 40,  // 15:40 - 第6节结束
                17 * 60 + 40,  // 17:40 - 第8节结束
                20 * 60 + 40,  // 20:40 - 第10节结束
                22 * 60 + 30   // 22:30 - 第12节结束
            )
            
            // 找到下一个课程结束时间
            val nextEndTime = courseEndTimes.firstOrNull { it > currentTimeInMinutes }
            
            if (nextEndTime != null) {
                // 今天还有课程结束
                calendar.set(Calendar.HOUR_OF_DAY, nextEndTime / 60)
                calendar.set(Calendar.MINUTE, nextEndTime % 60)
                calendar.set(Calendar.SECOND, 0)
            } else {
                // 今天的课程都结束了，设置为明天第一个课程结束时间
                calendar.add(Calendar.DAY_OF_YEAR, 1)
                calendar.set(Calendar.HOUR_OF_DAY, 9)
                calendar.set(Calendar.MINUTE, 40)
                calendar.set(Calendar.SECOND, 0)
            }
            
            return calendar.timeInMillis
        }
    }
}

