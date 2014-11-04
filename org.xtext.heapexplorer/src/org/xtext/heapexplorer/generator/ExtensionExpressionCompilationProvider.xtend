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
import org.xtext.heapexplorer.heapExplorer.CollectionLiteral
import org.xtext.heapexplorer.heapExplorer.StructLiteral
import java.util.HashMap
import org.xtext.heapexplorer.types.PointerType
import org.xtext.heapexplorer.types.LambdaFunctionType

class ExtensionExpressionCompilationProvider {
	
	private static final Logger log = Logger.getLogger(typeof(ExtensionExpressionCompilationProvider))
	
	@Inject extension ExpressionsTypeProvider
	
	val stack = new Stack<String>
	
	var count = 0;
	
	private def String allocateTmp() {
		'''tmp«count++»'''
	}
	
	private def String lastAllocatedTmp () '''tmp«count-1»'''
	
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
	'''typedef List* '''
	
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
	def dispatch String compile_to_c(StructLiteral e) {
		val tmp = allocateTmp();
		stack.push(tmp)
		val type = e.type as ComposedType
		val s0 = '''«type.c_declare_var» «tmp»;''' + '\n'
		val builder = new StringBuilder
		type.fields.forEach[f, idx|
			builder.append(e.expressions.get(idx).compile_to_c)
			val t = stack.pop
			builder.append('''«tmp».«f.key» = «t»;''' + '\n')
		]
		s0 + builder.toString
	}
	def dispatch String compile_to_c(CollectionLiteral e) {
		val tmp = allocateTmp()
		stack.push(tmp)
		val type = (e.type as CollectionType).baseType
		'''List* «tmp» = create_list();«FOR sub : e.expressions»
		«sub.compile_to_c»
		«type.c_declare_var»* «allocateTmp» = («type.c_declare_var»*)malloc(sizeof(«type.c_declare_var»));
		*«lastAllocatedTmp» = «stack.pop»;
		add_to_list(«tmp»,«lastAllocatedTmp»);
		«ENDFOR»
		'''
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
	 	'''
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
		val StringBuilder r = new StringBuilder(e.atomic.compile_to_c())
		var HeapExplorerType ty = e.atomic.type
		if (ty == HETypeFactory::voidType || ((ty instanceof LambdaFunctionType) && (ty as LambdaFunctionType).returnType == HETypeFactory::voidType) ) r.toString
		else {
			if (stack.isEmpty)
				log.error(" POR QUEEEEEEEEEEEEEEEEE " + e.atomic.eClass.name + "\n" + e.atomic.compile_to_c)
			var s0 = stack.pop
			if (e.member !=null && e?.member.size > 0) {
				var MemberCall mc = e.member.get(0)
				
				while (mc != null) {
					val info = ty.c_get_Member(s0, mc)
					r.append(info.key)
					ty = info.value
					s0 = stack.pop
					mc = if (mc.member == null || mc.member.size == 0) null else mc.member.get(0)
				}
			}
			stack.push(s0)
			r.toString
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
	«IF e.returnValue != null»
	«e.returnValue.compile_to_c»
	«ENDIF»
	'''
	
	def dispatch String compile_to_c(Assignament a) {
		val tyAss = a.type
		if (tyAss instanceof PointerType) {
			val s0 = a.expression.compile_to_c()
			val l = stack.pop
			val s1 = '''*«a.name» = «l»;
			'''
			s0 + s1
		}
		else {
			val s0 = a.expression.compile_to_c()
			val l = stack.pop
			val s1 = '''princ->«a.name» = «l»;
			'''
			s0 + s1
		}
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
	
	// =================================================================
	// to obtain the value of members i.e. Point.p 
	// =================================================================
	def dispatch Pair<String, HeapExplorerType> c_get_Member(HeapExplorerType type, String source, MemberCall mc) {
		throw new UnsupportedOperationException("TODO111: auto-generated method stub " + source + " " + mc.name + " " + type.class.name + " " + type.name)
	}
	def dispatch Pair<String, HeapExplorerType> c_get_Member(PointerType type, String source, MemberCall mc) {
		val tyTmp = mc.type(type.pointTo)
		val isMethod = type.methods.exists[it.name == mc.name]
		val tmp = allocateTmp
		stack.push(tmp)
		'''
		«tyTmp.c_declare_var» «tmp» = «source»->«mc.name»«IF isMethod»()«ENDIF»;
		'''->tyTmp
	}
	def dispatch Pair<String, HeapExplorerType> c_get_Member(ComposedType type, String source, MemberCall mc) {
		val tyTmp = mc.type(type)
		val isMethod = type.methods.exists[it.name == mc.name]
		val isBuiltIn = HETypeFactory.builtInTypes.exists[it == type]
		val tmp = allocateTmp
		stack.push(tmp)
		'''
		«tyTmp.c_declare_var» «tmp» = «source»«IF isBuiltIn»->«ELSE».«ENDIF»«mc.name»«IF isMethod»()«ENDIF»;
		'''->tyTmp
	}
	def dispatch Pair<String, HeapExplorerType> c_get_Member(CollectionType type, String source, MemberCall mc) {
		if (mc.name == 'append') {
			// generate parameter
			val s0 = 
			'''
			«mc.parameters.get(0).compile_to_c»
			'''
			// get the l-value that contains the parameter value
			val tmpSrc = stack.pop
			val tmpDst = allocateTmp
			stack.push(tmpDst)
			s0 + '''
			List* «tmpDst» = append(«source», «tmpSrc»);
			'''->type
		}
		else if (mc.name == 'findfirst') {
			
			val tmp = allocateTmp
			val tmpR = allocateTmp
			val tmpr0 = allocateTmp
			stack.push(tmpR)
			val lambda = (mc.parameters.get(0) as Atomic).atomic as LambdaExpression
			val rTy = type.methods.findFirst[it.name == mc.name].returnType
			'''
			bool «tmp»(void* data, void* user_data) {
				«type.baseType.c_declare_var»* «lambda.lambdaParams.get(0).name» = («type.baseType.c_declare_var»*) data;
				«lambda.compile_to_c»
				return «stack.pop»;
			}
			«rTy.c_declare_var»* «tmpr0» = «mc.name»(«source», «tmp», NULL);
			if («tmpr0» == NULL) {
				«rTy.c_declare_var» v;
				«tmpr0» = &v;
				memset(«tmpr0», 0, sizeof(«rTy.c_declare_var»));
			}
			«rTy.c_declare_var» «tmpR» = *«tmpr0»;
			'''->rTy
		}
		else if (mc.name == 'foreach') {
			val tmp = allocateTmp
			stack.push("nothing")
			val lambda = (mc.parameters.get(0) as Atomic).atomic as LambdaExpression
			'''
			void «tmp»(void* data, void* user_data) {
				«type.baseType.c_declare_var»* «lambda.lambdaParams.get(0).name» = («type.baseType.c_declare_var»*) data;
				«lambda.compile_to_c»
			}
			foreach(«source», «tmp», NULL);
			'''->HETypeFactory::voidType
		} 
		else if (mc.name == 'filter') {
			val tmp = allocateTmp
			val tmpR = allocateTmp
			stack.push(tmpR)
			val lambda = (mc.parameters.get(0) as Atomic).atomic as LambdaExpression
			'''
			bool «tmp»(void* data, void* user_data) {
				«type.baseType.c_declare_var»* «lambda.lambdaParams.get(0).name» = («type.baseType.c_declare_var»*) data;
				«lambda.compile_to_c»
				return «stack.pop»;
			}
			List* «tmpR» = filter(«source», «tmp», NULL);
			'''->type.methods.findFirst[it.name == mc.name].returnType
		}
		else if (mc.name == 'forall' || mc.name == 'exists') {
			val tmp = allocateTmp
			val tmpR = allocateTmp
			stack.push(tmpR)
			val lambda = (mc.parameters.get(0) as Atomic).atomic as LambdaExpression
			val rTy = type.methods.findFirst[it.name == mc.name].returnType
			'''
			bool «tmp»(void* data, void* user_data) {
				«type.baseType.c_declare_var»* «lambda.lambdaParams.get(0).name» = («type.baseType.c_declare_var»*) data;
				«lambda.compile_to_c»
				return «stack.pop»;
			}
			«rTy.c_declare_var» «tmpR» = «mc.name»(«source», «tmp», NULL);
			'''->rTy
		}
		else if (mc.name == 'map') {
			val tmp = allocateTmp
			val tmpR = allocateTmp
			stack.push(tmpR)
			val lambda = (mc.parameters.get(0) as Atomic).atomic as LambdaExpression
			val mappedType = lambda.returnValue.type
			val rTy = type.methods.findFirst[it.name == mc.name].returnType
			val tmpFinal = allocateTmp
			'''
			void* «tmp»(void* data, void* user_data) {
				«type.baseType.c_declare_var»* «lambda.lambdaParams.get(0).name» = («type.baseType.c_declare_var»*) data;
				«lambda.compile_to_c»
				«mappedType.c_declare_var»* «tmpFinal» = («mappedType.c_declare_var»*)malloc(sizeof(«mappedType.c_declare_var»));
				*«tmpFinal» = «stack.pop»;
				return «tmpFinal»;
			}
			«rTy.c_declare_var» «tmpR» = «mc.name»(«source», «tmp», NULL);
			'''->new CollectionType("", mappedType)
		}
		else throw new UnsupportedOperationException("TODO222: auto-generated method stub")
	}
}