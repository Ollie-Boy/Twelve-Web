import Foundation

struct DiaryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var selectedDate: Date
    var title: String
    var body: String
    var weather: WeatherOption
    var location: String?
    var attachments: [DiaryAttachment]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        selectedDate: Date = Date(),
        title: String = "",
        body: String = "",
        weather: WeatherOption = .sunny,
        location: String? = nil,
        attachments: [DiaryAttachment] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.selectedDate = selectedDate
        self.title = title
        self.body = body
        self.weather = weather
        self.location = location
        self.attachments = attachments
    }
}
