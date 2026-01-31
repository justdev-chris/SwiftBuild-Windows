import SwiftUI

@main
struct TempleChatApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}

struct Message: Identifiable, Codable {
    let id = UUID()
    let user: String
    let text: String
    let timestamp: Date
}

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var username = "Anon"
    @State private var showUsernamePrompt = true
    @State private var socket: URLSessionWebSocketTask?
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("🔐")
                Text("Temple Chat")
                    .font(.headline)
                Text("🔐")
            }
            .padding()
            .background(Color.black)
            
            // Messages
            ScrollView {
                LazyVStack {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.user == username {
                                Spacer()
                                Text(msg.text)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                VStack(alignment: .leading) {
                                    Text(msg.user).font(.caption)
                                    Text(msg.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Input
            HStack {
                TextField("Message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    sendMessage()
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
        .onAppear(perform: connectWebSocket)
        .alert("Enter Temple Name", isPresented: $showUsernamePrompt) {
            TextField("Username", text: $username)
            Button("Enter", action: {})
        }
    }
    
    func connectWebSocket() {
        guard let url = URL(string: "ws://YOUR_PYTHON_SERVER_IP:8765") else { return }
        socket = URLSession.shared.webSocketTask(with: url)
        socket?.resume()
        receiveMessages()
    }
    
    func receiveMessages() {
        socket?.receive { result in
            switch result {
            case .success(let message):
                if case .string(let text) = message,
                   let data = text.data(using: .utf8),
                   let msg = try? JSONDecoder().decode(Message.self, from: data) {
                    DispatchQueue.main.async {
                        messages.append(msg)
                    }
                }
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
            receiveMessages()
        }
    }
    
    func sendMessage() {
        let msg = Message(user: username, text: newMessage, timestamp: Date())
        guard let data = try? JSONEncoder().encode(msg),
              let json = String(data: data, encoding: .utf8) else { return }
        
        socket?.send(.string(json)) { error in
            if let error = error {
                print("Send error: \(error)")
            } else {
                DispatchQueue.main.async {
                    messages.append(msg)
                    newMessage = ""
                }
            }
        }
    }
}
