package org.xtext.heapexplorer.types

import org.xtext.heapexplorer.types.HeapExplorerType

class CollectionType extends HeapExplorerType {
	
	@Property
	val HeapExplorerType baseType;
	
	new(String string, HeapExplorerType baseType) {
		super(string)
		this._baseType = baseType
	}
	
	override equals(Object o) {
		o != null && o.class == CollectionType && (o as CollectionType).baseType.equals(baseType)
	}
	
	override toString() '''
	Collection: «super.toString» with baseType: («baseType.toString»)'''
	
	
	override boolean superTypeOf(HeapExplorerType type) {
		type != null && 
		(type instanceof CollectionType) && 
		_baseType.superTypeOf((type as CollectionType).baseType)
	}
	
}