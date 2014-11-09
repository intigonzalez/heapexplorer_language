package org.xtext.heapexplorer.types

import org.xtext.heapexplorer.types.HeapExplorerType
import java.util.List
import java.util.ArrayList
import org.apache.log4j.Logger

class ComposedType extends HeapExplorerType {
	
	private static final Logger log = Logger.getLogger(typeof(ComposedType))
	
	@Property
	private val ComposedType parent;
	
	private val List<Pair<String, HeapExplorerType>> _fields = new ArrayList();
	
	new(String name, List<Pair<String, HeapExplorerType>> fields) {
		super(name)
		this._fields.addAll(fields)
		_parent = null
	}
	
	new(String name, List<Pair<String, HeapExplorerType>> fields, ComposedType parent) {
		super(name)
		this._fields.addAll(fields)
		this._parent = parent
	}
	
	def addField(String string, HeapExplorerType type) {
		_fields.add(string -> type)
	}
	
	override equals(Object o) {
		var b = o != null && o.class == ComposedType && (o as ComposedType).name == name
		if (!b) return false
		val f1 = fields
		val f2 = (o as ComposedType).fields
		b = f1.size == f2.size
		if (b) {
			var i = 0
			while (i < f1.size && b) {
				val t1 = f1.get(i).value
				val t2 = f2.get(i).value
				b =(t1 === t2)
				b = b || (t1 == t2)
				i++;
			}
		}
		b
	}
	
	override toString() '''«super.toString»(with «fields.size» fields)'''
	
	def List<Pair<String, HeapExplorerType>> fields() {
		if(_parent != null)
		{
			val l = new ArrayList<Pair<String, HeapExplorerType>>
			l.addAll(_parent.fields)
			l.addAll(_fields)
			l
		}
		else _fields
	}
	
	override List<HeapExplorerMethod> methods() {
//		log.error("Calculating for 1 " + name + " => " + _parent + '=> ' + _methods.size + "=> " + (_parent != null))
		if (_parent != null){
//			log.error("Calculating for 2 " + name + " => " + _parent)
			val l = new ArrayList<HeapExplorerMethod>
			l.addAll(_parent.methods)
			l.addAll(_methods)
			l
		}
		else 
		return _methods
	}
	
	override boolean superTypeOf(HeapExplorerType type) {
//		log.error(String.format("00000 Comparing %s %s %s", this, type, (type as ComposedType)._parent))
//		val r = type != null && 
//		(type instanceof ComposedType) &&
//		(name == type.name || ((type as ComposedType)._parent != null && this.superTypeOf((type as ComposedType)._parent)))
//		log.error(String.format("11111 Comparing %s %s", this, type))
		var r = type != null && (type instanceof ComposedType)
		if (r) {
			val myFields = fields
			val otherFields = (type as ComposedType).fields;
			for (var i = 0 ; r && i<myFields.size ; i++) {
				r = ( myFields.get(i).value === otherFields.get(i).value) ||  myFields.get(i).value.superTypeOf(otherFields.get(i).value)
			}
		}
		r
	}
	
}