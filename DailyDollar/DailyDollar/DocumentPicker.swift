//
//  DocumentPicker.swift
//  DailyDollar
//
//  Created by David Wojcik III on 1/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: View {
    @Binding var isPresented: Bool
    var onPick: (URL) -> Void

    @State private var isPickerPresented = false

    var body: some View {
        Color.clear
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.commaSeparatedText, .text, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        onPick(url)
                    }
                case .failure(let error):
                    print("File import failed: \(error.localizedDescription)")
                }
                isPresented = false
            }
            .onAppear {
                isPickerPresented = true
            }
    }
}
