//
//  ViewController.swift
//  LXDJavaScriptCoreDemo
//
//  Created by linxinda on 16/6/28.
//  Copyright © 2016年 sindriLin. All rights reserved.
//

import UIKit
import JavaScriptCore

class ViewController: UIViewController {
    
    private let jsCodeKeyPath = "documentView.webView.mainFrame.javaScriptContext"

    @IBOutlet weak var webView: UIWebView!
    var interactionContext: JSContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let typeTest = false
        
        if typeTest {
            
            var jsCode: String?
            do {
                let context = JSContext()
                //MARK: - JSContext读取执行js代码
                jsCode = try String(contentsOf: URL(fileURLWithPath: Bundle.main().pathForResource("test", ofType: "js")!), encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                _ = context?.evaluateScript(jsCode)
                let value = context?.evaluateScript("square(num)")
                print("java script code run value : \(value)")
                
                //MARK: - 获取js代码中的方法变量
                let squareFunc = context?.objectForKeyedSubscript("square")
                let result = squareFunc?.call(withArguments: [2]).toInt32()
                print("the result: \(result)")
                
                let description = context?.objectForKeyedSubscript("jsDescription")
                print("description: \(description)")
                
                let iOSer = context?.objectForKeyedSubscript("iOSers").objectAtIndexedSubscript(0)
                print("the author of this code is \(iOSer?.toString())")
                
                
                //MARK: - 错误处理
                context?.exceptionHandler = {
                    print("\n=====================================")
                    print("JavaScript Error: \($1)")
                    print("=====================================\n")
                }
                _ = context?.evaluateScript("function multiply(value1, value2) { return value1 * value2 ")
                
                
                //MARK: - 将swift闭包转换成block然后转成AnyObject
                let convert: @convention(block) (String) -> String = { input in
                    let pinyin = NSMutableString(string: input) as CFMutableString
                    CFStringTransform(pinyin, nil, kCFStringTransformToLatin, false)
                    CFStringTransform(pinyin, nil, kCFStringTransformStripCombiningMarks, false)
                    return pinyin as String
                }
                let funcValue = JSValue(object: unsafeBitCast(convert, to: AnyObject.self), in: context)
                context?.setObject(unsafeBitCast(convert, to: AnyObject.self), forKeyedSubscript: "convertFunc")
                print("string convert: \(funcValue?.call(withArguments: ["林欣达"]).toString())")
                
            } catch let error as NSError {
                print("error: \(error.localizedDescription)")
            }
        }
        
        
        //MARK: - 从UIWebView加载html
        let jsPath = Bundle.main().pathForResource("interaction", ofType: "html")
        webView.loadRequest(URLRequest(url: URL(fileURLWithPath: jsPath!)))
        interactionContext = webView.value(forKeyPath: jsCodeKeyPath) as? JSContext
        interactionContext?.setObject(self, forKeyedSubscript: "sindrilin")
        interactionContext?.exceptionHandler = {
            print("Interaction Error: \($1?.toString())")
        }
    }

}


//MARK: - JSExport交互
@objc protocol LXDInteractionExport: JSExport {
    func call()
    @objc(login:) func login(accountInfo: String)
}


extension ViewController: LXDInteractionExport {
    func call() {
        print("call from html button clicked")
        view.backgroundColor = UIColor(red: CGFloat(arc4random() % 256) / 255, green: CGFloat(arc4random() % 256) / 255, blue: CGFloat(arc4random() % 256) / 255, alpha: 1)
    }
    
    func login(accountInfo: String) {
        do {
            if let JSON: [String: String] = try JSONSerialization.jsonObject(with: accountInfo.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? [String: String] {
                print("JSON: \(JSON)")
                
                let alert = interactionContext?.objectForKeyedSubscript("alertFromIOS")
                let message = "The alert from javascript call\naccount: \(JSON["account"]) and password: \(JSON["password"])"
                _ = alert?.call(withArguments: [message])
            }
            
        } catch {
            print("Error: \(error)")
        }
        
    }
}


