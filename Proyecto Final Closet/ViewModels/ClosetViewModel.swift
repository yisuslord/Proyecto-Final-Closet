//
//  ClosetViewModel.swift
//  MyApp
//
//  Created by iOS Lab UPMX on 11/24/26.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class ClosetViewModel {
    // Inventario del clóset
    var prendas: [Prenda] = []
    
    // Estado para la pantalla de "Agregar Prenda"
    var imagenOriginal: UIImage?
    var imagenProcesadaPreview: UIImage?
    var nombreNuevaPrenda: String = ""
    var categoriaSeleccionada: CategoriaPrenda = .superior
    
    // Estados de carga y error
    var isProcesandoRecorte: Bool = false
    var isGuardando: Bool = false
    var errorMessage: String?
    
    // Filtros rápidos para el creador de outfits
    func prendas(por categoria: CategoriaPrenda) -> [Prenda] {
        prendas.filter { $0.categoria == categoria }
    }
    
    /// Paso 1: El usuario elige o toma una foto y automáticamente le quitamos el fondo
    func procesarFotoSeleccionada(_ imagen: UIImage) async {
        self.imagenOriginal = imagen
        self.imagenProcesadaPreview = nil
        self.errorMessage = nil
        self.isProcesandoRecorte = true
        
        do {
            let prendaRecortada = try await BackgroundRemoverService.shared.aislarPrendaSobreFondoBlanco(
                imagenOriginal: imagen
            )
            self.imagenProcesadaPreview = prendaRecortada
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        self.isProcesandoRecorte = false
    }
    
    /// Paso 2: Guarda la prenda recortada en el clóset
    func guardarPrendaEnCloset(usuarioId: String) async -> Bool {
        guard let imagenFinal = imagenProcesadaPreview else {
            errorMessage = "Primero debes procesar una fotografía."
            return false
        }
        
        let nombreLimpio = nombreNuevaPrenda.trimmingCharacters(in: .whitespaces)
        guard !nombreLimpio.isEmpty else {
            errorMessage = "Asigna un nombre a tu prenda (ej. Suéter azul)."
            return false
        }
        
        isGuardando = true
        errorMessage = nil
        
        do {
            // Convertimos la imagen con fondo blanco a Data (JPEG optimizado al 85%)
            guard let imageData = imagenFinal.jpegData(compressionQuality: 0.85) else {
                throw BackgroundRemoverError.renderingFailed
            }
            
            // NOTA: Aquí es donde enviaremos `imageData` a tu API (multipart/form-data o Base64).
            // Mientras construimos el servidor, simulamos una respuesta exitosa guardando temporalmente en disco local:
            let localURL = guardarTemporalmenteEnDisco(data: imageData)
            
            let nuevaPrenda = Prenda(
                id: UUID().uuidString,
                usuarioId: usuarioId,
                nombre: nombreLimpio,
                categoria: categoriaSeleccionada,
                imagenURL: localURL.absoluteString,
                fechaCreacion: Date()
            )
            
            prendas.insert(nuevaPrenda, at: 0)
            limpiarFormularioCaptura()
            isGuardando = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isGuardando = false
            return false
        }
    }
    
    func limpiarFormularioCaptura() {
        imagenOriginal = nil
        imagenProcesadaPreview = nil
        nombreNuevaPrenda = ""
        categoriaSeleccionada = .superior
        errorMessage = nil
    }
    
    private func guardarTemporalmenteEnDisco(data: Data) -> URL {
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return url
    }
}
