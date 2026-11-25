//
//  AuthModels.swift
//  MyApp
//
//  Created by iOS Lab UPMX on 11/24/26.
//

import Foundation

// Lo que enviamos al servidor para iniciar sesión
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// Lo que enviamos para registrar un usuario nuevo
struct RegisterRequest: Codable {
    let nombre: String
    let email: String
    let password: String
}

// Lo que el servidor nos responde si las credenciales son válidas
struct AuthResponse: Codable {
    let token: String
    let usuario: UsuarioDTO
}

struct UsuarioDTO: Codable, Identifiable {
    let id: String
    let nombre: String
    let email: String
}
