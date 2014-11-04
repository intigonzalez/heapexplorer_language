package org.xtext.heapexplorer.types

import java.util.List
import java.util.ArrayList

class HeapExplorerType {
	@Property
	val String name
		
	protected val List<HeapExplorerMethod>  _methods = new ArrayList
	
	new(String name) {
		_name = name
	}
	
	new(String name, List<HeapExplorerMethod> m) {
		_name = name
		_methods.addAll(m)
	}
	
	override toString() {
		_name
	}
	
	override equals(Object o) {
		o!= null && o.class == HeapExplorerType && (o as HeapExplorerType).name == _name
	}
	
	def addMethod(HeapExplorerMethod m) {
		_methods.add(m)
	}
	
	def addMethods(List<HeapExplorerMethod> m) {
		_methods.addAll(m)
	}
	
	def List<HeapExplorerMethod> methods() {
		_methods
	}
	
	def boolean canReceive(HeapExplorerType type) {
		type != null && this.superTypeOf(type)
	}
	
	def boolean superTypeOf(HeapExplorerType type) {
		type != null && _name == type._name
	}
	
}