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

func openParentApp(with urlString: String) {
  let logger = Logger()
  logger.log("🚨🚨🚨 FUNCTION ENTRY - openParentApp called with: \(urlString, privacy: .public)")

  logger.log("🚨🚨🚨 STEP 1 - About to create URL")
  guard let url = URL(string: urlString) else {
    logger.log("❌ Invalid URL string: \(urlString, privacy: .public)")
    return
  }
  logger.log("🚨🚨🚨 STEP 2 - URL created successfully: \(url, privacy: .public)")

  // Method 1: Try LSApplicationWorkspace (private API) with timeout
  logger.log("🚨🚨🚨 STEP 3 - About to try LSApplicationWorkspace")

  DispatchQueue.global(qos: .userInitiated).async {
    logger.log("🚨🚨🚨 STEP 4 - Inside background thread")
    logger.log("🔧 LSApplicationWorkspace on background thread")

    if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type {
      logger.log("✅ LSApplicationWorkspace class found!")

      let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue()
      logger.log("✅ LSApplicationWorkspace instance: \(String(describing: workspace), privacy: .public)")

      let result = workspace?.perform(NSSelectorFromString("openSensitiveURL:withOptions:"), with: url, with: nil)
      logger.log("🎯 LSApplicationWorkspace result: \(String(describing: result), privacy: .public)")
    } else {
      logger.log("❌ LSApplicationWorkspace class not found")
    }

    logger.log("🔧 LSApplicationWorkspace attempt completed")
  }

  // Method 2: Try NSExtensionContext as backup
  logger.log("🚨🚨🚨 STEP 5 - About to try NSExtensionContext")
  let context = NSExtensionContext()
  logger.log("🚨🚨🚨 STEP 6 - NSExtensionContext created")

  context.open(url) { success in
    logger.log("🎯 Extension context open completed - success: \(success, privacy: .public)")
  }
  logger.log("🚨🚨🚨 STEP 7 - NSExtensionContext.open called")

  // Give the private API methods time to work without interference
  logger.log("🚨🚨🚨 STEP 8 - About to sleep")
  sleep(100)  // Reduced sleep time
  logger.log("🚨🚨🚨 STEP 9 - Sleep completed, function ending")
}

func handleShieldAction(
  configForSelectedAction: [String: Any],
  placeholders: [String: String?],
  applicationToken: ApplicationToken?,
  webdomainToken: WebDomainToken?,
  categoryToken: ActivityCategoryToken?
) -> ShieldActionResponse {
  let configKeys = Array(configForSelectedAction.keys).joined(separator: ", ")
  logger.log("🚨🚨🚨 ENTERING handleShieldAction FUNCTION 🚨🚨🚨")
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

      // Check if this is an openApp action and handle it directly
      if let actionType = action["type"] as? String, actionType == "openApp" {
        let deeplinkUrl = action["deeplinkUrl"] as? String ?? "device-activity://"
        logger.log("🚨 FOUND OPENAPP ACTION IN NEW SYSTEM: \(deeplinkUrl, privacy: .public)")

        // Do everything inline to avoid function call issues
        logger.log("🚨🚨🚨 INLINE START - processing URL: \(deeplinkUrl, privacy: .public)")

        guard let url = URL(string: deeplinkUrl) else {
          logger.log("❌ Invalid URL string: \(deeplinkUrl, privacy: .public)")
          return .close
        }

        logger.log("✅ URL created: \(url, privacy: .public)")

        // Try multiple LSApplicationWorkspace methods
        logger.log("🔧 Trying LSApplicationWorkspace inline")
        if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type {
          logger.log("✅ LSApplicationWorkspace class found!")
          let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue()
          logger.log("✅ LSApplicationWorkspace instance: \(String(describing: workspace), privacy: .public)")

          // Method 1: openSensitiveURL:withOptions:
          logger.log("🔧 Trying openSensitiveURL:withOptions:")
          let result1 = workspace?.perform(NSSelectorFromString("openSensitiveURL:withOptions:"), with: url, with: nil)
          logger.log("🎯 openSensitiveURL result: \(String(describing: result1), privacy: .public)")

          // Method 2: openURL:
          logger.log("🔧 Trying openURL:")
          let result2 = workspace?.perform(NSSelectorFromString("openURL:"), with: url)
          logger.log("🎯 openURL result: \(String(describing: result2), privacy: .public)")

          // Method 3: openApplicationWithBundleID:
          logger.log("🔧 Trying openApplicationWithBundleID:")
          let result3 = workspace?.perform(NSSelectorFromString("openApplicationWithBundleID:"), with: "com.path2us.bittersweet")
          logger.log("🎯 openApplicationWithBundleID result: \(String(describing: result3), privacy: .public)")
        } else {
          logger.log("❌ LSApplicationWorkspace class not found")
        }

        logger.log("🚨🚨🚨 INLINE COMPLETED")
      } else {
        executeGenericAction(
          action: action,
          placeholders: placeholders,
          triggeredBy: "shieldAction",
          applicationToken: applicationToken,
          webdomainToken: webdomainToken,
          categoryToken: categoryToken
        )
      }
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
      logger.log("🚨 ABOUT TO CALL openParentApp function")
      openParentApp(with: finalUrl)
      logger.log("🚨 RETURNED FROM openParentApp function")
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
    logger.log("✅ Found shield action config!")
    let configKeys = Array(shieldActionConfig.keys).joined(separator: ", ")
    logger.log("🔧 Config keys: \(configKeys, privacy: .public)")
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
      logger.log("❌ No action config found for button: \(actionButton, privacy: .public)")
      completionHandler(.close)
    }
  } else {
    logger.log("❌ No shield action config found at all!")
    logger.log("🔍 Checked keys: \(SHIELD_ACTIONS_FOR_SELECTION_PREFIX, privacy: .public) and \(SHIELD_ACTIONS_KEY, privacy: .public)")
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
    logger.log("🔍 Action type: \(action == .primaryButtonPressed ? "primary" : "secondary", privacy: .public)")

    // Log if we have any shield actions configured
    let fallbackConfig = userDefaults?.dictionary(forKey: SHIELD_ACTIONS_KEY)
    let hasFallbackConfig = fallbackConfig != nil
    logger.log("📋 Has fallback shield actions config: \(hasFallbackConfig, privacy: .public)")

    if let config = fallbackConfig {
      let configKeys = Array(config.keys).joined(separator: ", ")
      logger.log("📋 Fallback config keys: \(configKeys, privacy: .public)")
    }

    // Action parameter is just an enum (.primaryButtonPressed or .secondaryButtonPressed)
    // The actual configuration is retrieved in handleAction() from UserDefaults

    logger.log("🔄 About to call handleAction")
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
