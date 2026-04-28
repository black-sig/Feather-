import SwiftUI

// نموذج يمثل شكل التطبيق داخل Void Store
struct VoidApp: Identifiable {
    let id = UUID()
    let name: String
    let developer: String
    let iconName: String
    let version: String
}

struct StoreView: View {
    // تطبيقات تجريبية مؤقتة لنرى كيف يبدو التصميم قبل ربط السيرفر الخارجي
    @State private var apps: [VoidApp] = [
        VoidApp(name: "تطبيق حصري", developer: "Void Team", iconName: "star.fill", version: "1.0.0"),
        VoidApp(name: "لعبة محترفة", developer: "Void Team", iconName: "gamecontroller.fill", version: "2.1.0")
    ]
    
    var body: some View {
        NavigationView {
            List(apps) { app in
                HStack(spacing: 16) {
                    // مربع الأيقونة (سنستبدله لاحقاً بمكتبة تقرأ صيغ SVG)
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: app.iconName)
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    
                    // معلومات التطبيق
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(app.developer)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // زر التنزيل
                    Button(action: {
                        // هنا سنربط زر التحميل بمحرك التوقيع الخاص بـ Feather
                        print("تم طلب تحميل: \(app.name)")
                    }) {
                        Text("GET")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Void Store")
            .listStyle(PlainListStyle())
        }
    }
}
