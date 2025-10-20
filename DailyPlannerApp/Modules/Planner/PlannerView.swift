import SwiftUI
import SwiftData

struct PlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PlannerViewModel()
    @State private var showingAddSheet = false
    @State private var selectedItem: PlannerItem?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // View mode selector
                    viewModeSelector
                    
                    // Date navigation
                    dateNavigator
                    
                    // Items list
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingM) {
                            if viewModel.filteredItems.isEmpty {
                                emptyState
                            } else {
                                ForEach(viewModel.filteredItems) { item in
                                    PlannerItemCard(
                                        item: item,
                                        onTap: { selectedItem = item },
                                        onToggle: { viewModel.toggleCompletion(item) },
                                        onDelete: { viewModel.deleteItem(item) }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.goToToday() }) {
                        Text("Today")
                            .foregroundColor(.defaultAccentTeal)
                    }
                }
                
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
                AddPlannerItemView(viewModel: viewModel, initialDate: viewModel.selectedDate)
            }
            .sheet(item: $selectedItem) { item in
                EditPlannerItemView(item: item, viewModel: viewModel)
            }
        }
    }
    
    private var viewModeSelector: some View {
        Picker("View Mode", selection: $viewModel.viewMode) {
            Text("Day").tag(PlannerViewModel.ViewMode.day)
            Text("Week").tag(PlannerViewModel.ViewMode.week)
            Text("Month").tag(PlannerViewModel.ViewMode.month)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var dateNavigator: some View {
        HStack {
            Button(action: { viewModel.previousPeriod() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.defaultAccentTeal)
            }
            
            Spacer()
            
            Text(dateTitle)
                .font(.headline)
                .foregroundColor(.defaultTextPrimary)
            
            Spacer()
            
            Button(action: { viewModel.nextPeriod() }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.defaultAccentTeal)
            }
        }
        .padding()
        .background(Color.defaultSecondaryBackground)
    }
    
    private var dateTitle: String {
        switch viewModel.viewMode {
        case .day:
            return viewModel.selectedDate.formatted(style: .long)
        case .week:
            let calendar = Calendar.current
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: viewModel.selectedDate) {
                return "\(weekInterval.start.formatted(style: .short)) - \(weekInterval.end.formatted(style: .short))"
            }
            return "Week"
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: viewModel.selectedDate)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Theme.spacingM) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.defaultTextSecondary)
            
            Text("No events scheduled")
                .font(.headline)
                .foregroundColor(.defaultTextSecondary)
        }
        .padding(.top, 60)
    }
}

struct PlannerItemCard: View {
    let item: PlannerItem
    let onTap: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.spacingM) {
                // Time indicator
                VStack(alignment: .center, spacing: Theme.spacingXS) {
                    if let startTime = item.startTime {
                        Text(startTime.timeFormatted())
                            .font(.caption)
                            .foregroundColor(.defaultTextSecondary)
                    } else {
                        Text("All Day")
                            .font(.caption)
                            .foregroundColor(.defaultTextSecondary)
                    }
                }
                .frame(width: 60)
                
                // Category color
                RoundedRectangle(cornerRadius: 2)
                    .fill(categoryColor(item.category))
                    .frame(width: 4)
                
                // Content
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.defaultTextPrimary)
                        .strikethrough(item.isCompleted)
                    
                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(.caption)
                            .foregroundColor(.defaultTextSecondary)
                            .lineLimit(2)
                    }
                    
                    Text(item.category.capitalized)
                        .font(.caption)
                        .padding(.horizontal, Theme.spacingS)
                        .padding(.vertical, Theme.spacingXS)
                        .background(categoryColor(item.category).opacity(0.2))
                        .foregroundColor(categoryColor(item.category))
                        .cornerRadius(Theme.cornerRadiusS)
                }
                
                Spacer()
                
                // Complete button
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(item.isCompleted ? .defaultAccentTeal : .defaultTextSecondary)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(Theme.spacingM)
            .background(Color.defaultSecondaryBackground)
            .cornerRadius(Theme.cornerRadiusM)
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "work":
            return .blue
        case "personal":
            return .green
        case "health":
            return .red
        case "family":
            return .orange
        default:
            return .defaultAccentTeal
        }
    }
}

struct AddPlannerItemView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: PlannerViewModel
    let initialDate: Date
    
    @State private var title = ""
    @State private var detail = ""
    @State private var date: Date
    @State private var hasTime = false
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var category = "general"
    
    let categories = ["general", "work", "personal", "health", "family"]
    
    init(viewModel: PlannerViewModel, initialDate: Date) {
        self.viewModel = viewModel
        self.initialDate = initialDate
        _date = State(initialValue: initialDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacingM) {
                        TextField("Event title", text: $title)
                            .font(.title2)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        TextEditor(text: $detail)
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        Toggle("Set Time", isOn: $hasTime)
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        if hasTime {
                            VStack(spacing: Theme.spacingS) {
                                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                            }
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        }
                        
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Category")
                                .font(.caption)
                                .foregroundColor(.defaultTextSecondary)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat.capitalized).tag(cat)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                        .background(Color.defaultSecondaryBackground)
                        .cornerRadius(Theme.cornerRadiusM)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        viewModel.createItem(
            title: title,
            detail: detail,
            date: date,
            startTime: hasTime ? startTime : nil,
            endTime: hasTime ? endTime : nil,
            category: category
        )
    }
}

struct EditPlannerItemView: View {
    @Environment(\.dismiss) private var dismiss
    let item: PlannerItem
    let viewModel: PlannerViewModel
    
    @State private var title: String
    @State private var detail: String
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isAllDay: Bool
    @State private var category: String
    
    let categories = ["general", "work", "personal", "health", "family"]
    
    init(item: PlannerItem, viewModel: PlannerViewModel) {
        self.item = item
        self.viewModel = viewModel
        _title = State(initialValue: item.title)
        _detail = State(initialValue: item.detail)
        _date = State(initialValue: item.date)
        _hasTime = State(initialValue: item.startTime != nil)
        _startTime = State(initialValue: item.startTime ?? Date())
        _endTime = State(initialValue: item.endTime ?? Date())
        _isAllDay = State(initialValue: item.isAllDay)
        _category = State(initialValue: item.category)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.defaultPrimaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.spacingM) {
                        TextField("Event title", text: $title)
                            .font(.title2)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        TextEditor(text: $detail)
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        Toggle("Set Time", isOn: $hasTime)
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        
                        if hasTime {
                            VStack(spacing: Theme.spacingS) {
                                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                            }
                            .padding()
                            .background(Color.defaultSecondaryBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                        }
                        
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Category")
                                .font(.caption)
                                .foregroundColor(.defaultTextSecondary)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat.capitalized).tag(cat)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding()
                        .background(Color.defaultSecondaryBackground)
                        .cornerRadius(Theme.cornerRadiusM)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Event")
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
        viewModel.updateItem(
            item,
            title: title,
            detail: detail,
            date: date,
            startTime: hasTime ? startTime : nil,
            endTime: hasTime ? endTime : nil,
            isAllDay: !hasTime,
            category: category
        )
    }
}

