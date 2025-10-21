import SwiftUI
import SwiftData

struct ChecklistsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ChecklistsViewModel()
    @State private var showingAddSheet = false
    @State private var selectedItem: ChecklistItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filters
                    filterBar
                    
                    // List
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingM) {
                            ForEach(viewModel.filteredChecklists) { item in
                                ChecklistCardView(
                                    item: item,
                                    onToggle: { viewModel.toggleCompletion(item) },
                                    onTap: { selectedItem = item },
                                    onToggleFavorite: { viewModel.toggleFavorite(item) },
                                    onDelete: { viewModel.deleteChecklist(item) }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Checklists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.defaultAccentTeal)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddChecklistView(viewModel: viewModel)
            }
            .sheet(item: $selectedItem) { item in
                ChecklistDetailView(item: item, viewModel: viewModel)
            }
        }
    }
    
    private var filterBar: some View {
        HStack(spacing: Theme.spacingM) {
            Toggle("Show Completed", isOn: $viewModel.showCompleted)
                .font(.caption)
            
            Toggle("Sort by Priority", isOn: $viewModel.sortByPriority)
                .font(.caption)
        }
        .padding()
        .background(Color.defaultSecondaryBackground)
    }
}

struct ChecklistCardView: View {
    let item: ChecklistItem
    let onToggle: () -> Void
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacingM) {
                // Checkbox
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(item.isCompleted ? .defaultAccentTeal : .defaultTextSecondary)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    HStack {
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.defaultTextPrimary)
                            .strikethrough(item.isCompleted)
                        
                        if item.priority > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<item.priority, id: \.self) { _ in
                                    Image(systemName: "exclamationmark")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    if !item.subtasks.isEmpty {
                        let completed = item.subtasks.filter { $0.isCompleted }.count
                        Text("\(completed)/\(item.subtasks.count) subtasks")
                            .font(.caption)
                            .foregroundColor(.defaultTextSecondary)
                    }
                    
                    if let dueDate = item.dueDate {
                        Text("Due: \(dueDate.formatted(style: .short))")
                            .font(.caption)
                            .foregroundColor(dueDate < Date() ? .red : .defaultTextSecondary)
                    }
                }
                
                Spacer()
                
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.defaultAccentTeal)
                        .font(.caption)
                }
            }
            .padding(Theme.spacingM)
            .background(Color.defaultSecondaryBackground)
            .cornerRadius(Theme.cornerRadiusM)
        }
        .contextMenu {
            Button(action: onToggleFavorite) {
                Label(item.isFavorite ? "Unfavorite" : "Favorite", systemImage: item.isFavorite ? "star.slash" : "star")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ChecklistsViewModel
    @State private var title = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: Theme.spacingM) {
                    TextField("Checklist title", text: $title)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color.defaultSecondaryBackground)
                        .cornerRadius(Theme.cornerRadiusM)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !title.isEmpty {
                            viewModel.createChecklist(title: title)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct ChecklistDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ChecklistItem
    let viewModel: ChecklistsViewModel
    
    @State private var title: String
    @State private var notes: String
    @State private var priority: Int
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var newSubtaskTitle = ""
    
    init(item: ChecklistItem, viewModel: ChecklistsViewModel) {
        self.item = item
        self.viewModel = viewModel
        _title = State(initialValue: item.title)
        _notes = State(initialValue: item.notes ?? "")
        _priority = State(initialValue: item.priority)
        _dueDate = State(initialValue: item.dueDate)
        _hasDueDate = State(initialValue: item.dueDate != nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacingM) {
                        // Title
                        TextField("Title", text: $title)
                            .font(.title2)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        // Priority
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Priority")
                                .font(.caption)
                                .foregroundColor(.defaultTextSecondary)
                            
                            Picker("Priority", selection: $priority) {
                                Text("None").tag(0)
                                Text("Low").tag(1)
                                Text("Medium").tag(2)
                                Text("High").tag(3)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                        .background(Color.defaultSecondaryBackground)
                        .cornerRadius(Theme.cornerRadiusM)
                        
                        // Due date
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Toggle("Set Due Date", isOn: $hasDueDate)
                            
                            if hasDueDate {
                                DatePicker("Due Date", selection: Binding(
                                    get: { dueDate ?? Date() },
                                    set: { dueDate = $0 }
                                ), displayedComponents: [.date])
                            }
                        }
                        .padding()
                        .background(Color.defaultSecondaryBackground)
                        .cornerRadius(Theme.cornerRadiusM)
                        
                        // Notes
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.defaultTextSecondary)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .padding(Theme.spacingS)
                                .background(Color.defaultPrimaryBackground)
                                .cornerRadius(Theme.cornerRadiusS)
                        }
                        .padding()
                        .background(Color.defaultSecondaryBackground)
                        .cornerRadius(Theme.cornerRadiusM)
                        
                        // Subtasks
                        VStack(alignment: .leading, spacing: Theme.spacingM) {
                            Text("Subtasks")
                                .font(.headline)
                            
                            ForEach(item.subtasks) { subtask in
                                HStack {
                                    Button(action: { viewModel.toggleSubtask(item, subtask: subtask) }) {
                                        Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.defaultAccentTeal)
                                    }
                                    
                                    Text(subtask.title)
                                        .strikethrough(subtask.isCompleted)
                                    
                                    Spacer()
                                    
                                    Button(action: { viewModel.deleteSubtask(item, subtask: subtask) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(Theme.spacingS)
                                .background(Color.defaultPrimaryBackground)
                                .cornerRadius(Theme.cornerRadiusS)
                            }
                            
                            HStack {
                                TextField("Add subtask", text: $newSubtaskTitle)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                Button(action: addSubtask) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.defaultAccentTeal)
                                }
                                .disabled(newSubtaskTitle.isEmpty)
                            }
                            .padding()
                            .background(Color.defaultPrimaryBackground)
                            .cornerRadius(Theme.cornerRadiusS)
                        }
                        .padding()
                        .background(Color.defaultSecondaryBackground)
                        .cornerRadius(Theme.cornerRadiusM)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        viewModel.updateChecklist(
            item,
            title: title,
            notes: notes.isEmpty ? nil : notes,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil
        )
    }
    
    private func addSubtask() {
        if !newSubtaskTitle.isEmpty {
            viewModel.addSubtask(item, title: newSubtaskTitle)
            newSubtaskTitle = ""
        }
    }
}

