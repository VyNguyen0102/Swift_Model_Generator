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
    @IBAction func pasteButtonDidTap(_ sender: Any) {
        inputTextView.text = UIPasteboard.general.string
    }
    @IBAction func copyButtonDidTap(_ sender: Any) {
        UIPasteboard.general.string = outputTextView.text
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        outputTextView.text = Converter.convertStringToClass(json: inputTextView.text)
    }
}

