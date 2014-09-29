package org.xtext.heapexplorer.validation

import org.xtext.heapexplorer.heapExplorer.Atomic
import org.xtext.heapexplorer.heapExplorer.StringLiteral
import org.xtext.heapexplorer.heapExplorer.NumberLiteral
import org.xtext.heapexplorer.heapExplorer.Expression

class ConstantValueExpressionProvider {
	public static val Object nonConstant = new Object
	
	def dispatch Object constant(Atomic exp) {
		exp.atomic.constant
	}
	
	def dispatch Object constant(StringLiteral exp) {
		exp.value
	}
	
	def dispatch Object constant(NumberLiteral exp) {
		exp.value
	}
	
	def dispatch Object constant(Expression exp) {
		nonConstant
	}
}