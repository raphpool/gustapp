import SwiftUI
import UIKit
import Combine

class SimultaneouslyScrollViewHandler: NSObject, ObservableObject, UIScrollViewDelegate {
    @Published private var scrollViews: [UIScrollView] = []
    private var isScrolling = false

    func addScrollView(_ scrollView: UIScrollView) {
        scrollViews.append(scrollView)
        scrollView.delegate = self
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isScrolling else { return }
        isScrolling = true
        
        let contentOffset = scrollView.contentOffset
        for otherScrollView in scrollViews where otherScrollView != scrollView {
            otherScrollView.setContentOffset(contentOffset, animated: false)
        }
        
        isScrolling = false
    }
}
