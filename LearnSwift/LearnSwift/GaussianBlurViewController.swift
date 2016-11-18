//
//  GaussianBlurViewController.swift
//  LearnSwift
//
//  Created by javalong on 2016/11/18.
//  Copyright © 2016年 javalong. All rights reserved.
//

import UIKit

import UIKit
import MetalKit
import MetalPerformanceShaders

class GaussianBlurViewController: UIViewController, MTKViewDelegate
{
    var blurRadius: UISlider!
    
    var metalView: MTKView!
    
    var commandQueue: MTLCommandQueue!
    
    var sourceTexture: MTLTexture!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white;
        setUpMetalView()
        loadAssets()
    }
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func setUpMetalView()
    {
        blurRadius = UISlider(frame:CGRect(origin:CGPoint(x:20, y:view.bounds.size.height-60), size:CGSize(width:view.bounds.size.width-40, height:60)))
        blurRadius.addTarget(self, action: #selector(blurRadiusDidChanged), for: UIControlEvents.valueChanged)
        blurRadius.minimumValue = 1;
        blurRadius.maximumValue = 100;
        view.addSubview(blurRadius)
        
        metalView = MTKView(frame:CGRect(origin:CGPoint(x:0, y:0), size:CGSize(width: 300, height: 300)))
        metalView.center = view.center
        metalView.layer.borderColor = UIColor.white.cgColor
        metalView.layer.borderWidth = 5
        metalView.layer.cornerRadius = 20
        metalView.clipsToBounds = true
        view.addSubview(metalView)
        
        //读取默认设备.
        metalView.device = MTLCreateSystemDefaultDevice()
        
        //确保当前设备支持MetalPerformanceShaders
        guard let metalView = metalView , MPSSupportsMTLDevice(metalView.device) else {
            print("该设备不支持MetalPerformanceShaders!")
            return
        }
        
        //配置MTKview属性
        metalView.delegate = self
        metalView.depthStencilPixelFormat = .depth32Float_stencil8
        // 设置输入/输出数据的纹理(texture)格式
        metalView.colorPixelFormat = .bgra8Unorm
        //将`currentDrawable.texture`设置为可写
        metalView.framebufferOnly = false
    }
    
    func loadAssets()
    {
        // 创建新的命令队列
        commandQueue = metalView.device!.makeCommandQueue()
        
        //设置纹理加载器
        let textureLoader = MTKTextureLoader(device:metalView.device!)
        //对图片进行加载和设置
        let image = UIImage(named:"AnimalImage")
        //处理后的图片是倒置，要先将其倒置过来才能显示出正图像
        let mirrorImage = UIImage(cgImage:(image?.cgImage)!, scale:1, orientation:UIImageOrientation.downMirrored)
        //将图片调整至所需大小
        let scaledImage = UIImage.scaleToSize(image:mirrorImage, size:(image?.size)!)
        
        let cgimage = scaledImage.cgImage
        
        // 将图片加载到 MetalPerformanceShaders的输入纹理(source texture)
        do {
            sourceTexture = try textureLoader.newTexture(with:cgimage!, options: [:])
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }
    }
    
    /*!
     @method drawInMTKView:
     @abstract Called on the delegate when it is asked to render into the view
     @discussion Called on the delegate when it is asked to render into the view
     */
    public func draw(in view: MTKView)
    {
        //得到MetalPerformanceShaders需要使用的命令缓存区
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // 初始化MetalPerformanceShaders高斯模糊，模糊半径(sigma)为slider所设置的值
        let gaussianblur = MPSImageGaussianBlur(device:view.device!, sigma:self.blurRadius.value)
        
        // 运行MetalPerformanceShader高斯模糊
        gaussianblur.encode(commandBuffer:commandBuffer, sourceTexture:sourceTexture, destinationTexture:view.currentDrawable!.texture)
        
        // 提交`commandBuffer`
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        
    }
    
    func blurRadiusDidChanged(sender: UISlider)
    {
        metalView.setNeedsDisplay()
    }
}

extension UIImage
{
    class func scaleToSize(image:UIImage,size:CGSize)->UIImage
    {
        UIGraphicsBeginImageContext(size)
        image.draw(in:CGRect(origin:CGPoint(x:0, y:0), size:size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
}
