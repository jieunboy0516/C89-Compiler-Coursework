%code requires{
  #include "../include/ast.hpp"
  #include "../include/ast/types.hpp"
  #include <cassert>
  #include <iostream>
  #include <string>

  extern Node *g_root; // A way of getting the AST out
  extern FILE *yyin;

  //! This is to fix problems when generating C++
  // We are declaring the functions provided by Flex, so
  // that Bison generated code can call them.
  int yylex(void);
  void yyerror(const char *);
}

// Represents the value associated with any kind of
// AST node.
%union{
  std::string* str;
  int num;
  double floatnum;
  DataType datatype;

  class FuncDef* FuncDefPtr;
  class StatList* StatListPtr;
  class Declarator* DecPtr;
  class Statement* StatPtr;
  class Expression* ExpPtr;
  class DecList* DecListPtr;
  class ExternalDecList* ExternalDecListPtr;
  class CompoundStatement* CompoundStatPtr;
  class InitializerList* InitListPtr;
  class ExternalDeclaration* ExternalDecPtr;
}
%type <ExternalDecListPtr> TOPLEVEL
%type <FuncDefPtr> FUNCTION_DEF
%type <StatPtr> STATEMENT
%type <CompoundStatPtr> COMPOUND_STATEMENT
%type <StatListPtr> STATEMENT_LIST
%type <StatPtr> KW_RETURN
%type <StatPtr> JUMP_STATEMENT IF_STATEMENT ITERATION_STATEMENT
%type <ExpPtr> EXPRESSION CONSTANT INITIALIZER TERM FACTOR UNARY ASSIGNMENT_EXPRESSION
%type <InitListPtr> INITIALIZER_LIST
%type <datatype> TYPE
%type <str> IDENTIFIER
%type <DecPtr> DECLARATION
%type <DecListPtr> DECLARATION_LIST
%type <ExternalDecPtr> EXTERNAL_DECLARATION


// C89 Keywords: int, float, if, etc...
%token KW_AUTO KW_DOUBLE KW_INT KW_STRUCT KW_BREAK KW_ELSE KW_LONG KW_SWITCH KW_CASE KW_ENUM KW_REGISTER KW_TYPEDEF KW_CHAR KW_EXTERN KW_RETURN
%token KW_UNION KW_CONST KW_FOR KW_SIGNED KW_VOID KW_DEFUALT KW_GOTO KW_SIZEOF KW_VOLATILE KW_DO KW_IF KW_STATIC KW_WHILE


// C89 constant operators

%token T_LSQUAREBRACKET T_RSQUAREBRACKET T_LBRACKET T_RBRACKET T_LCURLYBRACKET T_RCURLYBRACKET;
%token T_PERIOD T_HYPHON T_EXCLAIM T_EXPONENT T_QUESTION T_COMMA T_SEMICOLON T_LESSTHAN T_GREATERTHAN T_AND T_PERCENT T_PLUS T_MINUS T_TIMES T_DIVIDE T_TILDE
%token T_COLON T_VERTICALBAR T_EQUALS T_HASH
%token T_NUMBER

// C89 Constants: Floating consts, digits, exponents etc...
%token T_DECIMAL_CONST T_OCTAL_CONST T_HEX_CONST T_CHAR_CONST
%token T_IDENTIFIER T_E T_SUFFIX_F T_SUFFIX_L T_SUFFIX_U T_DOUBLE_QUOTE T_SINGLE_QUOTE
%token T_LITERAL_STRING

%left T_PLUS T_MINUS
%left T_TIMES T_DIVIDE
%right T_EXPONENT

%start ROOT


//std::cout << "IM HERE: " <<std::endl;
%%

ROOT: TOPLEVEL { g_root = $1;}
    ;

TOPLEVEL: EXTERNAL_DECLARATION {$$ = new ExternalDecList();
                                $$->addToList($1);}
        | TOPLEVEL EXTERNAL_DECLARATION  {$1->addToList($2);
                                          $$ = $1;}
        ;

EXTERNAL_DECLARATION: FUNCTION_DEF { $$ = new ExternalDeclaration($1);  }
                    | DECLARATION  { $$ = new ExternalDeclaration($1);}
                    ;

FUNCTION_DEF: TYPE IDENTIFIER T_LBRACKET T_RBRACKET COMPOUND_STATEMENT {$$ = new FuncDef($1, *$2, $5); }
            ;

COMPOUND_STATEMENT: T_LCURLYBRACKET STATEMENT_LIST T_RCURLYBRACKET {$$ = new CompoundStatement(0,$2);  }
                  | T_LCURLYBRACKET DECLARATION_LIST T_RCURLYBRACKET {$$ = new CompoundStatement($2,0);  }
                  | T_LCURLYBRACKET DECLARATION_LIST STATEMENT_LIST T_RCURLYBRACKET {$$ = new CompoundStatement($2,$3);  }
                  ;

//printf("Address of x is %p\n", (void *)$2);
//std::cout << "start" << std::endl; Context test = Context(); $$->codeprint(test); std::cout << "done" << std::endl;

STATEMENT_LIST: STATEMENT {$$ = new StatList();
                           $$->addToList($1);}
              | STATEMENT_LIST STATEMENT  {$1->addToList($2);
                                          $$ = $1;}
              ;

DECLARATION_LIST: DECLARATION {$$ = new DecList();
                              $$->addToList($1);}
              | DECLARATION_LIST DECLARATION {$1->addToList($2);
                                              $$ = $1;}
              ;

STATEMENT: COMPOUND_STATEMENT {$$ = $1;}
         | JUMP_STATEMENT {$$ = $1; }
         | IF_STATEMENT {$$ = $1;}
         | ITERATION_STATEMENT {$$ = $1;}
         | ASSIGNMENT_EXPRESSION {$$ = new ExpressionStatement($1);}
        ;

DECLARATION : TYPE IDENTIFIER T_SEMICOLON {$$ = new Declarator($1, *$2, 0);}
            | TYPE IDENTIFIER T_LSQUAREBRACKET CONSTANT T_RSQUAREBRACKET T_SEMICOLON {$$ = new ArrayDeclarator($1, *$2, 0, $4);}
            | TYPE IDENTIFIER T_EQUALS INITIALIZER T_SEMICOLON {$$ = new Declarator($1, *$2, $4);}
            | TYPE IDENTIFIER T_LSQUAREBRACKET T_RSQUAREBRACKET T_EQUALS INITIALIZER T_SEMICOLON {$$ = new ArrayDeclarator($1, *$2, $6, 0);}
            | TYPE IDENTIFIER T_LSQUAREBRACKET CONSTANT T_RSQUAREBRACKET T_EQUALS INITIALIZER T_SEMICOLON {$$ = new ArrayDeclarator($1, *$2, $7,$4);}
            ;


JUMP_STATEMENT: KW_RETURN EXPRESSION T_SEMICOLON {std::string* strptr = new std::string("ret"); $$ = new JumpStatement(*strptr, $2);}
              ;

ITERATION_STATEMENT: KW_WHILE T_LBRACKET EXPRESSION T_RBRACKET STATEMENT {$$ = new WhileStatement($3, $5, false);}
                   | KW_DO STATEMENT KW_WHILE T_LBRACKET EXPRESSION T_RBRACKET T_SEMICOLON {$$ = new WhileStatement($5, $2, true);}
                   ;

IF_STATEMENT: KW_IF T_LBRACKET EXPRESSION T_RBRACKET STATEMENT {$$ = new IfStatement($3, $5, 0, false);}
            | KW_IF T_LBRACKET EXPRESSION T_RBRACKET STATEMENT KW_ELSE STATEMENT {$$ = new IfStatement($3, $5, $7, true);}
            ;

INITIALIZER: EXPRESSION {$$ = $1;}
           | T_LCURLYBRACKET INITIALIZER_LIST T_RCURLYBRACKET {$$ = $2;}
           ;

INITIALIZER_LIST: INITIALIZER {$$ = new InitializerList();
                               $$->addToList($1);}
                | INITIALIZER_LIST T_COMMA INITIALIZER {$1->addToList($3);
                                                        $$ = $1;}
                ;

ASSIGNMENT_EXPRESSION:  IDENTIFIER T_EQUALS EXPRESSION T_SEMICOLON {$$ = new AssignmentExpression(*$1, $3, EQUAL);}
                      //| IDENTIFIER T_LSQUAREBRACKET EXPRESSION T_RSQUAREBRACKET T_EQUALS EXPRESSION T_SEMICOLON {$$ = new ArrayAssignmentExpression($1, $3, $6, EQUAL);}
                      | IDENTIFIER T_TIMES T_EQUALS EXPRESSION T_SEMICOLON {$$ = new AssignmentExpression(*$1, $4, TIMES);}
                      ;

EXPRESSION: TERM                          { $$ = $1; }
          | EXPRESSION T_PLUS EXPRESSION  { $$ = new BinaryExpression($1,PLUS, $3); }
          | EXPRESSION T_MINUS EXPRESSION { $$ = new BinaryExpression($1,MINUS, $3); }
          | EXPRESSION T_EQUALS T_EQUALS EXPRESSION { $$ = new RelationalExpression($1,EQUALTO, $4); }
          | EXPRESSION T_EXCLAIM T_EQUALS EXPRESSION { $$ = new RelationalExpression($1,NOTEQUALTO, $4); }
          | EXPRESSION T_LESSTHAN EXPRESSION { $$ = new RelationalExpression($1,LESSTHAN, $3); }
          | EXPRESSION T_GREATERTHAN EXPRESSION { $$ = new RelationalExpression($1,GREATERTHAN, $3); }
          | EXPRESSION T_LESSTHAN T_EQUALS EXPRESSION { $$ = new RelationalExpression($1,LESSTHANEQUALTO, $4); }
          | EXPRESSION T_GREATERTHAN T_EQUALS EXPRESSION { $$ = new RelationalExpression($1,GREATERTHANEQUALTO, $4); }
          ;



TERM : UNARY               { $$ = $1; }
     | TERM T_TIMES TERM   { $$ = new BinaryExpression($1, TIMES ,$3); }
     | TERM T_DIVIDE TERM  { $$ = new BinaryExpression($1, TIMES ,$3); }

UNARY : FACTOR                { $$ = $1; }
      | T_MINUS EXPRESSION    { $$ = new UnaryExpression(MINUS, $2); }

FACTOR  : CONSTANT {$$ = $1;}
        | IDENTIFIER { $$ = new Identifier(*$1); }
        | T_LBRACKET EXPRESSION T_RBRACKET { $$ = $2; }
        ;

CONSTANT: T_DECIMAL_CONST {$$ = new ConstantValue(std::stoi(*yylval.str));}
        | T_OCTAL_CONST {$$ = new ConstantValue(std::stoi(*yylval.str, 0, 8));}
        | T_HEX_CONST  {$$ = new ConstantValue(std::stoi(*yylval.str, 0 , 16));}
        | T_CHAR_CONST {$$ = new ConstantValue((int)(*yylval.str)[0]);}
        ;


TYPE: KW_INT {$$ = yylval.datatype;}
    ;

IDENTIFIER: T_IDENTIFIER {$$ = yylval.str;}
          ;

%%

Node *g_root;

Node *parseAST(std::string filename)
{
  yyin = fopen(filename.c_str(), "r");
  if(yyin == NULL){
    std::cerr << "Couldn't open input file: " << filename << std::endl;
    exit(1);
  }

  g_root = NULL;
  yyparse();
  //std::cout << yyparse() << std::endl;
  return g_root;
}



