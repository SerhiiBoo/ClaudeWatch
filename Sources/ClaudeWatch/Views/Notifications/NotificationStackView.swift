import SwiftUI

struct NotificationStackView: View {
    let events: [HookEvent]
    let requests: [PermissionRequest]
    let onDismiss: (HookEvent) -> Void
    let onActivate: (HookEvent) -> Void
    let onDismissRequest: (PermissionRequest) -> Void
    let onActivateRequest: (PermissionRequest) -> Void
    let onAllow: (PermissionRequest) -> Void
    let onDeny: (PermissionRequest) -> Void

    @State private var viewModels: [UUID: NotificationCardViewModel] = [:]

    private var items: [NotificationCardItem] {
        requests.map { .request($0) } + events.map { .event($0) }
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(items) { item in
                NotificationCardView(
                    viewModel: viewModelFor(item),
                    onDismiss: { dismiss(item) },
                    onActivate: { activate(item) },
                    onAllow: item.permissionRequest.map { req in { onAllow(req) } },
                    onDeny: item.permissionRequest.map { req in { onDeny(req) } }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: items.map(\.id))
        .onChange(of: items.map(\.id)) { _, newIDs in
            let keep = Set(newIDs)
            viewModels = viewModels.filter { keep.contains($0.key) }
        }
    }

    private func viewModelFor(_ item: NotificationCardItem) -> NotificationCardViewModel {
        if let existing = viewModels[item.id] { return existing }
        let vm = NotificationCardViewModel(item: item)
        viewModels[item.id] = vm
        return vm
    }

    private func dismiss(_ item: NotificationCardItem) {
        switch item {
        case .event(let e):   onDismiss(e)
        case .request(let r): onDismissRequest(r)
        }
    }

    private func activate(_ item: NotificationCardItem) {
        switch item {
        case .event(let e):   onActivate(e)
        case .request(let r): onActivateRequest(r)
        }
    }
}
