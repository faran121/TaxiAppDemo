//
//  UberCloneApp.swift
//  UberClone
//
//  Created by Maliks on 15/09/2023.
//

import SwiftUI
import Firebase

@main
struct UberCloneApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
