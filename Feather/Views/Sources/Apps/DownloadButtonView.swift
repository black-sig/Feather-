import SwiftUI
import Combine
import NukeUI

// 1. نماذج قراءة البيانات من الرابط (JSON)
struct VoidStoreRepo: Codable {
    let apps: [VoidStoreApp]
}

struct VoidStoreApp: Codable, Identifiable {
    var id: String { bundleIdentifier ?? name }
    let name: String
    let developerName: String?
    let iconURL: String?
    let downloadURL: String?
    let version: String?
    let localizedDescription: String?
    let bundleIdentifier: String?
}

// 2. زر التحميل الذكي الخاص بمتجر Void (متصل بمحرك Feather)
struct VoidDownloadButton: View {
    let urlString: String
    let uniqueId: String
    
    // استدعاء محرك التحميل الخاص بالتطبيق
    @ObservedObject private var downloadManager = DownloadManager.shared
    @State private var downloadProgress: Double = 0
    @State private var cancellable: AnyCancellable?

    var body: some View {
        ZStack {
            // التحقق مما إذا كان التطبيق قيد التحميل حالياً
            if let currentDownload = downloadManager.getDownload(by: uniqueId) {
                ZStack {
                    // رسم دائرة تقدم التحميل
                    Circle()
                        .trim(from: 0, to: downloadProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 31, height: 31)
                        .animation(.smooth, value: downloadProgress)

                    Image(systemName: downloadProgress >= 0.75 ? "archivebox" : "square.fill")
                        .foregroundStyle(.tint)
                        .font(.footnote).bold()
                }
                .onTapGesture {
                    if downloadProgress <= 0.75 {
                        downloadManager.cancelDownload(currentDownload) // إلغاء التحميل
                    }
                }
            } else {
                // زر GET لطلب التحميل
                Button {
                    if let url = URL(string: urlString) {
                        _ = downloadManager.startDownload(from: url, id: uniqueId)
                    }
                } label: {
                    Text("GET")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .onAppear(perform: setupObserver)
        .onDisappear { cancellable?.cancel() }
        .onChange(of: downloadManager.downloads.description) { _ in
            setupObserver()
        }
    }

    // وظيفة مراقبة تقدم التحميل لملء الدائرة
    private func setupObserver() {
        cancellable?.cancel()
        guard let download = downloadManager.getDownload(by: uniqueId) else {
            downloadProgress = 0
            return
        }
        downloadProgress = download.overallProgress

        let publisher = Publishers.CombineLatest(
            download.$progress,
            download.$unpackageProgress
        )

        cancellable = publisher.sink { _, _ in
            downloadProgress = download.overallProgress
        }
    }
}

// 3. واجهة المتجر الرئيسية
struct StoreView: View {
    @State private var apps: [VoidStoreApp] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("جاري تحميل Void Store...")
                } else if let errorMessage = errorMessage {
                    VStack {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("حدث خطأ")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("إعادة المحاولة") { fetchApps() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(apps) { app in
                        HStack(spacing: 16) {
                            // تحميل الأيقونة
                            if let iconString = app.iconURL, let url = URL(string: iconString) {
                                LazyImage(url: url) { state in
                                    if let image = state.image {
                                        image.resizable().scaledToFit()
                                    } else {
                                        Image(systemName: "app.dashed")
                                            .resizable().scaledToFit().foregroundColor(.gray.opacity(0.5))
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(14)
                            }
                            
                            // معلومات التطبيق
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text(app.developerName ?? "مطور غير معروف")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // دمج زر التحميل الذكي هنا
                            if let downloadUrl = app.downloadURL, let uniqueId = app.bundleIdentifier {
                                VoidDownloadButton(urlString: downloadUrl, uniqueId: uniqueId)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Void Store")
            .onAppear {
                fetchApps()
            }
        }
    }
    
    // 4. وظيفة جلب البيانات
    func fetchApps() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://fastsign.dev/repo.json") else {
            errorMessage = "الرابط غير صالح."
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else { return }
                do {
                    let repo = try JSONDecoder().decode(VoidStoreRepo.self, from: data)
                    self.apps = repo.apps
                } catch {
                    errorMessage = "فشل في قراءة بيانات التطبيقات."
                }
            }
        }
        .resume()
    }
}
