package org.xtext.heapexplorer.types

import java.util.List
import java.util.ArrayList
import org.apache.log4j.Logger

class HeapExplorerMethod {
	
	private static final Logger log = Logger.getLogger(typeof(HeapExplorerMethod))
	
	@Property
	val String name;
	
	@Property
	val HeapExplorerType returnType
	
	@Property
	val List<? extends HeapExplorerType> parameters;
	
	new(String n, HeapExplorerType returnType) {
		_name = n
		_returnType = returnType
		_parameters = new ArrayList<HeapExplorerType>
	}
	
	new(String n, HeapExplorerType returnType, List<? extends HeapExplorerType> parameters) {
		_name = n
		_returnType = returnType
		_parameters = parameters
	}
	
	def boolean areValidParametersForCall(List<HeapExplorerType> types) {
//		log.error("Expected " + parameters.size + " and found " + types.size)
		if (types.size != parameters.size)
			false
		else {
			var flags = true
			var i = 0
			while (i < types.size && flags) {
//				log.error("Expected " + parameters.get(i).name + " and found " + types.get(i).name)
				flags = HETypeFactory::isAssignable(types.get(i), parameters.get(i))
				i++;
			}
			flags
		}
	}
	
}