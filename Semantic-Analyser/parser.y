/*
* Parser for C language
*
* Ref: http://www.quut.com/c/ANSI-C-grammar-y.html
*
* @author Shashank P, Praveen Gupta, Ashwin Joisa
*/

%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "lib/symbol_table.h"
#include "lib/scope.h"
#include "lib/misc.h"

#define TRACE_ENABLED false

// Number of rows in Hash table for symbol and constant tables
#define MAX_NODES 1000

void yyerror(const char * s);

symbol_node_t *symbol_table[MAX_NODES];
symbol_node_t *constant_table[MAX_NODES];

scope_node_t *curr_scope;

extern char *yytext;
extern int yylineno;

char datatype[100];

%}

// %token INT FLOAT CHAR DOUBLE VOID RETURN
%token SIGNED UNSIGNED LONG SHORT
%token SWITCH BREAK CONTINUE CASE DEFAULT RETURN
%token FOR WHILE DO
%token IF ELSE  
%token <char_ptr> CONSTANT_INTEGER
%token <char_ptr> CONSTANT_FLOAT
%token <char_ptr> CONSTANT_STRING
%token <char_ptr> CONSTANT_CHAR

%token INCLUDE

// To allow for mutiple datatypes
%union {
	char char_ptr[100];
}

%token <char_ptr> IDENTIFIER
%token <char_ptr> INT
%token <char_ptr> CHAR
%token <char_ptr> FLOAT
%token <char_ptr> DOUBLE
%token <char_ptr> VOID


%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN         
%left LOGIC_AND LOGIC_OR NOT INCREMENT_OPERATOR DECREMENT_OPERATOR
%left LESSER_EQUAL GREATER_EQUAL DOUBLE_EQUAL NOT_EQUAL LESSER_THAN GREATER_THAN             
%left '+' '-' '*' '/' '%' '^' '&' 

%start Begin

%% 
Begin   
    : Include
    | Include Begin
    | Declaration
    | Declaration Begin
	| Function_Definition
    | Function_Definition Begin
	;

Declaration
    :  Type Identifier_List ';'    
    ;

Identifier_List
    : Array_Notation
    | IDENTIFIER ',' Identifier_List        {   redeclaration_error_check($1);
                                                symbol_table_insert(symbol_table,$1 , curr_scope->scope_num, datatype, yylineno);
                                            }
    | '*' IDENTIFIER ',' Identifier_List    {
                                                redeclaration_error_check($2);
                                                int len = strlen(datatype);
                                                datatype[len] = '*';
                                                datatype[len +1] = '\0';
                                                symbol_table_insert(symbol_table,$2 , curr_scope->scope_num, datatype, yylineno);
                                                datatype[len] = '\0';
                                            }
    | Array_Notation ',' Identifier_List 
    | IDENTIFIER                            {   
                                                redeclaration_error_check($1);
                                                symbol_table_insert(symbol_table,$1 , curr_scope->scope_num, datatype, yylineno);} 
    | '*' IDENTIFIER                        {
                                                redeclaration_error_check($2);
                                                int len = strlen(datatype);
                                                datatype[len] = '*';
                                                datatype[len +1] = '\0';
                                                symbol_table_insert(symbol_table,$2 , curr_scope->scope_num, datatype, yylineno);
                                                datatype[len] = '\0';
                                            }
    | Define_Assign ',' Identifier_List
    | Define_Assign 
    ;

Function_Definition
	: Type IDENTIFIER '(' Formal_Param_List ')' Compound_Statement      {          
                                                                            redeclaration_error_check($2);                  
                                                                            char funcType[100] = "Function: ";
                                                                            strcat(funcType, datatype);
                                                                            symbol_table_insert(symbol_table,$2, curr_scope->scope_num, funcType, yylineno);
                                                                        }
	;

Formal_Param_List
	: Type IDENTIFIER                                  {symbol_table_insert(symbol_table,$2 , curr_scope->scope_num, datatype, yylineno);trace("Formal_Param_List Rule 1\n");}
	| Type '*' IDENTIFIER                              {symbol_table_insert(symbol_table,$3 , curr_scope->scope_num, datatype, yylineno);trace("Formal_Param_List Rule 2\n");}
	| Type Array_Notation                              {trace("Formal_Param_List Rule 3\n");}
	| Type IDENTIFIER ',' Formal_Param_List            {symbol_table_insert(symbol_table,$2 , curr_scope->scope_num, datatype, yylineno);trace("Formal_Param_List Rule 4\n");}
	| Type '*' IDENTIFIER ',' Formal_Param_List        {symbol_table_insert(symbol_table,$3 , curr_scope->scope_num, datatype, yylineno);trace("Formal_Param_List Rule 5\n");}
	| Type Array_Notation ',' Formal_Param_List        {trace("Formal_Param_List Rule 6\n");}
	|
	;

Type
    : INT                       {strcpy(datatype, $1);}
    | FLOAT                     {strcpy(datatype, $1);}
    | VOID                      {strcpy(datatype, $1);}
    | CHAR                      {strcpy(datatype, $1);}
    | DOUBLE                    {strcpy(datatype, $1);}
    | Modifiers INT             {strcpy(datatype, $2);}
    | Modifiers FLOAT           {strcpy(datatype, $2);}
    | Modifiers DOUBLE          {strcpy(datatype, $2);}
    | Modifiers CHAR            {strcpy(datatype, $2);}
    ;

Modifiers
    : SHORT | LONG | UNSIGNED | SIGNED
    ;

Array_Notation
    : IDENTIFIER '[' ']'            {   
                                        redeclaration_error_check($1);
                                        char arrayType[100] = "Array: ";
                                        strcat(arrayType, datatype);
                                        symbol_table_insert(symbol_table, $1, curr_scope->scope_num, arrayType, yylineno);
                                    }
    | IDENTIFIER '[' Expression ']' {   
                                        char arrayType[100] = "Array: ";strcat(arrayType, datatype);
                                        symbol_table_insert(symbol_table,$1, curr_scope->scope_num, arrayType,yylineno);
                                    }
    | '*' IDENTIFIER '[' Expression ']' {   
                                        redeclaration_error_check($2);
                                        int len = strlen(datatype);
                                        datatype[len] = '*';
                                        datatype[len +1] = '\0';                                
                                        char arrayType[100] = "Array: ";strcat(arrayType, datatype);
                                        symbol_table_insert(symbol_table,$2, curr_scope->scope_num, arrayType,yylineno);
                                        datatype[len] = '\0';
                                    }
    | '&' IDENTIFIER '[' Expression ']' {
                                        redeclaration_error_check($2);
                                        char arrayType[100] = "Array: ";strcat(arrayType, datatype);
                                        symbol_table_insert(symbol_table,$2, curr_scope->scope_num, arrayType,yylineno);
                                    }
    ;



Define_Assign
    : IDENTIFIER Assignment_Operator Expression             {
                                                                //redeclaration_error_check($1);
                                                                symbol_table_insert(symbol_table,$1 , curr_scope->scope_num, datatype, yylineno);trace("Define_Assign Rule 1\n");
                                                            }  
    | '*' IDENTIFIER Assignment_Operator Expression         {
                                                                //redeclaration_error_check($2);
                                                                symbol_table_insert(symbol_table,$2 , curr_scope->scope_num, datatype, yylineno);
                                                            }
    | Array_Notation Assignment_Operator Expression                   
    ;

Param_List
    : Expression
    | Expression ',' Param_List
    | 
    ;

Assignment
    : IDENTIFIER Assignment_Operator Expression           { scope_error_check($1); trace("Assignment Rule 1\n");}
    | '*' IDENTIFIER Assignment_Operator Expression       { scope_error_check($2); trace("Assignment Rule 2\n");}  
    | Array_Notation Assignment_Operator Expression
    | Primary
    ;

Assignment_Operator
	: '='
    | ADD_ASSIGN
    | SUB_ASSIGN
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| LEFT_ASSIGN
	| RIGHT_ASSIGN
	| AND_ASSIGN
	| XOR_ASSIGN
	| OR_ASSIGN
	;

Expression
    : Logical_Expression
    ;

Logical_Expression
    : Relational_Expression
    | Logical_Expression LOGIC_AND Relational_Expression
    | Logical_Expression LOGIC_OR Relational_Expression
    | NOT Relational_Expression 
    ;

Relational_Expression
    : Additive_Expression
    | Relational_Expression GREATER_THAN Additive_Expression
    | Relational_Expression LESSER_THAN Additive_Expression
    | Relational_Expression GREATER_EQUAL Additive_Expression
    | Relational_Expression LESSER_EQUAL Additive_Expression
    | Relational_Expression DOUBLE_EQUAL Additive_Expression
    | Relational_Expression NOT_EQUAL Additive_Expression
    ;

Additive_Expression
    : Multiplicative_Expression
    | Additive_Expression '+' Multiplicative_Expression
    | Additive_Expression '-' Multiplicative_Expression
    ;

Multiplicative_Expression
    : Primary
    | Multiplicative_Expression '*' Primary
    | Multiplicative_Expression '/' Primary
    | Multiplicative_Expression '%' Primary
    ;

Primary
    : '(' Expression ')'
    | CONSTANT_INTEGER     {symbol_table_insert(constant_table, $1, -1, "int", yylineno); trace("CONSTANT_INTEGER\n");}
    | CONSTANT_FLOAT       {symbol_table_insert(constant_table, $1, -1, "float", yylineno); trace("CONSTANT_FLOAT\n");}
    | CONSTANT_CHAR        {symbol_table_insert(constant_table, $1, -1, "char", yylineno); trace("CONSTANT_CHAR\n");}
    | CONSTANT_STRING      {symbol_table_insert(constant_table, $1, -1, "string", yylineno); trace("CONSTANT_STRING\n");}
    | IDENTIFIER           {scope_error_check($1);trace("Primary Identifier\n");}
    | '*' IDENTIFIER       {scope_error_check($2);trace("Pointer Identifier\n");}
    | '&' IDENTIFIER       {scope_error_check($2);trace("Address of Identifier\n");}
    | '-' Primary
    | '+' Primary
    | Array_Notation
    | Function_Call
    | INCREMENT_OPERATOR IDENTIFIER     {scope_error_check($2);}
    | IDENTIFIER INCREMENT_OPERATOR     {scope_error_check($1);}
    | DECREMENT_OPERATOR IDENTIFIER     {scope_error_check($2);}
    | IDENTIFIER DECREMENT_OPERATOR     {scope_error_check($1);}
    ;

Compound_Statement
    : Scope_Start Statement_List Scope_End
	;

Scope_Start
    : '{'   {   curr_scope = add_child_scope(curr_scope);   }
    ;


Scope_End
    : '}'   {   curr_scope = goto_parent_scope(curr_scope);   }
    ;

Statement_List
    : Statement Statement_List
    |
    ;

Statement
    : While_Statement 
    | Declaration   
    | For_Statement  
    | If_Statement  
    | Assignment    ';'
    | Return_Statement    
    | Do_While_Statement      
    | BREAK ';'
    | CONTINUE ';'                    
	| ';'
    ; 

Return_Statement
    : RETURN Expression ';'   {trace("Return_Statement Call\n");}
    ;

While_Statement
    : WHILE '(' Expression ')' Statement                                                        
    | WHILE '(' Expression ')' Compound_Statement
    ;

Do_While_Statement
    : DO Compound_Statement WHILE '(' Expression ')' ';'
    ;


For_Statement
    : FOR '(' Assignment ';' Expression ';' Assignment ')' Statement 
    | FOR '(' Assignment ';' Expression ';' Assignment ')' Compound_Statement 
    ;

If_Statement
    : IF '(' Expression ')' Statement Else_Statement     
    | IF '(' Expression ')' Compound_Statement Else_Statement
    ;

Else_Statement
    : ELSE Compound_Statement
    | ELSE Statement
    |
    ;

Function_Call
    : IDENTIFIER '(' Param_List ')'     {scope_error_check($1);symbol_table_insert(symbol_table, $1, curr_scope->scope_num, "Function", yylineno);trace("Function Call\n");} 
    ;

Include_Statement
	: '#' INCLUDE LESSER_THAN IDENTIFIER GREATER_THAN   {scope_error_check($4);}
	| '#' INCLUDE LESSER_THAN IDENTIFIER '.' IDENTIFIER GREATER_THAN    {scope_error_check($4);scope_error_check($6);}
	;

Include
	: Include_Statement
	;


%%

inline void scope_error_check(char *symbol){
    if(!scope_check(symbol_table, symbol, curr_scope)){
        yyerror(strcat(symbol, " not found in current or ancestor scopes"));
    }
}

inline void redeclaration_error_check(char *symbol){
    if(check_in_current_scope(symbol_table, symbol, curr_scope)){
        yyerror(strcat(symbol, " already declared in current scope"));
    }
}

inline void trace(char *s){
    if(TRACE_ENABLED)
        fprintf(stderr, FORE_CYN "%-20.20s%20.20s%20d\n" RESET, s, yytext, yylineno);
}


int main()
{
    curr_scope = init_scope();    
    symbol_table_initialize(symbol_table);
    symbol_table_initialize(constant_table);

    yyparse();

    symbol_table_print(symbol_table, "Symbol Table");
    symbol_table_print(constant_table, "Constant Table");
    printf(FORE_GRN "\n\n Parsing complete  ✔ \n\n" RESET); 
    
    symbol_table_free(symbol_table);
    symbol_table_free(constant_table);
    // TODO: Free Scope
    
    return 0;
}


void yyerror(const char *s) {
	printf(FORE_RED "%d : %s %s\n" RESET, yylineno, s, yytext );
    printf(FORE_RED "\nParsing failed ✘ \n\n" RESET);
    exit(-2);
}