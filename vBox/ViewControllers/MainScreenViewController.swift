//
//  MainScreenViewController.swift
//  vBox
//
//  Swift implementation of main screen navigation
//

import UIKit

// MARK: - Main Screen View Controller

final class MainScreenViewControllerSwift: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var startDriveButton: UIButton!
    @IBOutlet private weak var drivingHistoryButton: UIButton!
    @IBOutlet private weak var debugBluetoothButton: UIButton!
    @IBOutlet private weak var bluetoothTableButton: UIButton!

    // MARK: - Properties

    private var shouldShowNavigationBar = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        configureDebugMode()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if shouldShowNavigationBar {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        shouldShowNavigationBar = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupButtons() {
        // Configure button styles using MyStyleKit
        let blueImage = MyStyleKit.image(ofVBoxButtonWithButtonColor: MyStyleKit.gamebookersBlueColor())
        let orangeImage = MyStyleKit.image(ofVBoxButtonWithButtonColor: MyStyleKit.myOrange())
        let debugImage = MyStyleKit.image(ofVBoxButtonWithButtonColor: MyStyleKit.route66Color())

        startDriveButton.setBackgroundImage(blueImage, for: .normal)
        drivingHistoryButton.setBackgroundImage(orangeImage, for: .normal)
        debugBluetoothButton.setBackgroundImage(debugImage, for: .normal)
        bluetoothTableButton.setBackgroundImage(debugImage, for: .normal)
    }

    private func configureDebugMode() {
        let isDebugMode = UserDefaults.standard.bool(forKey: "debugMode")
        debugBluetoothButton.isHidden = !isDebugMode
        bluetoothTableButton.isHidden = !isDebugMode
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "googleMapsSegue" {
            shouldShowNavigationBar = false

            if let googleMapsVC = segue.destination as? GoogleMapsViewController {
                googleMapsVC.delegate = self
            }
        }
    }
}

// MARK: - GoogleMapsViewControllerDelegate

extension MainScreenViewControllerSwift: GoogleMapsViewControllerDelegate {
    func didTapStopRecordingButton() {
        dismiss(animated: true, completion: nil)
    }
}
