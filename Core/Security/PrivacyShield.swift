import UIKit

/// Закрывает содержимое приложения в app switcher и на экране блокировки.
final class PrivacyShield {
    static let shared = PrivacyShield()

    private var shieldView: UIView?
    private let tag = 9_140_216

    func show() {
        DispatchQueue.main.async {
            guard self.shieldView == nil,
                  let window = Self.foregroundWindow else { return }

            let view = UIView(frame: window.bounds)
            view.tag = self.tag
            view.backgroundColor = UIColor(hex: 0xFFF9FB)
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let symbol = UIImageView(image: UIImage(systemName: "sparkles"))
            symbol.tintColor = UIColor(hex: 0xF4A6BE)
            symbol.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(symbol)
            NSLayoutConstraint.activate([
                symbol.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                symbol.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                symbol.widthAnchor.constraint(equalToConstant: 64),
                symbol.heightAnchor.constraint(equalToConstant: 64)
            ])

            window.addSubview(view)
            self.shieldView = view
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.shieldView?.removeFromSuperview()
            self.shieldView = nil
        }
    }

    private static var foregroundWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
