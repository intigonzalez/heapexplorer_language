package org.xtext.heapexplorer.validation

import javax.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.util.IResourceScopeCache

class CachedExpressionsTypeProvider extends ExpressionsTypeProvider {
	@Inject IResourceScopeCache cache
	override type(EObject e) {
		cache.get('inferredType'->e, e.eResource) [|
			super.type(e)
		]
	}
}