//
//  ObjSer.swift
//  ObjSer
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

public enum DeserialiseError: ErrorType {
    
    case EmptyInput
    case IncorrectType(Any)
    case ConversionFailed(Any)
    case UnidentifiableType(Serialisable.Type)
    case UnknownTypeID(String)
    case IdentifiableTypeMismatch(type: Serialisable.Type, shouldConformTo: Serialisable.Type)
    
}

public final class ObjSer {

    public class func serialise<T : Serialisable>(v: T, to stream: OutputStream) {
        let s = Serialiser()
        s.serialiseRoot(v)
        s.writeTo(stream)
    }

    public class func deserialiseFrom<R : Serialisable>(stream: InputStream, identifiableTypes: [Serialisable.Type] = []) throws -> R {
        return try Deserialiser(readFrom: stream, identifiableTypes: identifiableTypes).deserialiseRoot()
    }
    
}
