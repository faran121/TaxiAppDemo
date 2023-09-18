//
//  SearchView.swift
//  UberClone
//
//  Created by Maliks on 15/09/2023.
//

import SwiftUI
import CoreLocation
import MapKit

struct SearchView: View {
    
    @State var result: [SearchData] = []
    @State var txt = ""
    @Binding var map: MKMapView
    @Binding var source: CLLocationCoordinate2D!
    @Binding var destination: CLLocationCoordinate2D!
    @Binding var name: String
    @Binding var distance: String
    @Binding var time: String
    @Binding var show: Bool
    @Binding var detail: Bool
    
    var body: some View {
        GeometryReader {reader in
            VStack(spacing: 0) {
                Spacer()
                
                SearchBar(map: self.$map, source: self.$source, destination: self.$destination, name: self.$name, distance: self.$distance, time: self.$time, result: self.$result, txt: self.$txt)
                
                Divider()
                
                if self.txt != "" {
                    List(self.result) { i in
                        VStack(alignment: .leading) {
                            Text(i.name)
                            Text(i.address)
                                .font(.caption)
                        }
                        .onTapGesture {
                            self.destination = i.coordinate
                            self.updateMap()
                            self.show.toggle()
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height / 2)
                }
                Spacer()
            }
            .padding(.horizontal, 25)
        }
        .background(Color.black.opacity(0.25).edgesIgnoringSafeArea(.all).onTapGesture {
            self.show.toggle()
        })
    }
    
    func updateMap() {
        
        let point = MKPointAnnotation()
        point.subtitle = "Destination"
        point.coordinate = destination
        
        let decoder = CLGeocoder()
        decoder.reverseGeocodeLocation(CLLocation(latitude: destination.latitude, longitude: destination.longitude)) { (places, error) in
            if error != nil {
                print((error?.localizedDescription)!)
                return
            }
            
            self.name = places?.first?.name ?? ""
            point.title = places?.first?.name ?? ""
            
            self.detail = true
        }
        
        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: self.source))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        req.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: req)
        
        directions.calculate { (dir, error) in
            if error != nil {
                print((error?.localizedDescription)!)
                return
            }
            
            let polyline = dir?.routes[0].polyline
            
            let distance = dir?.routes[0].distance as! Double
            self.distance = String(format: "%.1f", distance / 1000)
            
            let time = dir?.routes[0].expectedTravelTime as! Double
            self.time = String(format: "%.1f", time / 60)

            self.map.removeOverlays(self.map.overlays)
            self.map.addOverlay(polyline!)
            self.map.setRegion(MKCoordinateRegion(polyline!.boundingMapRect), animated: true)
        }
        
        self.map.removeAnnotations(self.map.annotations)
        self.map.addAnnotation(point)
    }
}

struct SearchBar: UIViewRepresentable {

    @Binding var map: MKMapView
    @Binding var source: CLLocationCoordinate2D!
    @Binding var destination: CLLocationCoordinate2D!
    @Binding var name: String
    @Binding var distance: String
    @Binding var time: String
    @Binding var result: [SearchData]
    @Binding var txt: String
    
    func makeCoordinator() -> Coordinator {
        return SearchBar.Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let view = UISearchBar()
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.delegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        var parent: SearchBar
        
        init(parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            
            self.parent.txt = searchText
            
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = searchText
            req.region = self.parent.map.region
            
            let search = MKLocalSearch(request: req)
            
            DispatchQueue.main.async {
                self.parent.result.removeAll()
            }
            
            search.start { (res, error) in
                if error != nil {
                    print((error?.localizedDescription)!)
                    return
                }
                
                for i in 0..<res!.mapItems.count {
                    let temp = SearchData(id: i, name: res!.mapItems[i].name!, address: res!.mapItems[i].placemark.title!, coordinate: res!.mapItems[i].placemark.coordinate)
                    
                    self.parent.result.append(temp)
                }
            }
        }
    }
}

struct SearchData: Identifiable {
    var id: Int
    var name: String
    var address: String
    var coordinate: CLLocationCoordinate2D
}

//struct SearchView_Previews: PreviewProvider {
//    @State static var show = false
//    static var previews: some View {
//        SearchView(show: $show)
//    }
//}


