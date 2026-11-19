import Foundation
import MultipeerConnectivity
import Combine

/// Service that advertises and scans for SOS beacons over direct Wi-Fi and Bluetooth mesh.
/// Operates 100% offline without cellular or internet infrastructure.
class MeshSOSService: NSObject, ObservableObject {
    // Unique Bonjour service type: max 15 chars, lowercase ASCII and hyphens only
    private let serviceType = "er-mesh-sos"

    private let myPeerID: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?

    @Published var isAdvertising = false
    @Published var isScanning = false
    @Published var detectedBeacons: [MeshSOSBeacon] = []
    @Published var myActiveBeacon: MeshSOSBeacon?
    @Published var connectedPeersCount: Int = 0

    override init() {
        // Use device name as peer ID
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    // MARK: - Broadcast My SOS Beacon
    func startBroadcasting(senderName: String, region: String, status: String, note: String) {
        let beacon = MeshSOSBeacon(
            id: UUID().uuidString,
            senderName: senderName.isEmpty ? "Unknown User" : senderName,
            region: region,
            emergencyStatus: status,
            note: note,
            timestamp: Date()
        )
        self.myActiveBeacon = beacon

        // Setup session
        if session == nil {
            session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
            session?.delegate = self
        }

        // Discovery info limited to small strings in advertiser payload
        let discoveryInfo: [String: String] = [
            "id": beacon.id,
            "name": String(beacon.senderName.prefix(30)),
            "reg": String(beacon.region.prefix(20)),
            "stat": String(beacon.emergencyStatus.prefix(30)),
            "time": String(beacon.timestamp.timeIntervalSince1970)
        ]

        advertiser?.stopAdvertisingPeer()
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isAdvertising = true

        // Also broadcast full payload to any already connected peers
        broadcastBeaconPayload(beacon)
    }

    func stopBroadcasting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
        myActiveBeacon = nil
    }

    // MARK: - Scan for Nearby Beacons
    func startScanning() {
        if session == nil {
            session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
            session?.delegate = self
        }

        browser?.stopBrowsingForPeers()
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isScanning = true
    }

    func stopScanning() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isScanning = false
    }

    func clearDetections() {
        detectedBeacons.removeAll()
    }

    private func broadcastBeaconPayload(_ beacon: MeshSOSBeacon) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(beacon)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("MeshSOSService: Failed to send beacon payload: \(error)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MeshSOSService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Automatically accept invitations from any emergency peers in disaster mesh
        invitationHandler(true, self.session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("MeshSOSService: Failed to start advertising: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isAdvertising = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MeshSOSService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            // Attempt to build beacon from discoveryInfo metadata immediately without requiring connection
            if let info = info,
               let id = info["id"],
               let name = info["name"],
               let region = info["reg"],
               let status = info["stat"] {
                let time = Double(info["time"] ?? "") ?? Date().timeIntervalSince1970
                let beacon = MeshSOSBeacon(
                    id: id,
                    senderName: name,
                    region: region,
                    emergencyStatus: status,
                    note: "",
                    timestamp: Date(timeIntervalSince1970: time)
                )

                if let index = self.detectedBeacons.firstIndex(where: { $0.id == beacon.id || $0.senderName == beacon.senderName }) {
                    self.detectedBeacons[index] = beacon
                } else {
                    self.detectedBeacons.insert(beacon, at: 0)
                }
            }

            // Also invite the peer to establish session to exchange notes and full details
            if let session = self.session {
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Optional: Keep beacons in list with timestamp, or keep them active for disaster awareness
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("MeshSOSService: Failed to start browsing: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isScanning = false
        }
    }
}

// MARK: - MCSessionDelegate
extension MeshSOSService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeersCount = session.connectedPeers.count

            // If we connected to a peer and we are currently broadcasting, transmit full beacon
            if state == .connected, let myBeacon = self.myActiveBeacon {
                self.broadcastBeaconPayload(myBeacon)
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            do {
                let beacon = try JSONDecoder().decode(MeshSOSBeacon.self, from: data)
                if let index = self.detectedBeacons.firstIndex(where: { $0.id == beacon.id || $0.senderName == beacon.senderName }) {
                    self.detectedBeacons[index] = beacon
                } else {
                    self.detectedBeacons.insert(beacon, at: 0)
                }
            } catch {
                print("MeshSOSService: Could not decode beacon: \(error)")
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
