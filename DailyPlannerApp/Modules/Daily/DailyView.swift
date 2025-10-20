import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DailyViewModel()
    @State private var content = ""
    @State private var selectedMood: String?
    @State private var showCalendar = false
    
    let moods = ["😊", "😐", "😔", "😴", "🤩", "😤"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Date selector
                    dateHeader
                    
                    ScrollView {
                        VStack(spacing: Theme.spacingL) {
                            // Mood selector
                            moodSelector
                            
                            // Editor
                            textEditor
                            
                            // Previous entries
                            if !viewModel.entries.isEmpty {
                                previousEntries
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Daily")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.setModelContext(modelContext)
                loadCurrentContent()
            }
            .onChange(of: viewModel.selectedDate) { _, _ in
                loadCurrentContent()
            }
            .sheet(isPresented: $showCalendar) {
                CalendarPickerView(selectedDate: $viewModel.selectedDate)
            }
        }
    }
    
    private var dateHeader: some View {
        HStack {
            Button(action: { viewModel.selectDate(Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.defaultAccentTeal)
            }
            
            Spacer()
            
            Button(action: { showCalendar = true }) {
                Text(viewModel.selectedDate.formatted(style: .long))
                    .font(.headline)
                    .foregroundColor(.defaultTextPrimary)
            }
            
            Spacer()
            
            Button(action: { viewModel.selectDate(Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.defaultAccentTeal)
            }
        }
        .padding()
        .background(Color.defaultSecondaryBackground)
    }
    
    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("How are you feeling?")
                .font(.subheadline)
                .foregroundColor(.defaultTextSecondary)
            
            HStack(spacing: Theme.spacingM) {
                ForEach(moods, id: \.self) { mood in
                    Button(action: { selectedMood = mood }) {
                        Text(mood)
                            .font(.system(size: 32))
                            .opacity(selectedMood == mood ? 1 : 0.4)
                            .scaleEffect(selectedMood == mood ? 1.2 : 1)
                            .animation(.spring(response: 0.3), value: selectedMood)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var textEditor: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Today's Entry")
                .font(.headline)
                .foregroundColor(.defaultTextPrimary)
            
            TextEditor(text: $content)
                .frame(minHeight: 200)
                .padding(Theme.spacingS)
                .background(Color.defaultPrimaryBackground)
                .cornerRadius(Theme.cornerRadiusS)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusS)
                        .stroke(Color.defaultAccentTeal.opacity(0.3), lineWidth: 1)
                )
            
            Button(action: saveEntry) {
                Text("Save Entry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.defaultAccentTeal)
                    .cornerRadius(Theme.cornerRadiusM)
            }
        }
        .cardStyle()
    }
    
    private var previousEntries: some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            Text("Previous Entries")
                .font(.headline)
                .foregroundColor(.defaultTextPrimary)
            
            ForEach(viewModel.entries.prefix(5)) { entry in
                if !Calendar.current.isDate(entry.date, inSameDayAs: viewModel.selectedDate) {
                    EntryRowView(entry: entry, onTap: {
                        viewModel.selectDate(entry.date)
                    }, onToggleFavorite: {
                        viewModel.toggleFavorite(entry)
                    }, onDelete: {
                        viewModel.deleteEntry(entry)
                    })
                }
            }
        }
        .cardStyle()
    }
    
    private func loadCurrentContent() {
        if let entry = viewModel.currentEntry {
            content = entry.content
            selectedMood = entry.mood
        } else {
            content = ""
            selectedMood = nil
        }
    }
    
    private func saveEntry() {
        viewModel.saveEntry(content: content, mood: selectedMood)
        hideKeyboard()
    }
}

struct EntryRowView: View {
    let entry: DailyEntry
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.spacingXS) {
                HStack {
                    if let mood = entry.mood {
                        Text(mood)
                            .font(.title3)
                    }
                    
                    Text(entry.date.formatted(style: .medium))
                        .font(.subheadline)
                        .foregroundColor(.defaultTextSecondary)
                    
                    Spacer()
                    
                    Button(action: onToggleFavorite) {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                            .foregroundColor(.defaultAccentTeal)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                Text(entry.content)
                    .font(.body)
                    .foregroundColor(.defaultTextPrimary)
                    .lineLimit(3)
            }
            .padding(Theme.spacingM)
            .background(Color.defaultPrimaryBackground)
            .cornerRadius(Theme.cornerRadiusS)
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Choose Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

