import SwiftUI
import PhotosUI
import UIKit

struct IOSContentView: View {
    @StateObject private var transfer = TransferService()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var photoFileURL: URL?
    @State private var dragOffset: CGSize = .zero
    @State private var isPreparingPhoto = false

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.07).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                    Text("swaap")
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Circle()
                        .fill(transfer.connectedDevice == nil ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(transfer.connectedDevice == nil ? "Searching" : "Connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 14)

                Spacer()

                VStack(spacing: 12) {
                    Text("SEND IT LIKE THIS.")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2.4)
                        .foregroundStyle(.white.opacity(0.45))

                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.055))
                            .frame(width: 280, height: 350)
                            .overlay {
                                RoundedRectangle(cornerRadius: 30)
                                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                            }

                        if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 254, height: 324)
                                .clipShape(RoundedRectangle(cornerRadius: 23))
                                .overlay(alignment: .bottom) {
                                    LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
                                        .clipShape(RoundedRectangle(cornerRadius: 23))
                                }
                        } else {
                            VStack(spacing: 14) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 43, weight: .light))
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("Your next photo")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("Choose one to get started")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }

                        if previewImage != nil {
                            Image(systemName: "arrow.left.and.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.black.opacity(0.42), in: Circle())
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                .padding(18)
                        }
                    }
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width / 28)))
                    .shadow(color: .black.opacity(0.35), radius: 30, y: 18)
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { dragOffset = $0.translation }
                            .onEnded { value in
                                let distance = value.translation.width
                                guard abs(distance) > 105 else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { dragOffset = .zero }
                                    return
                                }
                                guard let photoFileURL else {
                                    withAnimation(.spring()) { dragOffset = .zero }
                                    transfer.reportStatus("Choose a photo before sending")
                                    return
                                }
                                let fling = CGSize(width: distance > 0 ? 520 : -520, height: value.translation.height * 0.4)
                                withAnimation(.easeIn(duration: 0.16)) { dragOffset = fling }
                                transfer.send(fileURL: photoFileURL)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) { dragOffset = .zero }
                                }
                            }
                    )

                    HStack {
                        Label("DRAG TO SEND", systemImage: "arrow.left")
                        Spacer()
                        Label("DRAG TO SEND", systemImage: "arrow.right")
                    }
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 280)
                }

                Spacer()

                VStack(spacing: 14) {
                    Text(transfer.status)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(minHeight: 32)

                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        HStack(spacing: 9) {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                            Text(previewImage == nil ? "Choose a photo" : "Choose another photo")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 17))
                    }
                    .disabled(isPreparingPhoto)

                    Text("Your photo goes directly to your Mac. No cloud upload.")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
        .onAppear { transfer.start() }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                isPreparingPhoto = true
                defer { isPreparingPhoto = false }
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SwaapOutgoing", isDirectory: true)
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    let file = directory.appendingPathComponent("\(UUID().uuidString).jpg")
                    let jpegData = image.jpegData(compressionQuality: 0.95) ?? data
                    try jpegData.write(to: file, options: .atomic)
                    previewImage = image
                    photoFileURL = file
                    transfer.reportStatus(transfer.connectedDevice == nil ? "Photo ready — waiting for your Mac" : "Photo ready — drag it to either edge")
                } catch {
                    transfer.reportStatus("Couldn't load that photo: \(error.localizedDescription)")
                }
            }
        }
    }
}
