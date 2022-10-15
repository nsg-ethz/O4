#lang brag
; O4-Program
; ---------------------------------------
o4-program : (declaration)* [/";"]


; Declarations
; ---------------------------------------
@declaration : preprocessor-declaration
             | constant-declaration
             | type-declaration
             | parser-declaration
             | control-declaration
             | deparser-declaration
             | action-declaration
             | function-declaration
             | instantiation  ; TODO: `extern-declaration`, `error-declaration`, `match-kind-declaration`
preprocessor-declaration : PREPROCESSOR_DIRECTIVE
constant-declaration : /"const" type-name name /"=" expression-array /";"
@type-declaration : typedef-declaration
                  | header-declaration
                  | struct-declaration
                  | enum-declaration  ; TODO: `header-union-declaration`, `parser-type-declaration`, `control-type-declaration`, `package-type-declaration`
action-declaration : /"action" name /"(" parameter-list /")" block-statement
function-declaration : type-name-or-void name [/"<" type-parameter-list /">"] /"(" parameter-list /")" block-statement


variable-declaration : type-name name [/"=" expression-array] /";"


; Type Declarations
; ---------------------------------------
typedef-declaration : /"typedef" type-name name /";"  ; TODO: Handle "type" keyword and allow for "header", "struct, "enum" types to be aliased


header-declaration : "header" name /"{" struct-body /"}"  ; TODO: Allow for type parameters
struct-declaration : "struct" name /"{" struct-body /"}"  ; TODO: Allow for type parameters
@struct-body : (struct-body-line)*
struct-body-line : type-name name /";"


enum-declaration : /"enum" name /"{" enum-body /"}"
                 | /"enum" type-name name /"{" specified-enum-body /"}"
@enum-body : name (/"," name)*
@specified-enum-body : specified-enum-body-line (/"," specified-enum-body-line)*
specified-enum-body-line : name /"=" expression


; Parsers
; ---------------------------------------
parser-declaration : /"parser" name (/"(" parameter-list /")"){1,2} /"{" parser-body parser-states parser-transitions /"}"  ; TODO: Allow for type parameters


parser-body : (parser-body-line)*
@parser-body-line : constant-declaration
                  | variable-declaration
                  | instantiation  ; TODO: `valueset-declaration`


parser-states : (parser-state)+
parser-state : /"state" name parser-block-statement
parser-block-statement : /"{" (parser-statement)* /"}"
@parser-statement : constant-declaration
                  | variable-declaration
                  | assignment-statement
                  | call-statement
                  | conditional-statement
                  | loop-statement
                  | empty-statement
                  | parser-block-statement  ; TODO: Allow for direct invocation


parser-transitions : (parser-transition)*
parser-transition : transition-source (transition-expression)* final-transition-expression
transition-source : [/"("] name [/")"]
                  | /"(" name (/"," name)+ /")"
@transition-expression : simple-transition-expression
                       | select-transition-expression
@final-transition-expression : simple-transition-expression /";"
                             | select-transition-expression
simple-transition-expression : /">" /">" name
select-transition-expression : /">" /"(" expression-list /")" /">" /"{" select-body /"}"
select-body : (select-body-line)*
select-body-line : keyset-expression /":" name /";"
@keyset-expression : simple-keyset-expression
                   | tuple-keyset-expression
simple-keyset-expression : "default"
                         | expression
                         | expression "&&&" expression
                         | expression ".." expression
tuple-keyset-expression : /"(" simple-keyset-expression (/"," simple-keyset-expression)* /")"


; Controls & Deparsers
; ---------------------------------------
control-declaration : /"control" name (/"(" parameter-list /")"){1,2} /"{" control-body /"apply" block-statement /"}"  ; TODO: Allow for type parameters
deparser-declaration : /"deparser" name (/"(" parameter-list /")"){1,2} /"{" control-body /"apply" block-statement /"}"  ; TODO: Allow for type parameters


control-body : (control-body-line)*
@control-body-line : constant-declaration
                   | variable-declaration
                   | action-declaration
                   | table-declaration
                   | factory-declaration
                   | instantiation


table-declaration : /"table" name /"{" table-body /"}"
@table-body : (table-body-line)+
@table-body-line : key-property
                 | actions-property
                 | entries-property
                 | custom-property
key-property : "key" /"=" /"{" key-property-body /"}"
@key-property-body : (key-property-body-line)*
key-property-body-line : expression /":" name /";"
actions-property : "actions" /"=" /"{" actions-property-body /"}"
@actions-property-body : (action-reference)*
action-reference : name (/"(" argument-list /")"){,2} /";"
entries-property : /"const" "entries" /"=" /"{" entries-property-body /"}"
@entries-property-body : (entries-property-body-line)+
entries-property-body-line : keyset-expression /":" action-reference
custom-property : ["const"] table-name /"=" expression /";"


factory-declaration : /"factory" name /"(" parameter-list /")" /"{" factory-body return-statement /"}"
@factory-body : action-declaration
              | table-declaration
              | instantiation


; Instatiations
; ---------------------------------------
instantiation : type-name /"(" argument-list /")" name [/"=" /"{" instantiation-body /"}"] /";"


@instantiation-body : (instantiation-body-line)*
@instantiation-body-line : function-declaration
                         | instantiation;


; Names
; ---------------------------------------
name : IDENTIFIER
     | "state"
     | "key"
     | "actions"
     | "entries"
     | "apply"
table-name : IDENTIFIER
           | "state"
           | "apply"


; Type Names
; ---------------------------------------
type-name : simple-type-name (/"[" expression /"]")*
type-name-or-void : type-name
                  | "void"
simple-type-name : base-type
                 | specialized-type  ; TODO: Handle "."-prefixed, "tuple" types
@base-type : "int" [/"<" expression /">"]
           | "bit" [/"<" expression /">"]
           | "varbit" [/"<" expression /">"]
           | "bool"  ; TODO: Handle "error", "string" types
@specialized-type : IDENTIFIER [/"<" type-argument-list /">"]


; Parameters & Arguments
; ---------------------------------------
parameter-list : [parameter (/"," parameter)*]
parameter : direction type-name name [/"=" expression-array]
direction : ["in" | "inout" | "out"]
type-parameter-list : [name (/"," name)*]


argument-list : [argument (/"," argument)*]
argument : [name /"="] expression-array
type-argument-list : [type-name-or-void (/"," type-name-or-void)*]  ; TODO: Allow `name` as type arguments


; Statements
; ---------------------------------------
block-statement : /"{" (statement-or-declaration)* /"}"
@statement-or-declaration : constant-declaration
                          | variable-declaration
                          | instantiation
                          | statement
@statement : assignment-statement
           | call-statement
           | conditional-statement
           | loop-statement
           | return-statement
           | exit-statement
           | empty-statement
           | block-statement  ; TODO: `switch-statement` and allow for direct invocation
assignment-statement : lvalue "=" expression-array /";"
                     | lvalue "+=" expression-array /";"
                     | lvalue "-=" expression-array /";"
                     | lvalue "*=" expression-array /";"
                     | lvalue "/=" expression-array /";"
                     | lvalue "%=" expression-array /";"
                     | lvalue "&=" expression-array /";"
                     | lvalue "|=" expression-array /";"
                     | lvalue "^=" expression-array /";"
call-statement : lvalue [/"<" type-argument-list /">"] /"(" argument-list /")" /";"
lvalue : name
       | lvalue "[" expression "]"
       | lvalue "[" expression ":" expression "]"
       | lvalue "(" argument-list ")"
       | lvalue "." name  ; TODO: Handle "this" keyword
conditional-statement : /"if" /"(" expression /")" statement [/"else" statement]
loop-statement : /"for" /"(" type-name name /"in" expression-array /")" statement
return-statement : /"return" [expression] /";"
exit-statement : /"exit" /";"
empty-statement : /";"


; Expressions
; ---------------------------------------
expression-list : [expression (/"," expression)*]
expression-array : expression
                 | "[" expression-array-list "]"
@expression-array-list : expression-array (/"," expression-array)*
expression : logical-or-expression
           | "{" expression-list "}"  ; TODO: Handel "this" keyword, string literals, "."-prefixed values, key-value lists, error access, the ternary operator and allow for type arguments
logical-or-expression : logical-and-expression
                      | logical-or-expression "||" logical-and-expression
logical-and-expression : equality-expression
                       | logical-and-expression "&&" equality-expression
equality-expression : relational-expression
                    | equality-expression "==" relational-expression
                    | equality-expression "!=" relational-expression
relational-expression : bitwise-or-expression
                      | relational-expression "<" bitwise-or-expression
                      | relational-expression ">" bitwise-or-expression
                      | relational-expression "<=" bitwise-or-expression
                      | relational-expression ">=" bitwise-or-expression
bitwise-or-expression : bitwise-xor-expression
                      | bitwise-or-expression "|" bitwise-xor-expression
bitwise-xor-expression : bitwise-and-expression
                       | bitwise-xor-expression "^" bitwise-and-expression
bitwise-and-expression : bitshift-expression
                       | bitwise-and-expression "&" bitshift-expression
bitshift-expression : additive-expression
                    | bitshift-expression "<<" additive-expression
                    | bitshift-expression ">" ">" additive-expression
additive-expression : multiplicative-expression
                    | additive-expression "+" multiplicative-expression
                    | additive-expression "-" multiplicative-expression
                    | additive-expression "++" multiplicative-expression
                    | additive-expression "|+|" multiplicative-expression
                    | additive-expression "|-|" multiplicative-expression
multiplicative-expression : unary-cast-expression
                          | multiplicative-expression "*" unary-cast-expression
                          | multiplicative-expression "/" unary-cast-expression
                          | multiplicative-expression "%" unary-cast-expression
unary-cast-expression : postfix-expression
                      | "+" unary-cast-expression
                      | "-" unary-cast-expression
                      | "~" unary-cast-expression
                      | "!" unary-cast-expression
                      | "(" type-name ")" unary-cast-expression
postfix-expression : primary-expression
                   | postfix-expression "[" expression "]"
                   | postfix-expression "[" expression ":" expression "]"
                   | postfix-expression "(" argument-list ")"
                   | postfix-expression "." name
primary-expression : integer-primitive
                   | boolean-primitive
                   | name
                   | "(" expression ")"
integer-primitive : INTEGER
boolean-primitive : "true"
                  | "false"
