//
//  Tests.swift
//  Tests
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Greg Omelaenko
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
@testable import ObjSer


protocol P: Serialisable {
    
}

class Cyclic: P {
    
    var a = 5
    weak var c: Cyclic!
    
    required init() {
        c = self
    }
    
    required init(m: ()) { }

    static func createForDeserialising() -> Serialisable {
        return self.init(m: ())
    }

    func deserialiseWith(des: Deserialiser) throws {
        a = try des.deserialiseKey("a")!
        c = try des.deserialiseKey("c")! as Cyclic
    }

    func serialiseWith(ser: Serialiser) {
        ser.serialise(a, forKey: "a")
        ser.serialise(c, forKey: "c")
    }

    static var typeUniqueIdentifier: String? = "Cyclic"
    
}

func ==(a: Cyclic, b: Cyclic) -> Bool {
    return a.a == b.a && a.c === a && b.c === b
}

struct A: P, InitableSerialisable {
    
    let a: Int

    init(a: Int) {
        self.a = a
    }

    init(deserialiser des: Deserialiser) throws {
        a = try des.deserialiseKey("a")!
    }

    func serialiseWith(ser: Serialiser) {
        ser.serialise(a, forKey: "a")
    }

    static var typeUniqueIdentifier: String? = "A"
    
}

struct B: P, AcyclicSerialisable {
    
    let b: Float

    static func createByDeserialisingWith(des: Deserialiser) throws -> AcyclicSerialisable {
        return self.init(b: try des.deserialiseKey("b")!)
    }

    func serialiseWith(ser: Serialiser) {
        ser.serialise(b, forKey: "b")
    }

    static var typeUniqueIdentifier: String? = "B"
    
}

struct G<T: Serialisable>: P {
    
    var v: T!

    static func createForDeserialising() -> Serialisable {
        return self.init(v: nil)
    }

    mutating func deserialiseWith(des: Deserialiser) throws {
        v = try des.deserialiseKey("v")! as T
    }
    
    func serialiseWith(ser: Serialiser) {
        ser.serialise(v, forKey: "v")
    }

    static var typeUniqueIdentifier: String? {
        return "G-\(T.self)"
    }
    
}

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTypeCoding() {
        
        let f = Primitive.Array([
            Primitive.Integer(152352050802),
            Primitive.String("aoeu"),
            Primitive.Data([]),
            Primitive.Float(AnyFloat(3.14159265358979323846)),
            Primitive.Data([4, 255]),
            Primitive.Map([]),
            Primitive.Integer(-1),
            Primitive.Array([]),
            Primitive.Nil,
            Primitive.Boolean(true),
            Primitive.Array([
                Primitive.String(""),
                Primitive.Map([
                    Primitive.Integer(-7), Primitive.Boolean(false)
                    ])
                ])
            ])
        
        let o = OutputStream()
        f.writeTo(o)
//		o.close()
//		let data = o.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
//		print("data of size \(data.length): \(data)")
        let data = o.bytes
//		print("data of size \(data.count): \(data)")
//		let i = NSInputStream(data: data)
//		i.open()
        let i = InputStream(bytes: data)
        let g = try! Primitive(readFrom: i)
//		i.close()
//		
        XCTAssertEqual(String(f), String(g))
        
//		let b = [215,68,113,97,117,97,195,184,101,117,113,98,66,113,99,207] as [UInt8]
//		let ii = NSInputStream(data: NSData(bytes: b, length: b.count))
//		ii.open()
//		let h = try! Primitive(stream: ii)
//		ii.close()
//		print(h)
    }
    
    func testMapping() {

        struct S: AcyclicSerialisable {
            var a: [String : Int]
            var b: [Float]
            var c: Bool
            var d: Int!
            var e: [[String]]?
            var f: Bool!
            
//            private static func createForMapping() -> S {
//                return S(a: [:], b: [], c: false, d: nil, e: nil, f: nil)
//            }
//
//            private mutating func mapWith(mapper: Mapper) {
//                mapper.map(&a, forKey: "a")
//                mapper.map(&b, forKey: "à very long name that will øverflow into vstring Å.")
//                mapper.map(&c, forKey: "ç")
//                mapper.map(&d, forKey: "d (implicit optional)")
//                mapper.map(&e, forKey: "e (explicit optional)")
//                mapper.map(&f, forKey: "implicit f")
//            }

            static func createByDeserialisingWith(des: Deserialiser) throws -> AcyclicSerialisable {
                return try S(
                    a: des.deserialiseKey("a")!,
                    b: des.deserialiseKey("à very long name that will øverflow into vstring Å.")!,
                    c: des.deserialiseKey("ç")!,
                    d: des.deserialiseKey("d (implicit optional)"),
                    e: des.deserialiseKey("e (explicit optional)"),
                    f: des.deserialiseKey("implicit f")! as Bool
                )
            }

            func serialiseWith(ser: Serialiser) {
                ser.serialise(a, forKey: "a")
                ser.serialise(b, forKey: "à very long name that will øverflow into vstring Å.")
                ser.serialise(c, forKey: "ç")
                if let d = d { ser.serialise(d, forKey: "d (implicit optional)") }
                if let e = e { ser.serialise(e, forKey: "e (explicit optional)") }
                ser.serialise(f, forKey: "implicit f")
            }
        }
        
        
        let a = S(a: ["aoeu": 5, "cgp": -1], b: [4.6, 7.9], c: true, d: nil, e: [["ao´u", "Å"], []], f: false)
        
        let o = OutputStream()
        
        ObjSer.serialise(a, to: o)
//		print("bytes:", o.bytes.map { String($0, radix: 16) })
    
        let i = InputStream(bytes: o.bytes)
//		var x = 0
//		while i.hasBytesAvailable {
//			print(x, try? Primitive(readFrom: i))
//			x += 1
//		}
        do {
            let b = try ObjSer.deserialiseFrom(i) as S
            print("unarchived", b)
            
            XCTAssertEqual(String(a), String(b))
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testCyclePrevention() {
        
        let a = Cyclic()

        let o = OutputStream()
        ObjSer.serialise(a, to: o)
        print(o.bytes.map({ String($0, radix: 16) }).joinWithSeparator(" "))
        
        do {
            let b: Cyclic = try ObjSer.deserialiseFrom(InputStream(bytes: o.bytes))
            XCTAssert(a == b)
        }
        catch {
            XCTFail("\(error)")
        }
        
    }
    
    func testProtocolTypes() {
        
        let c = Cyclic()
        let a: [P] = [A(a: -32), B(b: 4.7), c]
        
        let o = OutputStream()
        ObjSer.serialise(a, to: o)
        print(o.bytes.map({ String($0, radix: 16) }).joinWithSeparator(" "))
        
        do {
            let b: [P] = try ObjSer.deserialiseFrom(InputStream(bytes: o.bytes), identifiableTypes: [A.self, B.self, Cyclic.self])
            print(String(a))
            print(String(b))
            XCTAssert(String(a) == String(b) && a[2] as! Cyclic == b[2] as! Cyclic)
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
    func testGenerics() {
        
        let a: [P] = [G<Int>(v: 15312)/*, G<Float>(v: 3.14)*/]

        let o = OutputStream()
        ObjSer.serialise(a, to: o)
        print(o.bytes.map({ String($0, radix: 16) }).joinWithSeparator(" "))
        
        do {
            let b: [P] = try ObjSer.deserialiseFrom(InputStream(bytes: o.bytes), identifiableTypes: [G<Int>.self, G<Float>.self])
            print(String(a))
            print(String(b))
            XCTAssert(String(a) == String(b))
        }
        catch {
            XCTFail("\(error)")
        }
    }
    
}
