//
//  DrivingHistoryViewController.swift
//  vBox
//
//  Swift implementation of trip list view
//

import UIKit
import CoreData

// MARK: - Driving History View Controller

final class DrivingHistoryViewControllerSwift: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Properties

    private var tripsGroupedByDate: [(date: Date, trips: [Trip])] = []
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        formatter.timeZone = .current
        return formatter
    }()

    private var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadTrips()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func loadTrips() {
        guard let trips = appDelegate.drivingHistory.trips else {
            tripsGroupedByDate = []
            return
        }

        // Group trips by date
        var grouped: [Date: [Trip]] = [:]
        let calendar = Calendar.current

        for case let trip as Trip in trips.reversed() {
            guard let startTime = trip.startTime else { continue }

            let dayStart = calendar.startOfDay(for: startTime)
            if grouped[dayStart] == nil {
                grouped[dayStart] = []
            }
            grouped[dayStart]?.append(trip)
        }

        // Sort by date (newest first) and convert to array of tuples
        tripsGroupedByDate = grouped
            .map { (date: $0.key, trips: $0.value) }
            .sorted { $0.date > $1.date }

        tableView.reloadData()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tripDetailSegue",
           let destination = segue.destination as? TripDetailViewController,
           let indexPath = sender as? IndexPath {
            destination.trip = trip(at: indexPath)
        }
    }

    // MARK: - Helper Methods

    private func trip(at indexPath: IndexPath) -> Trip {
        return tripsGroupedByDate[indexPath.section].trips[indexPath.row]
    }

    private func totalMiles(in section: Int) -> Double {
        return tripsGroupedByDate[section].trips.reduce(0) { $0 + ($1.totalMiles?.doubleValue ?? 0) }
    }

    private func headerTitle(for section: Int) -> String {
        let date = tripsGroupedByDate[section].date
        let dateString = dateFormatter.string(from: date)
        let totalMiles = totalMiles(in: section)
        return "\(dateString)   (\(String(format: "%.2f", totalMiles)) mi)"
    }

    private func deleteTrip(at indexPath: IndexPath) {
        let tripToDelete = trip(at: indexPath)
        let context = appDelegate.managedObjectContext
        let tripsInSection = tripsGroupedByDate[indexPath.section].trips.count

        context.delete(tripToDelete)
        appDelegate.saveContext()
        appDelegate.forgetDrivingHistory()

        // Reload data structure
        loadTrips()

        // Animate deletion
        tableView.beginUpdates()
        if tripsInSection == 1 {
            // Last trip in section - delete entire section
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        } else {
            // Delete just the row
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        tableView.endUpdates()
    }
}

// MARK: - UITableViewDataSource

extension DrivingHistoryViewControllerSwift: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tripsGroupedByDate.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tripsGroupedByDate[section].trips.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerTitle(for: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trip") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "trip")

        let trip = trip(at: indexPath)

        // Format time range
        let startTimeText = trip.startTime.map { timeFormatter.string(from: $0) } ?? "--:--"
        let endTimeText = trip.endTime.map { timeFormatter.string(from: $0) } ?? "--:--"
        cell.textLabel?.text = "\(startTimeText) - \(endTimeText)"

        // Format trip stats
        let avgSpeed = trip.avgSpeed?.doubleValue ?? 0
        let maxSpeed = trip.maxSpeed?.doubleValue ?? 0
        let totalMiles = trip.totalMiles?.doubleValue ?? 0
        cell.detailTextLabel?.text = String(format: "avg: %.2f mph - max: %.2f mph - (%.2f mi)", avgSpeed, maxSpeed, totalMiles)

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteTrip(at: indexPath)
        }
    }
}

// MARK: - UITableViewDelegate

extension DrivingHistoryViewControllerSwift: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "tripDetailSegue", sender: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .white
        header.tintColor = MyStyleKit.myOrange()
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize + 3)
        header.textLabel?.textAlignment = .center
    }
}
