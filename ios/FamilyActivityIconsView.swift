//
//  FamilyActivityIconsView.swift
//  react-native-device-activity
//
//  Created by ReactNativeDeviceActivity on 2024.
//

import SwiftUI
import FamilyControls
import React

@available(iOS 15.0, *)
@objc(FamilyActivityIconsViewManager)
class FamilyActivityIconsViewManager: RCTViewManager {

    override func view() -> UIView! {
        return FamilyActivityIconsHostingController().view
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

@available(iOS 15.0, *)
class FamilyActivityIconsHostingController: UIViewController {

    private var hostingController: UIHostingController<FamilyActivityIconsSwiftUIView>?
    private var selection: FamilyActivitySelection = FamilyActivitySelection()
    private var maxIcons: Int = 3
    private var iconSize: CGFloat = 24
    private var showOverflow: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingController()
    }

    private func setupHostingController() {
        let swiftUIView = FamilyActivityIconsSwiftUIView(
            selection: selection,
            maxIcons: maxIcons,
            iconSize: iconSize,
            showOverflow: showOverflow
        )
        hostingController = UIHostingController(rootView: swiftUIView)

        guard let hostingController = hostingController else { return }

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc func setFamilyActivitySelection(_ selectionId: String) {
        logger.log("🎨 FamilyActivityIconsView: Setting selection ID: \(selectionId, privacy: .public)")

        // Use existing getFamilyActivitySelectionById method from our library
        if let selection = getFamilyActivitySelectionById(id: selectionId) {
            self.selection = selection
            logger.log("🎨 Selection found with \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
            updateView()
        } else {
            logger.log("❌ FamilyActivityIconsView: Selection not found for ID: \(selectionId, privacy: .public)")
        }
    }

    @objc func setMaxDisplayedIcons(_ max: NSNumber) {
        self.maxIcons = max.intValue
        logger.log("🎨 FamilyActivityIconsView: Setting maxIcons to \(maxIcons)")
        updateView()
    }

    @objc func setIconSize(_ size: NSNumber) {
        self.iconSize = CGFloat(size.doubleValue)
        logger.log("🎨 FamilyActivityIconsView: Setting iconSize to \(iconSize)")
        updateView()
    }

    @objc func setShowOverflow(_ show: Bool) {
        self.showOverflow = show
        logger.log("🎨 FamilyActivityIconsView: Setting showOverflow to \(show)")
        updateView()
    }

    private func updateView() {
        DispatchQueue.main.async {
            let newView = FamilyActivityIconsSwiftUIView(
                selection: self.selection,
                maxIcons: self.maxIcons,
                iconSize: self.iconSize,
                showOverflow: self.showOverflow
            )
            self.hostingController?.rootView = newView
        }
    }
}

@available(iOS 15.0, *)
struct FamilyActivityIconsSwiftUIView: View {
    let selection: FamilyActivitySelection
    let maxIcons: Int
    let iconSize: CGFloat
    let showOverflow: Bool

    var body: some View {
        HStack(spacing: -4) {
            // Display actual app icons using SwiftUI Label - this is the magic!
            ForEach(Array(selection.applicationTokens.prefix(maxIcons)), id: \.self) { token in
                Label(token) // SwiftUI automatically decodes the cryptographic token!
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
            }

            // Show category icons if we have categories
            ForEach(Array(selection.categoryTokens.prefix(max(0, maxIcons - selection.applicationTokens.count))), id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
            }

            // Show overflow indicator
            if showOverflow && totalItemCount > maxIcons {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: iconSize, height: iconSize)

                    Text("+\(totalItemCount - maxIcons)")
                        .font(.system(size: iconSize * 0.4, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(4)
    }

    private var totalItemCount: Int {
        return selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }
}