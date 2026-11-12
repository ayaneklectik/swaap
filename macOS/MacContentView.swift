import SwiftUI
import AppKit

struct MacContentView: View {
    @StateObject private var transfer = TransferService()

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.07).ignoresSafeArea()
            VStack(spacing: 22) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 11))
                    Text("swaap")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Circle()
                        .fill(transfer.connectedDevice == nil ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(transfer.connectedDevice == nil ? "Waiting" : "Connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer(minLength: 4)

                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.055))
                        .frame(width: 330, height: 190)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                        }

                    if let file = transfer.lastReceivedFile, let image = NSImage(contentsOf: file) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 164)
                            .clipShape(RoundedRectangle(cornerRadius: 17))
                    } else {
                        VStack(spacing: 13) {
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(.white.opacity(0.75))
                            Text("Ready to receive")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text("Send a photo from your iPhone")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.42))
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text(transfer.status)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    if let file = transfer.lastReceivedFile {
                        Text(file.path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.36))
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: 420, minHeight: 42)

                Spacer(minLength: 4)

                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                    Text("Encrypted, direct transfer. Files are saved in Downloads/Swaap.")
                }
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.36))
            }
            .padding(28)
        }
        .frame(minWidth: 480, minHeight: 380)
        .preferredColorScheme(.dark)
        .onAppear { transfer.start() }
    }
}
