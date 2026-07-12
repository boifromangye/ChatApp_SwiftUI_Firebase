//
//  ContentView.swift
//  ChatApp_SwiftUI_Firebase
//
//  Created by 권태우 on 7/6/26.
//

import SwiftUI

struct ContentView: View {

    // TODO: 채팅방 목록 화면이 생기면 선택된 방의 ID를 전달하도록 교체.
    //       지금은 스크린샷의 chatroom001 문서 ID를 임시로 사용한다.
    @State private var viewModel = ChatViewModel(chatRoomId: "NkRWSIHCJRoWZ2CPDFmv")

    var body: some View {
        VStack(spacing: 0) {
            List(viewModel.messages) { message in
                Text(message.text)
                    .frame(maxWidth: .infinity,
                           alignment: message.sender ? .leading : .trailing)
            }

            HStack {
                TextField("메시지 입력", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)

                Button("전송") {
                    Task {
                        await viewModel.send()
                    }
                }
            }
            .padding()
            .task {
                await viewModel.observeMessages()
            }
        }
    }
}

#Preview {
    ContentView()
}
