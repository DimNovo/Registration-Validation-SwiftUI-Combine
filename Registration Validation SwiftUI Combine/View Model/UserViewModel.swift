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
    @Published var passwordLevelMessage = ""
    @Published var passwordLevelColor: Color?
    @Published var isValid = false
    
    private var cancellableSet: Set<AnyCancellable> = []
    
    private var isPasswordEmptyPublisher: ValidatePublisher {
        $password
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .eraseToAnyPublisher()
    }
    
    private var isPasswordEqualsPublisher: ValidatePublisher {
        Publishers.CombineLatest($password, $passwordAgain)
            .map { $0 == $1 }
            .eraseToAnyPublisher()
    }
    
    private var passwordLevelPublisher: AnyPublisher<PasswordLevel, Never> {
        $password
            .removeDuplicates()
            .map { [unowned self] in self.passwordLevel($0)}
            .eraseToAnyPublisher()
    }
    
    private var isPasswordValidPublisher: AnyPublisher<PasswordCheck, Never> {
        Publishers.CombineLatest3(isPasswordEmptyPublisher, isPasswordEqualsPublisher, passwordLevelPublisher)
            .map { [weak self] isEmpty, areEquals, isStrongEnough in
                if isEmpty { self?.passwordMessage = PasswordCheck.empty.rawValue; return .empty }
                if !areEquals { self?.passwordMessage = PasswordCheck.notMatch.rawValue; return .notMatch }
                self?.passwordMessage = PasswordCheck.valid.rawValue
                return .valid
        }
        .eraseToAnyPublisher()
    }
    
    private var isUsernameValidPublisher: ValidatePublisher {
        $username
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4 }
            .handleEvents(receiveOutput: { [weak self] in $0 ? (self?.usernameMessage = "") : (self?.usernameMessage = "User name must at least have 3 characters")})
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
        isFormValidatePublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValid, on: self)
            .store(in: &cancellableSet)
    }
}

extension UserViewModel {
    
    private enum PasswordCheck: String {
        case valid = ""
        case empty = "Password is empty"
        case notMatch = "Password don't match"
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
        
        switch level {
            case .reasonable, .strong, .veryStrong:
                passwordLevelMessage = level!.rawValue
                passwordLevelColor = level?.color
                return level!
            default:
                level = .weak
                passwordLevelMessage = level!.rawValue
                passwordLevelColor = level?.color
                return level!
        }
    }
}
