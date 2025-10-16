//
//  ClassTableWidget.swift
//  ClassTableWidget
//
//  Created by 韩沛霖 on 2025/10/16.
//

import WidgetKit
import SwiftUI

// MARK: - 课程数据模型
struct CourseInfo: Codable, Identifiable {
    let name: String
    let location: String
    let startSection: String
    let endSection: String
    let teacher: String
    let weekday: String
    
    var id: String {
        "\(weekday)_\(startSection)_\(endSection)_\(name)"
    }
    
    var timeRange: String {
        let startTime = sectionToTime(Int(startSection) ?? 1, isStart: true)
        let endTime = sectionToTime(Int(endSection) ?? 1, isStart: false)
        return "\(startTime)-\(endTime)"
    }
    
    // 根据节次计算时间
    private func sectionToTime(_ section: Int, isStart: Bool) -> String {
        switch section {
        case 1: return isStart ? "08:00" : "08:45"
        case 2: return isStart ? "08:55" : "09:40"
        case 3: return isStart ? "10:00" : "10:45"
        case 4: return isStart ? "10:55" : "11:40"
        case 5: return isStart ? "13:00" : "13:45"
        case 6: return isStart ? "13:55" : "14:40"
        case 7: return isStart ? "15:00" : "15:45"
        case 8: return isStart ? "15:55" : "16:40"
        case 9: return isStart ? "17:00" : "17:45"
        case 10: return isStart ? "17:55" : "18:40"
        case 11: return isStart ? "19:20" : "20:05"
        case 12: return isStart ? "20:15" : "21:00"
        case 13: return isStart ? "21:10" : "21:55"
        case 14: return isStart ? "22:05" : "22:50"
        default: return isStart ? "00:00" : "23:59"
        }
    }
    
    // 判断课程是否正在进行
    func isOngoing() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        
        guard let start = Int(startSection), let end = Int(endSection) else {
            return false
        }
        
        let startTime = sectionToTime(start, isStart: true)
        let endTime = sectionToTime(end, isStart: false)
        
        let startMinutes = timeToMinutes(startTime)
        let endMinutes = timeToMinutes(endTime)
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
    
    // 判断课程是否已结束
    func isFinished() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        
        guard let end = Int(endSection) else {
            return false
        }
        
        let endTime = sectionToTime(end, isStart: false)
        let endMinutes = timeToMinutes(endTime)
        
        return currentMinutes > endMinutes
    }
    
    // 起止分钟（方便比较）
    func startMinutesValue() -> Int {
        guard let start = Int(startSection) else { return 0 }
        return timeToMinutes(sectionToTime(start, isStart: true))
    }
    
    func endMinutesValue() -> Int {
        guard let end = Int(endSection) else { return 24 * 60 }
        return timeToMinutes(sectionToTime(end, isStart: false))
    }
    
    private func timeToMinutes(_ time: String) -> Int {
        let components = time.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return 0 }
        return components[0] * 60 + components[1]
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), courses: [], currentWeek: 1, currentWeekday: 1)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadEntry()
        
        // 每10分钟更新一次
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func loadEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.social.swu.camphor_forest")
        
        let currentWeek = userDefaults?.integer(forKey: "current_week") ?? 1
        // Flutter的weekday: 1=周一, 7=周日
        // 如果UserDefaults中有值就使用，否则从iOS的Calendar转换
        var currentWeekday = userDefaults?.integer(forKey: "current_weekday") ?? 0
        
        if currentWeekday == 0 {
            // iOS Calendar.weekday: 1=周日, 2=周一, ..., 7=周六
            // 需要转换为Flutter的格式: 1=周一, 7=周日
            let iosWeekday = Calendar.current.component(.weekday, from: Date())
            currentWeekday = iosWeekday == 1 ? 7 : iosWeekday - 1
        }
        
        // 读取课表数据
        var courses: [CourseInfo] = []
        if let jsonString = userDefaults?.string(forKey: "class_table_data"),
           let jsonData = jsonString.data(using: .utf8) {
            do {
                let weekData = try JSONDecoder().decode([String: [CourseInfo]].self, from: jsonData)
                // 获取今天的课程（使用Flutter的weekday格式）
                let dayKey = "day_\(currentWeekday)"
                courses = weekData[dayKey] ?? []
                
                // 按开始节次排序
                courses.sort { Int($0.startSection) ?? 0 < Int($1.startSection) ?? 0 }
            } catch {
                print("Error decoding class table data: \(error)")
            }
        }
        
        return SimpleEntry(
            date: Date(),
            courses: courses,
            currentWeek: currentWeek,
            currentWeekday: currentWeekday
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let courses: [CourseInfo]
    let currentWeek: Int
    let currentWeekday: Int
}

// MARK: - Widget View
struct ClassTableWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge, .systemExtraLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (显示当前/下一节课)
struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    // 当前时间（分钟）
    private var nowMinutes: Int {
        let now = Date()
        let cal = Calendar.current
        return cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
    }
    
    // 正在进行的课程
    private var currentCourse: CourseInfo? {
        entry.courses.first { c in
            let start = c.startMinutesValue()
            let end = c.endMinutesValue()
            return nowMinutes >= start && nowMinutes <= end
        }
    }
    
    // 下一节课程
    private var upcomingCourse: CourseInfo? {
        entry.courses.first { c in c.startMinutesValue() > nowMinutes }
    }
    
    // 是否切换显示下一节（当前课结束前10分钟）
    private var shouldShowNextInsteadOfCurrent: Bool {
        guard let c = currentCourse else { return false }
        let remaining = c.endMinutesValue() - nowMinutes
        return remaining <= 10 && upcomingCourse != nil
    }
    
    // 当天第一节课
    private var firstCourse: CourseInfo? { entry.courses.first }
    
    // 最终要展示的课程与标签
    private var courseToShow: (course: CourseInfo?, label: String, isCurrent: Bool) {
        if let cur = currentCourse, !shouldShowNextInsteadOfCurrent {
            return (cur, "正在上课", true)
        }
        if let first = firstCourse {
            let start = first.startMinutesValue()
            if nowMinutes < start {
                return (first, "第一节课", false)
            }
        }
        if let next = upcomingCourse {
            return (next, "下一节", false)
        }
        
        // 区分无课和已完成
        if entry.courses.isEmpty {
            return (nil, "今日无课", false)
        } else {
            return (nil, "今日课程已完成", false)
        }
    }
    
    var body: some View {
        
        let data = courseToShow
        VStack(alignment: .leading, spacing: 6) {
            // 标签（只在有课程时显示）
            if data.course != nil {
                HStack(spacing: 6) {
                    Text(data.label)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule().fill(data.isCurrent ? Color.yellow : Color.white.opacity(0.18))
                        )
                        .foregroundColor(data.isCurrent ? .black : .white)
                    Spacer(minLength: 0)
                }
            }
            
            if let course = data.course {
                Text(course.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(course.location)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(course.timeRange)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer(minLength: 0)
                
                HStack {
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(course.teacher)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            } else {
                Text(data.label == "今日无课" ? "今日无课 🎉" : "今日课程已完成 ✨")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Medium Widget (显示今日课程列表)
struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("\(dateString) \(weekdayString)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("今日共 \(entry.courses.count) 节")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 2)
            
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.bottom, 2)
            
            // 课程列表
            if entry.courses.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("今日无课 🎉")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 3) {
                    ForEach(getDisplayCourses()) { course in
                        MediumCourseRowView(course: course)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: entry.date)
    }
    
    private var weekdayString: String {
        // entry.currentWeekday 使用的是 Flutter 格式: 1=周一, 7=周日
        let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let index = entry.currentWeekday - 1
        guard index >= 0 && index < weekdays.count else {
            return "周一"
        }
        return weekdays[index]
    }
    
    // 获取要显示的课程（滑动窗口逻辑）
    private func getDisplayCourses() -> [CourseInfo] {
        let courses = entry.courses
        
        // 如果课程少于4节，直接显示所有课程
        if courses.count < 4 {
            return courses
        }
        
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        
        // 找到当前时间对应的课程索引
        var currentIndex = 0
        for (index, course) in courses.enumerated() {
            let endMinutes = course.endMinutesValue()
            if currentMinutes <= endMinutes {
                currentIndex = index
                break
            }
            currentIndex = index + 1
        }
        
        // 确保不超出数组边界
        let startIndex = max(0, min(currentIndex, courses.count - 3))
        let endIndex = min(startIndex + 3, courses.count)
        
        return Array(courses[startIndex..<endIndex])
    }
}

// MARK: - Large Widget (显示完整今日课程)
struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.15, blue: 0.15)
            
            VStack(alignment: .leading, spacing: 10) {
                // 顶部标题栏
                HStack {
                    Text("\(dateString) \(weekdayString)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("今日共 \(entry.courses.count) 节")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 2)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // 课程列表
                if entry.courses.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("今日无课 🎉")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("好好享受这一天吧")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(entry.courses) { course in
                            CourseRowView(course: course, isFixedHeight: entry.courses.count <= 3)
                        }
                        
                        // 课程少时，添加Spacer让内容靠上显示
                        if entry.courses.count <= 3 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(12)
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: entry.date)
    }
    
    private var weekdayString: String {
        // entry.currentWeekday 使用的是 Flutter 格式: 1=周一, 7=周日
        let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        let index = entry.currentWeekday - 1
        guard index >= 0 && index < weekdays.count else {
            return "周一"
        }
        return weekdays[index]
    }
}

// MARK: - Medium小组件专用课程行（紧凑版）
struct MediumCourseRowView: View {
    let course: CourseInfo
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 左侧竖线（当前课程高亮）
            Rectangle()
                .fill(course.isOngoing() ? Color.yellow : Color.white.opacity(0.25))
                .frame(width: 2.5)

            // 课程信息
            VStack(alignment: .leading, spacing: 0) {
                Text(course.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    // 左侧突出显示地点
                    Text(course.location)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // 右侧时间 + 教师
                    HStack(spacing: 6) {
                        Text(course.timeRange)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)
                        Text(course.teacher)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, 8)
            .padding(.top, 4)
            .padding(.bottom, 2)

            Spacer()
        }
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(course.isOngoing() ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.white.opacity(course.isOngoing() ? 0.25 : 0.12), lineWidth: 0.8)
        )
        .opacity(course.isFinished() ? 0.4 : 1.0)
    }
}

// MARK: - 课程行视图（用于Large小组件）
struct CourseRowView: View {
    let course: CourseInfo
    let isFixedHeight: Bool
    
    init(course: CourseInfo, isFixedHeight: Bool = false) {
        self.course = course
        self.isFixedHeight = isFixedHeight
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 左侧竖线（当前课程高亮）
            Rectangle()
                .fill(course.isOngoing() ? Color(red: 1.0, green: 0.8, blue: 0.0) : Color.clear)
                .frame(width: 4)
            
            // 课程信息
            VStack(alignment: .leading, spacing: 3) {
                Text(course.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // 左侧突出显示地点
                    Text(course.location)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 右侧时间 + 教师
                    HStack(spacing: 8) {
                        Text(course.timeRange)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)
                        Text(course.teacher)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 10)
            
            Spacer()
        }
        .frame(height: isFixedHeight ? 50 : nil)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(course.isOngoing() ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
        .opacity(course.isFinished() ? 0.4 : 1.0)
    }
}

// MARK: - Widget Configuration
struct ClassTableWidget: Widget {
    let kind: String = "ClassTableWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClassTableWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 0.15, green: 0.15, blue: 0.15), for: .widget)
        }
        .configurationDisplayName("课程表")
        .description("查看今日课程安排")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview("Small Widget", as: .systemSmall) {
    ClassTableWidget()
} timeline: {
    // 正在上课
    SimpleEntry(
        date: .now,
        courses: [
            CourseInfo(name: "马克思主义基本原理", location: "08-0610", startSection: "1", endSection: "3", teacher: "张老师", weekday: "4"),
            CourseInfo(name: "学术语言与研究方法 I", location: "27-0306", startSection: "7", endSection: "8", teacher: "李老师", weekday: "4"),
            CourseInfo(name: "系统分析与设计", location: "27-0402", startSection: "11", endSection: "13", teacher: "王老师", weekday: "4")
        ],
        currentWeek: 1,
        currentWeekday: 4
    )
    
    // 第一节课前
    SimpleEntry(
        date: Calendar.current.date(byAdding: .hour, value: -1, to: .now)!,
        courses: [
            CourseInfo(name: "高等数学", location: "01-0201", startSection: "1", endSection: "2", teacher: "刘老师", weekday: "1"),
            CourseInfo(name: "大学英语", location: "02-0302", startSection: "3", endSection: "4", teacher: "陈老师", weekday: "1")
        ],
        currentWeek: 1,
        currentWeekday: 1
    )
    
    // 今日无课
    SimpleEntry(
        date: .now,
        courses: [],
        currentWeek: 1,
        currentWeekday: 7
    )
}

#Preview("Medium Widget", as: .systemMedium) {
    ClassTableWidget()
} timeline: {
    // 正常课程
    SimpleEntry(
        date: .now,
        courses: [
            CourseInfo(name: "马克思主义基本原理", location: "08-0610", startSection: "1", endSection: "3", teacher: "张老师", weekday: "4"),
            CourseInfo(name: "学术语言与研究方法 I", location: "27-0306", startSection: "7", endSection: "8", teacher: "李老师", weekday: "4"),
            CourseInfo(name: "系统分析与设计", location: "27-0402", startSection: "11", endSection: "13", teacher: "王老师", weekday: "4")
        ],
        currentWeek: 1,
        currentWeekday: 4
    )
    
    // 课程较少
    SimpleEntry(
        date: .now,
        courses: [
            CourseInfo(name: "高等数学", location: "01-0201", startSection: "1", endSection: "2", teacher: "刘老师", weekday: "1")
        ],
        currentWeek: 1,
        currentWeekday: 1
    )
    
    // 今日无课
    SimpleEntry(
        date: .now,
        courses: [],
        currentWeek: 1,
        currentWeekday: 7
    )
}

#Preview("Large Widget", as: .systemLarge) {
    ClassTableWidget()
} timeline: {
    // 少量课程（≤3节）
    SimpleEntry(
        date: .now,
        courses: [
            CourseInfo(name: "高等数学", location: "01-0201", startSection: "1", endSection: "2", teacher: "刘老师", weekday: "1"),
            CourseInfo(name: "大学英语", location: "02-0302", startSection: "3", endSection: "4", teacher: "陈老师", weekday: "1")
        ],
        currentWeek: 1,
        currentWeekday: 1
    )
    
    // 大量课程（>3节）
    SimpleEntry(
        date: .now,
        courses: [
            CourseInfo(name: "马克思主义基本原理", location: "08-0610", startSection: "1", endSection: "3", teacher: "张老师", weekday: "4"),
            CourseInfo(name: "学术语言与研究方法 I", location: "27-0306", startSection: "7", endSection: "8", teacher: "李老师", weekday: "4"),
            CourseInfo(name: "系统分析与设计", location: "27-0402", startSection: "11", endSection: "13", teacher: "王老师", weekday: "4"),
            CourseInfo(name: "数据结构与算法", location: "15-0801", startSection: "5", endSection: "6", teacher: "赵老师", weekday: "4"),
            CourseInfo(name: "计算机网络", location: "12-0503", startSection: "9", endSection: "10", teacher: "孙老师", weekday: "4")
        ],
        currentWeek: 1,
        currentWeekday: 4
    )
    
    // 今日无课
    SimpleEntry(
        date: .now,
        courses: [],
        currentWeek: 1,
        currentWeekday: 7
    )
}
