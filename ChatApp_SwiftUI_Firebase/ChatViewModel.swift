//
//  ChatViewModel.swift
//  ChatApp_SwiftUI_Firebase
//

import Foundation
import Observation

@MainActor
@Observable
final class ChatViewModel {

    var messages: [Message] = []
    var inputText = ""

    // Firebase가 아니라 "저장소" 추상화에만 의존한다.
    private let repository: MessageRepository

    // 테스트 시 가짜 저장소를 주입하기 위한 기본 이니셜라이저.
    init(repository: MessageRepository) {
        self.repository = repository
    }

    // 실제 앱에서는 채팅방 ID만 넘기면 Firestore 저장소를 자동으로 구성한다.
    convenience init(chatRoomId: String) {
        self.init(repository: FirestoreMessageRepository(chatRoomId: chatRoomId))
    }

    /// 메시지 실시간 스트림을 구독한다.
    /// View의 .task 안에서 호출하면, 화면이 사라질 때 자동으로 취소되어 리스너도 해제된다.
    func observeMessages() async {
        do {
            for try await messages in repository.messagesStream() {
                self.messages = messages
            }
        } catch {
            print("Error observing messages: \(error)")
        }
    }

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        do {
            // 저장만 하면, 갱신된 목록은 리스너가 자동으로 반영한다.
            try await repository.sendMessage(text: text)
        } catch {
            print("Error adding document: \(error)")
        }
    }
}
