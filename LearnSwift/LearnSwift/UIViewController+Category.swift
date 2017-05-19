//
//  UIViewController+Category.swift
//  LearnSwift
//
//  Created by javalong on 2017/5/19.
//  Copyright © 2017年 javalong. All rights reserved.
//

import UIKit

extension UIViewController
{
    func openMetalImageView() -> Void
    {
        self.openSubWithClassName(className: "MetalImageViewController")
    }
    
    func openGaussianBlurView() -> Void
    {
        self.openSubWithClassName(className: "GaussianBlurViewController")
    }
    
    func openSubWithClassName(className:String) -> Void
    {
        guard let NameSpace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else {
            NSLog("无法获取到命名空间  后续代码不用执行")
            return
        }
        
        guard let vcClass = NSClassFromString(NameSpace+"."+className) else {
            NSLog("无法获取到该类 后续代码不用执行");
            return
        }
        
        guard let vcType = vcClass as? UIViewController.Type else {
            NSLog("无法获取到该控制器类型 后续代码不用执行");
            return
        }
        let sub = vcType.init()
        if (self.navigationController != nil)
        {
            self.navigationController?.pushViewController(sub, animated: true)
        } else if (self is UINavigationController)
        {
            let p = self as! UINavigationController
            p.pushViewController(sub, animated: true)
        } else
        {
            self.present(sub, animated: true, completion: nil)
        }
    }
}
