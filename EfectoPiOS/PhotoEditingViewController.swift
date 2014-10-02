//
//  PhotoEditingViewController.swift
//  EfectoPiOS
//
//  Created by Fernando Medina on 9/30/14.
//  Copyright (c) 2014 Programadores-iOS.net. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController {

    var input: PHContentEditingInput?
    var output: PHContentEditingOutput!
    let filaOperaciones = NSOperationQueue()

    @IBOutlet weak var imagen: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - PHContentEditingController
    

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
               return false
    }

    func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
        
        input = contentEditingInput
        imagen.image = placeholderImage;
        
        
        //defino el bloque y paso el Closure
        let bloque = NSBlockOperation(block: operacionDeEdicion)
        filaOperaciones.addOperation(bloque)
        
        
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
    
            completionHandler?(output)
        
    }
    
    
    func procesaImagen(input: PHContentEditingInput, tipoFiltro : String) ->
        PHContentEditingOutput{
            
            //capturamos la imagen de entrada
            let imagen = input.fullSizeImageURL
            
            // utilizando un prefijo input creamos un recipiente CIImage para editar
            let inputImagenActual = CIImage(contentsOfURL: imagen, options: nil)
            
            // definimos el filtro
            let filtro = CIFilter(name: tipoFiltro)
            
            // aplicamos el filtro con setValue
            filtro.setValue(inputImagenActual, forKey: kCIInputImageKey)
            
            // con el metodo outputImage obtenemos la CIImage
            let ciImagenSalida = filtro.outputImage
            
            /* obtenemos las modificaciones con nuestra funcion que regresa un NSData */
            let modificaciones = procesaCIImage(ciImagenSalida)
            
            /* declaramos una variable donde encapsular las modificaciones */
            let contenidoDeSalida = PHContentEditingOutput(contentEditingInput: input)
            
            /* escribimos las modificaciones a nuestro contenido de salida */
            modificaciones.writeToURL(contenidoDeSalida.renderedContentURL,
                atomically: true)
            
            /* guardamos los ajustes para revertir mas tarde en caso que sea necesario */
            contenidoDeSalida.adjustmentData =
                PHAdjustmentData(formatIdentifier: NSBundle.mainBundle().bundleIdentifier,
                    formatVersion: "1.0",
                    data: tipoFiltro.dataUsingEncoding(NSUTF8StringEncoding,
                        allowLossyConversion: false))
            
            return contenidoDeSalida
            
    }
    
    func procesaCIImage(imagen: CIImage) -> NSData{
        let glContexto = EAGLContext(API: .OpenGLES2)
        let contexto = CIContext(EAGLContext: glContexto)
        let imagenReferencia = contexto.createCGImage(imagen, fromRect: imagen.extent())
        let imagen = UIImage(CGImage: imagenReferencia, scale: 1.0, orientation: .Up)
        return UIImageJPEGRepresentation(imagen, 0.8)
    }

    
    func operacionDeEdicion(){
        
        // aplicamos el filtro y obtenemos el contenido de salida.
        output = procesaImagen(input!, tipoFiltro: "CIPhotoEffectInstant")
        

        //utilizamos dispatch_async para que la operacion corra en el background
        dispatch_async(dispatch_get_main_queue(), {[weak self] in
            
            let strongSelf = self!
            
            // creamos una instancia desde la locacion donde se encuentra nuestra imagen modificada
            let datos = NSData(contentsOfURL: strongSelf.output.renderedContentURL,
                options: .DataReadingMappedIfSafe,
                error: nil)
            
            // la convertimos en una UIImage
            let imagenSalida = UIImage(data: datos)
            
            // la desplegamos
            strongSelf.imagen.image = imagenSalida

            
        })
    }

    var shouldShowCancelConfirmation: Bool {
       
        return true
    }

    func cancelContentEditing() {
         filaOperaciones.cancelAllOperations()
      
    }

}
