//
//  Archiver.swift
//  AOGF
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

final class Archiver: Mapper {
	
	// MARK: Initialisers
	
	init<T : Archiving>(encodeRootObject obj: T) {
		index(obj)
	}
	
	// MARK: Indexing
	
	private var objects = ContiguousArray<ArchiveType>()
	private var objectIDs = [(UnsafePointer<Void>) : Int]()
	
	private func index(v: Archiving) -> Int {
		if let v = v as? Encoding {
			let ev = v.encodedValue
			switch ev.value {
			case .Type(let t):
				let id = objects.count
				objects.append(t)
				return id
			case .EncodingArray(let s):
				let id = objects.count
				objects.append(.Placeholder)
				var a = ArchiveTypeArray()
				a.reserveCapacity(s.underestimateCount())
				for v in s {
					a.append(.Unresolved(index(v)))
				}
				objects[id] = .Array(a)
				return id
			case .EncodingMap(let s):
				let id = objects.count
				objects.append(.Placeholder)
				var a = ArchiveTypeArray()
				a.reserveCapacity(s.underestimateCount() * 2)
				for (k, v) in s {
					a.append(.Unresolved(index(k)))
					a.append(.Unresolved(index(v)))
				}
				objects[id] = .Map(a)
				return id
			case .EncodingValue(let v):
				return index(v)
			default:
				preconditionFailure("Could not index case \(ev.value).")
			}
		}
		else if let v = v as? Mapping {
			// Only objects can cause cycles
			if let o = v as? AnyObject {
				let addr = unsafeAddressOf(o)
				if let id = objectIDs[addr] {
					return id
				}
				else {
					objectIDs[addr] = objects.count
				}
			}
			let id = objects.count
			objects.append(.Placeholder)
			
			objects[id] = .Map(map(v))
			
			return id
		}
		else {
			archivingConformanceFailure(v.dynamicType)
		}
	}
	
	// MARK: Mapper
	
	private var maps = ContiguousArray<ArchiveTypeArray>()
	
	func lastMapAppend(v: ArchiveType) {
		maps[maps.count-1].append(v)
	}
	
	private func map(var v: Mapping) -> ArchiveTypeArray {
		maps.append(ArchiveTypeArray())
		v.archiveMap(self)
		return maps.popLast()!
	}
	
	func map<V : Archiving>(inout v: V, forKey key: String) {
		lastMapAppend(.Unresolved(index(key)))
		lastMapAppend(.Unresolved(index(v)))
	}
	
	// MARK: Output
	
	func writeTo(stream: OutputStream) {
		let n = objects.count
		// Write in reverse order, since the root object must be last.
		for t in objects.reverse() {
			// Resolve the ids so the largest is the root object, as it should be the least referenced
			// TODO: count object references and sort by count, so most used objects get smaller ids
			t.writeTo(stream, resolver: { .Reference(UInt32(n-$0-1)) })
		}
	}
	
}
