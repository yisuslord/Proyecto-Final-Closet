//
//  NetworkService.swift
//  MyApp
//
//  Created by iOS Lab UPMX on 11/24/26.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case unauthorized // Error 401: Token expirado o credenciales inválidas
    case serverError(statusCode: Int)
    case decodingError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "La URL del servidor no es válida."
        case .unauthorized: return "Credenciales incorrectas o sesión expirada."
        case .serverError(let code): return "Error del servidor (Código: \(code))."
        case .decodingError: return "No se pudo procesar la respuesta del servidor."
        case .unknown(let error): return error.localizedDescription
        }
    }
}

final class NetworkService {
    static let shared = NetworkService()
    private init() {}
    
    // Cambia esta URL por la de tu servidor real cuando esté desplegado
    private let baseURL = "https://api.tuclosetapp.com/v1"
    
    func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: String = "GET",
        body: B? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Si la ruta pide autenticación, sacamos el token del Keychain automáticamente
        if requiresAuth, let token = KeychainService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(statusCode: 0)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
