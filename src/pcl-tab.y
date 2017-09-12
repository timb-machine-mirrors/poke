/* pcl-tab.y - LARL(1) parser for the Poke Command Language.  */

/* Copyright (C) 2017 Jose E. Marchesi.  */

/* This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

%pure-parser
%name-prefix "pcl_tab_"
 /* %parse-param {pcl_parser_t pcl_parser} */
 /*%lex-param { void *scanner } */

%{
#include <config.h>
#include <stdarg.h>
#include <stdlib.h>
#include <xalloc.h>

#include <pcl-ast.h>
#include "pcl-tab.h"

#define PCL_AST_CHILDREN_STEP 12

void
pcl_tab_error (const char *err)
{
  /* Do nothing. */
}
 
%}

%union {
  pcl_ast ast;
  enum pcl_ast_op opcode;
}

%token <ast> PCL_TOK_INT
%token <ast> PCL_TOK_STR
%token <ast> PCL_TOK_ID
%token <ast> PCL_TOK_TYPENAME
%token <ast> PCL_TOK_DOCSTR

%token PCL_TOK_ENUM
%token PCL_TOK_STRUCT
%token PCL_TOK_TYPEDEF
%token PCL_TOK_BREAK
%token PCL_TOK_CONST
%token PCL_TOK_CONTINUE
%token PCL_TOK_ELSE
%token PCL_TOK_FOR
%token PCL_TOK_IF
%token PCL_TOK_SIZEOF
%token PCL_TOK_ERR

%token PCL_TOK_AND
%token PCL_TOK_OR
%token PCL_TOK_LE
%token PCL_TOK_GE
%token PCL_TOK_INC
%token PCL_TOK_DEC
%token PCL_TOK_SL
%token PCL_TOK_SR
%token PCL_TOK_EQ
%token PCL_TOK_NE

%token <opcode> PCL_TOK_MULA
%token <opcode> PCL_TOK_DIVA
%token <opcode> PCL_TOK_MODA
%token <opcode> PCL_TOK_ADDA
%token <opcode> PCL_TOK_SUBA
%token <opcode> PCL_TOK_SLA
%token <opcode> PCL_TOK_SRA
%token <opcode> PCL_TOK_BANDA
%token <opcode> PCL_TOK_XORA
%token <opcode> PCL_TOK_IORA

%type <opcode> unary_operator assignment_operator

%type <ast> enumerator_list enumerator constant_expression
%type <ast> conditional_expression logical_or_expression
%type <ast> logical_and_expression inclusive_or_expression
%type <ast> exclusive_or_expression and_expression
%type <ast> equality_expression relational_expression
%type <ast> shift_expression additive_expression
%type <ast> multiplicative_expression unary_expression
%type <ast> postfix_expression primary_expression
%type <ast> expression assignment_expression

%% /* The grammar follows.  */

enumerator_list:
	  enumerator
	| enumerator_list ',' enumerator
		{ $$ = pcl_ast_chainon ($1, $3); }
	;

enumerator:
	  PCL_TOK_ID
                { $$ = pcl_ast_make_enumerator ($1, NULL, NULL); }
	| PCL_TOK_ID PCL_TOK_DOCSTR
                { $$ = pcl_ast_make_enumerator ($1, NULL, $2); }
        | PCL_TOK_ID '=' constant_expression
                { $$ = pcl_ast_make_enumerator ($1, $3, NULL); }
        | PCL_TOK_ID '=' PCL_TOK_DOCSTR constant_expression
        	{ $$ = pcl_ast_make_enumerator ($1, $4, $3); }
        | PCL_TOK_ID '=' constant_expression PCL_TOK_DOCSTR
	        { $$ = pcl_ast_make_enumerator ($1, $3, $4); }
	;

constant_expression:
	  conditional_expression
		{ PCL_AST_EXPR_CONST_P ($1) = 1; $$ = $1; }
        ;

expression:
	  assignment_expression
        | expression ',' assignment_expression
		{ $$ = pcl_ast_chainon ($1, $3); }
        ;

assignment_expression:
	  conditional_expression
        | unary_expression assignment_operator assignment_expression
		{ $$ = pcl_ast_make_binary_exp ($2, $1, $3); }
        ;

assignment_operator:
	  '='
		{ $$ = PCL_AST_OP_ASSIGN; }
        | PCL_TOK_MULA
        | PCL_TOK_DIVA
        | PCL_TOK_MODA
        | PCL_TOK_ADDA
        | PCL_TOK_SUBA
        | PCL_TOK_SLA
        | PCL_TOK_SRA
        | PCL_TOK_BANDA
        | PCL_TOK_XORA
        | PCL_TOK_IORA
        ;

conditional_expression:
	  logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression
          	{ $$ = pcl_ast_make_cond_expr ($1, $3, $5); }
	;

logical_or_expression:
	  logical_and_expression
        | logical_or_expression PCL_TOK_OR logical_and_expression
          	{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_OR, $1, $3); }
        ;

logical_and_expression:
	  inclusive_or_expression
	| logical_and_expression PCL_TOK_AND inclusive_or_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_AND, $1, $3); }
	;

inclusive_or_expression:
	  exclusive_or_expression
        | inclusive_or_expression '|' exclusive_or_expression
	        { $$ = pcl_ast_make_binary_exp (PCL_AST_OP_IOR, $1, $3); }
	;

exclusive_or_expression:
	  and_expression
        | exclusive_or_expression '^' and_expression
          	{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_XOR, $1, $3); }
	;

and_expression:
	  equality_expression
        | and_expression '&' equality_expression
          { $$ = pcl_ast_make_binary_exp (PCL_AST_OP_BAND, $1, $3); }
	;

equality_expression:
          relational_expression
	| equality_expression PCL_TOK_EQ relational_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_EQ, $1, $3); }
	| equality_expression PCL_TOK_NE relational_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_NE, $1, $3); }
	;

relational_expression:
	  shift_expression
        | relational_expression '<' shift_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_LT, $1, $3); }
        | relational_expression '>' shift_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_GT, $1, $3); }
        | relational_expression PCL_TOK_LE shift_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_LE, $1, $3); }
        | relational_expression PCL_TOK_GE shift_expression
        	{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_GE, $1, $3); }
        ;

shift_expression:
	  additive_expression
        | shift_expression PCL_TOK_SL additive_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_SL, $1, $3); }
        | shift_expression PCL_TOK_SR additive_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_SR, $1, $3); }
        ;

additive_expression:
	  multiplicative_expression
        | additive_expression '+' multiplicative_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_ADD, $1, $3); }
        | additive_expression '-' multiplicative_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_SUB, $1, $3); }
        ;

multiplicative_expression:
	  unary_expression
        | multiplicative_expression '*' unary_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_MUL, $1, $3); }
        | multiplicative_expression '/' unary_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_DIV, $1, $3); }
        | multiplicative_expression '%' unary_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_MOD, $1, $3); }
        ;

unary_expression:
	  postfix_expression
        | PCL_TOK_INC unary_expression
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_INC, $2); }
        | PCL_TOK_DEC unary_expression
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_DEC, $2); }
        | unary_operator multiplicative_expression
		{ $$ = pcl_ast_make_unary_exp ($1, $2); }
        | PCL_TOK_SIZEOF unary_expression
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_SIZEOF, $2); }
        | PCL_TOK_SIZEOF '(' type_name ')'
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_SIZEOF, $3); }
        ;

unary_operator:
	  '&' 	{ $$ = PCL_AST_OP_ADDRESS; }
	| '+'	{ $$ = PCL_AST_OP_POS; }
	| '-'	{ $$ = PCL_AST_OP_NEG; }
	| '~'	{ $$ = PCL_AST_OP_BNOT; }
	| '!'	{ $$ = PCL_AST_OP_NOT; }
	;

postfix_expression:
	  primary_expression
        | postfix_expression '[' expression ']'
		{ $$ = pcl_ast_make_array_ref ($1, $3); }
        | postfix_expression '.' PCL_TOK_ID
		{ $$ = pcl_ast_make_struct_ref ($1, $3); }
        | postfix_expression PCL_TOK_INC
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_INC, $1); }
	| postfix_expression PCL_TOK_DEC
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_DEC, $1); }
/*
        | '(' type_name ')' '{' initializer_list '}'
		{ $$ = pcl_ast_make_initializer ($2, $5); }
        | '(' type_name ')' '{' initializer_list ',' '}'
		{ $$ = pcl_ast_make_initializer ($2, $5); }
 */
	;

primary_expression:
	  PCL_TOK_ID
        | PCL_TOK_INT
        | PCL_TOK_STR
        | '(' expression ')'
		{ $$ = $1; }
	;

%%
