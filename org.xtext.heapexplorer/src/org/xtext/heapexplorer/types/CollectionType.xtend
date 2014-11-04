package org.xtext.heapexplorer.types

import org.xtext.heapexplorer.types.HeapExplorerType

class CollectionType extends HeapExplorerType {
	
	public static val String[] methods_for_collections = #[
		"append",
		"foreach"
	];
	
	@Property
	val HeapExplorerType baseType;
	
	new(String string, HeapExplorerType baseType) {
		super(string)
		this._baseType = baseType
		this.addMethod(new HeapExplorerMethod("append", this, #[ this ]))
		this.addMethod(new HeapExplorerMethod("foreach", HETypeFactory::voidType, #[ HETypeFactory::createLambdaAction(baseType) ]))
		this.addMethod(new HeapExplorerMethod("filter", this, #[ HETypeFactory::createLambdaPredicate(baseType) ]))
		this.addMethod(new HeapExplorerMethod("forall", HETypeFactory::boolType, #[ HETypeFactory::createLambdaPredicate(baseType) ]))
		this.addMethod(new HeapExplorerMethod("exists", HETypeFactory::boolType, #[ HETypeFactory::createLambdaPredicate(baseType) ]))
		this.addMethod(new HeapExplorerMethod("findfirst", baseType, #[ HETypeFactory::createLambdaPredicate(baseType) ]))
		this.addMethod(new HeapExplorerMethod("map", this, #[ new LambdaFunctionType("mapper", baseType, #[baseType]) ]))
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