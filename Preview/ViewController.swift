//
//  ViewController.swift
//  Preview
//
//  Created by jxw on 2019/8/25.
//  Copyright © 2019 jxw. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func preview(_ sender: Any) {
        let preview = PreviewView(isShowIndex: true)
        preview.images = [UIImage(named: "image1")!,UIImage(named: "image2")!]
        preview.show()
    }
    
}

