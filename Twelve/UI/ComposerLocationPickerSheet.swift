import SwiftUI
import MapKit
import CoreLocation

/// Map location picker shared by diary composer and Ledger (identical layout and chrome).
struct ComposerLocationPickerSheet: View {
    var onPickAddress: (String) -> Void
    var onClearAddress: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var pickedAddressText = ""
    @State private var isResolving = false
    @State private var errorText: String?
    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            ZStack {
                ComposerLegacyMapView(
                    region: $region,
                    selectedCoordinate: $selectedCoordinate,
                    onTapCoordinate: { coordinate in
                        selectedCoordinate = coordinate
                        resolveAddress(for: coordinate, shouldDismiss: false)
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                VStack {
                    Text("Tap map to select an exact point, then confirm")
                        .font(TwelveTheme.appFont(size: 12, weight: .medium))
                        .foregroundStyle(TwelveTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())

                    if isResolving {
                        ProgressView()
                    } else if let errorText {
                        Text(errorText)
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    } else if !pickedAddressText.isEmpty {
                        Text(pickedAddressText)
                            .font(TwelveTheme.appFont(size: 12))
                            .foregroundStyle(TwelveTheme.textPrimary)
                            .lineLimit(2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }

                    Spacer()
                }
                .padding(.top, 10)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Button {
                                useCurrentLocation()
                            } label: {
                                Image(systemName: "location.fill")
                                    .frame(width: 36, height: 36)
                                    .background(TwelveTheme.surface, in: Circle())
                            }
                            Button {
                                useMapCenter()
                            } label: {
                                Image(systemName: "checkmark")
                                    .frame(width: 36, height: 36)
                                    .background(TwelveTheme.primaryBlue, in: Circle())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(14)
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("No Address") {
                        onClearAddress()
                        dismiss()
                    }
                }
            }
            .onAppear {
                useCurrentLocation()
            }
        }
    }

    private func useCurrentLocation() {
        if let coordinate = LocationStore.shared.lastCoordinate {
            selectedCoordinate = coordinate
            region.center = coordinate
        }
    }

    private func useMapCenter() {
        let target = selectedCoordinate ?? region.center
        resolveAddress(for: target, shouldDismiss: true)
    }

    private func resolveAddress(for coordinate: CLLocationCoordinate2D, shouldDismiss: Bool = true) {
        errorText = nil
        isResolving = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            isResolving = false
            if let error {
                errorText = error.localizedDescription
                return
            }
            guard let placemark = placemarks?.first else {
                errorText = "Address unavailable"
                return
            }
            let parts = [placemark.name, placemark.locality, placemark.administrativeArea, placemark.country]
            let address = parts.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            guard !address.isEmpty else {
                errorText = "Address unavailable"
                return
            }
            pickedAddressText = address
            if shouldDismiss {
                onPickAddress(address)
                dismiss()
            }
        }
    }
}

struct ComposerLegacyMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    var onTapCoordinate: ((CLLocationCoordinate2D) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsCompass = true
        map.showsScale = false
        map.setRegion(region, animated: false)
        map.delegate = context.coordinator
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        map.addGestureRecognizer(tapRecognizer)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self
        if abs(uiView.region.center.latitude - region.center.latitude) > 0.00001
            || abs(uiView.region.center.longitude - region.center.longitude) > 0.00001
        {
            uiView.setRegion(region, animated: false)
        }

        let existingPins = uiView.annotations.filter { !($0 is MKUserLocation) }
        if let selectedCoordinate {
            uiView.removeAnnotations(existingPins)
            let pin = MKPointAnnotation()
            pin.coordinate = selectedCoordinate
            uiView.addAnnotation(pin)
        } else if !existingPins.isEmpty {
            uiView.removeAnnotations(existingPins)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ComposerLegacyMapView
        init(parent: ComposerLegacyMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }

        @objc func handleMapTap(_ recognizer: UITapGestureRecognizer) {
            guard let mapView = recognizer.view as? MKMapView else { return }
            let point = recognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.selectedCoordinate = coordinate
            parent.onTapCoordinate?(coordinate)
        }
    }
}
