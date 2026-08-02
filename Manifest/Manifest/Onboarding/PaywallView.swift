//
//  PaywallView.swift
//  Manifest
//
//  Screen 10/19 — images/screens/10-paywall.png
//
//  Every price, period and trial length here comes from RevenueCat's
//  Offerings at runtime — nothing is hardcoded. If REVENUECAT_API_KEY isn't
//  set yet, or no Offering is configured in the dashboard, this shows an
//  honest "not configured" state with a dev bypass rather than fabricating
//  prices, since there's nothing real to show.
//

import SwiftUI
import RevenueCat

private enum PaywallState {
    case loading
    case unavailable(String)
    case loaded(Offering)
}

struct PaywallView: View {
    var settings: AppSettings
    /// Where this paywall was opened from — onboarding, Home, Settings, etc.
    /// Purely for analytics grouping, defaults to "unknown" so existing call
    /// sites don't need to change unless they want the extra detail.
    var source: String = "unknown"
    /// Called on close (X), a completed purchase, or the dev bypass —
    /// callers decide what "done with the paywall" means: finishing
    /// onboarding, or just dismissing a sheet shown from elsewhere.
    var onDismiss: () -> Void

    @State private var state: PaywallState = .loading
    @State private var selected: Package?
    @State private var isPurchasing = false

    // App Store review requires subscription paywalls to link to real Terms
    // of Use and Privacy Policy pages — swap these once they're live.
    static let termsURL = URL(string: "https://www.akizitech.com/manifest/terms")!
    static let privacyURL = URL(string: "https://www.akizitech.com/manifest/privacy")!

    var body: some View {
        ZStack {
            LinearGradient.themeDarkBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 60)

                HStack {
                    RoadMarkGlyph(size: 44)
                    Spacer()
                    Button {
                        Analytics.track("paywall_closed", ["source": source])
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer().frame(height: 20)

                Text("Get full access")
                    .font(.newsreader(37))
                    .foregroundStyle(.white)

                Spacer().frame(height: 16)

                HStack(alignment: .top, spacing: 10) {
                    LumenMascot(mood: .calm, size: 32)
                    Text("Unlimited goals, a fresh script every morning in your language, and the gatekeeper that holds the line.")
                        .font(.manrope(15))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(3)
                }

                Spacer().frame(height: 22)

                content

                Spacer()

                PrimaryButton(title: ctaTitle, isEnabled: selected != nil && !isPurchasing) {
                    purchaseSelected()
                }

                Spacer().frame(height: 14)

                HStack(spacing: 24) {
                    Button("Restore") { restore() }
                    Link("Terms", destination: Self.termsURL)
                    Link("Privacy", destination: Self.privacyURL)
                }
                .font(.manrope(13))
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
        .task {
            Analytics.screen("paywall", ["source": source])
            await loadOfferings()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView().tint(.white).frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 30)

        case .unavailable(let message):
            VStack(alignment: .leading, spacing: 14) {
                Text(message)
                    .font(.manrope(14))
                    .foregroundStyle(.white.opacity(0.7))
                // #if DEBUG: this bypass must never reach a Release/App Store
                // build — it would let anyone skip paying whenever offerings
                // fail to load (misconfiguration, network hiccup, etc).
                #if DEBUG
                Button("Continue without subscribing (dev)") {
                    Analytics.track("paywall_dev_bypass_used", ["source": source])
                    onDismiss()
                }
                    .font(.manrope(14, weight: .semibold))
                    .foregroundStyle(.accent300)
                #endif
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

        case .loaded(let offering):
            VStack(spacing: 12) {
                ForEach(offering.availablePackages, id: \.identifier) { package in
                    packageRow(package, offering: offering)
                }
            }

            if let trialText {
                Spacer().frame(height: 18)
                VStack(alignment: .leading, spacing: 10) {
                    timelineRow("Today \u{2014} full access, nothing charged")
                    timelineRow(trialText)
                    timelineRow("Subscription begins after your trial \u{2014} cancel anytime")
                }
            }
        }
    }

    private func packageRow(_ package: Package, offering: Offering) -> some View {
        let isSelected = selected?.identifier == package.identifier
        let badge = badgeText(for: package, offering: offering)
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title(for: package))
                        .font(.manropeBold(17))
                        .foregroundStyle(.white)
                    if let badge {
                        Text(badge)
                            .font(.manrope(10.5, weight: .bold))
                            .foregroundStyle(.ink900)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gold300)
                            .clipShape(Capsule())
                    }
                }
                Text(priceLine(for: package))
                    .font(.manrope(14))
                    .foregroundStyle(.white.opacity(0.7))
                if let subtitle = subtitleText(for: package, offering: offering) {
                    Text(subtitle)
                        .font(.manrope(12.5))
                        .foregroundStyle(.accent300)
                }
            }
            Spacer()
            if hasFreeTrial(package) {
                Text("FREE TRIAL")
                    .font(.manrope(11, weight: .bold))
                    .foregroundStyle(.ink900)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gold300)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.white.opacity(isSelected ? 0.1 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.accent300 : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selected = package
            Analytics.track("paywall_package_selected", ["package_type": String(describing: package.packageType), "source": source])
        }
    }

    /// Everything here is derived from the offering's own live prices —
    /// never hardcoded — so it stays correct no matter what you're
    /// experimenting with in the RevenueCat dashboard.
    private func priceValue(_ package: Package) -> Double {
        NSDecimalNumber(decimal: package.storeProduct.price).doubleValue
    }

    private func badgeText(for package: Package, offering: Offering) -> String? {
        let locale = Locale(identifier: settings.language)
        switch package.packageType {
        case .annual:
            guard let monthly = offering.monthly, priceValue(monthly) > 0 else { return nil }
            let annualizedMonthly = priceValue(monthly) * 12
            let savings = (1 - priceValue(package) / annualizedMonthly) * 100
            guard savings >= 1 else { return nil }
            return String(localized: "SAVE \(Int(savings.rounded()))%", locale: locale)
        case .lifetime:
            return String(localized: "BEST VALUE", locale: locale)
        default:
            return nil
        }
    }

    private func subtitleText(for package: Package, offering: Offering) -> String? {
        guard package.packageType == .lifetime,
              let annual = offering.annual, priceValue(annual) > 0 else { return nil }
        let years = priceValue(package) / priceValue(annual)
        guard years >= 0.1 else { return nil }
        let locale = Locale(identifier: settings.language)
        let yearsText = years.formatted(.number.locale(locale).precision(.fractionLength(1)))
        return String(localized: "Pays for itself after \(yearsText) years of Yearly", locale: locale)
    }

    private func timelineRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.accent300)
            Text(text).font(.manrope(14)).foregroundStyle(.white.opacity(0.85))
        }
    }

    private var ctaTitle: String {
        if let selected, hasFreeTrial(selected), let days = trialDays(selected) {
            return "Start \(days)-day free trial"
        }
        return "Continue"
    }

    private var trialText: String? {
        guard let selected, hasFreeTrial(selected), let days = trialDays(selected) else { return nil }
        return "Day \(days) \u{2014} reminder before the trial ends"
    }

    private func title(for package: Package) -> String {
        let locale = Locale(identifier: settings.language)
        switch package.packageType {
        case .annual: return String(localized: "Yearly", locale: locale)
        case .monthly: return String(localized: "Monthly", locale: locale)
        case .lifetime: return String(localized: "Lifetime", locale: locale)
        case .weekly: return String(localized: "Weekly", locale: locale)
        case .sixMonth: return String(localized: "6 Months", locale: locale)
        case .threeMonth: return String(localized: "3 Months", locale: locale)
        case .twoMonth: return String(localized: "2 Months", locale: locale)
        default: return package.storeProduct.localizedTitle
        }
    }

    private func priceLine(for package: Package) -> String {
        let price = package.storeProduct.localizedPriceString
        guard let period = package.storeProduct.subscriptionPeriod else { return price }
        let locale = Locale(identifier: settings.language)
        let unit: String
        switch period.unit {
        case .day: unit = String(localized: "day", locale: locale)
        case .week: unit = String(localized: "week", locale: locale)
        case .month: unit = String(localized: "month", locale: locale)
        case .year: unit = String(localized: "year", locale: locale)
        @unknown default: unit = ""
        }
        return period.value == 1 ? "\(price) / \(unit)" : "\(price) / \(period.value) \(unit)s"
    }

    private func hasFreeTrial(_ package: Package) -> Bool {
        package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial
    }

    private func trialDays(_ package: Package) -> Int? {
        guard let discount = package.storeProduct.introductoryDiscount else { return nil }
        let period = discount.subscriptionPeriod
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        default: return nil
        }
    }

    private func loadOfferings() async {
        let locale = Locale(identifier: settings.language)
        guard Purchases.isConfigured else {
            state = .unavailable(String(localized: "Subscriptions aren't set up yet — add REVENUECAT_API_KEY to Config.xcconfig.", locale: locale))
            return
        }
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current, !offering.availablePackages.isEmpty else {
                state = .unavailable(String(localized: "No subscription plans are configured in RevenueCat yet.", locale: locale))
                return
            }
            state = .loaded(offering)
            selected = offering.annual ?? offering.availablePackages.first
        } catch {
            print("[Paywall] Failed to load offerings: \(error)")
            state = .unavailable(String(localized: "Couldn't load subscription plans. Check your connection and try again.", locale: locale))
        }
    }

    private func purchaseSelected() {
        guard let package = selected else { return }
        let packageType = String(describing: package.packageType)
        isPurchasing = true
        Analytics.track("purchase_started", ["package_type": packageType, "source": source])
        Task {
            do {
                let result = try await Purchases.shared.purchase(package: package)
                if result.userCancelled {
                    Analytics.track("purchase_cancelled", ["package_type": packageType, "source": source])
                } else {
                    // Apply immediately rather than waiting on the delegate
                    // callback — onDismiss() below can dismiss this sheet
                    // (or finish onboarding) right away, and the rest of the
                    // app needs isSubscribed to already be true by then.
                    await EntitlementStore.shared.apply(result.customerInfo)
                    Analytics.track("purchase_completed", ["package_type": packageType, "source": source])
                    onDismiss()
                }
            } catch {
                print("[Paywall] Purchase failed: \(error)")
                Analytics.track("purchase_failed", ["package_type": packageType, "source": source])
            }
            isPurchasing = false
        }
    }

    private func restore() {
        Analytics.track("restore_purchases_tapped", ["source": source])
        Task {
            do {
                let info = try await Purchases.shared.restorePurchases()
                await EntitlementStore.shared.apply(info)
                Analytics.track("restore_purchases_succeeded", ["source": source])
            } catch {
                print("[Paywall] Restore failed: \(error)")
                Analytics.track("restore_purchases_failed", ["source": source])
            }
        }
    }
}

#Preview {
    PaywallView(settings: AppSettings()) {}
}
