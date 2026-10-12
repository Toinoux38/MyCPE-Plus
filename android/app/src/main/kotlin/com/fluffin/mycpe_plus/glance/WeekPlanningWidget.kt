package com.fluffin.mycpe_plus.glance

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.itemsIndexed
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.unit.ColorProvider
import androidx.glance.color.ColorProvider as colorProvider
import com.fluffin.mycpe_plus.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class WeekPlanningWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            DayContent(currentState())
        }
    }

    @Composable
    private fun DayContent(state: HomeWidgetGlanceState) {
        val prefs = state.preferences

        // The app pushes the next weeks of courses; the day to show and the
        // next course are picked here from the current time, so the widget
        // stays right on the following days without the app being opened.
        val schedule = parseSchedule(prefs.getString("schedule", null))
        val labelToday = prefs.getString("label_today", null) ?: "Aujourd'hui"
        val labelNoCourse = prefs.getString("label_no_course", null) ?: "Aucun cours à venir"

        val now = System.currentTimeMillis()
        // Today while a course is left, otherwise the next day with courses.
        val shownDayStart = schedule.firstOrNull { it.end > now }?.let { startOfDay(it.start) }
        val courses = if (shownDayStart == null) {
            emptyList()
        } else {
            schedule.filter { startOfDay(it.start) == shownDayStart }
        }
        val nextCourseIndex = courses.indexOfFirst { it.end > now }
        val isToday = shownDayStart == startOfDay(now)
        val shownDay = Calendar.getInstance().apply { timeInMillis = shownDayStart ?: now }
        val dayLetter = SimpleDateFormat("EEEEE", Locale.getDefault()).format(shownDay.time)
        val dayNumber = shownDay.get(Calendar.DAY_OF_MONTH)

        // Colors
        val white = androidx.compose.ui.graphics.Color.White
        val darkBg = androidx.compose.ui.graphics.Color(0xFF1E1E2E)
        val accentDay = androidx.compose.ui.graphics.Color(0xFF04A3D5)
        val accentNight = androidx.compose.ui.graphics.Color(0xFF62D6F5)
        val textPrimDay = androidx.compose.ui.graphics.Color(0xFF1A1A2E)
        val textPrimNight = androidx.compose.ui.graphics.Color(0xFFE8E8F0)
        val textSecDay = androidx.compose.ui.graphics.Color(0xFF6B7280)
        val textSecNight = androidx.compose.ui.graphics.Color(0xFF9CA3AF)
        val chipDay = androidx.compose.ui.graphics.Color(0xFFF3F4F6)
        val chipNight = androidx.compose.ui.graphics.Color(0xFF2A2A3E)
        val nextCourseBgStart = androidx.compose.ui.graphics.Color(0xFF1E40AF) // Deep blue
        val nextCourseBgEnd = androidx.compose.ui.graphics.Color(0xFF3B82F6) // Lighter blue
        val nextCourseBg = androidx.compose.ui.graphics.Color(0xFF2563EB) // Medium blue for solid

        val bgColor = colorProvider(white, darkBg)
        val headerColor = colorProvider(accentDay, accentNight)
        val textPrimary = colorProvider(textPrimDay, textPrimNight)
        val textSecondary = colorProvider(textSecDay, textSecNight)
        val todayBg = colorProvider(accentDay, accentDay)
        val chipBg = colorProvider(chipDay, chipNight)
        val accentBar = colorProvider(accentDay, accentNight)
        val whiteColor = colorProvider(white, white)
        val nextBg = colorProvider(nextCourseBg, nextCourseBg)

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(bgColor)
                .cornerRadius(20.dp)
                .clickable(actionStartActivity<MainActivity>())
        ) {
            Column(modifier = GlanceModifier.fillMaxSize().padding(16.dp)) {
                // Header: MyCPE+ title
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "MyCPE+",
                        style = TextStyle(
                            color = headerColor,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                    Spacer(modifier = GlanceModifier.defaultWeight())
                    
                    // Date badge
                    if (isToday) {
                        Box(
                            modifier = GlanceModifier
                                .height(38.dp)
                                .cornerRadius(12.dp)
                                .background(todayBg)
                                .padding(horizontal = 10.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalAlignment = Alignment.CenterHorizontally,
                            ) {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = GlanceModifier.padding(end = 6.dp),
                                ) {
                                    Text(
                                        text = dayLetter,
                                        style = TextStyle(
                                            color = whiteColor,
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Medium,
                                        ),
                                    )
                                    Text(
                                        text = dayNumber.toString(),
                                        style = TextStyle(
                                            color = whiteColor,
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold,
                                        ),
                                    )
                                }
                                Text(
                                    text = labelToday,
                                    style = TextStyle(
                                        color = whiteColor,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Medium,
                                    ),
                                )
                            }
                        }
                    } else {
                        Box(
                            modifier = GlanceModifier
                                .height(38.dp)
                                .cornerRadius(12.dp)
                                .padding(horizontal = 10.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = dayLetter,
                                    style = TextStyle(
                                        color = textSecondary,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Medium,
                                    ),
                                )
                                Text(
                                    text = dayNumber.toString(),
                                    style = TextStyle(
                                        color = textPrimary,
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Bold,
                                    ),
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = GlanceModifier.height(12.dp))

                // Courses list
                if (courses.isEmpty()) {
                    Box(
                        modifier = GlanceModifier.fillMaxSize(),
                        contentAlignment = Alignment.Center,
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "🎉",
                                style = TextStyle(fontSize = 32.sp),
                            )
                            Spacer(modifier = GlanceModifier.height(8.dp))
                            Text(
                                text = labelNoCourse,
                                style = TextStyle(
                                    color = textSecondary,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Medium,
                                ),
                            )
                        }
                    }
                } else {
                    LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                        itemsIndexed(courses) { index, course ->
                            val isNextCourse = index == nextCourseIndex

                            Box(
                                modifier = GlanceModifier
                                    .fillMaxWidth()
                                    .padding(bottom = 8.dp),
                            ) {
                                Box(
                                    modifier = if (isNextCourse) {
                                        GlanceModifier
                                            .fillMaxWidth()
                                            .background(nextBg)
                                            .cornerRadius(12.dp)
                                            .padding(12.dp)
                                    } else {
                                        GlanceModifier
                                            .fillMaxWidth()
                                            .background(chipBg)
                                            .cornerRadius(12.dp)
                                            .padding(12.dp)
                                    },
                                ) {
                                    Row(
                                        modifier = GlanceModifier.fillMaxWidth(),
                                        verticalAlignment = Alignment.CenterVertically,
                                    ) {
                                        // Accent bar
                                        Box(
                                            modifier = GlanceModifier
                                                .width(4.dp)
                                                .height(40.dp)
                                                .cornerRadius(2.dp)
                                                .background(
                                                    if (isNextCourse) whiteColor else accentBar
                                                ),
                                        ) {}
                                        
                                        Spacer(modifier = GlanceModifier.width(10.dp))
                                        
                                        Column(modifier = GlanceModifier.defaultWeight()) {
                                            Text(
                                                text = course.title,
                                                style = TextStyle(
                                                    color = if (isNextCourse) whiteColor else textPrimary,
                                                    fontSize = 13.sp,
                                                    fontWeight = FontWeight.Bold,
                                                ),
                                                maxLines = 2,
                                            )
                                            Spacer(modifier = GlanceModifier.height(2.dp))
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Text(
                                                    text = course.time,
                                                    style = TextStyle(
                                                        color = if (isNextCourse) whiteColor else textSecondary,
                                                        fontSize = 11.sp,
                                                    ),
                                                )
                                                if (course.room.isNotEmpty()) {
                                                    Text(
                                                        text = " • ",
                                                        style = TextStyle(
                                                            color = if (isNextCourse) whiteColor else textSecondary,
                                                            fontSize = 11.sp,
                                                        ),
                                                    )
                                                    Text(
                                                        text = course.room,
                                                        style = TextStyle(
                                                            color = if (isNextCourse) whiteColor else textSecondary,
                                                            fontSize = 11.sp,
                                                        ),
                                                    )
                                                }
                                            }
                                        }
                                        
                                        if (isNextCourse) {
                                            Spacer(modifier = GlanceModifier.width(8.dp))
                                            Text(
                                                text = "▶",
                                                style = TextStyle(
                                                    color = whiteColor,
                                                    fontSize = 16.sp,
                                                ),
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // Data helpers
    // =========================================================================

    private fun parseSchedule(json: String?): List<CourseData> {
        if (json == null) return emptyList()
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                CourseData(
                    title = obj.getString("title"),
                    time = obj.getString("time"),
                    room = obj.optString("room", ""),
                    start = obj.getLong("start"),
                    end = obj.getLong("end"),
                )
            }.sortedBy { it.start }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun startOfDay(millis: Long): Long = Calendar.getInstance().apply {
        timeInMillis = millis
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis
}

// =============================================================================
// Data classes
// =============================================================================

data class CourseData(
    val title: String,
    val time: String,
    val room: String,
    val start: Long,
    val end: Long,
)
