//
//  ChangeUsernameView.swift
//  BeenThere
//
//  Created by Jared Jones on 11/3/23.
//

//import SwiftUI
//import FirebaseAuth
//import Firebase
//
//struct ChangeUsernameView: View {
//    @Environment(\.dismiss) var dismiss
//    @AppStorage("username") var currentUsername = ""
//    @EnvironmentObject var authViewModel: AuthViewModel
//    @EnvironmentObject var viewModel: SettingsViewModel
//    @FocusState private var isUsernameFieldFocused: Bool
//
//   
//    var body: some View {
//        HStack {
//            Text("Username: ")
//                .foregroundStyle(.tertiary)
//                .onAppear {
//                    changeViewModel.newUsername = currentUsername
//                }
//            TextField("New Username", text: $changeViewModel.newUsername)
//                .onChange(of: changeViewModel.newUsername) {
//                    changeViewModel.checkAndSetUsername()
//                }
//                .textInputAutocapitalization(.never)
//                .autocorrectionDisabled()
//        }
//        
//        if changeViewModel.invalidUsernameReason != "" {
//            Text(changeViewModel.invalidUsernameReason)
//                .fontWeight(.black)
//            
//        } else if changeViewModel.isUsernameTaken {
//            Text("Username is already taken")
//                .fontWeight(.black)
//        }
////        if isCheckingUsername {
////            //                ProgressView()
////            
////        } else {
////            if !(!isUsernameValid || isCheckingUsername || isUsernameTaken) {
////                Button("Change Username") {
////                    if authViewModel.isAuthenticated && authViewModel.isSignedIn {
////                        setUsernameInFirestore()
////                    }
////                }
////                .fontWeight(.black)
////                .disabled(isChangeButtonDisabled)
////                .buttonStyle(.bordered)
////                .tint(.green)
////            }
////            
////        }
//        
//    }
//}
//
//#Preview {
//    ChangeUsernameView()
//}


