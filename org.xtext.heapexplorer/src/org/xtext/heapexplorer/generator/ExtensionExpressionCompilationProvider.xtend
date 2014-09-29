package org.xtext.heapexplorer.generator

import org.xtext.heapexplorer.heapExplorer.Expression
import org.xtext.heapexplorer.heapExplorer.NumberLiteral
import org.xtext.heapexplorer.heapExplorer.Varr
import org.xtext.heapexplorer.heapExplorer.Plus
import org.xtext.heapexplorer.heapExplorer.Minus
import org.xtext.heapexplorer.heapExplorer.Atomic
import org.xtext.heapexplorer.heapExplorer.BooleanLiteral
import org.xtext.heapexplorer.heapExplorer.BooleanNegation
import org.xtext.heapexplorer.heapExplorer.ArithmeticSigned
import org.xtext.heapexplorer.heapExplorer.MultiOrDiv
import org.xtext.heapexplorer.heapExplorer.Equals
import org.xtext.heapexplorer.heapExplorer.Comparison
import org.xtext.heapexplorer.heapExplorer.AndOrExpression
import org.xtext.heapexplorer.heapExplorer.LambdaExpression
import org.xtext.heapexplorer.heapExplorer.Assignament
import org.xtext.heapexplorer.heapExplorer.GroupExpression
import org.xtext.heapexplorer.heapExplorer.EntityData
import org.xtext.heapexplorer.heapExplorer.ComponentType
import java.util.Stack
import org.xtext.heapexplorer.validation.CachedExpressionsTypeProvider
import javax.inject.Inject
import org.xtext.heapexplorer.types.HeapExplorerType
import org.xtext.heapexplorer.heapExplorer.BaseType
import org.xtext.heapexplorer.heapExplorer.StructType
import org.xtext.heapexplorer.heapExplorer.TableType
import org.xtext.heapexplorer.heapExplorer.Type
import org.xtext.heapexplorer.types.HETypeFactory
import org.xtext.heapexplorer.types.ComposedType
import org.xtext.heapexplorer.types.CollectionType
import org.xtext.heapexplorer.heapExplorer.MemberCall
import org.xtext.heapexplorer.validation.ExpressionsTypeProvider
import org.apache.log4j.Logger
import org.xtext.heapexplorer.heapExplorer.Instance
import org.xtext.heapexplorer.heapExplorer.StringLiteral

class ExtensionExpressionCompilationProvider {
	
	private static final Logger log = Logger.getLogger(typeof(ExtensionExpressionCompilationProvider))
	
	@Inject extension ExpressionsTypeProvider
	
	val stack = new Stack<String>
	
	var count = 0;
	
	private def String allocateTmp() {
		'''tmp«count++»'''
	}
	
		// types
	def dispatch String c_representation(BaseType t) {
		if (t.name == "bool")	"int"
		else if (t.name == "string") "char*"
		else t.name
	}
	
	def String c_declare_var(HeapExplorerType t) {
		switch (t) {
			ComposedType:t.name
			CollectionType: "List*" //t.name
			default: {
				if (t.name == "bool")	"int"
				else if (t.name == "string") "char*"
				else t.name
			}
		}
	}

	def dispatch String c_representation(StructType s) '''
		typedef struct {
			«FOR f:s.fields»
			«f.field_type.name» «f.name»;
			«ENDFOR»
		} '''
	
	def dispatch String c_representation(TableType tt) 
	//'''typedef «tt.base_type.name» * '''
	'''List* '''
	
	def dispatch String c_representation(Type t) '''
		«t.definition.c_representation» «t.name»; '''
	
	def dispatch String compile_to_c(ComponentType c) {
		var result = ""
		for (p : c.properties) {
			val localEnvironment = HETypeFactory::needLocalEnvironment(p.property.name)
			val expression = p.expression.compile_to_c
			val l = if (p.property.type.type != HETypeFactory::voidType) stack.pop else ""
			val s1 = 
			'''
			«p.property.type.type.c_declare_var»
			«c.name»_«p.property.name»(«IF localEnvironment»LocalEnvironment* env, 
					void* ud«ELSE»EntityEnvironment* env,
					void* ud«ENDIF»)
			{
				«ConstantValuesForGeneration::PRINCIPAL_DATA»* princ = 
					(«ConstantValuesForGeneration::PRINCIPAL_DATA»*)ud;
				«expression»
				«IF p.property.type.type != HETypeFactory::voidType»return «l»;«ENDIF»
			}
			'''
			result += s1
		}
		result
	}
	
	def dispatch String compile_to_c(Expression e) '''FUCK(«e.class»)'''
	def dispatch String compile_to_c(GroupExpression e) '''«e.group.compile_to_c»''' 
	
	// literals
	def dispatch String compile_to_c(NumberLiteral e) {
		val s = '''«e.value»'''
		stack.push(s)
		''
	}
	def dispatch String compile_to_c(BooleanLiteral e) {
		val s = '''«if (e.value=='true')"1"else "0"»'''
		stack.push(s)
		''
	}
	def dispatch String compile_to_c(StringLiteral e) {
		stack.push('''"«e.value»"''')
		''
	}
	// variables
	def dispatch String compile_to_c(Varr e) {
		var s = '''princ->«e.name»'''
		val flag = e.eResource.allContents.filter(typeof(EntityData)).exists[it.name == e.name]
		if (!flag) {
			// it's not an user-defined property
			s='''«e.name»'''
		}
		stack.push(s)
		''
	}
	
	// arithmetic operators
	def dispatch String compile_to_c(ArithmeticSigned e) {
		val s0 = e.expression.compile_to_c()
		val resultLocation = stack.pop
		val tmp = allocateTmp()
	 	val s1 = '''«e.expression.type.c_declare_var» «tmp» = -«resultLocation»;
	 	''' // FIXME: it is not name but c_representation or something like that
	 	stack.push(tmp)
	 	s0 + s1
	}
	def dispatch String compile_to_c(Plus e) {
		val s0 = '''«e.left.compile_to_c()»«e.right.compile_to_c()»'''
		val l_right = stack.pop
		val l_left = stack.pop
		val tmp = allocateTmp()
		val s1 = '''«e.type.c_declare_var» «tmp» = «l_left» + «l_right»;
		'''
		stack.push(tmp)
		s0 + s1
	}
	def dispatch String compile_to_c(Minus e) {
		val s0 = '''«e.left.compile_to_c()»«e.right.compile_to_c()»'''
		val l_right = stack.pop
		val l_left = stack.pop
		val tmp = allocateTmp()
		val s1 = '''«e.type.c_declare_var» «tmp» = «l_left» - «l_right»;
		'''
		stack.push(tmp)
		s0 + s1
	}
	def dispatch String compile_to_c(MultiOrDiv e) {
		val s0 = '''«e.left.compile_to_c()»«e.right.compile_to_c()»'''
		val l_right = stack.pop
		val l_left = stack.pop
		val tmp = allocateTmp()
		val s1 = '''«e.type.c_declare_var» «tmp» = «l_left» «e.op» «l_right»;
		'''
		stack.push(tmp)
		s0 + s1
	} 

	def dispatch String compile_to_c(Atomic e) {
		var r = e.atomic.compile_to_c()
		var HeapExplorerType ty = e.atomic.type
		if (ty == HETypeFactory::voidType) r
		else {
			var s0 = stack.pop
			if (e.member !=null && e.member.size > 0) {
				var MemberCall mc = e.member.get(0)
				
				while (mc != null) {
					val tmp = allocateTmp()
					val memberName = mc.name
					val isMethod = ty.methods.exists[it.name == memberName]
					if (!isMethod)
						log.error("AQUI VIENE EL ERROR " + memberName)
					ty = mc.type(ty)
					r += '''«ty.c_declare_var» «tmp» = «s0»->«mc.name»«IF isMethod»()«ENDIF»;
					'''
					s0 = tmp
					mc = if (mc.member == null || mc.member.size == 0) null else mc.member.get(0)
				}
			}
			stack.push(s0)
			r
		}
	}
	
	// logical operators
	def dispatch String compile_to_c(BooleanNegation e) {
		val s0 = e.expression.compile_to_c()
		val resultLocation = stack.pop
		val tmp = allocateTmp()
	 	val s1 = '''«e.expression.type.c_declare_var» «tmp» = !«resultLocation»;
	 	''' // FIXME: it is not name but c_representation or something like that
	 	stack.push(tmp)
	 	s0 + s1
	}
	def dispatch String compile_to_c(AndOrExpression e)  {
		val s0 = '''«e.left.compile_to_c()»«e.right.compile_to_c()»
		'''
		val l_right = stack.pop
		val l_left = stack.pop
		val tmp = allocateTmp()
		val s1 = '''«e.type.c_declare_var» «tmp» = «l_left» «e.op» «l_right»;
		'''
		stack.push(tmp)
		s0 + s1
	} 
	
	// quantifiers
	def dispatch String compile_to_c(Equals e)  {
		val s0 = '''«e.left.compile_to_c()»«e.right.compile_to_c()»
		'''
		val l_right = stack.pop
		val l_left = stack.pop
		val tmp = allocateTmp()
		val s1 = '''«e.type.c_declare_var» «tmp» = «l_left» «e.op» == «l_right»;
		'''
		stack.push(tmp)
		s0 + s1
	} 
	def dispatch String compile_to_c(Comparison e) {
		if (e.op == "belongs-to") { /// ahahabhahahah, ugly FIXME
			val s0 = '''«e.left.compile_to_c()»«e.right.compile_to_c()»'''
			val l_0 = stack.pop
			val l_1 = stack.pop
			val tmp = allocateTmp()
			val s1 = '''«e.type.c_declare_var» «tmp» = belongs_to(«l_1»,«l_0»);
			'''
			stack.push(tmp)
			s0 + s1
		}
		else  {
			val s0 = '''«e.left.compile_to_c()»«e.right.compile_to_c()»'''
			val l_right = stack.pop
			val l_left = stack.pop
			val tmp = allocateTmp()
			val s1 = '''«e.type.c_declare_var» «tmp» = «l_left» «e.op» «l_right»;
			'''
			stack.push(tmp)
			s0 + s1
		} 
	}
	
	// lambda expressions
	def dispatch String compile_to_c(LambdaExpression e) '''
	«FOR a:e.assignaments»
	«a.compile_to_c()»
	«ENDFOR»
	'''
	
	def dispatch String compile_to_c(Assignament a) {
		val s0 = a.expression.compile_to_c()
		val l = stack.pop
		val s1 = '''princ->«a.name» = «l»;
		'''
		s0 + s1
	}
	
	def dispatch String compile_to_c(Instance ins) {
		val typeExp = ins.names.type
		val expression = ins.names.compile_to_c
		val l = if (stack.isEmpty) '' else stack.pop
		val s1 = 
		'''
		«typeExp.c_declare_var»
		«ins.name.name»_init_names(GlobalEnvironment* env)
		{
			«expression»
			return «l»;
		}
		'''
		s1
	}
	
}