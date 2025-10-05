import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - ContentView (Watchlist)
            ContentView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Journal Tab
            StockJounalView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(1)
            
            // HeatMap Tab
            StockHeatMapView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("HeatMap", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .accentColor(.blue) // Tab bar selection color
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Customize selected tab item
            appearance.selectionIndicatorTintColor = UIColor.systemBlue
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
