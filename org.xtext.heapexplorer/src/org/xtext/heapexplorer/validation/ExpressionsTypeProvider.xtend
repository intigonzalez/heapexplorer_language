package org.xtext.heapexplorer.validation

import org.xtext.heapexplorer.heapExplorer.Expression
import org.xtext.heapexplorer.heapExplorer.NumberLiteral
import org.xtext.heapexplorer.heapExplorer.StringLiteral
import org.xtext.heapexplorer.heapExplorer.BooleanLiteral
import org.xtext.heapexplorer.heapExplorer.Plus
import org.xtext.heapexplorer.heapExplorer.Minus
import org.xtext.heapexplorer.heapExplorer.MultiOrDiv
import org.xtext.heapexplorer.heapExplorer.ArithmeticSigned
import org.xtext.heapexplorer.heapExplorer.BooleanNegation
import org.xtext.heapexplorer.heapExplorer.AndOrExpression
import org.xtext.heapexplorer.heapExplorer.Comparison
import org.xtext.heapexplorer.heapExplorer.Equals
import org.xtext.heapexplorer.heapExplorer.Varr
import org.xtext.heapexplorer.types.HeapExplorerType
import org.xtext.heapexplorer.types.HETypeFactory
import org.xtext.heapexplorer.heapExplorer.Type
import org.xtext.heapexplorer.types.CollectionType
import org.xtext.heapexplorer.types.ComposedType
import org.xtext.heapexplorer.heapExplorer.TableType
import org.xtext.heapexplorer.heapExplorer.BaseType
import org.xtext.heapexplorer.heapExplorer.StructType
import org.xtext.heapexplorer.heapExplorer.CollectionLiteral
import org.xtext.heapexplorer.heapExplorer.StructLiteral
import org.xtext.heapexplorer.heapExplorer.Atomic
import org.apache.log4j.Logger
import org.xtext.heapexplorer.heapExplorer.MemberCall
import org.xtext.heapexplorer.heapExplorer.HeapExplorer
import java.util.ArrayList
import org.xtext.heapexplorer.heapExplorer.LambdaExpression
import org.xtext.heapexplorer.heapExplorer.EntityData
import org.xtext.heapexplorer.heapExplorer.GroupExpression
import org.xtext.heapexplorer.types.LambdaFunctionType
import org.xtext.heapexplorer.heapExplorer.Assignament
import org.xtext.heapexplorer.types.PointerType

class ExpressionsTypeProvider {
	
	public static HeapExplorerType unknownType = HETypeFactory::unknownType
	public static HeapExplorerType intType = HETypeFactory::intType
	public static HeapExplorerType stringType = HETypeFactory::stringType
	public static HeapExplorerType boolType = HETypeFactory::boolType
	public static HeapExplorerType objectType = HETypeFactory::objectType
	public static HeapExplorerType entityType = HETypeFactory::entityType
	
	private static final Logger log = Logger.getLogger(typeof(HeapExplorerValidator))
	
	def dispatch HeapExplorerType type(Type t) {
		if (t != null && t.definition != null) {
			HETypeFactory::getType(t.name, t.definition.type)
		}
		else
			unknownType
	}
	
	def dispatch HeapExplorerType type(StructType t) {
		val b = t.fields.forall[f|
			f.field_type != null && !f.field_type.type.equals(unknownType)
		]
		if (b) {
			new ComposedType(t.name, t.fields.map[
				it.name -> it.field_type.type
			])
		}
		else unknownType
	}
	
	def dispatch HeapExplorerType type(TableType t) {
		if (t.base_type != null) {
			val tt = t.base_type.type
			if (tt != unknownType)
				return new CollectionType(t.name, tt)	
		}
		unknownType
	}
	
	def dispatch HeapExplorerType type(BaseType t) {
		val l = HETypeFactory::builtInTypes.filter[it.name == t.name]
		if (!l.empty) l.get(0)
		else unknownType
	}
	
	def dispatch HeapExplorerType type(Expression exp) { 
		switch (exp) {
			NumberLiteral:intType
			StringLiteral:stringType
			BooleanLiteral:boolType
			default:unknownType
		}
	}
	
	def dispatch HeapExplorerType type(Varr exp) {
		val t = HETypeFactory::getBuilInPropertyType(exp.name)
		if (t == unknownType) {
			// check if it is an user-defined property
			val d = exp.eResource.allContents.filter(typeof(EntityData)).findFirst[
				it.name == exp.name
			]
			if (d != null) {
				d.type.type
			}
			else {
				// maybe it is a local variable within a lambda expression
				var c = exp.eContainer
				while (c!= null && !(c instanceof LambdaExpression)) {
//					log.error("TYPE OF THING " + c.eClass.name)
					c = c.eContainer
				}
				if (c != null) {
					val l = c as LambdaExpression
					if (l.lambdaParams != null && l.lambdaParams.exists[it.name == exp.name]) {
						val tt = l.lambdaParams.findFirst[it.name == exp.name].type.type
//						log.error("TYPE FOUND " + tt.name)
						new PointerType(tt)
					} else unknownType
				}
				else unknownType
			}
		}
		else 
		t
	}
	
	def dispatch HeapExplorerType type(ArithmeticSigned exp) {
		if (exp.expression.type.equals(intType))
			intType
		else
			unknownType
	}
	
	def dispatch HeapExplorerType type(BooleanNegation exp) {
		if (exp.expression.type.equals(boolType))
			boolType
		else
			unknownType
	}
	
	def dispatch HeapExplorerType type(Plus p) {
		if(p.left == null || p.right == null)
			unknownType
		else if (p.left.type.equals(intType) && p.right.type.equals(intType))
			intType
		else if (p.left.type.equals(stringType) && p.right.type.equals(stringType))
			stringType
		else {
			unknownType	
		}
	}
	
	def dispatch HeapExplorerType type(Minus p) { 
		if(p.left == null || p.right == null)
			unknownType
		else
		if (p.left.type.equals(intType) && p.right.type.equals(intType))
			intType
		else unknownType
	}
	
	def dispatch HeapExplorerType type(MultiOrDiv p) {
		if(p.left == null || p.right == null)
			unknownType
		else
		if (p.left.type.equals(intType) && p.right.type.equals(intType)) {
			intType
		}
		else unknownType
	}
	
	def dispatch HeapExplorerType type(AndOrExpression p) {
		if(p.left == null || p.right == null)
			unknownType
		else
		if (p.left.type.equals(boolType) && p.right.type.equals(boolType))
			boolType
		else unknownType
	}
	
	def dispatch HeapExplorerType type(Comparison p) {
		if(p.left == null || p.right == null)
			unknownType
		else
		if (p.op == "belongs-to") {
			if (p.left.type.equals(objectType) && p.right.type.equals(entityType))
				boolType
			else unknownType
		}
		else if (p.left.type.equals(intType) && p.right.type.equals(intType)) {
			boolType
		}
		else unknownType
	}
	
	def dispatch HeapExplorerType type(Equals p) {
		if(p.left == null || p.right == null)
			unknownType
		else if (p.left.type == p.right.type)
			boolType
		else unknownType
	}
	
	def dispatch HeapExplorerType type(Atomic a) {
		val callerType = a.atomic.type
		if (a.member == null || a.member.empty)
			callerType
		else {
			val m = a.member.get(0) as MemberCall
			if (callerType.methods.exists[it.name == m.name]){
				m.type(callerType)
			}
			else if (callerType instanceof ComposedType &&
					(callerType as ComposedType).fields.exists[
						it.key == m.name
					]
			) {
				m.type(callerType)
			}
			else if (callerType instanceof PointerType &&
					 (callerType as PointerType).pointTo instanceof ComposedType &&
					( (callerType as PointerType).pointTo as ComposedType).fields.exists[
						it.key == m.name
					]
			) {
				m.type((callerType as PointerType).pointTo)
			}
			else
				unknownType
			
		}
	}
	
	def HeapExplorerType type(MemberCall m, HeapExplorerType het) {
		if (het.methods.exists[it.name == m.name]) {
			val method = het.methods.findFirst[it.name == m.name]
			// check parameters
			val actualParamters = m.parameters.map[it.type]
			if (method.name != 'map' && method.areValidParametersForCall(actualParamters) == false) {
				unknownType
			}
			else if (m.member == null || m.member.empty) {
				if (method.name == 'map' && het instanceof CollectionType) {
					if (actualParamters.size == 1 && actualParamters.get(0) instanceof LambdaFunctionType) {
						val lt = actualParamters.get(0) as LambdaFunctionType
						if (1 == lt?.params.size && lt.params.get(0).equals((het as CollectionType).baseType) && !HETypeFactory::voidType.equals(lt.returnType))
							new CollectionType("", lt.returnType)
						else unknownType
					}
					else unknownType
				}
				else method.returnType	
			}
			else {
				val subcall = m.member.get(0) as MemberCall
				if (method.name == 'map' && het instanceof CollectionType) {
					if (actualParamters.size == 1 && actualParamters.get(0) instanceof LambdaFunctionType) {
						val lt = actualParamters.get(0) as LambdaFunctionType
						if (1 == lt?.params.size && lt.params.get(0).equals((het as CollectionType).baseType) && !HETypeFactory::voidType.equals(lt.returnType))
							subcall.type(new CollectionType("", lt.returnType))
						else unknownType
					}
					else unknownType
				}
				else subcall.type(method.returnType)
			}
		}
		else if (het instanceof ComposedType && (het as ComposedType).fields.exists[it.key == m.name]) {
			val returnType = (het as ComposedType).fields.findFirst[it.key == m.name].value
			if (m.member == null || m.member.empty)
				returnType
			else {
				val subcall = m.member.get(0) as MemberCall
//				if (returnType.methods.exists[it.name == subcall.name])
					subcall.type(returnType)
//				else
//					unknownType
			}
		}
		else unknownType
	} 
	
	def dispatch HeapExplorerType type(MemberCall method) {
			unknownType
	}
	
	def dispatch HeapExplorerType type(CollectionLiteral p) {
		val expressions = p.expressions
		if (expressions == null || expressions.empty)
			HETypeFactory::anyEmptyCollectionType
		else
		{
			var HeapExplorerType r = null
			for (exp : expressions) {
				val expType = exp.type
				if (r == null)
					r = expType
				else if (r != expType) {
					val ancestor = HETypeFactory::commonAncestor(r, expType)
					if (unknownType.equals(ancestor)) return unknownType
					r = ancestor
				}
			}
			new CollectionType("",r)
		}
	}
	
	def dispatch HeapExplorerType type(StructLiteral p) {
		if (p.expressions == null || p.expressions.empty)
			HETypeFactory::anyEmptyCollectionType
		else
		{
			if (p.expressions.exists[
				val t = it.type
				t == unknownType
			]) {
				unknownType
			}
			else {
				val structTypeTMP = p.eResource.allContents.filter(Type).filter[
					it.name != null
				].findFirst[name == p.struct_type.name && it.definition instanceof StructType]
				if (structTypeTMP != null) {
					val structType = structTypeTMP.definition as StructType
					val ty = p.expressions.map[it.type]
					val fieldsTmp = structType.fields
					if (fieldsTmp.size != ty.size) return unknownType
				
					val ArrayList<Pair<String, HeapExplorerType>> list = new ArrayList
					for (var i = 0 ; i < ty.size; i++) {
						list.add( structType.fields.get(i).name -> ty.get(i) )
					}
					return new ComposedType(p.struct_type.name, list)
				}
				else {
					val builtinType = HETypeFactory::builtInTypes.filter(typeof(ComposedType))
											.findFirst[it.name == p.struct_type.name] as ComposedType
					if (builtinType == null) return unknownType
					val fieldsBuiltIn = builtinType.fields // expected
					val ty = p.expressions.map[it.type] // observed
					if (fieldsBuiltIn.size != ty.size) return unknownType
					
					for (var i = 0 ; i < ty.size ; i++) {
						val e = ty.get(i).equals(fieldsBuiltIn.get(i).value)
						if (!e) 
							return unknownType
					}
					
					builtinType
					
//					val ArrayList<Pair<String, HeapExplorerType>> list = new ArrayList
//					for (var i = 0 ; i < ty.size; i++) {
//						list.add( fieldsBuiltIn.get(i).key -> ty.get(i) )
//					}
//					return new ComposedType(p.struct_type.name, list)
				}
			}
		}
	}
	
	def dispatch HeapExplorerType type(LambdaExpression exp) {
		val p = if (exp.lambdaParams == null) #[] else exp.lambdaParams.map[it.type.type]
		val ret = if (exp.returnValue != null) exp.returnValue.type
		else HETypeFactory::voidType
		new LambdaFunctionType("anonimousLambda", ret, p)
	}
	
	def dispatch HeapExplorerType type(GroupExpression e) {
		e.group.type
	}
	
	def dispatch HeapExplorerType type(Assignament a) {
		// check if it is an user-defined property
		val d = a.eResource.allContents.filter(typeof(EntityData)).findFirst[
			it.name == a.name
		]
		if (d != null) {
			d.type.type
		}
		else {
			// maybe it is a local variable within a lambda expression
			var c = a.eContainer
			while (c!= null && !(c instanceof LambdaExpression)) {
				c = c.eContainer
			}
			if (c != null) {
				val l = c as LambdaExpression
				if (l.lambdaParams != null && l.lambdaParams.exists[it.name == a.name]) {
					val tt = l.lambdaParams.findFirst[it.name == a.name].type.type
					new PointerType(tt)
				} else unknownType
			}
			else unknownType
		}
	}
}