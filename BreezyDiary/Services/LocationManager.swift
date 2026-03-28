import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocationText: String = "Unknown Place"
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
        let lat = String(format: "%.4f", location.coordinate.latitude)
        let lon = String(format: "%.4f", location.coordinate.longitude)
        currentLocationText = "Lat \(lat), Lon \(lon)"
        didResolveLocation = true
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentLocationText = "Location error: \(error.localizedDescription)"
        didResolveLocation = false
    }
}
