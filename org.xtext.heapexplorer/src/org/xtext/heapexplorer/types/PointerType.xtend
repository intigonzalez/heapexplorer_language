package org.xtext.heapexplorer.types

import org.xtext.heapexplorer.types.HeapExplorerType
import java.util.List

class PointerType extends HeapExplorerType {
	
	@Property
	val HeapExplorerType pointTo 
	
	new(HeapExplorerType pointTo) {
		super("P" + pointTo.name)
		_pointTo = pointTo
	}
	
	override equals(Object o) {
		o!= null && o.class == PointerType && (o as PointerType).pointTo == _pointTo
	}
	
	override addMethod(HeapExplorerMethod m) {
		throw new UnsupportedOperationException
	}
	
	override addMethods(List<HeapExplorerMethod> m) {
		throw new UnsupportedOperationException
	}
	
	override List<HeapExplorerMethod> methods() {
		pointTo.methods
	}
	
	override boolean canReceive(HeapExplorerType type) {
		this.equals(type) || this.pointTo.canReceive(type)
	}
	
	override boolean superTypeOf(HeapExplorerType type) {
		throw new UnsupportedOperationException
	}
}