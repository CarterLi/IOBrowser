/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2022, Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Foundation

@objc( PropertyValueTransformer )
public class PropertyValueTransformer: ValueTransformer
{
    public override class func transformedValueClass() -> AnyClass
    {
        NSString.self
    }

    public override func transformedValue( _ value: Any? ) -> Any?
    {
        guard let value = value as? PropertyListNode
        else
        {
            return nil
        }

        if let number = value.propertyList as? NSNumber
        {
            if CFGetTypeID(number) == CFBooleanGetTypeID()
            {
                return number.boolValue ? "true" : "false"
            }
            else if Preferences.shared.numberDisplayMode == 0
            {
                return number.description
            }
            else
            {
                switch CFNumberGetType(number)
                {
                    case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .charType, .shortType, .intType, .longType, .longLongType:
                        return String(format: "0x%0*llX", CFNumberGetByteSize(number) * 2, number.uint64Value)

                    case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                        return String(format: "0x%a", number.doubleValue)

                    default:
                        return number.description
                }
            }
        }

        if let data = value.propertyList as? Data, data.count > 0
        {
            if Preferences.shared.detectNumbersInData != 0, [1, 2, 4, 8].contains(data.count)
            {
                var number: UInt64 = 0

                switch (Preferences.shared.detectNumbersInData)
                {
                    case 1: // big-endian
                        for byte in data
                        {
                            number = (number << 8) | UInt64(byte)
                        }
                    case 2: // little-endian
                        for ( i, byte ) in data.enumerated()
                        {
                            number |= UInt64( byte ) << ( i * 8 )
                        }
                    default:
                        break
                }

                if Preferences.shared.numberDisplayMode == 0
                {
                    return number.description
                }
                else
                {
                    let width = data.count * 2
                    return String(format: "0x%0*llX", width, number)
                }
            }
            else
            {
                switch Preferences.shared.dataDisplayMode
                {
                    case 1:
                        return data.base64EncodedString()
                    case 2:
                        return "0x" + data.map { String(format: "%02X", $0) }.joined()
                    case 3:
                        return String(data: data, encoding: .utf8) ?? "<invalid UTF-8 data>"
                    default:
                        return data.description
                }
            }
        }

        return value.value
    }

    public override class func allowsReverseTransformation() -> Bool
    {
        false
    }
}
