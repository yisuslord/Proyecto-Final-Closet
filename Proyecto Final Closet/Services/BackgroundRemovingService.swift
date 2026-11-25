//
//  BackgroundRemovingService.swift
//  MyApp
//
//  Created by iOS Lab UPMX on 11/24/26.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

enum BackgroundRemoverError: LocalizedError {
    case invalidImage
    case noSubjectFound
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "No se pudo leer la imagen proporcionada."
        case .noSubjectFound: return "No se detectó ninguna prenda clara en la fotografía."
        case .renderingFailed: return "Error al generar la imagen recortada."
        }
    }
}

final class BackgroundRemoverService {
    static let shared = BackgroundRemoverService()
    private let ciContext = CIContext()
    
    private init() {}
    
    /// Toma una foto original, elimina el fondo y coloca la prenda sobre fondo blanco puro.
    func aislarPrendaSobreFondoBlanco(imagenOriginal: UIImage) async throws -> UIImage {
        // Corregimos la orientación de la cámara del iPhone antes de procesar
        guard let imagenNormalizada = normalizarOrientacion(imagenOriginal),
              let ciImage = CIImage(image: imagenNormalizada) else {
            throw BackgroundRemoverError.invalidImage
        }
        
        // Ejecutamos el procesamiento pesado en un hilo secundario para no congelar la pantalla
        return try await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { throw BackgroundRemoverError.renderingFailed }
            
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            try handler.perform([request])
            
            guard let result = request.results?.first else {
                throw BackgroundRemoverError.noSubjectFound
            }
            
            // Generamos la máscara que aísla únicamente la prenda detectada
            let maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
            let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            
            // Creamos un fondo blanco sólido del mismo tamaño que la foto
            let fondoBlanco = CIImage(color: .white).cropped(to: ciImage.extent)
            
            // Combinamos: Prenda original + Fondo Blanco usando la máscara de Vision
            let blendFilter = CIFilter.blendWithMask()
            blendFilter.inputImage = ciImage
            blendFilter.backgroundImage = fondoBlanco
            blendFilter.maskImage = maskCIImage
            
            guard let outputCIImage = blendFilter.outputImage,
                  let cgImage = self.ciContext.createCGImage(outputCIImage, from: outputCIImage.extent) else {
                throw BackgroundRemoverError.renderingFailed
            }
            
            return UIImage(cgImage: cgImage)
        }.value
    }
    
    /// Garantiza que las fotos tomadas en vertical con la cámara no salgan rotadas 90 grados.
    private func normalizarOrientacion(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized
    }
}
