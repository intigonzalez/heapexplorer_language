#ifndef __COMMON_DSL__
#define __COMMON_DSL__

#include "list.h"

#define THIS LocalGetThis(env)
#define REFERRER LocalGetReferrer(env)
#define THIS_ENTITY LocalGetCurrentEntity(env)
#define REFERENCE_KIND LocalGetReferenceKind(env)

#define threads getThreads(env)

#define NONE 0
#define IS_NO_ENTITY(e) e==0
#define SAME_ENTITIES(obj,e_id) obj == e_id

#define OBJECT_COMUNALITY \
EntityID membership; \
int size; \
struct LocalClass* clazz;

typedef int EntityID;
typedef int ReferenceKind;

// =====================================================
// Structures representing the concepts of the language
// at runtime
// =====================================================
typedef struct {
	EntityID id;
} LocalEntity;

struct LocalClass;

struct LocalClass {
	OBJECT_COMUNALITY
	char* name;
	struct LocalClass* parent;	
};

// Representation of Object used in local Environment
typedef struct {
	OBJECT_COMUNALITY
} LocalObject;

/*============================================================
	Each environment specifies the values a property
	has access to 
==============================================================*/
// this environment is used for the initialization of instances
typedef struct {
} GlobalEnvironment;

// this environment is used to initialize user-defined properties 
// and the built-in property "root-objects"
typedef struct {
} EntityEnvironment;


// Used for "membership" and "on-inclusion"
typedef struct {
	// fields
	struct LocalClass this_class;
	struct LocalClass referrer_class;
	LocalObject current;
	LocalObject referrer;
	ReferenceKind refereceKind;
	LocalEntity entity;
} LocalEnvironment;

// ======================================================
// Types used as callback
// ======================================================

typedef void* (*Create_Principal_Data)
		();

typedef List* (*RootObjects_Initialization_Callback) 
		(EntityEnvironment* env, void* princ);

typedef int (*Membership_Callback)
		(LocalEnvironment* env, void* princ);

typedef void (*On_Inclusion_Callback)
		(LocalEnvironment* env, void* princ);

typedef char* (*On_Single_Instance_Creation)
		(GlobalEnvironment* env);

typedef char** (*On_Multiple_Instances_Creation)
		(GlobalEnvironment* env);

typedef void (*UserDefined_Initialization_Callback) 
		(EntityEnvironment* env, 
		void* princ);

typedef struct {
	Create_Principal_Data createPrincipalData;
	On_Single_Instance_Creation singleInstance;
	On_Multiple_Instances_Creation multipleInstances;
	RootObjects_Initialization_Callback root_objects;
	Membership_Callback member;
	On_Inclusion_Callback on_inclusion;
	UserDefined_Initialization_Callback initializeUserDefinedFunctions;
} ResourcePrincipalType;

typedef struct {
	ResourcePrincipalType* type;
	void* princ;
} InnerPrincipal;


// ============================================================
// routines to obtain built-in properties
// ============================================================
LocalObject*
LocalGetThis(LocalEnvironment* env);

LocalObject*
LocalGetReferrer(LocalEnvironment* env);

LocalEntity*
LocalGetCurrentEntity(LocalEnvironment* env);

ReferenceKind
LocalGetReferenceKind(LocalEnvironment* env);

// operators
int
belongs_to(LocalObject* o, LocalEntity* e);

// =============================================================
// to create principals
// =============================================================
InnerPrincipal*
createInstances(ResourcePrincipalType* types, int count, int* nbInstances);

void
initializeInstances(InnerPrincipal* princs, int nbInstances);

#endif
