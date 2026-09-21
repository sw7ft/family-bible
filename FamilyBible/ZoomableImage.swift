import SwiftUI
import UIKit

struct ZoomableImage: UIViewRepresentable {
    let image: UIImage

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MapScrollView {
        let scroll = MapScrollView()
        scroll.delegate = context.coordinator
        scroll.bouncesZoom = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.backgroundColor = .clear
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scroll.addSubview(imageView)
        context.coordinator.imageView = imageView
        scroll.onBounds = { [weak scroll] in
            guard let scroll else { return }
            context.coordinator.layout(in: scroll, image: image)
        }

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
        tap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(tap)
        return scroll
    }

    func updateUIView(_ scroll: MapScrollView, context: Context) {
        context.coordinator.layout(in: scroll, image: image)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        private var lastBounds: CGSize = .zero
        private var started = false
        private var fitScale: CGFloat = 1

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            center(in: scrollView)
        }

        func layout(in scroll: UIScrollView, image: UIImage) {
            let bounds = scroll.bounds.size
            guard bounds.width > 1, bounds.height > 1, let imageView else { return }
            let size = image.size
            guard size.width > 1, size.height > 1 else { return }

            if imageView.bounds.size != size {
                imageView.frame = CGRect(origin: .zero, size: size)
                scroll.contentSize = size
            }

            let fit = min(bounds.width / size.width, bounds.height / size.height)
            fitScale = fit
            scroll.minimumZoomScale = fit * 0.4
            scroll.maximumZoomScale = max(fit * 8, 2)

            if !started {
                scroll.setZoomScale(fit, animated: false)
                started = true
            } else if bounds != lastBounds {
                let kept = scroll.zoomScale
                scroll.zoomScale = min(max(kept, scroll.minimumZoomScale), scroll.maximumZoomScale)
            }
            lastBounds = bounds
            center(in: scroll)
        }

        func center(in scroll: UIScrollView) {
            guard let imageView else { return }
            let extraX = max((scroll.bounds.width - scroll.contentSize.width) * 0.5, 0)
            let extraY = max((scroll.bounds.height - scroll.contentSize.height) * 0.5, 0)
            imageView.center = CGPoint(
                x: scroll.contentSize.width * 0.5 + extraX,
                y: scroll.contentSize.height * 0.5 + extraY
            )
        }

        @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scroll = gesture.view?.superview as? UIScrollView else { return }
            if scroll.zoomScale > fitScale * 1.15 {
                scroll.setZoomScale(fitScale, animated: true)
            } else {
                scroll.setZoomScale(min(fitScale * 2.5, scroll.maximumZoomScale), animated: true)
            }
        }
    }
}

final class MapScrollView: UIScrollView {
    var onBounds: (() -> Void)?
    private var last: CGSize = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != last {
            last = bounds.size
            onBounds?()
        }
    }
}
