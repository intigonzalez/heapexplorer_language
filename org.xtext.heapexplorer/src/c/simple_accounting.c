#include "list.h"

#define Principal ResourcePrincipalData

// user-defined types

//this structure represents the data on each resource principal
typedef struct {
int nbObjects;
int nbSize;
} ResourcePrincipalData;

#include "common.h"

// methods to initialize properties

List*
all_root_objects(EntityEnvironment* env,
		ResourcePrincipalData* princ)
{
	return threads;
}
int
all_membership(LocalEnvironment* env, 
		ResourcePrincipalData* princ)
{
	int tmp6 = belongs_to(THIS,NONE);
	int tmp7 = belongs_to(REFERRER,THIS_ENTITY);
	int tmp8 = tmp6 && tmp7;
	return tmp8;
}
void
all_on_inclusion(LocalEnvironment* env, 
		ResourcePrincipalData* princ)
{
	int tmp9 = princ->nbObjects + 1;
	princ->nbObjects = tmp9;
	int tmp10 = THIS->size();
	int tmp11 = princ->nbSize + tmp10;
	princ->nbSize = tmp11;
}
int
all_nbObjects(EntityEnvironment* env,
		ResourcePrincipalData* princ)
{
	return 0;
}
int
all_nbSize(EntityEnvironment* env,
		ResourcePrincipalData* princ)
{
	return 0;
}

// methods to obtain instances' names
char*
all_init_names(GlobalEnvironment* env)
{
	return "all-jvm";
}

// routines to initialize user-defined functions

void all_initialize
	(EntityEnvironment* env, 
	ResourcePrincipalData* princ)
{
	princ->nbObjects = all_nbObjects(env,princ);
	princ->nbSize = all_nbSize(env,princ);
}

// ResourcePrincipalTypes
ResourcePrincipalType TYPES[] = {
{ 
  all_init_names, 
  0, 
  all_root_objects,
  all_membership,
  all_on_inclusion,
  all_initialize
}
};
