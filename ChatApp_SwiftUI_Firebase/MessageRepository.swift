//
//  MessageRepository.swift
//  ChatApp_SwiftUI_Firebase
//

import Foundation
import FirebaseFirestore

/// 메시지 데이터 입출력을 담당하는 저장소 추상화.
/// ViewModel은 이 프로토콜에만 의존하므로, 실제 데이터 출처(Firebase 등)를 몰라도 된다.
protocol MessageRepository {
    /// 메시지 목록의 실시간 변경을 스트림으로 방출한다.
    /// 새 메시지가 추가되면 갱신된 전체 목록이 다시 방출된다.
    func messagesStream() -> AsyncThrowingStream<[Message], Error>
    /// 새 메시지를 저장한다. (저장 결과는 리스너가 자동으로 반영한다)
    func sendMessage(text: String) async throws
}

/// Firestore를 사용하는 MessageRepository 구현체.
/// Firebase 관련 코드는 오직 이 파일에만 존재한다.
///
/// 구조: chatrooms/{chatRoomId}/messages/{messageId}
final class FirestoreMessageRepository: MessageRepository {

    private let db = Firestore.firestore()
    private let chatRoomId: String

    init(chatRoomId: String) {
        self.chatRoomId = chatRoomId
    }

    /// 이 채팅방의 messages 하위 컬렉션 참조.
    private var messagesCollection: CollectionReference {
        db.collection("chatrooms")
            .document(chatRoomId)
            .collection("messages")
    }

    func messagesStream() -> AsyncThrowingStream<[Message], Error> {
        AsyncThrowingStream { continuation in
            // 실시간 리스너 등록: 하위 컬렉션이 바뀔 때마다 콜백이 호출된다.
            let registration = messagesCollection
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else {
                        continuation.yield([])
                        return
                    }
                    let messages = snapshot.documents.map { document in
                        let data = document.data()
                        // Firestore의 "content" 필드를 도메인 모델의 text로 매핑한다.
                        return Message(
                            id: document.documentID,
                            text: data["content"] as? String ?? "",
                            sender: data["sender"] as? Bool ?? false,
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    continuation.yield(messages)
                }

            // 스트림 소비가 끝나거나(화면 종료 등) 취소되면 리스너를 해제한다.
            continuation.onTermination = { _ in
                registration.remove()
            }
        }
    }

    func sendMessage(text: String) async throws {
        try await messagesCollection.addDocument(data: [
            "sender": false, // 내가 보낸 메시지면 false
            "content": text,
            "timestamp": Timestamp(date: Date())
        ])
    }
}
