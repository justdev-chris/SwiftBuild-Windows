import SwiftUI
import UniformTypeIdentifiers

struct RevokeDomain: Identifiable, Codable {
    var id = UUID()
    let domain: String
    var isEnabled: Bool
}

class AntiRevokeManager: ObservableObject {
    @Published var isEnabled = false
    @Published var domains: [RevokeDomain] = [
        RevokeDomain(domain: "ocsp.apple.com", isEnabled: true),
        RevokeDomain(domain: "ocsp2.apple.com", isEnabled: true),
        RevokeDomain(domain: "crl.apple.com", isEnabled: true),
        RevokeDomain(domain: "crl.entrust.net", isEnabled: true),
        RevokeDomain(domain: "crl3.digicert.com", isEnabled: true),
        RevokeDomain(domain: "crl4.digicert.com", isEnabled: true),
        RevokeDomain(domain: "ocsp.digicert.com", isEnabled: true),
        RevokeDomain(domain: "ocsp.entrust.net", isEnabled: true),
        RevokeDomain(domain: "valid.apple.com", isEnabled: true),
        RevokeDomain(domain: "gdmf.apple.com", isEnabled: true),
        RevokeDomain(domain: "mesu.apple.com", isEnabled: true),
        RevokeDomain(domain: "xp.apple.com", isEnabled: true)
    ]
    
    func generateProfile() -> URL {
        let fileManager = FileManager.default
        let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let profileURL = docsURL.appendingPathComponent("antirevoke.mobileconfig")
        
        let enabledDomains = domains.filter { $0.isEnabled }.map { $0.domain }
        
        let domainStrings = enabledDomains.map { "<string>\($0)</string>" }.joined(separator: "\n                            ")
        
        let profileContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>PayloadContent</key>
            <array>
                <dict>
                    <key>PayloadDescription</key>
                    <string>Blocks Apple revocation servers</string>
                    <key>PayloadDisplayName</key>
                    <string>Anti-Revoke DNS</string>
                    <key>PayloadIdentifier</key>
                    <string>com.justdev-chris.antirevoke.dns</string>
                    <key>PayloadType</key>
                    <string>com.apple.dnsSettings.managed</string>
                    <key>PayloadUUID</key>
                    <string>\(UUID().uuidString)</string>
                    <key>PayloadVersion</key>
                    <integer>1</integer>
                    <key>DNSSettings</key>
                    <dict>
                        <key>DNSProtocol</key>
                        <string>HTTPS</string>
                        <key>ServerURL</key>
                        <string>https://dns.adguard.com/dns-query</string>
                        <key>ServerAddresses</key>
                        <array>
                            <string>94.140.14.14</string>
                            <string>94.140.15.15</string>
                        </array>
                        <key>SupplementalMatchDomains</key>
                        <array>
                            \(domainStrings)
                        </array>
                    </dict>
                </dict>
            </array>
            <key>PayloadDescription</key>
            <string>Blocks Apple OCSP and revocation servers to prevent app revokes</string>
            <key>PayloadDisplayName</key>
            <string>Anti-Revoke</string>
            <key>PayloadIdentifier</key>
            <string>com.justdev-chris.antirevoke</string>
            <key>PayloadRemovalDisallowed</key>
            <false/>
            <key>PayloadType</key>
            <string>Configuration</string>
            <key>PayloadUUID</key>
            <string>\(UUID().uuidString)</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
        </plist>
        """
        
        try? profileContent.write(to: profileURL, atomically: true, encoding: .utf8)
        return profileURL
    }
    
    func installProfile() {
        let profileURL = generateProfile()
        
        let activityVC = UIActivityViewController(
            activityItems: [profileURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct DashboardView: View {
    @ObservedObject var manager: AntiRevokeManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        manager.installProfile()
                    }) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundColor(.blue)
                            Text("Generate & Install Profile")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("This will create a configuration profile that blocks Apple revocation servers. Install it in Settings app.")
                }
                
                Section("Status") {
                    let enabledCount = manager.domains.filter { $0.isEnabled }.count
                    HStack {
                        Text("Blocked domains")
                        Spacer()
                        Text("\(enabledCount)/\(manager.domains.count)")
                            .foregroundColor(enabledCount > 0 ? .green : .red)
                    }
                }
                
                Section("How it works") {
                    Text("The profile configures DNS to block Apple's OCSP servers, preventing app revocation checks.")
                        .font(.caption)
                    
                    Text("No VPN or extension needed - just DNS settings")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Section("Instructions") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("1. Tap 'Generate & Install Profile'", systemImage: "1.circle")
                        Label("2. Share to yourself (AirDrop/Mail)", systemImage: "2.circle")
                        Label("3. Open on this device", systemImage: "3.circle")
                        Label("4. Go to Settings → Profile Downloaded", systemImage: "4.circle")
                        Label("5. Tap Install", systemImage: "5.circle")
                    }
                    .font(.caption)
                }
            }
            .navigationTitle("Anti-Revoke")
        }
    }
}

struct DomainsView: View {
    @ObservedObject var manager: AntiRevokeManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach($manager.domains) { $domain in
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(domain.isEnabled ? .green : .gray)
                            Text(domain.domain)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Toggle("", isOn: $domain.isEnabled)
                                .labelsHidden()
                        }
                    }
                } header: {
                    Text("Blocked Domains")
                } footer: {
                    Text("Toggle domains on/off. Only enabled domains are blocked when profile is installed.")
                }
            }
            .navigationTitle("Blocklist")
        }
    }
}

struct ContentView: View {
    @StateObject private var manager = AntiRevokeManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(manager: manager)
                .tabItem { Label("Protection", systemImage: "shield") }
                .tag(0)
            
            DomainsView(manager: manager)
                .tabItem { Label("Blocked", systemImage: "list.bullet") }
                .tag(1)
        }
    }
}

@main
struct AntiRevokeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
