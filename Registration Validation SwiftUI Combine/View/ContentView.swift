//
//  ContentView.swift
//  Registration Validation SwiftUI Combine
//
//  Created by Dmitry Novosyolov on 20/03/2020.
//  Copyright © 2020 Dmitry Novosyolov. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var userVM = UserViewModel()
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text(userVM.usernameMessage != "" ?
                        userVM.usernameMessage : "User name")
                        .font(userVM.usernameMessage != "" ? .caption : .headline)
                        .foregroundColor(userVM.usernameMessage != "" ? .red : .blue)) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(userVM.usernameMessage != "" ? .red : .blue)
                                    .opacity(0.5)
                                TextField("user name", text: $userVM.username)
                            }
                    }
                    Section(header: HStack {
                        Text(userVM.passwordMessage != "" ?
                            userVM.passwordMessage :"Password")
                            .font(userVM.passwordMessage != "" ? .caption : .headline)
                            .foregroundColor(userVM.passwordMessage != "" ? .red : .green)
                        Spacer()
                        Text(userVM.password.isEmpty ? "" : userVM.passwordLevelMessage)
                            .foregroundColor(userVM.passwordLevelColor)
                            .font(.custom("Courier", size: 15))
                    }) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(userVM.passwordMessage != "" ? .red : .green)
                                .opacity(0.4)
                            SecureField("password", text: $userVM.password)
                        }
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(userVM.passwordMessage != "" ? .red : .green)
                                .opacity(0.4)
                            SecureField("password again", text: $userVM.passwordAgain)
                                .disabled(userVM.password.isEmpty)
                        }
                    }
                }
                .imageScale(.large)
                .font(.headline)
                .navigationBarTitle("Registration Form")
                
                Button(action: { print("User: \(self.userVM.username) is logged in")}) {
                    Text("Registration")
                        .font(.title)
                        .bold()
                        .foregroundColor(userVM.isValid ? .primary : .clear)
                        .padding(.horizontal, 90)
                        .padding(.vertical, 10)
                        .background(userVM.isValid ? Color.blue : Color.gray.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .circular))
                }
                .animation(.default)
                .disabled(!userVM.isValid)
                .offset(y: UIScreen.main.bounds.height / 3)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .colorScheme(.dark)
    }
}
