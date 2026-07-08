//
//  ContentView.swift
//  ChatApp_SwiftUI_Firebase
//
//  Created by 권태우 on 7/6/26.
//

import SwiftUI
import FirebaseFirestore

struct Message: Identifiable {
    let id: String            // Firestore documentID
    let text: String
    let sender: Bool   // true: 수신(좌측 정렬), false: 발신(우측 정렬)
    let timestamp: Date
}

struct ContentView: View {
    
    private let db = Firestore.firestore()
    
    @State private var messages: [Message] = []
    @State private var inputText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            List(messages) { message in
                Text(message.text)
                    .frame(maxWidth: .infinity, alignment: message.sender ? .leading : .trailing)
            }

            HStack {
                TextField("메시지 입력", text: $inputText)
                    .textFieldStyle(.roundedBorder)

                Button("전송") {
                    Task {
                        await send()
                        await loadMessages()
                    }
                }
            }
            .padding()
            .task {
                await loadMessages()
            }
        }
    }

    private func send() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        do {
            // Create document and get its ID with timestamp
            let ref = try await db.collection("messages").addDocument(data: [
                "sender": false, // 내가 보낸 메시지면 false
                "text": text,
                "timestamp": Timestamp(date: Date())
            ])
            // Append locally with Firestore ID and timestamp
            let now = Date()
            let newMessage = Message(id: ref.documentID, text: text, sender: false, timestamp: now)
            messages.append(newMessage)
        } catch {
            print("Error adding document: \(error)")
        }
        inputText = ""
    }
    
    private func loadMessages() async {
        do {
            let snapshot = try await db.collection("messages").order(by: "timestamp", descending: false).getDocuments()
            var loaded: [Message] = []
            for document in snapshot.documents {
                let data = document.data()
                let text = data["text"] as? String ?? ""
                let sender = data["sender"] as? Bool ?? false
                let ts = data["timestamp"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                loaded.append(Message(id: document.documentID, text: text, sender: sender, timestamp: date))
            }
            messages = loaded
        } catch {
            print("Error getting documents: \(error)")
        }
    }
}
