import CoreLocation
import Foundation
import Combine

final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocationText: String = "No location selected"
    @Published var didResolveLocation: Bool = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return
        }
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            currentLocationText = "Location permission denied"
            didResolveLocation = false
            return
        }
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            currentLocationText = "Location unavailable"
            didResolveLocation = false
            return
        }
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            if let placemark = placemarks?.first {
                var pieces: [String] = []
                for field in [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country] {
                    guard let raw = field else { continue }
                    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty {
                        pieces.append(value)
                    }
                }
                if pieces.isEmpty {
                    self.currentLocationText = "Location found"
                } else {
                    self.currentLocationText = pieces.joined(separator: ", ")
                }
                self.didResolveLocation = true
            } else {
                let lat = String(format: "%.4f", location.coordinate.latitude)
                let lon = String(format: "%.4f", location.coordinate.longitude)
                self.currentLocationText = "Lat \(lat), Lon \(lon)"
                self.didResolveLocation = true
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentLocationText = "Location error: \(error.localizedDescription)"
        didResolveLocation = false
    }
}
