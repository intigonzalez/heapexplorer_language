package org.xtext.heapexplorer.types

class HeapExplorerMethod {
	@Property
	val String name;
	
	@Property
	val HeapExplorerType returnType
	
	new(String n, HeapExplorerType returnType) {
		_name = n
		_returnType = returnType
	}
	
	
}