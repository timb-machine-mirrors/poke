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

%define api.pure full
%define parse.lac full
%define parse.error verbose
%locations
%name-prefix "pcl_tab_"

%lex-param {void *scanner}
%parse-param {void *scanner}


%{
#include <config.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <xalloc.h>

#include <pcl-ast.h>
#include "pcl-tab.h"
#include "pcl-lex.h"

/* YYLLOC_DEFAULT -> default code for computing locations.  */
  
#define PCL_AST_CHILDREN_STEP 12

/* Error reporting function for pcl_tab_parse.

   When this function returns, the parser tries to recover the error.
   If it is unable to recover, then it returns with 1 (syntax error)
   immediately.

   We use the default structure for YYLTYPE:

     typedef struct YYLTYPE
     {
       int first_line;
       int first_column;
       int last_line;
       int last_column;
     } YYLTYPE;
 */
  
void
pcl_tab_error (YYLTYPE *llocp, void *extra, char const *err)
{
  /* yynerrs is a local variable of yyparse that contains the number of
     syntax errors reported so far.  */
  fprintf (stderr, "stdin: %d: %s\n", llocp->first_line, err);
}

/* The following functions are used in the actions in several grammar
   rules below.  This is to avoid replicating code in situations where
   the difference between rules are just a different permutation of
   its elements.

   All these functions return 1 if the action is executed
   successfully, or 0 if a syntax error should be raised at the
   grammar rule invoking the function.  */

static int
enum_specifier_action (pcl_ast *enumeration,
                       pcl_ast type, YYLTYPE *loc_type,
                       pcl_ast tag, YYLTYPE *loc_tag,
                       pcl_ast enumerators, YYLTYPE *loc_enumerators,
                       pcl_ast docstr, YYLTYPE *loc_docstr)
{
  *enumeration = pcl_ast_make_enum (type, tag, enumerators, docstr);
  if (pcl_ast_register_enum (PCL_AST_IDENTIFIER_POINTER (tag),
                             *enumeration) == NULL)
    {
      pcl_tab_error (loc_tag, NULL, "enum already defined");
      return 0;
    }

  return 1;
}

static int
struct_specifier_action (pcl_ast *strct,
                         pcl_ast tag, YYLTYPE *loc_tag,
                         pcl_ast fields, YYLTYPE *loc_fields,
                         pcl_ast docstr, YYLTYPE *loc_docstr)
{
  *strct = pcl_ast_make_struct (tag, fields, docstr,
                                pcl_ast_default_endian ());

  if (pcl_ast_register_struct (PCL_AST_IDENTIFIER_POINTER (tag),
                               *strct) == NULL)
    {
      pcl_tab_error (loc_tag, NULL, "struct already defined");
      return 0;
    }

  return 1;
}
 
%}

%union {
  pcl_ast ast;
  enum pcl_ast_op opcode;
}

%token <ast> INT
%token <ast> STR
%token <ast> IDENTIFIER
%token <ast> TYPENAME
%token <ast> DOCSTR

%token ENUM
%token STRUCT
%token TYPEDEF
%token BREAK
%token CONST
%token CONTINUE
%token ELSE
%token FOR
%token IF
%token SIZEOF
%token ERR

%token AND
%token OR
%token LE
%token GE
%token INC
%token DEC
%token SL
%token SR
%token EQ
%token NE

%token <opcode> MULA
%token <opcode> DIVA
%token <opcode> MODA
%token <opcode> ADDA
%token <opcode> SUBA
%token <opcode> SLA
%token <opcode> SRA
%token <opcode> BANDA
%token <opcode> XORA
%token <opcode> IORA

%token MSB LSB

%type <opcode> unary_operator assignment_operator

%type <ast> enumerator_list enumerator constant_expression
%type <ast> conditional_expression logical_or_expression
%type <ast> logical_and_expression inclusive_or_expression
%type <ast> exclusive_or_expression and_expression
%type <ast> equality_expression relational_expression
%type <ast> shift_expression additive_expression
%type <ast> multiplicative_expression unary_expression
%type <ast> postfix_expression primary_expression
%type <ast> expression assignment_expression simple_type_specifier
%type <ast> type_specifier declaration declaration_specifiers
%type <ast> typedef_specifier struct_specifier enum_specifier
%type <ast> struct_declaration_list struct_declaration_with_endian
%type <ast> struct_declaration struct_field declaration_list program

%start program

%% /* The grammar follows.  */

program: declaration_list
          	{
                  $$ = pcl_ast_make_program ();
                  PCL_AST_PROGRAM_DECLARATIONS ($$) = $1;

#ifdef PCL_DEBUG
                  pcl_ast_print (stdout, $$);
#endif                  
                }
        ;

declaration_list:
	  declaration
        | declaration_list declaration
        	{ $$ = pcl_ast_chainon ($1, $2); }
	;

/*
 * Expressions.
 */

constant_expression:
	  conditional_expression
          	{
                  if (!PCL_AST_LITERAL_P ($1))
                    {
                      pcl_tab_error (&@1, NULL, "expected constant expression");
                      YYERROR;
                    }

                  $$ = $1;
                }
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
	'='		{ $$ = PCL_AST_OP_ASSIGN; }
	| MULA	{ $$ = PCL_AST_OP_MULA; }
	| DIVA	{ $$ = PCL_AST_OP_DIVA; }
	| MODA	{ $$ = PCL_AST_OP_MODA; }
	| ADDA	{ $$ = PCL_AST_OP_ADDA; }
	| SUBA	{ $$ = PCL_AST_OP_SUBA; }
	| SLA	{ $$ = PCL_AST_OP_SLA; }
	| SRA	{ $$ = PCL_AST_OP_SRA; }
	| BANDA	{ $$ = PCL_AST_OP_BANDA; }
	| XORA	{ $$ = PCL_AST_OP_XORA; }
	| IORA	{ $$ = PCL_AST_OP_IORA; }
        ;

conditional_expression:
	  logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression
          	{ $$ = pcl_ast_make_cond_exp ($1, $3, $5); }
	;

logical_or_expression:
	  logical_and_expression
        | logical_or_expression OR logical_and_expression
          	{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_OR, $1, $3); }
        ;

logical_and_expression:
	  inclusive_or_expression
	| logical_and_expression AND inclusive_or_expression
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
	| equality_expression EQ relational_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_EQ, $1, $3); }
	| equality_expression NE relational_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_NE, $1, $3); }
	;

relational_expression:
	  shift_expression
        | relational_expression '<' shift_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_LT, $1, $3); }
        | relational_expression '>' shift_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_GT, $1, $3); }
        | relational_expression LE shift_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_LE, $1, $3); }
        | relational_expression GE shift_expression
        	{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_GE, $1, $3); }
        ;

shift_expression:
	  additive_expression
        | shift_expression SL additive_expression
		{ $$ = pcl_ast_make_binary_exp (PCL_AST_OP_SL, $1, $3); }
        | shift_expression SR additive_expression
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
        | INC unary_expression
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_INC, $2); }
        | DEC unary_expression
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_DEC, $2); }
        | unary_operator multiplicative_expression
		{ $$ = pcl_ast_make_unary_exp ($1, $2); }
        | SIZEOF unary_expression
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_SIZEOF, $2); }
        | SIZEOF '(' TYPENAME ')'
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
        | postfix_expression '.' IDENTIFIER
		{ $$ = pcl_ast_make_struct_ref ($1, $3); }
        | postfix_expression INC
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_INC, $1); }
	| postfix_expression DEC
		{ $$ = pcl_ast_make_unary_exp (PCL_AST_OP_DEC, $1); }
/*
        | '(' type_name ')' '{' initializer_list '}'
		{ $$ = pcl_ast_make_initializer ($2, $5); }
        | '(' type_name ')' '{' initializer_list ',' '}'
		{ $$ = pcl_ast_make_initializer ($2, $5); }
 */
	;

primary_expression:
	  IDENTIFIER
        | INT
        | STR
        | '(' expression ')'
		{ $$ = $2; }
	;

/*
 * Declarations.
 */

declaration:
	  declaration_specifiers ';'
        ;

declaration_specifiers:
          typedef_specifier
	| struct_specifier
        | MSB struct_specifier
          	{ PCL_AST_STRUCT_ENDIAN ($2) = PCL_AST_MSB; $$ = $2; }
        | LSB struct_specifier
        	{ PCL_AST_STRUCT_ENDIAN ($2) = PCL_AST_LSB; $$ = $2; }
        | enum_specifier
        ;

/*
 * Typedefs
 */

typedef_specifier:
	  TYPEDEF type_specifier IDENTIFIER
          	{
                  const char *id = PCL_AST_IDENTIFIER_POINTER ($3);
                  pcl_ast type = pcl_ast_make_type (PCL_AST_TYPE_SIGNED_P ($2),
                                                    PCL_AST_TYPE_WIDTH ($2),
                                                    PCL_AST_TYPE_ENUMERATION ($2),
                                                    PCL_AST_TYPE_STRUCT ($2));

                  if (pcl_ast_register_type (id, type) == NULL)
                    {
                      pcl_tab_error (&@2, NULL, "type already defined");
                      YYERROR;
                    }
                  /* XXX:
                     pcl_ast_free ($1);
                     pcl_ast_free ($3);
                  */
                  $$ = NULL;
                }
        ;

type_specifier:
	  simple_type_specifier
	| STRUCT IDENTIFIER
        	{
                  pcl_ast strct
                    = pcl_ast_get_struct (PCL_AST_IDENTIFIER_POINTER ($2));

                  if (!strct)
                    {
                      pcl_tab_error (&@2, NULL,
                                     "expected struct");
                      YYERROR;
                    }
                  else
                    $$ = pcl_ast_make_type (0, NULL, NULL, strct);
                }
        | ENUM IDENTIFIER
        	{
                  pcl_ast enumeration
                    = pcl_ast_get_enum (PCL_AST_IDENTIFIER_POINTER ($2));

                  if (!enumeration)
                    {
                      pcl_tab_error (&@2, NULL, "expected enumeration");
                      YYERROR;
                    }
                  else
                    $$ = pcl_ast_make_type (0, NULL, enumeration, NULL);
                }
        ;

simple_type_specifier:
          TYPENAME
        |
	  's' ':' constant_expression
          	{ $$ = pcl_ast_make_type (1, $3, NULL, NULL); }
        | 'u' ':' constant_expression
        	{ $$ = pcl_ast_make_type (0, $3, NULL, NULL); }
	;

/*
 * Enumerations.
 */

enum_specifier:
	  ENUM simple_type_specifier IDENTIFIER '{' enumerator_list '}'
          	{
                  if (! enum_specifier_action (&$$,
                                               $simple_type_specifier, &@simple_type_specifier,
                                               $IDENTIFIER, &@IDENTIFIER,
                                               $enumerator_list, &@enumerator_list,
                                               NULL, NULL))
                    YYERROR;
                }
	| ENUM simple_type_specifier IDENTIFIER DOCSTR '{' enumerator_list '}'
          	{
                  if (! enum_specifier_action (&$$,
                                               $simple_type_specifier, &@simple_type_specifier,
                                               $IDENTIFIER, &@IDENTIFIER,
                                               $enumerator_list, &@enumerator_list,
                                               $DOCSTR, &@DOCSTR))
                    YYERROR;
                }
        | ENUM DOCSTR simple_type_specifier IDENTIFIER '{' enumerator_list '}'
          	{
                  if (! enum_specifier_action (&$$,
                                               $simple_type_specifier, &@simple_type_specifier,
                                               $IDENTIFIER, &@IDENTIFIER,
                                               $enumerator_list, &@enumerator_list,
                                               $DOCSTR, &@DOCSTR))
                    YYERROR;
                }
        | ENUM simple_type_specifier IDENTIFIER '{' enumerator_list '}' DOCSTR
          	{
                  if (! enum_specifier_action (&$$,
                                               $simple_type_specifier, &@simple_type_specifier,
                                               $IDENTIFIER, &@IDENTIFIER,
                                               $enumerator_list, &@enumerator_list,
                                               $DOCSTR, &@DOCSTR))
                    YYERROR;
                }
        | DOCSTR ENUM simple_type_specifier IDENTIFIER '{' enumerator_list '}'
          	{
                  if (! enum_specifier_action (&$$,
                                               $simple_type_specifier, &@simple_type_specifier,
                                               $IDENTIFIER, &@IDENTIFIER,
                                               $enumerator_list, &@enumerator_list,
                                               $DOCSTR, &@DOCSTR))
                    YYERROR;
                }
        ;

enumerator_list:
	  enumerator
	| enumerator_list ',' enumerator
		{ $$ = pcl_ast_chainon ($1, $3); }
	;

enumerator:
	  IDENTIFIER
                { $$ = pcl_ast_make_enumerator ($1, NULL, NULL); }
	| IDENTIFIER DOCSTR
                {
                  $$ = pcl_ast_make_enumerator ($1, NULL, $2);
                  PCL_AST_DOC_STRING_ENTITY ($2) = $$;
                }
        | IDENTIFIER '=' constant_expression
                { $$ = pcl_ast_make_enumerator ($1, $3, NULL); }
        | IDENTIFIER '=' DOCSTR constant_expression
        	{
                  $$ = pcl_ast_make_enumerator ($1, $4, $3);
                  PCL_AST_DOC_STRING_ENTITY ($3) = $$;
                }
        | IDENTIFIER '=' constant_expression DOCSTR
	        {
                  $$ = pcl_ast_make_enumerator ($1, $3, $4);
                  PCL_AST_DOC_STRING_ENTITY ($4) = $$;
                }
        | DOCSTR IDENTIFIER '=' constant_expression
        	{
                  $$ = pcl_ast_make_enumerator ($2, $4, $1);
                  PCL_AST_DOC_STRING_ENTITY ($1) = $$;
                }
	;

/*
 * Structs.
 */

struct_specifier:
	  STRUCT IDENTIFIER '{' struct_declaration_list '}'
          	{
                  if (! struct_specifier_action (&$$,
                                                 $IDENTIFIER, &@IDENTIFIER,
                                                 $struct_declaration_list,
                                                 &@struct_declaration_list,
                                                 NULL, NULL))
                    YYERROR;
                }
	| STRUCT IDENTIFIER DOCSTR '{' struct_declaration_list '}'
          	{
                  if (! struct_specifier_action (&$$,
                                                 $IDENTIFIER, &@IDENTIFIER,
                                                 $struct_declaration_list,
                                                 &@struct_declaration_list,
                                                 $DOCSTR, &@DOCSTR))
                    YYERROR;
                }
        | STRUCT DOCSTR IDENTIFIER '{' struct_declaration_list '}'
        	{
                  if (! struct_specifier_action (&$$,
                                                 $IDENTIFIER, &@IDENTIFIER,
                                                 $struct_declaration_list,
                                                 &@struct_declaration_list,
                                                 $DOCSTR, &@DOCSTR))
                    YYERROR;
                }
        | STRUCT IDENTIFIER '{' struct_declaration_list '}' DOCSTR
        	{
                  if (! struct_specifier_action (&$$,
                                                 $IDENTIFIER, &@IDENTIFIER,
                                                 $struct_declaration_list,
                                                 &@struct_declaration_list,
                                                 $DOCSTR, &@DOCSTR))
                    YYERROR;
                }
        ;

struct_declaration_list:
          %empty
		{ $$ = NULL; }
	| struct_declaration_with_endian
        | struct_declaration_list struct_declaration_with_endian
        	{ $$ = pcl_ast_chainon ($1, $2); }
/* XXX: add conditionals and loops.  */
	;

struct_declaration_with_endian:
	  struct_declaration
        | MSB struct_declaration
		{
                  PCL_AST_FIELD_ENDIAN ($2) = PCL_AST_MSB;
                  $$ = $2;
                }
        | LSB struct_declaration
        	{
                  PCL_AST_FIELD_ENDIAN ($2) = PCL_AST_LSB;
                  $$ = $2;
                }
        ;

struct_declaration:
	   type_specifier struct_field ';'
          	{
                  PCL_AST_FIELD_TYPE ($2) = $1;
                  $$ = $2;
                }

	 | type_specifier struct_field DOCSTR ';'
          	{
                  PCL_AST_FIELD_TYPE ($2) = $1;
                  PCL_AST_FIELD_DOCSTR ($2) = $3;
                  $$ = $2;
                  PCL_AST_DOC_STRING_ENTITY ($3) = $$;
                }
        | type_specifier DOCSTR struct_field ';'
        	{
                  PCL_AST_FIELD_TYPE ($3) = $1;
                  PCL_AST_FIELD_DOCSTR ($3) = $2;
                  $$ = $3;
                  PCL_AST_DOC_STRING_ENTITY ($2) = $$;
                }
        | DOCSTR type_specifier struct_field ';'
        	{
                  PCL_AST_FIELD_TYPE ($3) = $2;
                  PCL_AST_FIELD_DOCSTR ($3) = $1;
                  $$ = $3;
                  PCL_AST_DOC_STRING_ENTITY ($1) = $$;
                }
        ;

struct_field:
	  IDENTIFIER
          	{
                  $$ = pcl_ast_make_field ($1,
                                           /* type */ NULL,
                                           /* docstr */ NULL,
                                           pcl_ast_default_endian (),
                                           /* size_exp */ NULL);
                }
        | IDENTIFIER '[' assignment_expression ']'
        	{
                  $$ = pcl_ast_make_field ($1,
                                           /* type */ NULL,
                                           /* docstr */ NULL,
                                           pcl_ast_default_endian (),
                                           $3);
                }
        ;

%%
