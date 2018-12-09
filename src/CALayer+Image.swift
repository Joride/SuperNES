//
//  CALayer+Image.swift
//  SuperNES
//
//  Created by Joride on 05-07-15.
//  Copyright (c) 2015 SuperNES. All rights reserved.
//

import QuartzCore

@objc extension CALayer
{
    @objc func imageRepresentation() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0)
        let context = UIGraphicsGetCurrentContext()

        self.render(in: context!)
        let outputImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return outputImage!;
    }
}
