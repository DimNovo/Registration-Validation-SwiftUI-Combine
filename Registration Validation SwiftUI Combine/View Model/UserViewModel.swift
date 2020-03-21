//
//  UserViewModel.swift
//  Registration Validation SwiftUI Combine
//
//  Created by Dmitry Novosyolov on 20/03/2020.
//  Copyright © 2020 Dmitry Novosyolov. All rights reserved.
//

import SwiftUI
import Combine

final class UserViewModel: ObservableObject {
    
    typealias ValidatePublisher = AnyPublisher<Bool, Never>
    
    @Published var username = ""
    @Published var password = ""
    @Published var passwordAgain = ""
    
    @Published var usernameMessage = ""
    @Published var passwordMessage = ""
    @Published var passwordLevelMerssage = ""
    @Published var passwordLevelColor: Color = .red
    @Published var isValid = false
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    private var isPasswordEmptyPublisher: ValidatePublisher {
        $password
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .eraseToAnyPublisher()
    }
    
    private var isPasswordEqualsPublisher: ValidatePublisher {
        Publishers.CombineLatest($password, $passwordAgain)
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .map { $0 == $1 }
            .eraseToAnyPublisher()
    }
    
    private var passwordLevelPublisher: AnyPublisher<PasswordLevel, Never> {
        $password
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { self.passwordLevel($0)}
            .eraseToAnyPublisher()
    }
    
    private var isPasswordOkPublisher: ValidatePublisher {
        passwordLevelPublisher
            .map {
                switch $0 {
                case .reasonable, .strong, .veryStrong:
                    self.passwordLevelMerssage = $0.rawValue
                    self.passwordLevelColor = $0.color
                    return true
                case .weak:
                    self.passwordLevelMerssage = $0.rawValue
                    self.passwordLevelColor = $0.color
                    return false
                }
        }
        .eraseToAnyPublisher()
    }
    
    private var isPasswordValidPublisher: AnyPublisher<PasswordCheck, Never> {
        Publishers.CombineLatest3(isPasswordEmptyPublisher, isPasswordEqualsPublisher, isPasswordOkPublisher)
            .map { isEmpty, areEquals, isStrongEnough in
                if isEmpty { return .empty }
                if !areEquals { return .noMatch }
                if !isStrongEnough { return .notStrongEnough }
                return .valid
        }
        .eraseToAnyPublisher()
    }
    
    private var isUsernameValidPublisher: ValidatePublisher {
        $username
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4 }
            .eraseToAnyPublisher()
    }
    
    private var isFormValidatePublisher: ValidatePublisher {
        Publishers.CombineLatest(isUsernameValidPublisher, isPasswordValidPublisher)
            .map { usernameIsValid, passwordIsValid in
                usernameIsValid && passwordIsValid == .valid
        }
        .eraseToAnyPublisher()
    }
    
    init() {
        isUsernameValidPublisher
            .receive(on: RunLoop.main)
            .map { $0 ? "" : "User name must at least have 3 characters"}
            .assign(to: \.usernameMessage, on: self)
            .store(in: &cancellableSet)
        
        isPasswordValidPublisher
            .receive(on: RunLoop.main)
            .map { passwordCheck in
                switch passwordCheck {
                case .valid:
                    return ""
                case .empty:
                    return "Password is empty"
                case .noMatch:
                    return "Password don't match"
                case .notStrongEnough:
                    return "Password not strong enough"
                }
        }
        .assign(to: \.passwordMessage, on: self)
        .store(in: &cancellableSet)
        
        isFormValidatePublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValid, on: self)
            .store(in: &cancellableSet)
    }
}

extension UserViewModel {
    
    private enum PasswordCheck {
        case valid
        case empty
        case noMatch
        case notStrongEnough
    }
    
    private enum PasswordLevel: String {
        case weak = "weak"
        case reasonable = "reasonable"
        case strong = "strong"
        case veryStrong = "veryStrong"
        
        var color: Color {
            switch self {
            case .weak: return .red
            case .reasonable: return .yellow
            case .strong: return .orange
            case .veryStrong: return .green
            }
        }
    }
    
    private func passwordLevel(_ password: String) -> PasswordLevel {
        let text = password.replacingOccurrences(of: " ", with: "", options: .regularExpression)
        var level: PasswordLevel?
        if 6 < text.count && 24 > text.count { level = .reasonable }
        if level == .reasonable &&
            (text.filter { $0.isUppercase }.count >= 3) &&
            (text.filter { $0.isLowercase }.count >= 3) { level = .strong }
        if level == .strong &&
            (text.filter { $0.isNumber }.count > 3) { level = .veryStrong }
        guard level != nil else { return .weak }
        return level!
    }
}
