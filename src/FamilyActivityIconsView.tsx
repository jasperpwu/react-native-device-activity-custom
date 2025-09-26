import React from 'react';
import { requireNativeComponent, ViewStyle, Platform, StyleSheet } from 'react-native';
import { View, Text } from 'react-native';

export interface FamilyActivityIconsViewProps {
  /**
   * The family activity selection ID to display icons for.
   * This should be the ID of a selection stored via your selection management system.
   */
  familyActivitySelection: string;

  /**
   * Maximum number of icons to display before showing overflow indicator.
   * @default 3
   */
  maxDisplayedIcons?: number;

  /**
   * Size of each app icon in points.
   * @default 24
   */
  iconSize?: number;

  /**
   * Whether to show "+N" overflow indicator when there are more apps than maxDisplayedIcons.
   * @default true
   */
  showOverflow?: boolean;

  /**
   * Style for the container view.
   */
  style?: ViewStyle;
}

const NativeFamilyActivityIconsView = requireNativeComponent<FamilyActivityIconsViewProps>(
  'FamilyActivityIconsView'
);

/**
 * FamilyActivityIconsView displays actual app icons from a FamilyActivitySelection.
 *
 * This component uses SwiftUI's Label component to decode cryptographic tokens
 * and display real app icons, which is not possible from the React Native side directly.
 *
 * @example
 * ```tsx
 * import { FamilyActivityIconsView } from 'react-native-device-activity';
 *
 * <View style={{ flexDirection: 'row', alignItems: 'center' }}>
 *   <Text>Blocked Apps: </Text>
 *   <FamilyActivityIconsView
 *     familyActivitySelection={currentSelectionId}
 *     maxDisplayedIcons={3}
 *     iconSize={24}
 *     showOverflow={true}
 *   />
 * </View>
 * ```
 */
export const FamilyActivityIconsView: React.FC<FamilyActivityIconsViewProps> = ({
  familyActivitySelection,
  maxDisplayedIcons = 3,
  iconSize = 24,
  showOverflow = true,
  style,
}) => {
  // Only available on iOS 15+
  if (Platform.OS !== 'ios') {
    return (
      <View style={[{ height: iconSize, justifyContent: 'center' }, style]}>
        <Text style={{ fontSize: 12, color: '#666' }}>iOS only</Text>
      </View>
    );
  }

  return (
    <NativeFamilyActivityIconsView
      familyActivitySelection={familyActivitySelection}
      maxDisplayedIcons={maxDisplayedIcons}
      iconSize={iconSize}
      showOverflow={showOverflow}
      style={StyleSheet.flatten([{ height: iconSize + 8 }, style])}
    />
  );
};