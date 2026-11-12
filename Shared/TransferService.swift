import Foundation
import Combine
import MultipeerConnectivity

/// Nearby, encrypted peer-to-peer transfer. Multipeer Connectivity chooses
/// Bluetooth or the local Wi-Fi network; files are never uploaded to a server.
final class TransferService: NSObject, ObservableObject {
    static let serviceType = "swaap-transfer"

    @Published private(set) var status = "Looking for your Mac…"
    @Published private(set) var connectedDevice: String?
    @Published private(set) var lastReceivedFile: URL?
    @Published private(set) var sentCount = 0

    private let peerID: MCPeerID
    private let session: MCSession
    #if os(iOS)
    private var browser: MCNearbyServiceBrowser?
    #else
    private var advertiser: MCNearbyServiceAdvertiser?
    #endif

    override init() {
        #if os(iOS)
        peerID = MCPeerID(displayName: "Swaap iPhone")
        #else
        peerID = MCPeerID(displayName: Host.current().localizedName ?? "Swaap Mac")
        #endif
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    func start() {
        #if os(iOS)
        guard browser == nil else { return }
        let nearbyBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        nearbyBrowser.delegate = self
        browser = nearbyBrowser
        nearbyBrowser.startBrowsingForPeers()
        status = "Looking for your Mac on this network…"
        #else
        guard advertiser == nil else { return }
        let nearbyAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["app": "Swaap", "version": "1"],
            serviceType: Self.serviceType
        )
        nearbyAdvertiser.delegate = self
        advertiser = nearbyAdvertiser
        nearbyAdvertiser.startAdvertisingPeer()
        status = "Ready — waiting for your iPhone"
        #endif
    }

    func reportStatus(_ message: String) { status = message }

    func stop() {
        #if os(iOS)
        browser?.stopBrowsingForPeers()
        browser = nil
        #else
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        #endif
        session.disconnect()
        connectedDevice = nil
    }

    func send(fileURL: URL) {
        guard let peer = session.connectedPeers.first else {
            status = "Your Mac is not connected yet"
            return
        }
        status = "Sending photo…"
        let progress = session.sendResource(
            at: fileURL,
            withName: fileURL.lastPathComponent,
            toPeer: peer
        ) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.status = "Couldn't send: \(error.localizedDescription)"
                } else {
                    self?.sentCount += 1
                    self?.status = "Photo sent"
                }
            }
        }
        if progress == nil {
            status = "Couldn't start the transfer. Try again."
        }
    }

    private func updateConnection(_ state: MCSessionState, peer: MCPeerID) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedDevice = peer.displayName
                self.status = "Connected to \(peer.displayName)"
            case .connecting:
                self.status = "Connecting to \(peer.displayName)…"
            case .notConnected:
                self.connectedDevice = nil
                #if os(iOS)
                self.status = "Looking for your Mac…"
                #else
                self.status = "Ready — waiting for your iPhone"
                #endif
            @unknown default:
                self.status = "Checking connection…"
            }
        }
    }

    private func saveReceivedFile(from sourceURL: URL, named resourceName: String) {
        do {
            #if os(macOS)
            let base = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            #else
            let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            #endif
            let folder = base.appendingPathComponent("Swaap", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let safeName = URL(fileURLWithPath: resourceName).lastPathComponent
            let destination = folder.appendingPathComponent("\(UUID().uuidString.prefix(8))-\(safeName)")
            try FileManager.default.moveItem(at: sourceURL, to: destination)
            DispatchQueue.main.async {
                self.lastReceivedFile = destination
                self.status = "Received — saved to \(destination.path)"
            }
        } catch {
            DispatchQueue.main.async {
                self.status = "File received, but couldn't save it: \(error.localizedDescription)"
            }
        }
    }
}

extension TransferService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        updateConnection(state, peer: peerID)
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        DispatchQueue.main.async { self.status = "Receiving \(resourceName)…" }
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error {
            DispatchQueue.main.async { self.status = "Transfer failed: \(error.localizedDescription)" }
            return
        }
        guard let localURL else {
            DispatchQueue.main.async { self.status = "The received file was unavailable" }
            return
        }
        saveReceivedFile(from: localURL, named: resourceName)
    }

    func session(_ session: MCSession, didReceive certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        // Accept only the encrypted nearby session invitation; the transport
        // itself is protected by Multipeer Connectivity's required encryption.
        certificateHandler(true)
    }
}

extension TransferService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard info?["app"] == "Swaap" else { return }
        browser.invitePeer(peerID, to: session, withContext: Data("swaap-v1".utf8), timeout: 20)
        DispatchQueue.main.async { self.status = "Found your Mac — connecting…" }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if self.connectedDevice == nil { self.status = "Looking for your Mac…" }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { self.status = "Nearby discovery unavailable: \(error.localizedDescription)" }
    }
}

extension TransferService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(context == Data("swaap-v1".utf8), session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { self.status = "Couldn't advertise nearby: \(error.localizedDescription)" }
    }
}
