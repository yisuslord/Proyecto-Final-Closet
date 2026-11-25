//
//  AuthViewModel.swift
//  MyApp
//
//  Created by iOS Lab UPMX on 11/24/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {
    // Estado que observa la UI
    var isAuthenticated: Bool = false
    var usuarioActual: UsuarioDTO?
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Campos del formulario
    var nombre: String = ""
    var email: String = ""
    var password: String = ""
    
    init() {
        // Al abrir la app, verificamos si ya existe un token guardado en el Keychain
        verificarSesionExistente()
    }
    
    func verificarSesionExistente() {
        if let token = KeychainService.shared.getToken(), !token.isEmpty {
            // En producción, aquí puedes hacer un GET /me para validar que el token siga vigente
            self.isAuthenticated = true
        }
    }
    
    func iniciarSesion() async {
        guard validarCampos(esRegistro: false) else { return }
        
        isLoading = true
        errorMessage = nil
        
        let payload = LoginRequest(email: email, password: password)
        
        do {
            let response: AuthResponse = try await NetworkService.shared.request(
                endpoint: "/auth/login",
                method: "POST",
                body: payload,
                requiresAuth: false
            )
            
            // Guardamos el token en el Keychain de forma segura
            _ = KeychainService.shared.saveToken(response.token)
            self.usuarioActual = response.usuario
            self.isAuthenticated = true
            limpiarFormulario()
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func registrarUsuario() async {
        guard validarCampos(esRegistro: true) else { return }
        
        isLoading = true
        errorMessage = nil
        
        let payload = RegisterRequest(nombre: nombre, email: email, password: password)
        
        do {
            let response: AuthResponse = try await NetworkService.shared.request(
                endpoint: "/auth/register",
                method: "POST",
                body: payload,
                requiresAuth: false
            )
            
            _ = KeychainService.shared.saveToken(response.token)
            self.usuarioActual = response.usuario
            self.isAuthenticated = true
            limpiarFormulario()
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func cerrarSesion() {
        KeychainService.shared.deleteToken()
        usuarioActual = nil
        isAuthenticated = false
    }
    
    // Validación básica en cliente antes de gastar datos de red
    private func validarCampos(esRegistro: Bool) -> Bool {
        if esRegistro && nombre.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Por favor ingresa tu nombre."
            return false
        }
        guard email.contains("@"), email.contains(".") else {
            errorMessage = "Ingresa un correo electrónico válido."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres."
            return false
        }
        return true
    }
    
    private func limpiarFormulario() {
        nombre = ""
        email = ""
        password = ""
    }
}
