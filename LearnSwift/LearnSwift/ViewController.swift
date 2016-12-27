//
//  ViewController.swift
//  LearnSwift
//
//  Created by javalong on 2016/11/18.
//  Copyright © 2016年 javalong. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    var dataArray = NSMutableArray.init();
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tableView = UITableView.init(frame: self.view.bounds, style: UITableViewStyle.plain)
        tableView.delegate = self;
        tableView.dataSource = self;
        self.view.addSubview(tableView);
        
        dataArray.add(["title": "高斯模糊", "class": "GaussianBlurViewController"]);
        dataArray.add(["title": "马赛克",  "class": "MetalImageViewController"])
        
        tableView.reloadData();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // UITableView Delegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dataArray.count;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellID = "cellID";
        let cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: cellID);
        
        let dic:NSDictionary = dataArray.object(at: indexPath.row) as! NSDictionary;
        
        cell.textLabel?.text = dic.object(forKey: "title") as! String?;
    
        return cell;
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        
        let dic: NSDictionary = dataArray.object(at: indexPath.row) as! NSDictionary;

        guard let NameSpace = Bundle.main.infoDictionary!["CFBundleExecutable"]as? String else {
            NSLog("无法获取到命名空间  后续代码不用执行")
            return
        }
        
        let className = dic.object(forKey: "class") as! String
        guard let vcClass = NSClassFromString(NameSpace+"."+className) else {
            NSLog("无法获取到该类 后续代码不用执行");
            return
        }
        
        guard let vcType = vcClass as? UIViewController.Type else {
            NSLog("无法获取到该控制器类型 后续代码不用执行");
            return
        }
        let vc = vcType.init()
        self.navigationController?.pushViewController(vc, animated: true);
    }
}

