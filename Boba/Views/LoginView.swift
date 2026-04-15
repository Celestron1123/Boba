//  LoginView.swift
//  Boba
//
//  Created by Julia Maia on 4/15/26.
//

import SwiftUI
import FirebaseFirestore

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
