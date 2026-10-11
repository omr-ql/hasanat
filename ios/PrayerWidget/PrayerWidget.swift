import SwiftUI
import WidgetKit

private let appGroup = "group.com.hasanat.app.hasanat"
private let storageKey = "prayer-widget"

struct PrayerRow: Decodable, Identifiable {
  let name: String
  let time: String
  let at: Double

  var id: String { "\(name)-\(at)" }
  var date: Date { Date(timeIntervalSince1970: at / 1000) }
}

struct PrayerEntry: TimelineEntry {
  let date: Date
  let rows: [PrayerRow]

  func visible(at moment: Date) -> [PrayerRow] {
    guard let focus = rows.first(where: { $0.date > moment }) else { return [] }
    return rows.filter { Calendar.current.isDate($0.date, inSameDayAs: focus.date) }
  }

  func upcoming(at moment: Date) -> PrayerRow? {
    rows.first { $0.date > moment }
  }
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(date: Date(), rows: [])
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(PrayerEntry(date: Date(), rows: loadRows()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let rows = loadRows()
    let now = Date()
    var moments = [now]
    moments.append(contentsOf: rows.map(\.date).filter { $0 > now })
    let entries = moments.map { PrayerEntry(date: $0, rows: rows) }
    let refresh = (rows.last?.date ?? now).addingTimeInterval(60 * 60)
    completion(Timeline(entries: entries, policy: .after(refresh)))
  }

  private func loadRows() -> [PrayerRow] {
    guard
      let raw = UserDefaults(suiteName: appGroup)?.string(forKey: storageKey),
      let data = raw.data(using: .utf8),
      let rows = try? JSONDecoder().decode([PrayerRow].self, from: data)
    else {
      return []
    }
    return rows
  }
}

struct PrayerWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: PrayerEntry

  var body: some View {
    let day = entry.visible(at: entry.date)
    let next = entry.upcoming(at: entry.date)
    Group {
      if day.isEmpty || next == nil {
        Text("افتح حسنات وحدد موقعك")
          .font(.system(size: 15, weight: .semibold))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color(white: 0.33))
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if family == .systemSmall, let next {
        VStack(alignment: .trailing, spacing: 6) {
          Text("القادم")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(white: 0.46))
          Text(next.name)
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(prayerBlue)
            .lineLimit(1)
          Text(next.time)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(prayerBlue)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      } else {
        VStack(alignment: .trailing, spacing: 6) {
          ForEach(day) { row in
            HStack {
              Text(row.name)
                .lineLimit(1)
              Spacer(minLength: 8)
              Text(row.time)
                .lineLimit(1)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(row.id == next?.id ? prayerBlue : Color(white: 0.13))
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      }
    }
    .environment(\.layoutDirection, .rightToLeft)
  }
}

private let prayerBlue = Color(red: 0.035, green: 0.478, blue: 1)

struct PrayerWidget: Widget {
  let kind = "PrayerWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
      PrayerWidgetView(entry: entry)
        .containerBackground(for: .widget) {
          Color.white
        }
    }
    .configurationDisplayName("مواقيت الصلاة")
    .description("أوقات الصلاة حسب موقعك")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct PrayerWidgetBundle: WidgetBundle {
  var body: some Widget {
    PrayerWidget()
  }
}
