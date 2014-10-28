#ifndef __LINKED_LIST__
#define __LINKED_LIST__

#include <stdbool.h>
#include <stdio.h>

struct list_node;

struct _List;

typedef struct _List List;

// common list's routines

List*
create_list();

void
add_to_list(List* l, void* data);


// collection's routines
List*
filter(List* l, bool (*predicate)(void* data, void* user_data), void* user_data);

void*
findfirst(List* l, bool (*predicate)(void* data, void* user_data), void* user_data);

List*
map(List* l, void* transform(void* data, void* user_data), void* user_data);

void
foreach(List* l, void action(void* data, void* user_data), void* user_data);

void
append(List* dst, List* src);

bool
forall(List* l, bool (*predicate)(void* data, void* user_data), void* user_data);

bool
exists(List* l, bool (*predicate)(void* data, void* user_data), void* user_data);



#endif
