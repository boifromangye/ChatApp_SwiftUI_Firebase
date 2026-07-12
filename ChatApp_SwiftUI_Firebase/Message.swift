//
//  Message.swift
//  ChatApp_SwiftUI_Firebase
//

import Foundation

struct Message: Identifiable {
    let id: String            // Firestore documentID
    let text: String
    let sender: Bool   // true: 수신(좌측 정렬), false: 발신(우측 정렬)
    let timestamp: Date
}
