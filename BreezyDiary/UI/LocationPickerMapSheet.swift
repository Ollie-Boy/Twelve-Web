import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerMapSheet: View {
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

    var body: some View {
        NavigationStack {
            ZStack {
                LegacyMapView(region: $region)
                    .ignoresSafeArea(edges: .bottom)

                Image(systemName: "mappin.circle.fill")
                    .font(BreezyTheme.appFont(size: 34, weight: .semibold))
                    .foregroundStyle(BreezyTheme.primaryBlue)
                    .shadow(radius: 4)

                VStack {
                    Text("Move map, then tap Use Center")
                        .font(BreezyTheme.appFont(size: 12, weight: .medium))
                        .foregroundStyle(BreezyTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())

                    if isResolving {
                        ProgressView()
                    } else if let errorText {
                        Text(errorText)
                            .font(BreezyTheme.appFont(size: 12))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    } else if !pickedAddressText.isEmpty {
                        Text(pickedAddressText)
                            .font(BreezyTheme.appFont(size: 12))
                            .foregroundStyle(BreezyTheme.textPrimary)
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
                                    .background(BreezyTheme.surface, in: Circle())
                            }
                            Button {
                                useMapCenter()
                            } label: {
                                Image(systemName: "checkmark")
                                    .frame(width: 36, height: 36)
                                    .background(BreezyTheme.primaryBlue, in: Circle())
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
            region.center = coordinate
        }
    }

    private func useMapCenter() {
        resolveAddress(for: region.center)
    }

    private func resolveAddress(for coordinate: CLLocationCoordinate2D) {
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
            onPickAddress(address)
            dismiss()
        }
    }
}

private struct LegacyMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.showsCompass = true
        map.showsScale = false
        map.setRegion(region, animated: false)
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if abs(uiView.region.center.latitude - region.center.latitude) > 0.00001
            || abs(uiView.region.center.longitude - region.center.longitude) > 0.00001
        {
            uiView.setRegion(region, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LegacyMapView
        init(parent: LegacyMapView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

