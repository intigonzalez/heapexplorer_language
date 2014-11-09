
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "plugins.h"

#include "common.h"
#include "RuntimeObjects.h"

#include "delegateHeader.h"


/* Callback for HeapReferences in FollowReferences (Shows alive objects in the whole JVM) */
static
jint JNICALL callback_all_alive_objects
    (jvmtiHeapReferenceKind reference_kind, 
     const jvmtiHeapReferenceInfo* reference_info, 
     jlong class_tag, 
     jlong referrer_class_tag, 
     jlong size, 
     jlong* tag_ptr, 
     jlong* referrer_tag_ptr, 
     jint length, 
     void* user_data)
{
	ResourcePrincipal* princ = (ResourcePrincipal*)user_data;
	InnerPrincipal* iPrinc = (InnerPrincipal*)princ->user_data;
	ResourcePrincipalData* dPrinc = (ResourcePrincipalData*)iPrinc->princ;

	// the class has a tag
	if ( (class_tag != (jlong)0)) {
		ClassDetails *d = (ClassDetails*)getDataFromTag(class_tag);
		LocalEnvironment env;

		env.this_class.name = getClassSignature(d);
		env.current.clazz = &env.this_class;

		env.refereceKind = reference_kind;
		env.current.size = size;
		env.entity.id = (jint)princ->tag;

		if (isClassClass(d)) {
			if ((*tag_ptr) == 0) return 0;			
			if (!isTagged(*tag_ptr))
				env.current.membership = 0;
			else
				env.current.membership = ((ObjectTag*)(void*)(ptrdiff_t)(*tag_ptr))->tag;
		}
		else if (isTagged((*tag_ptr)))
			env.current.membership = ((ObjectTag*)(void*)(ptrdiff_t)(*tag_ptr))->tag;
		else
			env.current.membership = 0;
		
		int flag = iPrinc->type->member(&env, dPrinc);
		if (flag) {
			iPrinc->type->on_inclusion(&env, dPrinc);
			//if (loco % 1000 == 0)
			//	fprintf(stderr, "blblb %d\n", (loco));
			//++loco;
			if ((*tag_ptr) == 0)
				*tag_ptr = tagForObject(princ);
			else
				attachToPrincipal(*tag_ptr, princ);
			return JVMTI_VISIT_OBJECTS;	
		}
		return 0;
		// done !!!
    }
	return 0; // I don't know the class of this object, so don't explore it
}

/* Routine to explore all alive objects within the JVM */
static void
explore_FollowReferencesAll(
		jvmtiEnv* jvmti, ResourcePrincipal* principal)
{
	jvmtiError err;
	jvmtiHeapCallbacks heapCallbacks;

	(void)memset(&heapCallbacks, 0, sizeof(heapCallbacks));
    heapCallbacks.heap_reference_callback = &callback_all_alive_objects;
    err = (*jvmti)->FollowReferences(jvmti,
                   JVMTI_HEAP_FILTER_CLASS_UNTAGGED, NULL, NULL,
                   &heapCallbacks, (const void*)principal);
    check_jvmti_error(jvmti, err, "iterate through heap");
}

static
jint createPrincipals(jvmtiEnv* jvmti, JNIEnv *jniEnv,
		ResourcePrincipal** principals, ClassInfo* infos, int count_classes)
{
	jint count_principals;
	int j;
	int i;
	jlong tmp;
	InnerPrincipal* innerP = createInstances(TYPES, nbTYPES, &count_principals);
	initializeInstances(innerP, count_principals);

	(*principals) = (ResourcePrincipal*)calloc(sizeof(ResourcePrincipal), count_principals);       
    for (j = 0 ; j < count_principals ; ++j) {
		/* Setup an area to hold details about these classes */
		(*principals)[j].details = (ClassDetails*)calloc(sizeof(ClassDetails), count_classes);
        if ( (*principals)[j].details == NULL ) 
            fatal_error("ERROR: Ran out of malloc space\n");

		// setting the inner principal structure
		(*principals)[j].user_data = &innerP[j];
		

        for ( i = 0 ; i < count_classes ; i++ )
			(*principals)[j].details[i].info = &infos[i];

		(*principals)[j].tag = (j+1);
		(*principals)[j].strategy_to_explore = &explore_FollowReferencesAll;
    }
	return count_principals;
}

/** Fill a structure with the infomation about the plugin 
* Returns 0 if everything was OK, a negative value otherwise	
*/
int DECLARE_FUNCTION(HeapAnalyzerPlugin* r)
{
	r->name = "from dsl0";
	r->description = "This plugin calculates the number of objects of each class within the whole JVM. It returns only alive objects";
	r->createPrincipals = createPrincipals;
	r->createResults = localCreateResults;
	return 0;
}
