//
//  ViewController.swift
//  SwiftModelGenerator
//
//  Created by Vy Nguyen on 11/26/18.
//  Copyright © 2018 VVLab. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextView.delegate = self
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        var sampleStruct = StructModel.init(structName: "StructModel")
        sampleStruct.variables["meoMeo"] = DataType.bool
        sampleStruct.variables["goGo"] = DataType.string
        sampleStruct.variables["quakQuak"] = DataType.typeStruct(structName: "HeoHeo")
        outputTextView.text = Converter.convertStringToClass(json: inputTextView.text)

    }
}

