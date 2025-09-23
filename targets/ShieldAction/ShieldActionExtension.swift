//
//  ShieldActionExtension.swift
//  ShieldAction
//
//  Created by Robert Herber on 2024-10-25.
//

import FamilyControls
import ManagedSettings
import UIKit
import UserNotifications
import os

private let logger = Logger()

func openParentApp(with urlString: String) {
  logger.log("🔗 Attempting to open parent app with URL: \(urlString, privacy: .public)")

  guard let url = URL(string: urlString) else {
    logger.log("❌ Invalid URL string: \(urlString, privacy: .public)")
    return
  }

  logger.log("📱 Using UIApplication.shared.open")
  UIApplication.shared.open(url) { success in
    logger.log("🎯 UIApplication.open completed - success: \(success, privacy: .public)")
  }
}

func handleShieldAction(
  configForSelectedAction: [String: Any],
  placeholders: [String: String?],
  applicationToken: ApplicationToken?,
  webdomainToken: WebDomainToken?,
  categoryToken: ActivityCategoryToken?
) -> ShieldActionResponse {
  let configKeys = Array(configForSelectedAction.keys).joined(separator: ", ")
  logger.log("🔥 handleAction START - config keys: \(configKeys, privacy: .public)")

  // Log the full config (be careful with sensitive data)
  if let configData = try? JSONSerialization.data(withJSONObject: configForSelectedAction),
     let configString = String(data: configData, encoding: .utf8) {
    logger.log("📋 Full config: \(configString, privacy: .public)")
  }

  if let actions = configForSelectedAction["actions"] as? [[String: Any]] {
    let actionCount = actions.count
    logger.log("🎯 Found \(actionCount) actions to execute")
    for (index, action) in actions.enumerated() {
      let actionNumber = index + 1
      logger.log("▶️ Executing action \(actionNumber)/\(actionCount)")
      executeGenericAction(
        action: action,
        placeholders: placeholders,
        triggeredBy: "shieldAction",
        applicationToken: applicationToken,
        webdomainToken: webdomainToken,
        categoryToken: categoryToken
      )
      logger.log("✅ Completed action \(actionNumber)")
    }
  } else {
    logger.log("❌ No actions array found in config")
  }

  if let type = configForSelectedAction["type"] as? String {
    logger.log("🔧 Processing deprecated type: \(type, privacy: .public)")
    if type == "disableBlockAllMode" {
      disableBlockAllMode(triggeredBy: "shieldAction")
    }

    let onlyFamilySelectionIdsContainingMonitoredActivityNames =
      configForSelectedAction["onlyFamilySelectionIdsContainingMonitoredActivityNames"] as? Bool
      ?? true

    let sortByGranularity = true

    if type == "unblockPossibleFamilyActivitySelection" {
      if let possibleFamilyActivitySelectionId = getPossibleFamilyActivitySelectionIds(
        applicationToken: applicationToken,
        webDomainToken: webdomainToken,
        categoryToken: categoryToken,
        onlyFamilySelectionIdsContainingMonitoredActivityNames:
          onlyFamilySelectionIdsContainingMonitoredActivityNames,
        sortByGranularity: sortByGranularity
      ).first?.id {
        if let selection = getFamilyActivitySelectionById(id: possibleFamilyActivitySelectionId) {
          unblockSelection(removeSelection: selection, triggeredBy: "shieldAction")
        }
      }
    }

    if type == "unblockAllPossibleFamilyActivitySelections" {
      let possibleFamilyActivitySelections = getPossibleFamilyActivitySelectionIds(
        applicationToken: applicationToken,
        webDomainToken: webdomainToken,
        categoryToken: categoryToken,
        onlyFamilySelectionIdsContainingMonitoredActivityNames:
          onlyFamilySelectionIdsContainingMonitoredActivityNames,
        sortByGranularity: sortByGranularity
      )

      for selection in possibleFamilyActivitySelections {
        unblockSelection(
          removeSelection: selection.selection,
          triggeredBy: "shieldAction"
        )
      }
    }

    if type == "whitelistPossibleFamilyActivitySelection" {
      if let possibleFamilyActivitySelectionId = getPossibleFamilyActivitySelectionIds(
        applicationToken: applicationToken,
        webDomainToken: webdomainToken,
        categoryToken: categoryToken,
        onlyFamilySelectionIdsContainingMonitoredActivityNames:
          onlyFamilySelectionIdsContainingMonitoredActivityNames,
        sortByGranularity: sortByGranularity
      ).first?.id {
        if let selection = getFamilyActivitySelectionById(id: possibleFamilyActivitySelectionId) {
          addSelectionToWhitelistAndUpdateBlock(
            whitelistSelection: selection,
            triggeredBy: "shieldAction"
          )
        }
      }
    }

    if type == "whitelistAllPossibleFamilyActivitySelections" {
      let possibleFamilyActivitySelections = getPossibleFamilyActivitySelectionIds(
        applicationToken: applicationToken,
        webDomainToken: webdomainToken,
        categoryToken: categoryToken,
        onlyFamilySelectionIdsContainingMonitoredActivityNames:
          onlyFamilySelectionIdsContainingMonitoredActivityNames,
        sortByGranularity: sortByGranularity
      )

      for selection in possibleFamilyActivitySelections {
        addSelectionToWhitelistAndUpdateBlock(
          whitelistSelection: selection.selection,
          triggeredBy: "shieldAction"
        )
      }
    }

    if type == "resetBlocks" {
      resetBlocks(triggeredBy: "shieldAction")
    }

    let url = configForSelectedAction["url"] as? String
    let deeplinkUrl = configForSelectedAction["deeplinkUrl"] as? String

    let urlStr = url ?? "nil"
    let deeplinkStr = deeplinkUrl ?? "nil"
    logger.log("🔍 Extracted values - url: \(urlStr, privacy: .public), deeplinkUrl: \(deeplinkStr, privacy: .public)")

    if type == "openUrl" {
      let openUrlStr = url ?? "device-activity://"
      logger.log("🌐 Executing openUrl with: \(openUrlStr, privacy: .public)")
      openParentApp(with: openUrlStr)
      logger.log("✅ openUrl completed")
    }

    if type == "openApp" {
      let finalUrl = deeplinkUrl ?? "device-activity://"
      logger.log("📱 Executing openApp with URL: \(finalUrl, privacy: .public)")
      openParentApp(with: finalUrl)
      logger.log("✅ openApp completed")
    }

    if type == "openUrlWithDispatch" {
      logger.log("🔄 Executing openUrlWithDispatch")
      let dispatchUrl = url ?? "device-activity://"
      DispatchQueue.main.async {
        logger.log("🔄 Inside dispatch queue, opening URL: \(dispatchUrl, privacy: .public)")
        openParentApp(with: dispatchUrl)
        logger.log("✅ openUrlWithDispatch completed")
      }
    }

    if type == "sendNotification" {
      logger.log("🔔 Executing sendNotification")
      if let payload = configForSelectedAction["payload"] as? [String: Any] {
        logger.log("📩 Notification payload found")
        sendNotification(contents: payload, placeholders: [:])
        logger.log("✅ sendNotification completed")
      } else {
        logger.log("❌ No payload found for sendNotification")
      }
    }

    if type == "addCurrentToWhitelist" {
      var selection = getCurrentWhitelist()

      if let applicationToken = applicationToken {
        selection.applicationTokens.insert(applicationToken)
      }

      if let webdomainToken = webdomainToken {
        selection.webDomainTokens.insert(webdomainToken)
      }

      if let categoryToken = categoryToken {
        selection.categoryTokens.insert(categoryToken)
      }

      saveCurrentWhitelist(whitelist: selection)
      updateBlock(triggeredBy: "shieldAction")
    }
  }

  CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)

  let behavior = configForSelectedAction["behavior"] as? String ?? "close"
  logger.log("🏁 Shield action completed, returning behavior: \(behavior, privacy: .public)")

  if behavior == "defer" {
    return .defer
  }

  return .close
}

func handleAction(
  action: ShieldAction,
  completionHandler: @escaping (ShieldActionResponse) -> Void,
  applicationToken: ApplicationToken?,
  webdomainToken: WebDomainToken?,
  categoryToken: ActivityCategoryToken?
) {
  logger.log("🚀 HandleAction START")
  CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
  logger.log("🔄 Preferences synchronized")

  if let shieldActionConfig = getActivitySelectionPrefixedConfigFromUserDefaults(
    keyPrefix: SHIELD_ACTIONS_FOR_SELECTION_PREFIX,
    fallbackKey: SHIELD_ACTIONS_KEY,
    applicationToken: applicationToken,
    webDomainToken: webdomainToken,
    categoryToken: categoryToken
  ) {
    let actionButton = action == .primaryButtonPressed ? "primary" : "secondary"
    let familyActivitySelectionId = getPossibleFamilyActivitySelectionIds(
      applicationToken: applicationToken,
      webDomainToken: webdomainToken,
      categoryToken: categoryToken,
      onlyFamilySelectionIdsContainingMonitoredActivityNames: true,
      sortByGranularity: true
    ).first
    if let configForSelectedAction = shieldActionConfig[actionButton] as? [String: Any] {
      let placeholders: [String: String?] = [
        "action": actionButton,
        "applicationName": applicationToken != nil
          ? Application(token: applicationToken!).localizedDisplayName : nil,
        "webDomain": webdomainToken != nil
          ? WebDomain(
            token: webdomainToken!
          ).domain : nil,
        "familyActivitySelectionId": familyActivitySelectionId?.id
      ]

      let response = handleShieldAction(
        configForSelectedAction: configForSelectedAction,
        placeholders: placeholders,
        applicationToken: applicationToken,
        webdomainToken: webdomainToken,
        categoryToken: categoryToken
      )
      if let delay = configForSelectedAction["delay"] as? Double {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
          completionHandler(response)
        }
      } else {
        completionHandler(response)
      }
    } else {
      completionHandler(.close)
    }
  } else {
    completionHandler(.close)
  }
}

// Override the functions below to customize the shield actions used in various situations.
// The system provides a default response for any functions that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldActionExtension: ShieldActionDelegate {
  override func handle(
    action: ShieldAction, for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    logger.log("🍎 Handle Application - action received")
    logger.log("🍎 Application token received")

    // Check for direct openApp action first
    if let configData = try? JSONSerialization.data(withJSONObject: action),
       let jsonDict = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
       let actions = jsonDict["actions"] as? [[String: Any]] {

      for actionDict in actions {
        if let type = actionDict["type"] as? String,
           type == "openApp",
           let deeplinkUrl = actionDict["deeplinkUrl"] as? String {

          logger.log("🚀 Found openApp action with deeplinkUrl: \(deeplinkUrl, privacy: .public)")

          logger.log("📱 Using responder chain approach")

          // Delay slightly to ensure UI is ready
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            openParentApp(with: deeplinkUrl)
            logger.log("✅ Parent app opening attempted")
          }
        }
      }
    }

    handleAction(
      action: action,
      completionHandler: { response in
        let responseStr = String(describing: response)
        logger.log("🍎 Application action completed with response: \(responseStr, privacy: .public)")
        completionHandler(response)
      },
      applicationToken: application,
      webdomainToken: nil,
      categoryToken: nil
    )
  }

  override func handle(
    action: ShieldAction, for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    logger.log("🌐 Handle Web Domain - action received")
    logger.log("🌐 Web domain token received")

    handleAction(
      action: action,
      completionHandler: completionHandler,
      applicationToken: nil,
      webdomainToken: webDomain,
      categoryToken: nil
    )
  }

  override func handle(
    action: ShieldAction, for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    logger.log("handle category")

    handleAction(
      action: action,
      completionHandler: completionHandler,
      applicationToken: nil,
      webdomainToken: nil,
      categoryToken: category
    )
  }
}
