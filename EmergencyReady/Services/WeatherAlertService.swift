import Foundation
import CoreLocation

struct WeatherAlert: Identifiable, Codable {
    let id: String
    let event: String
    let headline: String
    let severity: String
    let description: String
    let instruction: String?
    let effective: String
    let expires: String
}

class WeatherAlertService: ObservableObject {
    @Published var alerts: [WeatherAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var locationName: String = "Your Area"

    func fetchAlerts(for location: CLLocation) {
        isLoading = true
        errorMessage = nil

        let lat = String(format: "%.4f", location.coordinate.latitude)
        let lon = String(format: "%.4f", location.coordinate.longitude)

        // 1. First fetch NOAA active alerts for this point
        guard let url = URL(string: "https://api.weather.gov/alerts/active?point=\(lat),\(lon)") else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("EmergencyReadyApp (emergencyready.app)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let features = json["features"] as? [[String: Any]] {

                    let parsedAlerts: [WeatherAlert] = features.compactMap { feature in
                        guard let properties = feature["properties"] as? [String: Any],
                              let event = properties["event"] as? String,
                              let headline = properties["headline"] as? String else {
                            return nil
                        }
                        let id = properties["id"] as? String ?? UUID().uuidString
                        let severity = properties["severity"] as? String ?? "Moderate"
                        let desc = properties["description"] as? String ?? ""
                        let instruction = properties["instruction"] as? String
                        let eff = properties["effective"] as? String ?? ""
                        let exp = properties["expires"] as? String ?? ""

                        return WeatherAlert(id: id, event: event, headline: headline, severity: severity, description: desc, instruction: instruction, effective: eff, expires: exp)
                    }

                    if !parsedAlerts.isEmpty {
                        self?.alerts = parsedAlerts
                        return
                    }
                }

                // If outside USA or no active emergency alerts, query Open-Meteo for real-time severe conditions
                self?.fetchOpenMeteoWarnings(lat: lat, lon: lon)
            }
        }.resume()
    }

    private func fetchOpenMeteoWarnings(lat: String, lon: String) {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m&timezone=auto") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any] else { return }

            let windSpeed = current["wind_speed_10m"] as? Double ?? 0
            let weatherCode = current["weather_code"] as? Int ?? 0
            let precip = current["precipitation"] as? Double ?? 0

            var generatedAlerts: [WeatherAlert] = []

            // WMO Weather codes: 95, 96, 99 = Thunderstorm; 65, 75 = Heavy Rain/Snow; 55 = Dense drizzle
            if weatherCode >= 95 {
                generatedAlerts.append(WeatherAlert(
                    id: "thunderstorm-warning",
                    event: "Severe Thunderstorm Warning",
                    headline: "Active thunderstorm detected in your area",
                    severity: "Severe",
                    description: "Thunderstorm with lightning and strong convective gusts. Stay indoors away from windows.",
                    instruction: "Seek substantial shelter immediately. Avoid electrical appliances and corded phones.",
                    effective: "Now",
                    expires: "Ongoing"
                ))
            } else if windSpeed > 45 {
                generatedAlerts.append(WeatherAlert(
                    id: "high-wind-warning",
                    event: "High Wind Advisory",
                    headline: "High winds reported (\(Int(windSpeed)) km/h)",
                    severity: "Moderate",
                    description: "Strong winds may blow down branches and cause power outages.",
                    instruction: "Secure outdoor objects and exercise caution if driving high-profile vehicles.",
                    effective: "Now",
                    expires: "Ongoing"
                ))
            } else if precip > 15 {
                generatedAlerts.append(WeatherAlert(
                    id: "heavy-rain-warning",
                    event: "Heavy Rainfall Alert",
                    headline: "Heavy precipitation in your area",
                    severity: "Moderate",
                    description: "Localized pooling of water and flash flooding possible in low-lying zones.",
                    instruction: "Do not attempt to walk or drive through flood waters.",
                    effective: "Now",
                    expires: "Ongoing"
                ))
            }

            DispatchQueue.main.async {
                self?.alerts = generatedAlerts
            }
        }.resume()
    }
}
