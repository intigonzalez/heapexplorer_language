package org.xtext.heapexplorer.types

import org.xtext.heapexplorer.types.HeapExplorerType
import java.util.List

class LambdaFunctionType extends HeapExplorerType {
	
	@Property
	val HeapExplorerType returnType;
	
	@Property
	val List<HeapExplorerType> params;
	
	new(String name, HeapExplorerType returnType, List<HeapExplorerType> params) {
		super(name)
		_returnType = returnType
		_params = params;
	}
	
	override equals(Object o) {
		if (o != null && o.class == LambdaFunctionType) {
			val l = o as LambdaFunctionType
			if (params.size != l.params.size)
				false
			else if (returnType != l.returnType)
				false
			else {
				var f = true
				var idx = 0
				while (idx < params.size && f) {
					f = params.get(idx) == l.params.get(idx)
					idx++	
				}
				f
			}
		}
		else false
	}
	
	override toString() '''
	LambdaType: «FOR p : params SEPARATOR '->'» «p.name» «ENDFOR» -> «returnType.toString»'''
	
}