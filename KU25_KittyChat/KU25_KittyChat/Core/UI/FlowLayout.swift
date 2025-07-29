import SwiftUI

// MARK: - FlowLayout - 自動換行的 Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeRows(rows, in: bounds)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var currentRow: [LayoutSubviews.Element] = []
        var rows: [[LayoutSubviews.Element]] = []
        var currentX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > (proposal.width ?? 0) {
                rows.append(currentRow)
                currentRow = []
                currentX = 0
            }
            currentRow.append(subview)
            currentX += size.width + spacing
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubviews.Element]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + (height > 0 ? spacing : 0)
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    private func placeRows(_ rows: [[LayoutSubviews.Element]], in bounds: CGRect) {
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
} 