import SwiftUI
import SwiftData

@main
struct DailyPlannerApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    let modelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
            ChecklistItem.self,
            PlannerItem.self,
            DailyEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if appViewModel.isLoading {
                    EmptyView()
                        .transition(.opacity)
                }
                else if appViewModel.showWebView, let url = appViewModel.webURL {
                    WebViewContainer(url: url)
                        .preferredColorScheme(.dark)
                        .transition(.opacity)
                }
                else if appViewModel.showOfflineScreen, let url = appViewModel.webURL {
                    WebViewContainer(url: url)
                        .transition(.opacity)
                }
                else if appViewModel.showNativeFallback {
                    MainTabView()
                        .modelContainer(modelContainer)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: appViewModel.isLoading)
            .animation(.easeInOut(duration: 0.5), value: appViewModel.showWebView)
            .animation(.easeInOut(duration: 0.5), value: appViewModel.showOfflineScreen)
            .animation(.easeInOut(duration: 0.5), value: appViewModel.showNativeFallback)
            .task {
                await appViewModel.initialize()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyView()
                .tabItem {
                    Label("Daily", systemImage: "book")
                }
                .tag(0)
            
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(1)
            
            ChecklistsView()
                .tabItem {
                    Label("Checklists", systemImage: "checklist")
                }
                .tag(2)
            
            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }
                .tag(3)
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
                .tag(4)
        }
        .tint(.defaultAccentTeal)
    }
}

//struct SplashView: View {
//    @State private var scale: CGFloat = 0.5
//    @State private var opacity: Double = 0
//    
//    var body: some View {
//        ZStack {
//            Color.defaultPrimaryBackground
//                .ignoresSafeArea()
//            
//            VStack(spacing: Theme.spacingL) {
//                Image(systemName: "book.pages")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 100, height: 100)
//                    .foregroundColor(.defaultAccentTeal)
//                    .scaleEffect(scale)
//                    .opacity(opacity)
//                
//                Text("Daily Planner")
//                    .font(.system(size: Theme.fontSizeHero, weight: .bold))
//                    .foregroundColor(.defaultTextPrimary)
//                    .opacity(opacity)
//                
//                Text("Organize your life")
//                    .font(.system(size: Theme.fontSizeMedium))
//                    .foregroundColor(.defaultTextSecondary)
//                    .opacity(opacity)
//            }
//        }
//        .statusBar(hidden: true)
//        .onAppear {
//            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
//                scale = 1.0
//                opacity = 1.0
//            }
//        }
//    }
//}
//
