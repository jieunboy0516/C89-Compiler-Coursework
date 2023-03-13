#ifndef __LISTDECSTAT__
#define __LISTDECSTAT__

#include "ast_all.h"

class DecList : public Node {
private:
	std::list<Declarator*> dlist;
public:
	DecList() {};
	void addToList(Declarator* dec_in) {
	}

};

class StatList : public Node {
private:
	std::list<Statement*> slist;
public:
	StatList() {};
	void addToList(Statement* stat_in) {}

};

class ExternalDecList : public Node{
private:
	std::list<ExternalDeclaration*> exdeclist;
public:
	ExternalDecList() {};
	void addToList(ExternalDeclaration* external_dec){}
};


#endif