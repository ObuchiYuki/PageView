//
//  HorizontalPage.swift
//  PageView
//
//  Created by yuki on 2025/01/30.
//


import SwiftUI

public struct HorizontalPage<Item: Identifiable, Page: View>: UIViewControllerRepresentable {
    public let items: [Item]
    
    public let page: (Item) -> Page
    
    public let spacing: CGFloat
    
    @Binding public var selection: Item.ID?

    public init(
        items: [Item],
        spacing: CGFloat,
        selection: Binding<Item.ID?>,
        page: @escaping (Item) -> Page
    ) {
        self.items = items
        self.spacing = spacing
        self._selection = selection
        self.page = page
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> UIPageViewController {
        let options: [UIPageViewController.OptionsKey: Any] = [.interPageSpacing: self.spacing]
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: options
        )
        controller.view.backgroundColor = .clear
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        if
            let item = self.items.first(where: { $0.id == self.selection }),
            let initialVC = context.coordinator.makeViewController(for: item)
        {
            controller.setViewControllers([initialVC], direction: .forward, animated: false)
        }
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // initial update
        if uiViewController.viewControllers?.isEmpty ?? true,
           let item = self.items.first(where: { $0.id == self.selection }),
           let initialVC = context.coordinator.makeViewController(for: item)
        {
            uiViewController.setViewControllers([initialVC], direction: .forward, animated: false)
        }
        
        // page update
        if
            let currentVC = uiViewController.viewControllers?.first as? HostingControllerWrapper<Item, Page>,
            currentVC.item.id != self.selection,
            let item = self.items.first(where: { $0.id == self.selection }),
            let newVC = context.coordinator.makeViewController(for: item)
        {
            let currentIndex = self.items.firstIndex(where: { $0.id == currentVC.item.id }) ?? 0
            let newIndex = self.items.firstIndex(where: { $0.id == self.selection }) ?? 0
            let direction: UIPageViewController.NavigationDirection = (newIndex >= currentIndex) ? .forward : .reverse
            uiViewController.setViewControllers([newVC], direction: direction, animated: true)
        }
    }

    public class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        public let parent: HorizontalPage

        public init(parent: HorizontalPage) {
            self.parent = parent
        }

        fileprivate func makeViewController(for item: Item) -> HostingControllerWrapper<Item, Page>? {
            return HostingControllerWrapper(rootView: self.parent.page(item), item: item)
        }

        public func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let vc = viewController as? HostingControllerWrapper<Item, Page>,
                  let currentIndex = self.parent.items.firstIndex(where: { $0.id == vc.item.id }),
                  currentIndex > 0
            else { return nil }
            let prevItem = self.parent.items[currentIndex - 1]
            return self.makeViewController(for: prevItem)
        }

        public func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let vc = viewController as? HostingControllerWrapper<Item, Page>,
                  let currentIndex = self.parent.items.firstIndex(where: { $0.id == vc.item.id }),
                  currentIndex < (self.parent.items.count - 1)
            else { return nil }
            let nextItem = self.parent.items[currentIndex + 1]
            return self.makeViewController(for: nextItem)
        }

        public func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let currentVC = pageViewController.viewControllers?.first as? HostingControllerWrapper<Item, Page>
            else { return }
            self.parent.selection = currentVC.item.id
        }
    }
}

private class HostingControllerWrapper<Item, Content: View>: UIHostingController<Content> {
    let item: Item

    init(rootView: Content, item: Item) {
        self.item = item
        super.init(rootView: rootView)
        self.view.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
