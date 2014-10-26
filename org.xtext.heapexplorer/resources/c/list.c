#include "list.h"

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

struct list_node  {
	void* data;
	struct list_node* next;	
};

struct _List {
	struct list_node* head;
};

// common list's routines

List*
create_list()
{
	List* l = (List*)malloc(sizeof(List));
	struct list_node* node = (struct list_node*)malloc(sizeof(struct list_node));
	node->data = NULL;
	node->next = NULL;
	l->head = node;
}

void
add_to_list(List* l, void* data) {
	struct list_node* node = (struct list_node*)malloc(sizeof(struct list_node));
	node->data = data;
	node->next = l->head->next;
	l->head->next = node;
}


// collection's routines
List*
filter(List* l, bool (*predicate)(void* data, void* user_data), void* user_data)
{
	List* r = create_list();
	struct list_node* node = l->head->next;
	while (node) {
		bool b = predicate(node->data, user_data);
		if (b)
			add_to_list(r, node->data);
		node= node->next;	
	} 
	return r;	
}

void*
findfirst(List* l, bool (*predicate)(void* data, void* user_data), void* user_data)
{
	List* r = create_list();
	struct list_node* node = l->head->next;
	while (node) {
		bool b = predicate(node->data, user_data);
		if (b)
			return node->data;
		node= node->next;
	} 
	return NULL;
}

List*
map(List* l, void* transform(void* data, void* user_data), void* user_data)
{
	List* r = create_list();
	struct list_node* node = l->head->next;
	while (node) {
		void* tmp = transform(node->data, user_data);
		add_to_list(r, tmp);
		node= node->next;
	} 
	return r;
}

void
foreach(List* l, void action(void* data, void* user_data), void* user_data)
{
	struct list_node* node = l->head->next;
	while (node) {
		action(node->data, user_data);
		node= node->next;
	}
}

void
append(List* dst, List* src)
{
	struct list_node* node = src->head->next;
	while (node) {
		add_to_list(dst, node->data);
		node= node->next;
	}
}

bool
forall(List* l, bool (*predicate)(void* data, void* user_data), void* user_data)
{
	struct list_node* node = l->head->next;
	while (node) {
		bool b = predicate(node->data, user_data);
		if (!b) return false;
		node= node->next;	
	} 
	return true;	
}

bool
exists(List* l, bool (*predicate)(void* data, void* user_data), void* user_data)
{
	struct list_node* node = l->head->next;
	while (node) {
		bool b = predicate(node->data, user_data);
		if (b) return true;
		node= node->next;	
	} 
	return false;	
}
