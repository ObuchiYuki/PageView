//
//  File.swift
//  PageView
//
//  Created by yuki on 2025/01/30.
//

import SwiftUI

fileprivate struct Item: Identifiable {
    let id: Int
    let color: Color
}

fileprivate struct HorizontalPageExample: View {
    let items: [Item] = [
        Item(id: 0, color: .red),
        Item(id: 1, color: .green),
        Item(id: 2, color: .blue),
    ]
    @State var selection: Item.ID? = 0

    var body: some View {
        HorizontalPage(
            items: items,
            spacing: 16,
            selection: $selection
        ) { item in
            item.color
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    HorizontalPageExample()
}
