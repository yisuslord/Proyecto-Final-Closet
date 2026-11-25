//
//  AgregarPrenda.swift
//  MyApp
//
//  Created by iOS Lab UPMX on 11/24/26.
//

import SwiftUI
import PhotosUI

struct AgregarPrendaView: View {
    // Recibimos el ViewModel inyectado desde la vista padre
    @Bindable var viewModel: ClosetViewModel
    let usuarioId: String
    
    @Environment(\.dismiss) private var dismiss
    
    // Estados locales exclusivos de la interfaz (modales y pickers)
    @State private var mostrarCamara = false
    @State private var imagenCamaraTemp: UIImage?
    @State private var itemGaleriaSeleccionado: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            Form {
                // SECCIÓN 1: Vista previa de la prenda recortada sobre fondo blanco
                Section {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                            .frame(height: 280)
                        
                        if viewModel.isProcesandoRecorte {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Eliminando fondo con IA...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let imagenRecortada = viewModel.imagenProcesadaPreview {
                            Image(uiImage: imagenRecortada)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "tshirt")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.gray.opacity(0.5))
                                Text("Toma una foto o elige de tu galería")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    
                    // Botones de acción para capturar imagen
                    HStack(spacing: 12) {
                        Button {
                            mostrarCamara = true
                        } label: {
                            Label("Cámara", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        // Deshabilitamos el botón de cámara si estamos en el Simulador de Mac
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        
                        PhotosPicker(
                            selection: $itemGaleriaSeleccionado,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Galería", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                    }
                    .listRowBackground(Color.clear)
                }
                
                // SECCIÓN 2: Detalles de la prenda
                Section("Detalles de la prenda") {
                    TextField("Nombre (ej. Suéter beige tejido)", text: $viewModel.nombreNuevaPrenda)
                    
                    Picker("Categoría", selection: $viewModel.categoriaSeleccionada) {
                        ForEach(CategoriaPrenda.allCases) { categoria in
                            Text(categoria.rawValue).tag(categoria)
                        }
                    }
                }
                
                // SECCIÓN 3: Mensajes de error (si Vision no detecta prenda o falta nombre)
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Nueva Prenda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.limpiarFormularioCaptura()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            let exito = await viewModel.guardarPrendaEnCloset(usuarioId: usuarioId)
                            if exito { dismiss() }
                        }
                    }
                    .disabled(viewModel.imagenProcesadaPreview == nil || viewModel.isGuardando)
                }
            }
            // Abre la cámara en pantalla completa
            .fullScreenCover(isPresented: $mostrarCamara) {
                CameraPicker(selectedImage: $imagenCamaraTemp)
                    .ignoresSafeArea()
            }
            // Reacciona cuando se toma una foto con la cámara
            .onChange(of: imagenCamaraTemp) { _, nuevaFoto in
                guard let foto = nuevaFoto else { return }
                Task {
                    await viewModel.procesarFotoSeleccionada(foto)
                }
            }
            // Reacciona cuando se elige una foto de la galería
            .onChange(of: itemGaleriaSeleccionado) { _, nuevoItem in
                guard let item = nuevoItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await viewModel.procesarFotoSeleccionada(uiImage)
                    }
                }
            }
        }
    }
}

#Preview {
    AgregarPrendaView(
        viewModel: ClosetViewModel(),
        usuarioId: "usuario_prueba_123"
    )
}
