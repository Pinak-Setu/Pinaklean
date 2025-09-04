
import SwiftUI

/// A simple segmented control for filtering with RawRepresentable options.
struct SimpleFilterSegmentedControl<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
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
