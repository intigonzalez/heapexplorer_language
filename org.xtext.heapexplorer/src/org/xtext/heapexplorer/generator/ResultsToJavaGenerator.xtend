package org.xtext.heapexplorer.generator

import org.xtext.heapexplorer.types.HeapExplorerType
import org.xtext.heapexplorer.types.ComposedType
import java.util.HashMap
import org.xtext.heapexplorer.types.CollectionType
import org.xtext.heapexplorer.heapExplorer.EntityData
import java.util.List
import org.xtext.heapexplorer.validation.CachedExpressionsTypeProvider
import com.google.inject.Inject
import org.xtext.heapexplorer.types.HETypeFactory

class ResultsToJavaGenerator {
	
	@Inject extension CachedExpressionsTypeProvider
	@Inject extension ExtensionExpressionCompilationProvider
	@Inject extension JvmSpecInfo
	
	val routines = new HashMap<HeapExplorerType, String>
	
	def java_declare_var(HeapExplorerType type) {
		switch(type) {
			CollectionType:'''List<«(type as CollectionType).baseType.name»>'''
			default:if (type == HETypeFactory::boolType) '''boolean''' else '''«type.name»'''
		}
	}
	
	def dispatch String routine_to_create_object(HeapExplorerType t, String analysisName)
	''''''
	
	def dispatch String routine_to_create_object(CollectionType t, String analysisName)
		'''«t.baseType.routine_to_create_object(analysisName)»'''
	
	def String routine_to_create_main_result(List<EntityData> features, String analysisName) {
		val v = features.map[it.name -> it.type.type];
		magic(analysisName, analysisName, "ResourcePrincipalData", v)
	}
	
	def dispatch String routine_to_create_object(ComposedType t, String analysisName) {
		if (routines.containsKey(t)) ''''''
		else {
			routines.put(t, '''create_«analysisName»_«t.name»''')
			magic(analysisName, t.java_declare_var.toString, t.c_declare_var, t.fields)
		}
	}
	
	def String magic(String analysisName, String javaTypeToCreate, String cTypeToCopy, List<Pair<String, HeapExplorerType>> fields) {
		'''
		«FOR st : fields SEPARATOR '\n'»
		«IF st.value instanceof ComposedType»
		«st.value.routine_to_create_object(analysisName)»
		«ENDIF»
		«ENDFOR»
		// routine for creating «javaTypeToCreate»'s objects
		static jobject
		create_«analysisName»_«cTypeToCopy»(JNIEnv * jniEnv, «cTypeToCopy»* o)
		{
			jobject result = NULL;
			jclass resultClass;
			jmethodID constructor;
			char* signatureCnstr = "(«FOR d : fields»«d.value.jvmSpecType(analysisName)»«ENDFOR»)V";
			jclass clazzList;
			jmethodID constructorArrayList;
			jmethodID addArrayList;
			«FOR st : fields.filter[it| 
				it.value instanceof ComposedType || 
				it.value instanceof CollectionType
			]»
			jobject «st.key» = NULL;
			«ENDFOR»
			
			«FOR st : fields»
			«IF st.value instanceof ComposedType»
			«st.key» = create_«analysisName»_«st.value.name»(jniEnv, &o->«st.key»);
			«ELSEIF st.value instanceof CollectionType»
			
			// obtain ArrayList class
			clazzList = (*jniEnv)->FindClass(jniEnv, "java/util/ArrayList");
			if (clazzList == NULL) {
				fprintf(stderr, "ERROR: Impossible to obtain java/util/ArrayList in localCreateResults\n");
				exit(1);
			}
			constructorArrayList = (*jniEnv)->GetMethodID(jniEnv, clazzList, "<init>", "()V");
			if (constructorArrayList == NULL) {
				fprintf(stderr, "ERROR: Impossible to obtain java/util/ArrayList::<init> in localCreateResults\n");
				exit(1);
			}
			addArrayList = (*jniEnv)->GetMethodID(jniEnv, clazzList, "add", "(Ljava/lang/Object;)Z");
			if (addArrayList == NULL) {
				fprintf(stderr, "ERROR: Impossible to obtain java/util/ArrayList::add(Object) in localCreateResults\n");
				exit(1);
			}
			«st.key» = (*jniEnv)->NewObject(jniEnv, clazzList, constructorArrayList);
			void myaction_«st.key»(void* data, void* user_data) {
				jobject el = «routines.get((st.value as CollectionType).baseType)»(jniEnv, («(st.value as CollectionType).baseType.c_declare_var»*) data);
				(*jniEnv)->CallObjectMethod(jniEnv, «st.key», addArrayList, el);
			}
			foreach(o->«st.key», myaction_«st.key», NULL);
			«ENDIF»
			«ENDFOR»
			// obtain class representing the whole result
			resultClass = (*jniEnv)->FindClass(jniEnv, "«analysisName»/«javaTypeToCreate»");
			if (resultClass == NULL) {
				fprintf(stderr, "ERROR: Impossible to obtain «analysisName»/«javaTypeToCreate» in %s%d\n",
				__FILE__, __LINE__);
				exit(1);
			}
			constructor = (*jniEnv)->GetMethodID(jniEnv, resultClass, "<init>", signatureCnstr);
			if (constructor == NULL) {
				fprintf(stderr, "ERROR: Impossible to obtain «analysisName»/«javaTypeToCreate»::<init>(%s) in %s:%d\n",
				signatureCnstr,
				__FILE__, __LINE__
				);
				exit(1);
			}
			result = (*jniEnv)->NewObject(jniEnv, resultClass, constructor,
				«FOR st : fields SEPARATOR ','»
				«IF st.value instanceof ComposedType || st.value instanceof CollectionType»
				«st.key»
				«ELSE»
				o->«st.key»
				«ENDIF»
				«ENDFOR»
			);
			return result;
		}
		
		'''
	}
}