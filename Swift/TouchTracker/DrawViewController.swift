//
//  BNRDrawViewController.swift
//  TouchTracker
//
//  Created by LeonTse on 2017/4/18.
//  Copyright © 2017年 LeonTse. All rights reserved.
//

import UIKit

class DrawViewController : UIViewController
{
    override func loadView()
    {
        view = DrawView.init(frame: .zero)
    }
}
