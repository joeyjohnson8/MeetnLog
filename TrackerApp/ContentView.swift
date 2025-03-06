//
//  ContentView.swift
//  TrackerApp
//
//  Created by Joey Johnson on 2025-02-03.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Phone Number Formatting Extension

extension String {
    /// Returns a string containing only the numeric digits from the original string.
    var onlyDigits: String {
        self.filter { $0.isNumber }
    }
    
    /// Formats the phone number:
    /// - If there are 10 digits, returns: (xxx) xxx-xxxx.
    /// - If there are 11 digits and the first digit is 1, returns: +1 (xxx) xxx-xxxx.
    /// - Otherwise, returns the original string.
    var formattedPhoneNumber: String {
        let digits = self.onlyDigits
        if digits.count == 10 {
            let area = digits.prefix(3)
            let prefix = digits[digits.index(digits.startIndex, offsetBy: 3)..<digits.index(digits.startIndex, offsetBy: 6)]
            let line = digits.suffix(4)
            return "(\(area)) \(prefix)-\(line)"
        } else if digits.count == 11 && digits.first == "1" {
            let areaStart = digits.index(digits.startIndex, offsetBy: 1)
            let areaEnd = digits.index(areaStart, offsetBy: 3)
            let prefixStart = areaEnd
            let prefixEnd = digits.index(prefixStart, offsetBy: 3)
            let area = digits[areaStart..<areaEnd]
            let prefix = digits[prefixStart..<prefixEnd]
            let line = digits.suffix(4)
            return "+1 (\(area)) \(prefix)-\(line)"
        }
        return self
    }
}

// MARK: - Meeting Purpose Enum

enum MeetingPurpose: String, CaseIterable, Identifiable, Codable {
    case networking = "Networking"
    case jobInquiry = "Job Inquiry"
    case advice = "Advice"
    case collaboration = "Collaboration"
    case other = "Other"
    
    var id: String { self.rawValue }
}

// MARK: - Model

struct Meeting: Identifiable, Codable {
    var id: UUID = UUID()       // Unique identifier for each meeting
    var name: String           // Person's name
    var company: String        // Company they represent
    var position: String       // Their job title
    var phoneNumber: String    // Phone number for contact
    var date: Date             // Date (and optionally time) of the meeting
    var purpose: MeetingPurpose // Reason for meeting (as an enum)
    var notes: String          // Additional details or follow-up notes
}

// MARK: - View Model

class MeetingsViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    
    init() {
        // Add some sample meetings to get started
        meetings = [
            Meeting(name: "Alice Smith",
                    company: "Acme Inc.",
                    position: "Software Engineer",
                    phoneNumber: "7058134343",
                    date: Date().addingTimeInterval(3600),  // Upcoming chat in 1 hour
                    purpose: .networking,
                    notes: "Had a great conversation about SwiftUI."),
            Meeting(name: "Bob Johnson",
                    company: "TechCorp",
                    position: "Product Manager",
                    phoneNumber: "14344343434",
                    date: Date().addingTimeInterval(-86400), // Past meeting yesterday
                    purpose: .jobInquiry,
                    notes: "Discussed upcoming opportunities.")
        ]
    }
    
    func addMeeting(_ meeting: Meeting) {
        meetings.append(meeting)
    }
    
    func deleteMeeting(at offsets: IndexSet) {
        meetings.remove(atOffsets: offsets)
    }
}

// MARK: - Shared Views

struct MeetingRow: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meeting.name)
                .font(.headline)
            Text("\(meeting.position) @ \(meeting.company)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("🗓 \(meeting.date, formatter: dateFormatter)")
                .font(.caption)
        }
        .padding(.vertical, 6)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

struct DetailView: View {
    let meeting: Meeting

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(meeting.name)
                    .font(.largeTitle)
                    .bold()
                Text("\(meeting.position) @ \(meeting.company)")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Date: \(meeting.date, formatter: dateFormatter)")
                    .font(.subheadline)
                
                Divider()
                
                // Clickable phone number button
                if let phoneURL = URL(string: "tel://\(meeting.phoneNumber.onlyDigits)") {
                    Button(action: {
                        UIApplication.shared.open(phoneURL)
                    }) {
                        Text(meeting.phoneNumber.formattedPhoneNumber)
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                Text("Purpose")
                    .font(.headline)
                Text(meeting.purpose.rawValue)
                    .font(.body)
                
                Divider()
                
                Text("Notes")
                    .font(.headline)
                Text(meeting.notes)
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Meeting Details")
    }
}

struct AddMeetingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MeetingsViewModel

    @State private var name: String = ""
    @State private var company: String = ""
    @State private var position: String = ""
    @State private var phoneNumber: String = ""
    @State private var date: Date = Date()
    @State private var selectedPurpose: MeetingPurpose = .networking
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Info")) {
                    TextField("Name", text: $name)
                    TextField("Company", text: $company)
                    TextField("Position", text: $position)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Meeting Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Picker("Purpose", selection: $selectedPurpose) {
                        ForEach(MeetingPurpose.allCases) { purpose in
                            Text(purpose.rawValue).tag(purpose)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Meeting")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newMeeting = Meeting(name: name,
                                                 company: company,
                                                 position: position,
                                                 phoneNumber: phoneNumber,
                                                 date: date,
                                                 purpose: selectedPurpose,
                                                 notes: notes)
                        viewModel.addMeeting(newMeeting)
                        dismiss()
                    }
                    .disabled(name.isEmpty || company.isEmpty || position.isEmpty || phoneNumber.isEmpty)
                }
            }
        }
    }
}

// MARK: - New Section Views

struct UpcomingView: View {
    @ObservedObject var viewModel: MeetingsViewModel
    @State private var searchText: String = ""
    
    // Meetings with a date later than or equal to now are considered upcoming.
    var upcomingMeetings: [Meeting] {
        let now = Date()
        return viewModel.meetings.filter { $0.date >= now }
    }
    
    var filteredMeetings: [Meeting] {
        if searchText.isEmpty {
            return upcomingMeetings
        } else {
            return upcomingMeetings.filter { meeting in
                meeting.name.localizedCaseInsensitiveContains(searchText) ||
                meeting.company.localizedCaseInsensitiveContains(searchText) ||
                meeting.position.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredMeetings) { meeting in
                    NavigationLink(destination: DetailView(meeting: meeting)) {
                        MeetingRow(meeting: meeting)
                    }
                }
                .onDelete(perform: viewModel.deleteMeeting)
            }
            .searchable(text: $searchText, prompt: "Search upcoming chats")
            .navigationTitle("Upcoming Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddMeetingView(viewModel: viewModel)) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
            }
        }
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: MeetingsViewModel
    @State private var searchText: String = ""
    
    // Meetings with a date before now are considered history.
    var historyMeetings: [Meeting] {
        let now = Date()
        return viewModel.meetings.filter { $0.date < now }
    }
    
    var filteredMeetings: [Meeting] {
        if searchText.isEmpty {
            return historyMeetings
        } else {
            return historyMeetings.filter { meeting in
                meeting.name.localizedCaseInsensitiveContains(searchText) ||
                meeting.company.localizedCaseInsensitiveContains(searchText) ||
                meeting.position.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredMeetings) { meeting in
                    NavigationLink(destination: DetailView(meeting: meeting)) {
                        MeetingRow(meeting: meeting)
                    }
                }
                .onDelete(perform: viewModel.deleteMeeting)
            }
            .searchable(text: $searchText, prompt: "Search past chats")
            .navigationTitle("History")
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @StateObject var viewModel = MeetingsViewModel()
    
    var body: some View {
        TabView {
            UpcomingView(viewModel: viewModel)
                .tabItem {
                    Label("Upcoming", systemImage: "calendar.badge.plus")
                }
            HistoryView(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
