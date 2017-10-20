/*
 Copyright © 2017 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 


Abstract:
WatermarkPage is a PDFPage subclass that implements custom drawing.
*/

import Foundation
import PDFKit

/**
 WatermarkPage subclasses PDFPage so that it can override the draw(with box: to context:) method.
 This method is called by PDFDocument to draw the page into a PDFView. All custom drawing for a PDF
 page should be done through this mechanism.
 
 Custom drawing methods should always be thread-safe and call the super-class method. This is needed
 to draw the original PDFPage content. Custom drawing code can execute before or after this super-class
 call, though order matters! If your graphics run before the super-class call, they are drawn below the
 PDFPage content. Conversely, if your graphics run after the super-class call, they are drawn above the
 PDFPage.
*/
class WatermarkPage: PDFPage {

    // MARK: - Properties
    var watermark: NSString?
    
    // Override PDFPage custom draw
    /// - Tag: OverrideDraw
    override func draw(with box: PDFDisplayBox, to context: CGContext) {

        // Draw original content
        super.draw(with: box, to: context)

        // Draw rotated overlay string
        UIGraphicsPushContext(context)
        context.saveGState()

        let pageBounds = self.bounds(for: box)
        context.translateBy(x: 0.0, y: pageBounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.rotate(by: CGFloat.pi / 4.0)
        
        let attributes = [
            NSAttributedStringKey.foregroundColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5),
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 64)
        ]

        watermark?.draw(at: CGPoint(x:250, y:40), withAttributes: attributes)

        context.restoreGState()
        UIGraphicsPopContext()

    }
}
