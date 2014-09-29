package org.xtext.heapexplorer.types

import java.util.HashMap
import java.util.List
import org.xtext.heapexplorer.heapExplorer.HeapExplorer
import java.util.ArrayList
import org.apache.log4j.Logger

class HETypeFactory {
	static val private HeapExplorerType _stringType = new HeapExplorerType("string")
	static val private HeapExplorerType _intType = new HeapExplorerType("int")
	static val public HeapExplorerType boolType = new HeapExplorerType("bool")
	static val public HeapExplorerType doubleType = new HeapExplorerType("double")
	static val public HeapExplorerType voidType = new HeapExplorerType("void")
	static val public HeapExplorerType unknownType = new HeapExplorerType("unknownType")
	static val public HeapExplorerType anyEmptyCollectionType = new CollectionType("anyEmptyCollection", unknownType)
	
	// objects
	static val private ComposedType _objectType = new ComposedType("Object",#[])
	static val public CollectionType objectCollectionType = new CollectionType("Objects", _objectType)
	
	// Threads
	static val private ComposedType _threadType = new ComposedType("Thread",#[
		"name"->_stringType
	], _objectType)
	static val public CollectionType threadCollectionType = new CollectionType("Threads", _threadType)
	
	// ClassLoaders
	static val private ComposedType _classloaderType = new ComposedType("ClassLoader",#[], _objectType)
	static val public CollectionType classloaderCollectionType = new CollectionType("ClassLoaders", _classloaderType)
	
	// Thread Groups
	static val private ComposedType _threadGroupType = new ComposedType("ThreadGroup",#[
		"name"->_stringType
	], _objectType)
	static val public CollectionType threadGroupCollectionType = new CollectionType("ThreadGroups", _threadGroupType)
	
	// interfaces
	static val private CollectionType interfacesType = new CollectionType("Interfaces", _intType)
	
	// classes
	static val private ComposedType _classType = new ComposedType("Class",#[
		"name"->_stringType,
		"interfaces" -> interfacesType
	], _objectType)
	static val public CollectionType classesCollectionType = new CollectionType("Classes", _classType)
	
	
	// entities
	static val public ComposedType entityType = new ComposedType("entity", #["name" -> stringType])
	
	static val public List<? extends HeapExplorerType> builtInTypes = #[
		intType, stringType,boolType,doubleType, voidType, // basic types
		objectType, objectCollectionType, // objects
		threadType, threadCollectionType, // threads
		threadGroupType, threadGroupCollectionType, // thread groups
		classloaderType, classloaderCollectionType, // classloaders
		interfacesType,
		classType, classesCollectionType // classes
	];
	
	public static def HeapExplorerType stringType() {
		if (_stringType.methods.size == 0) {
			_stringType.addMethods(#[new HeapExplorerMethod("toInt", _intType)])
		}
		_stringType
	}
	
	public static def HeapExplorerType intType() {
		if (_intType.methods.size == 0) {
			_intType.addMethods(#[new HeapExplorerMethod("toString", stringType)])
		}
		_intType
	}
	
	public static def HeapExplorerType objectType() {
		if (_objectType.methods.size == 0) {
			_objectType.addMethods(#[
				new HeapExplorerMethod("id", _intType),
				new HeapExplorerMethod("idClass", _intType)
//				new HeapExplorerMethod("size", _intType)
			])
			_objectType.addField("size", _intType)
		}
		_objectType
	}
	
	public static def HeapExplorerType threadType() {
		if (_objectType.methods.size == _threadType.methods.size) {
			_threadType.addMethods(#[
				new HeapExplorerMethod("idGroup", _intType),
				new HeapExplorerMethod("idClassLoader", _intType)
			])
		}
		_threadType
	}
	
	public static def HeapExplorerType classloaderType() {
		if (_objectType.methods.size == _classloaderType.methods.size) {
			_classloaderType.addMethods(#[
				new HeapExplorerMethod("idParent", _intType)
			])
		}
		_classloaderType
	}
	
	public static def HeapExplorerType threadGroupType() {
		if (_objectType.methods.size == _threadGroupType.methods.size) {
			_threadGroupType.addMethods(#[
				new HeapExplorerMethod("idParent", _intType)
			])
		}
		_threadGroupType
	}
	
	public static def HeapExplorerType classType() {
		if (_objectType.methods.size == _classType.methods.size) {
			_classType.addMethods(#[
				new HeapExplorerMethod("idParent", _intType),
				new HeapExplorerMethod("idClassLoader", _intType)
			])
		}
		_classType
	}
	
	static val private HashMap<String, HeapExplorerType> builtInProperties = new HashMap()
	
	def static getBuilInPropertyType(String propertyName) {
		if (builtInProperties.empty) {
			builtInProperties.put("NONE", entityType)
			builtInProperties.put("THIS", objectType)
			builtInProperties.put("THIS_ENTITY", entityType)
			builtInProperties.put("REFERRER", objectType)
			builtInProperties.put("threads", threadCollectionType)
			builtInProperties.put("classes", classesCollectionType)
		}
		if (builtInProperties.containsKey(propertyName))
			builtInProperties.get(propertyName)
		else
			unknownType
	}
	
	def dispatch static getType(String name, HeapExplorerType type) {
		return type
	}
	
	def dispatch static getType(String name, CollectionType type) {
		new CollectionType(name, type.baseType)
	}
	
	def dispatch static getType(String name, ComposedType type) {
		val List<Pair<String, HeapExplorerType>> l = new ArrayList();
		for (var int i = 0 ; i < type.fields.size ; i++)
			l.add(type.fields.get(i).key -> type.fields.get(i).value)
		new ComposedType(name, l)
	}
	
	def static isCollectionOf(HeapExplorerType type, HeapExplorerType baseType) {
		type.class == CollectionType && (type as CollectionType).baseType.equals(baseType)
	}
	
	
	def static HeapExplorerType commonAncestor(HeapExplorerType t0, HeapExplorerType t1) {
		if (t0 instanceof ComposedType && t1 instanceof ComposedType) {
			var _t0 = t0 as ComposedType
			var _t1 = t1 as ComposedType
			val p0 = new ArrayList<ComposedType>()
			val p1 = new ArrayList<ComposedType>()
			while (_t0 != null) {
				p0.add(_t0)
				_t0 = _t0.parent
			}
			while (_t1 != null) {
				p1.add(_t1)
				_t1 = _t1.parent
			}
			val _p0 = p0.reverse
			val _p1 = p1.reverse
			var r = unknownType
			val min = Math.min(_p0.size, _p1.size)
			for (var i = 0 ; i < min ; i++) {
				val r1 = _p1.get(i)
				val r0 = _p0.get(i)
				if (r0 == r1)
					r = r0
				else
					return r
			}
			r
		}
	}
	
	def static boolean needLocalEnvironment(String name) {
		val map = new HashMap<String, Boolean>
		#["membership" -> true, "on_inclusion" ->true, "root_objects" -> false].forEach[
			map.put(it.key, it.value)
		]
		if (map.containsKey(name)) map.get(name)
		else false
	}
	
}