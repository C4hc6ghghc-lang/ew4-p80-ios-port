import Foundation

/// Original item artwork filenames are the item display names with spaces
/// converted to underscores, matching the frozen EW4 item asset directory.
public enum NativeOriginalItemArtCore {
    public static func resourceFileName(for itemName: String) -> String {
        itemName.replacingOccurrences(of: " ", with: "_") + ".png"
    }
}
