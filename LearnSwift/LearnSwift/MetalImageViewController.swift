//
//  MetalImageViewController.swift
//  LearnSwift
//
//  Created by javalong on 2016/11/18.
//  Copyright © 2016年 javalong. All rights reserved.
//

import UIKit


import UIKit
import Metal
import MetalKit

class MetalImageViewController: UIViewController
{
    var imageView: UIImageView!
    var blurRadius: UISlider!
    
    var pixelSize: UInt = 60
    
    /// The queue to process Metal
    let queue = DispatchQueue(label: "com.invasivecode.metalQueue",  attributes: .concurrent);
    
    func changePixelSize(_ sender: AnyObject)
    {
        if let slider = sender as? UISlider
        {
            pixelSize = UInt(slider.value)
            
            queue.async {
                self.applyFilter()
                
                let finalResult = self.imageFromTexture(texture:self.outTexture)
                
                DispatchQueue.main.async {
                    self.imageView.image = finalResult
                }
            }
        }
    }
    
    
    /// A Metal device
    lazy var device: MTLDevice! = {
        MTLCreateSystemDefaultDevice()
    }()
    
    /// A Metal library
    lazy var defaultLibrary: MTLLibrary! = {
        self.device.newDefaultLibrary()
    }()
    
    /// A Metal command queue
    lazy var commandQueue: MTLCommandQueue! = {
        NSLog("\(self.device.name!)")
        return self.device.makeCommandQueue()
    }()
    
    var inTexture: MTLTexture!
    var outTexture: MTLTexture!
    let bytesPerPixel: Int = 4
    
    /// A Metal compute pipeline state
    var pipelineState: MTLComputePipelineState!
    
    func setUpMetal()
    {
        if let kernelFunction = defaultLibrary.makeFunction(name:"pixelate") {
            do {
                pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            }
            catch {
                fatalError("Impossible to setup Metal")
            }
        }
    }
    
    let threadGroupCount = MTLSizeMake(16, 16, 1)
    
    lazy var threadGroups: MTLSize = {
        MTLSizeMake(Int(self.inTexture.width) / self.threadGroupCount.width, Int(self.inTexture.height) / self.threadGroupCount.height, 1)
    }()
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white;
        
        imageView = UIImageView(frame:CGRect(origin:CGPoint(x:0, y:0), size:CGSize(width:300, height:300)))
        imageView.center = view.center
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 5
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "1")
        view.addSubview(imageView)
        
        blurRadius = UISlider(frame:CGRect(origin:CGPoint(x:20, y:view.bounds.size.height-60), size:CGSize(width:view.bounds.size.width-40, height:60)))
        blurRadius.addTarget(self, action: #selector(changePixelSize), for: UIControlEvents.valueChanged)
        blurRadius.minimumValue = 1;
        blurRadius.maximumValue = 100;
        view.addSubview(blurRadius)
        
        queue.async {
            self.setUpMetal()
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        queue.async {
            self.importTexture()
            
            self.applyFilter()
            
            let finalResult = self.imageFromTexture(texture: self.outTexture)
            DispatchQueue.main.async {
                self.imageView.image = finalResult
            }
        }
    }
    
    func importTexture()
    {
        guard let image = UIImage(named: "1") else
        {
            fatalError("Can't read image")
        }
        inTexture = textureFromImage(image: image)
    }
    
    func applyFilter()
    {
        let commandBuffer  = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(inTexture, at:0)
        commandEncoder.setTexture(outTexture, at:1)
        
        let buffer = device.makeBuffer(bytes:&pixelSize, length:MemoryLayout<UInt>.size, options:[MTLResourceOptions.storageModeShared])
        commandEncoder.setBuffer(buffer, offset:0, at:0)
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup:threadGroupCount)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func textureFromImage(image: UIImage) -> MTLTexture
    {
        guard let cgImage = image.cgImage else {
            fatalError("Can't open image \(image)")
        }
        
        let textureLoader = MTKTextureLoader(device: self.device)
        do {
            let textureOut = try textureLoader.newTexture(with: cgImage, options: nil)
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: textureOut.pixelFormat, width: textureOut.width, height: textureOut.height, mipmapped: false)
            outTexture = self.device.makeTexture(descriptor: textureDescriptor)
            return textureOut
        }
        catch {
            fatalError("Can't load texture")
        }
    }
    
    
    func imageFromTexture(texture: MTLTexture) -> UIImage
    {
        let imageByteCount = texture.width * texture.height * bytesPerPixel
        let bytesPerRow = texture.width * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue:(CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        
        let grayColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data:&src, width:texture.width, height:texture.height, bitsPerComponent:bitsPerComponent, bytesPerRow: bytesPerRow, space:grayColorSpace, bitmapInfo:bitmapInfo.rawValue);
        
        let dstImageFilter = context!.makeImage();
        
        return UIImage(cgImage:dstImageFilter!, scale:0.0, orientation:UIImageOrientation.downMirrored)
    }
}
