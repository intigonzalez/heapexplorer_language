package org.xtext.heapexplorer.generator

import org.xtext.heapexplorer.types.HeapExplorerType
import org.xtext.heapexplorer.types.ComposedType
import org.xtext.heapexplorer.types.CollectionType
import org.xtext.heapexplorer.types.HETypeFactory

class JvmSpecInfo {
	
	def dispatch String jvmSpecType(ComposedType type, String analysisName) 
		'''L«analysisName»/«type.name»;'''
	
	def dispatch String jvmSpecType(CollectionType type, String analysisName) 
		'''Ljava/util/List;'''
		
	def dispatch String jvmSpecType(HeapExplorerType type, String analysisName) {
		if (type == HETypeFactory.stringType)
			'''Ljava/lang/String;'''
		else if (type == HETypeFactory.intType)
			'''I'''
		else if (type == HETypeFactory.boolType)
			'''Z'''
		else if (type == HETypeFactory.doubleType)
			'''D'''
		else if (type == HETypeFactory.objectType)
			'''Ljava/lang/Object;'''
		else if (type == HETypeFactory.threadType)
			'''Ljava/lang/Thread;'''
		else if (type == HETypeFactory.classType)
			'''Ljava/lang/Class;'''
		else if (type == HETypeFactory.classloaderType)
			'''Ljava/lang/ClassLoader;'''
		else if (type == HETypeFactory.threadGroupType)
			'''Ljava/lang/ThreadGroup;'''
		else if (type == HETypeFactory.voidType)
			'''V'''
		else throw new RuntimeException('''Unknown type in jvmSpecType''')
	}
}