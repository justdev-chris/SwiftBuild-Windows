import SwiftUI

struct Message: Identifiable, Codable {
    var id = UUID()  // CHANGED: var instead of let
    let user: String
    let text: String
    let timestamp: Date
    
    // Add CodingKeys to fix the warning
    enum CodingKeys: String, CodingKey {
        case id, user, text, timestamp
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("You")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.user)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(18)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
    }
}

@main
struct TempleChatApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }
    }
}

class WebSocketManager: ObservableObject {
    @Published var isConnected = false
    @Published var connectionError: String?
    private var socket: URLSessionWebSocketTask?
    
    func connect(to urlString: String) {
        guard let url = URL(string: urlString) else {
            connectionError = "Invalid URL"
            return
        }
        
        let request = URLRequest(url: url)
        socket = URLSession.shared.webSocketTask(with: request)
        socket?.resume()
        isConnected = true
        connectionError = nil
    }
    
    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
    
    func send(_ message: String, completion: @escaping (Error?) -> Void) {
        socket?.send(.string(message), completionHandler: completion)
    }
    
    func receive(completion: @escaping (Result<String, Error>) -> Void) {
        socket?.receive { result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "WebSocket", code: 0)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

struct ChatView: View {
    @StateObject private var socketManager = WebSocketManager()
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var username = "Anon"
    @State private var showUsernamePrompt = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Epsteins Kids Locked In His Temple")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Connection status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(socketManager.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(socketManager.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, isCurrentUser: message.user == username)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                
                // Connection error
                if let error = socketManager.connectionError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error)
                            .font(.caption)
                        Spacer()
                        Button("Retry") {
                            socketManager.connect(to: "wss://temple-chat-backend.onrender.com/ws")
                        }
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                }
                
                // Input
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        TextField("Message...", text: $newMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                                .frame(width: 44, height: 44)
                                .background(newMessage.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .disabled(newMessage.isEmpty || !socketManager.isConnected)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            socketManager.connect(to: "wss://temple-chat-backend.onrender.com/ws")
            startReceiving()
        }
        .onDisappear {
            socketManager.disconnect()
        }
        .alert("Enter Name", isPresented: $showUsernamePrompt) {
            TextField("Username", text: $username)
            Button("OK") {
                showUsernamePrompt = false
            }
        }
    }
    
    private func startReceiving() {
        guard socketManager.isConnected else { return }
        
        socketManager.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let text):
                if let data = text.data(using: .utf8),
                   let message = try? JSONDecoder().decode(Message.self, from: data) {
                    DispatchQueue.main.async {
                        self.messages.append(message)
                    }
                }
                // Continue listening
                self.startReceiving()
                
            case .failure:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startReceiving()
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty, socketManager.isConnected else { return }
        
        let message = Message(
            user: username,
            text: messageText,
            timestamp: Date()
        )
        
        // Clear input
        newMessage = ""
        
        // Optimistic update
        messages.append(message)
        
        // Send via WebSocket
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(message)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }
            
            socketManager.send(jsonString) { error in
                if let error = error {
                    print("Send failed: \(error)")
                }
            }
        } catch {
            print("Encode failed: \(error)")
        }
    }
}
