import SwiftUI
import NukeUI // نستخدم مكتبة NukeUI الموجودة في التطبيق لتحميل الصور بكفاءة

// 1. هيكل قراءة مصدر التطبيقات بالكامل
struct VoidStoreRepo: Codable {
    let apps: [VoidStoreApp]
}

// 2. هيكل بيانات التطبيق الواحد (يدعم المتغيرات الاختيارية في حال كان هناك نقص في ملف JSON)
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

// 3. واجهة المتجر
struct StoreView: View {
    // المتغيرات التي تتحكم في الشاشة
    @State private var apps: [VoidStoreApp] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    // شاشة التحميل
                    ProgressView("جاري تحميل التطبيقات...")
                        .font(.headline)
                } else if let errorMessage = errorMessage {
                    // شاشة الخطأ مع زر إعادة المحاولة
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text("حدث خطأ في الاتصال")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("إعادة المحاولة") {
                            fetchApps()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    // قائمة التطبيقات بعد نجاح التحميل
                    List(apps) { app in
                        HStack(spacing: 16) {
                            // تحميل الأيقونة باستخدام مكتبة NukeUI
                            if let iconString = app.iconURL, let url = URL(string: iconString) {
                                LazyImage(url: url) { state in
                                    if let image = state.image {
                                        image.resizable().scaledToFit()
                                    } else if state.error != nil {
                                        Image(systemName: "app.dashed")
                                            .resizable().scaledToFit().foregroundColor(.gray)
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(14)
                            } else {
                                Image(systemName: "app.dashed")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
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
                            
                            // زر التحميل
                            Button(action: {
                                // سيتم ربط هذا الزر بمحرك Feather قريباً!
                                print("رابط التحميل هو: \(app.downloadURL ?? "لا يوجد رابط")")
                            }) {
                                Text("GET")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Void Store")
            .onAppear {
                // جلب البيانات بمجرد ظهور الشاشة
                fetchApps()
            }
        }
    }
    
    // 4. وظيفة جلب البيانات من الإنترنت
    func fetchApps() {
        isLoading = true
        errorMessage = nil
        
        // الرابط الخاص بك
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
                
                guard let data = data else {
                    errorMessage = "لم يتم استلام أي بيانات."
                    return
                }
                
                // محاولة تحويل JSON إلى كود يفهمه التطبيق
                do {
                    let repo = try JSONDecoder().decode(VoidStoreRepo.self, from: data)
                    self.apps = repo.apps
                } catch {
                    errorMessage = "فشل في قراءة بيانات التطبيقات."
                    print("خطأ في قراءة JSON: \(error)")
                }
            }
        }
        .resume()
    }
}
