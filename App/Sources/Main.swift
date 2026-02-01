import SwiftUI

struct Message: Identifiable, Codable {
    let id = UUID()
    let user: String
    let text: String
    let timestamp: Date
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
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(message.text)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.user)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(message.text)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var username = "Anon"
    @State private var showUsernamePrompt = true
    @State private var socket: URLSessionWebSocketTask?
    @State private var isConnected = false
    @State private var connectionError: String?
    
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
                            .fill(isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                
                // Messages area
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
                        if let lastMessage = messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                
                // Connection error banner
                if let error = connectionError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error)
                            .font(.caption)
                        Spacer()
                        Button("Retry") {
                            connectionError = nil
                            connectWebSocket()
                        }
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $newMessage)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .onSubmit {
                                if !newMessage.isEmpty && isConnected {
                                    sendMessage()
                                }
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 44, height: 44)
                                .background(isConnected && !newMessage.isEmpty ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .disabled(newMessage.isEmpty || !isConnected)
                        .animation(.easeInOut(duration: 0.2), value: newMessage.isEmpty || !isConnected)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: connectWebSocket)
        .alert("Enter Your Name", isPresented: $showUsernamePrompt) {
            TextField("Username", text: $username)
            Button("Continue") {
                showUsernamePrompt = false
                if username.trimmingCharacters(in: .whitespaces).isEmpty {
                    username = "Anon"
                }
            }
        } message: {
            Text("Choose a name to use in the chat.")
        }
        .onDisappear {
            socket?.cancel(with: .goingAway, reason: nil)
        }
    }
    
    // MARK: - WebSocket Functions
    
    private func connectWebSocket() {
        guard let url = URL(string: "wss://temple-chat-backend.onrender.com/ws") else {
            connectionError = "Invalid server URL"
            return
        }
        
        let request = URLRequest(url: url)
        socket = URLSession.shared.webSocketTask(with: request)
        socket?.resume()
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionError = nil
        }
        
        receiveMessages()
        print("WebSocket connected to: \(url)")
    }
    
    private func receiveMessages() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                    if let data = text.data(using: .utf8) {
                        do {
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            let msg = try decoder.decode(Message.self, from: data)
                            DispatchQueue.main.async {
                                self.messages.append(msg)
                            }
                        } catch {
                            print("Failed to decode message: \(error)")
                        }
                    }
                case .data(let data):
                    print("Received binary data: \(data.count) bytes")
                @unknown default:
                    break
                }
                // Continue listening
                self.receiveMessages()
                
            case .failure(let error):
                print("WebSocket error: \(error)")
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.connectionError = "Connection lost. Tap Retry to reconnect."
                }
                // Auto-reconnect after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if !self.isConnected {
                        self.connectWebSocket()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty, isConnected, let socket = socket else {
            return
        }
        
        // Clear input immediately
        newMessage = ""
        
        let msg = Message(
            user: username,
            text: messageText,
            timestamp: Date()
        )
        
        // Optimistic UI update
        let optimisticMessage = msg
        DispatchQueue.main.async {
            self.messages.append(optimisticMessage)
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(msg)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "EncodingError", code: 1, userInfo: nil)
            }
            
            socket.send(.string(jsonString)) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Failed to send message: \(error)")
                        // Remove optimistic message on failure
                        self?.messages.removeAll { $0.id == optimisticMessage.id }
                        self?.newMessage = messageText // Restore message for retry
                        self?.connectionError = "Send failed. Tap to retry."
                    }
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
            // Remove optimistic message
            messages.removeAll { $0.id == optimisticMessage.id }
            newMessage = messageText // Restore message
        }
    }
}

// Preview for Xcode
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
