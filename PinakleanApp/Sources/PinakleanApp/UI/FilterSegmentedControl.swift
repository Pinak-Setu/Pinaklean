
import SwiftUI

/// A custom segmented control for filtering.
struct FilterSegmentedControl<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        Picker("Filter", selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option.rawValue.capitalized).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}
