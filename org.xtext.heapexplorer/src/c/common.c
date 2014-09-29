
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "common.h"
#include "list.h"


LocalObject*
LocalGetThis(LocalEnvironment* env)
{
	return &(env->current);
}

LocalObject*
LocalGetReferrer(LocalEnvironment* env)
{
	return &(env->referrer);
}

LocalEntity*
LocalGetCurrentEntity(LocalEnvironment* env)
{
	return &(env->entity);
}

int
belongs_to(LocalObject* o, LocalEntity* e)
{
	if (IS_NO_ENTITY(e))
		return SAME_ENTITIES(o->membership, 0);
	else 
		return ( SAME_ENTITIES(o->membership,e->id) );
}

ReferenceKind
LocalGetReferenceKind(LocalEnvironment* env)
{
	return env->refereceKind;
}


InnerPrincipal*
createInstances(ResourcePrincipalType* types, int count, int* nbInstances)
{
	InnerPrincipal* result = 0;
	GlobalEnvironment env;
	char** names = (char**)malloc(sizeof(char*)*100); // FIXME: static number of maximum number of components
	int* idxType = (int*)malloc(sizeof(int)*100);
	int n = 0;
	// create instances	
	for (int i = 0 ; i < count ; i++) {
		if (types[i].singleInstance) {
			names[n] = types[i].singleInstance(&env);
			idxType[n++] = i; 
		}
		else if (types[i].multipleInstances) {
			fprintf(stderr, "Unimplemened branch %s:%d", __FILE__, __LINE__);
			exit(1);
		}	
	}
	result = (InnerPrincipal*)calloc(sizeof(InnerPrincipal), n);
	for (int i = 0 ; i < n; i++) {
		result[i].type = &types[idxType[i]];
		result[i].princ = result[i].type->createPrincipalData();
	}
	free(names);
	free(idxType);
	*nbInstances = n;
	return result;
}


void
initializeInstances(InnerPrincipal* princs, int nbInstances)
{
	EntityEnvironment env;
	// calculate root objects
	for (int i = 0 ; i < nbInstances ; i++) {
		// FIXME: get a real list as result
		List* l = princs[i].type->root_objects(&env, &princs[i].princ);
		// TODO, call on_inclusion on each element of the list
	}

	// initialize other properties
	for (int i = 0 ; i < nbInstances ; i++) {
		UserDefined_Initialization_Callback initializer = 
				(UserDefined_Initialization_Callback) 
				princs[i].type->initializeUserDefinedFunctions;
		initializer(&env, princs[i].princ);
	}
}
