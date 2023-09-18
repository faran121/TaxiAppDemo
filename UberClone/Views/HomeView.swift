//
//  HomeView.swift
//  UberClone
//
//  Created by Maliks on 16/09/2023.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import Firebase

struct HomeView: View {
    
    @State var map = MKMapView()
    @State var manager = CLLocationManager()
    @State var alert = false
    @State var source: CLLocationCoordinate2D!
    @State var destination: CLLocationCoordinate2D!
    @State var name = ""
    @State var distance = ""
    @State var time = ""
    @State var show = false
    @State var loading = false
    @State var book = false
    @State var doc = ""
    @State var data: Data = .init(count: 0)
    @State var search = false
    
    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(self.destination != nil ? "Destination" : "Pick a Location")
                                .font(.title)
                            
                            if self.destination != nil {
                                Text(self.name)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            self.search.toggle()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                    .background(Color.white)
                    
                    MapView(map: self.$map, manager: self.$manager, alert: self.$alert, source: self.$source, destination: self.$destination, name: self.$name, distance: self.$distance, time: self.$time, show: self.$show)
                        .onAppear {
                            self.manager.requestAlwaysAuthorization()
                        }
                }
                
                if self.destination != nil && self.show {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Destination")
                                        .fontWeight(.bold)
                                    Text(self.name)
                                    Text("Distance - " + self.distance + " Km")
                                    Text("Time - " + self.time + " Minutes")
                                }
                                
                                Spacer()
                            }
                            
                            Button(action: {
                                self.loading.toggle()
                                self.bookRide()
                            }) {
                                Text("Book Now")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .frame(width: UIScreen.main.bounds.width / 2)
                            }
                            .background(Color.red)
                            .clipShape(Capsule())
                        }
                        
                        Button(action: {
                            self.map.removeOverlays(self.map.overlays)
                            self.map.removeAnnotations(self.map.annotations)
                            self.show.toggle()
                            self.destination = nil
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom)
                    .background(Color.white)
                }
            }
            
            if self.loading {
                LoaderView()
            }
            
            if self.book {
                BookedView(data: self.$data, doc: self.$doc, loading: self.$loading, book: self.$book)
            }
            
            if self.search {
                SearchView(map: self.$map, source: self.$source, destination: self.$destination, name: self.$name, distance: self.$distance, time: self.$time, show: self.$search, detail: self.$show)
            }
        }
        .ignoresSafeArea(.all)
        .alert(isPresented: self.$alert) { () -> Alert in
            Alert(title: Text("Error"), message: Text("Please Enable Location in Settings"), dismissButton: .destructive(Text("Ok")))
        }
    }
    
    func bookRide() {
        let db = Firestore.firestore()
        let doc = db.collection("Booking").document()
        
        self.doc = doc.documentID
        
        let from = GeoPoint(latitude: self.source.latitude, longitude: self.source.longitude)
        let to = GeoPoint(latitude: self.destination.latitude, longitude: self.destination.longitude)
        
        doc.setData(["name":"UberClone", "from":from, "to":to, "distance":self.distance, "fair":(self.distance as NSString).floatValue * 1.2]) { (error) in
            
            if error != nil {
                print((error?.localizedDescription)!)
                return
            }
            
            let filter = CIFilter(name: "CIQRCodeGenerator")
            filter?.setValue(self.doc.data(using: .ascii), forKey: "inputMessage")
            
            let image = UIImage(ciImage: (filter?.outputImage?.transformed(by: CGAffineTransform(scaleX: 5, y: 5)))!)
            
            self.data = image.pngData()!
            
            self.loading.toggle()
            self.book.toggle()
        }
    }
}
