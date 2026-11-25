//
//  Prenda.swift
//  MyApp
//
//  Created by iOS Lab UPMX on 11/24/26.
//

import Foundation

enum CategoriaPrenda: String, Codable, CaseIterable, Identifiable {
    case superior = "Superior"     // Playeras, camisas, suéteres, chamarras
    case inferior = "Inferior"     // Pantalones, shorts, faldas
    case calzado = "Calzado"       // Tenis, zapatos, botas
    case accesorio = "Accesorio"   // Gorras, bolsos, lentes
    
    var id: String { rawValue }
}

struct Prenda: Codable, Identifiable, Hashable {
    let id: String
    let usuarioId: String
    let nombre: String
    let categoria: CategoriaPrenda
    let imagenURL: String          // URL donde tu servidor guarda la imagen recortada
    let fechaCreacion: Date
}

struct Outfit: Codable, Identifiable {
    let id: String
    let usuarioId: String
    let nombre: String
    let prendaSuperiorId: String
    let prendaInferiorId: String
    let calzadoId: String
    let accesorioId: String?
    let fechaCreacion: Date
}
