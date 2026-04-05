//
//  DateFormatterManager.swift
//  DateFormatter
//
//  Created by Yann Bonafons on 10/02/2026.
//

import Foundation

// MARK: - DateFormatterManaging

public protocol DateFormatterManaging: AnyObject {
    func string(from date: Date, using type: any DateFormatTypeProtocol) -> String
    func date(from string: String, using type: any DateFormatTypeProtocol) -> Date?
    func clearCache()
}

// MARK: - DateFormatterManager

public final class DateFormatterManager: DateFormatterManaging {

    // MARK: Singleton

    public static let shared = DateFormatterManager()

    // MARK: Private

    private var cache: [String: DateFormatter] = [:]
    private let lock = NSLock()

    private init() {}

    // MARK: - Public API

    /// Convertit une date en String avec le format demandé.
    public func string(from date: Date, using type: any DateFormatTypeProtocol) -> String {
        commit {
            formatter(for: type).string(from: date)
        }
    }

    /// Parse une date depuis une String avec le format demandé.
    public func date(from string: String, using type: any DateFormatTypeProtocol) -> Date? {
        commit {
            formatter(for: type).date(from: string)
        }
    }

    // MARK: - Cache Management

    /// Vide entièrement le cache (utile si la locale change à chaud).
    public func clearCache() {
        commit {
            cache.removeAll()
        }
    }

    // MARK: - Locking

    private func commit<T>(_ mutation: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return mutation()
    }

    // MARK: - Private Factory

    /// Récupère un `DateFormatter` depuis le cache ou le crée si absent.
    private func formatter(for type: any DateFormatTypeProtocol) -> DateFormatter {
        let key = type.cacheKey

        if let cached = cache[key] {
            return cached
        }

        let formatter = makeDateFormatter(for: type)
        cache[key] = formatter
        return formatter
    }

    /// Renvoie la locale à utiliser pour les formatters.
    /// Priorité : langue du téléphone si supportée → "en" par défaut.
    private var resolvedLocale: Locale {
        // Parcourt les langues préférées de l'utilisateur dans l'ordre
        for preferredLanguage in Locale.preferredLanguages {
            // On extrait uniquement le code langue (ex: "fr" depuis "fr-FR")
            let languageCode = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? ""
            let supporedLanguage = Bundle.main.localizations
            if supporedLanguage.contains(languageCode) {
                return Locale(identifier: preferredLanguage)
            }
        }
        return Locale(identifier: "en")
    }

    private func makeDateFormatter(for type: any DateFormatTypeProtocol) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = type.formatString
        formatter.locale = resolvedLocale
        return formatter
    }
}
