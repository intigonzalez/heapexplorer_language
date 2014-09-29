package org.xtext.heapexplorer.tests

import org.eclipse.xtext.junit4.InjectWith
import org.junit.runner.RunWith
import org.eclipse.xtext.junit4.XtextRunner
import org.xtext.heapexplorer.HeapExplorerInjectorProvider
import javax.inject.Inject
import org.eclipse.xtext.junit4.util.ParseHelper
import org.xtext.heapexplorer.heapExplorer.HeapExplorer
import org.junit.Test

import static org.junit.Assert.*


@InjectWith(HeapExplorerInjectorProvider)
@RunWith(XtextRunner)
class TestingLanguage {
	@Inject ParseHelper<HeapExplorer> parser
 
	@Test
	def void parseHeapExplorer() {
		val model = parser.parse(
			'name="lala"      
			 description = "This is the description"
			 types
				TAges = table-of int
				TNames = table-of string
				TPerson = struct { name(string) age(int) family(TNames) } 
	
			 data
				ages = TAges
				names = TNames
	 
   			 component-type Runtime: 
				Root_objects = "" + "122" 
				membership = !(THIS belongs-to NONE) && (REFERRER belongs-to THIS_ENTITY) 
				on_inclusion = (1+3) + 12 > 7 && (12 > 7) && (true == false) 
				toto = 1 / 1 - 1
	
             component-type ThreadComponent:
	         	root_objects = "sfd"  
				java = "dfd"    
	
			 instances-for Runtime have-id = "id"
			 instances-for ThreadComponent have-id = "dd"'
			)
			assertSame(model.components.length, 2)
		//val entity = model.components as Entity
		//assertSame(entity, entity.features.head.type)
	}
	
	@Test
	def void parseHeapExplorer1() {
		val s = '''name="lala"       
		description = "This is the description"
		types   
			// builtin types
			Object = struct { id(int) size(int) } 
			Thread = struct { id(int) size(int) name(string) idGroup(int) idClassLoader(int) }
			ClassLoader = struct { id(int) size(int) idParent(int) }
			ThreadGroup = struct { id(int) size(int) idParent(int) name(string) }
			Interfaces = table-of int
			Class = struct { id(int) size(int) name(string) idParent(int) idClassLoader(int) interfaces(Interfaces) }
			
			Objects = table-of Object
			Threads = table-of Thread
			ClassLoaders = table-of ClassLoader
			ThreadGroups = table-of ThreadGroup
			Classes = table-of Class
			
			Objects = table-of Object  
			// testing
			Point = struct { 
				x(int) y(int)
			} 
			Mesh = table-of Point
			TAges = table-of int     
			TNames = table-of double        
			TPerson = struct { 
				name(string) age(int) family(TNames)
			}  
			Triangle = struct {
				p0(Point) p1(Point) p2(Point) p3(Point) 
			}
			
		data
			// builtin properties 
			membership = bool 
			on_inclusion = void
			root_objects = Objects  
			// testing 
			ages = TAges
			names = TNames 
			x = int  
			y = string 
			p = Point
			t = Triangle 
			m = Mesh 
			  
		component-type Runtime:
			root_objects = #[ struct Object {1,345} ]  
			membership = !(THIS belongs-to NONE) && (REFERRER belongs-to THIS_ENTITY) 
			//on_inclusion = (1+3) + 12 > 7 && (12 > 7) && (true == false)
			// testing
			p = struct Point { 1, 1 } 
			t = struct Triangle { 
				struct Point { 1, 1}, 
				struct Point { 1, 1}, 
				struct Point { 1, 1},
				struct Point { 1, 1}
			}
			m = #[struct Point {1,1}, struct Point {2,2} ]
			
			ages = #[12, 13]
			
		component-type ThreadComponent:
			x = 3.toString().toInt().toString().toInt() + "".toInt().toString().toInt() 
			x = (struct Point { 1, 1 }).y
		//	root_objects = "sfd"   
		//	java = "dfd"
		
		component-type LALA:
			x = 123
		//	root_objects = "lalala"
		//	Coco = 1 + 123
			
		instances-for Runtime have-id = "id"
		instances-for ThreadComponent have-id = #["The guy","The super guy"]'''
		
		val model = parser.parse(s)
		assertSame(model.components.length, 3)
	}
}