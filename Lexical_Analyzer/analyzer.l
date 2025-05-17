%option noyywrap yylineno

%x SINGLECOMMENT
%x MULTICOMMENT
%x STRING

%{
#include<bits/stdc++.h>
#include <iostream>
#include <fstream>
#include <cstring>
#include <cctype>
#include "hashfunctions.h"
#include "SymbolTable.h"
using namespace std;

ofstream logout;
ofstream tokenout;
int error_count = 0;
string currentcomment="";
string currentstringlexeme="";
string currentstring="";
char* to_upper(const char *str) {
    static char buffer[150];  
    int i;
    for (i = 0; str[i] && i < 149; i++) {
        buffer[i] = toupper((unsigned char)str[i]);
    }
    buffer[i] = '\0';
    return buffer;
}

HashFunction func = sdbmHash;
int bucket=7;
Symboltable *table = new Symboltable(bucket,func);

void insert_into_symboltable(string lexeme,string id){
    if(table->insert(lexeme,id,logout)){
    table->PrintNonempty(logout);
    }
    logout<<"\n";        

}
int commentstartline=0;
int stringstartline=0;
%}

KEYWORD if|for|do|int|float|void|switch|default|else|while|break|char|double|return|case|continue|goto|long|short|static|unsigned

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
CONST_INT {DIGIT}+
LETUNDERSCORE [a-zA-Z_]
NEWLINE \n
IDENTIFIER {LETUNDERSCORE}({LETTER}|{DIGIT}|_)*

ESCAPECHAR [nt'afrbv0\\]
CHARSET [ -&(-[\]-~]

CHAR \'({CHARSET}|(\\{ESCAPECHAR}))\'
/* --- NUMBERS --- */
EXPONENT [Ee][+-]?{DIGIT}+
CONST_FLOAT {DIGIT}*(\.{DIGIT}*)?{EXPONENT}?

DECIMALNUM {DIGIT}*\.{DIGIT}+
DECIMALEXT \.|(\.{DIGIT}+)

DECIMALERROR  {DECIMALNUM}{DECIMALEXT}+
ILLFORMED {DIGIT}*(\.{DIGIT}+)?{EXPONENT}{DIGIT}*{DECIMALEXT}+

DECIMALANDEXPONETNERROR {DECIMALERROR}{ILLFORMED}
DECIMALERRORBUTEXPONENTRIGHT {DECIMALERROR}{EXPONENT}
DECIMALRIGHTBUTEXPONENTERROR {CONST_FLOAT}{EXPONENT}{DIGIT}*{DECIMALEXT}+
EXPONENTERROR {CONST_FLOAT}[Ee]

INVALID_ID_NUM {DIGIT}+{LETUNDERSCORE}+ 
INVALID_CHAR \'({CHARSET}|(\\{ESCAPECHAR}))({CHARSET}|(\\{ESCAPECHAR}))+\'
EMPTY_CHAR \'\'
UNTERMINATED_CHAR (\'({CHARSET}|(\\{ESCAPECHAR}))*)

%%

{EMPTY_CHAR} {
      logout<<"Error at line no "<<yylineno<<": Empty character constant error "<<yytext<<"\n\n\n";
    error_count++;     
}

{INVALID_ID_NUM} {
    logout<<"Error at line no "<<yylineno<<": Invalid prefix on ID or invalid suffix on Number "<<yytext<<"\n\n";
    error_count++;      
}
{DECIMALANDEXPONETNERROR} {
    logout<<"Error at line no "<<yylineno<<": Too many decimal points and Illformed number "<<yytext<<"\n\n\n";
    error_count++;    
}
{DECIMALERRORBUTEXPONENTRIGHT} {
     logout<<"Error at line no "<<yylineno<<": Too many decimal points "<<yytext<<"\n\n\n";
    error_count++;   
}
{DECIMALRIGHTBUTEXPONENTERROR} {
     logout<<"Error at line no "<<yylineno<<": Ill formed number "<<yytext<<"\n\n\n";
    error_count++;     
}
{DECIMALERROR} {
    logout<<"Error at line no "<<yylineno<<": Too many decimal points "<<yytext<<"\n\n\n";
    error_count++;
}
{EXPONENTERROR} {
    logout<<"Error at line no "<<yylineno<<": Ill formed number "<<yytext<<"\n\n\n";
    error_count++;    
}

{KEYWORD} {
    char *upper = to_upper(yytext);
    tokenout << "<" << upper << "> ";
	logout << "Line no " << yylineno << ": Token <" << upper << "> Lexeme " << yytext << " found\n\n";

}
{IDENTIFIER} {
    char *upper = to_upper(yytext);
    tokenout << "<" << "ID" <<", "<<yytext<<"> ";
	logout << "Line no " << yylineno << ": Token <" << "ID" << "> Lexeme " << yytext << " found\n\n";	
	insert_into_symboltable(yytext,"ID");
}
{CONST_INT} {
		tokenout<<"<"<<"CONST_INT"<<", "<<yytext<<"> ";
		logout << "Line no " << yylineno << ": Token <" << "CONST_INT" << "> Lexeme " << yytext << " found\n\n";
        insert_into_symboltable(yytext,"CONST_INT");
}
{CONST_FLOAT} {
		tokenout<<"<"<<"CONST_FLOAT"<<", "<<yytext<<"> ";
		logout << "Line no " << yylineno << ": Token <" << "CONST_FLOAT" << "> Lexeme " << yytext << " found\n\n";	
        insert_into_symboltable(yytext,"CONST_FLOAT");
}

{CHAR} {
	char actualChar = yytext[1];
	if(yytext[1]=='\\'){
        switch (yytext[2]) {
        case 'n': actualChar = '\n'; break;
        case 't': actualChar = '\t'; break;
        case 'r': actualChar = '\r'; break;
        case '0': actualChar = '\0'; break;
        case '\'': actualChar = '\''; break;
        case '\"': actualChar = '\"'; break;
        case '\\': actualChar = '\\'; break;
        case 'a': actualChar = '\a'; break;
        case 'b': actualChar = '\b'; break;
        case 'f': actualChar = '\f'; break;
        case 'v': actualChar = '\v'; break;
    }
}
    tokenout << "<" << "CONST_CHAR" << ", " << std::string(1, actualChar) << "> ";
    logout << "Line no " << yylineno << ": Token <CONST_CHAR> Lexeme " << yytext << " found --> <CONST_CHAR, " << std::string(1, actualChar) << ">\n\n";
    insert_into_symboltable(yytext,"CONST_CHAR");
}
{INVALID_CHAR} {
     logout<<"Error at line no "<<yylineno<<": Multi character constant error "<<yytext<<"\n\n\n";
    error_count++;    
}
{UNTERMINATED_CHAR} {
    logout<<"Error at line no "<<yylineno<<": Unterminated character "<<yytext<<"\n\n\n";
    error_count++;
}
\} {
		tokenout<<"<"<<"RCURL"<<", "<<yytext<<"> ";
		logout << "Line no " << yylineno << ": Token <" << "RCURL" << "> Lexeme " << yytext << " found\n\n";		
        table->ExitScope();

}
\{ {
		tokenout<<"<"<<"LCURL"<<", "<<yytext<<"> ";
		logout << "Line no " << yylineno << ": Token <" << "LCURL" << "> Lexeme " << yytext << " found\n\n";		
		table->EnterScope();
 }	

\) {
    tokenout << "<" << "RPAREN" << ", " << yytext << "> ";
    logout << "Line no " << yylineno << ": Token <" << "RPAREN" << "> Lexeme " << yytext << " found\n\n";
}

\( {
    tokenout << "<" << "LPAREN" << ", " << yytext << "> ";
    logout << "Line no " << yylineno << ": Token <" << "LPAREN" << "> Lexeme " << yytext << " found\n\n";
}

\] {
    tokenout << "<" << "RTHIRD" << ", " << yytext << "> ";
    logout << "Line no " << yylineno << ": Token <" << "RTHIRD" << "> Lexeme " << yytext << " found\n\n";
}

\[ {
    tokenout << "<" << "LTHIRD" << ", " << yytext << "> ";
    logout << "Line no " << yylineno << ": Token <" << "LTHIRD" << "> Lexeme " << yytext << " found\n\n";
}

"+"|"-" {
    tokenout<<"<ADDOP, "<<yytext<<"> ";
    logout<<"Line no "<< yylineno <<": Token " <<"<ADDOP>"<<" Lexeme "<<yytext<<" found\n\n";
}
"*"|"/"|"%"  {
    tokenout<<"<MULOP, "<<yytext<<"> ";
    logout<<"Line no "<< yylineno <<": Token " <<"<MULOP>"<<" Lexeme "<<yytext<<" found\n\n";
}
"++"|"--"  {
    tokenout<<"<INCOP, "<<yytext<<"> ";
    logout<<"Line no "<< yylineno <<": Token " <<"<INCOP>"<<" Lexeme "<<yytext<<" found\n\n";
}
"<"|"<="|">"|">="|"=="|"!="  {
    tokenout<<"<RELOP, "<<yytext<<"> ";
    logout<<"Line no "<< yylineno <<": Token " <<"<RELOP>"<<" Lexeme "<<yytext<<" found\n\n";
}
"="  {
    tokenout<<"<ASSIGNOP, "<<yytext<<"> ";
    logout<<"Line no "<< yylineno <<": Token " <<"<ASSIGNOP>"<<" Lexeme "<<yytext<<" found\n\n";
}
"&&"|"||"  {
    tokenout<<"<LOGICOP, "<<yytext<<"> ";
    logout<<"Line no "<< yylineno <<": Token " <<"<LOGICOP>"<<" Lexeme "<<yytext<<" found\n\n";
}
"!"  {
    tokenout<<"<NOT, "<<yytext<<"> ";
    logout<<"Line no "<< yylineno <<": Token " <<"<NOT>"<<" Lexeme "<<yytext<<" found\n\n";
}

";" {
    tokenout << "<SEMICOLON, " << yytext << "> ";
    logout << "Line no " << yylineno << ": Token <SEMICOLON> Lexeme " << yytext << " found\n\n";
}

"//" {
        BEGIN SINGLECOMMENT; 
    }
"/*" {
        BEGIN MULTICOMMENT;
        commentstartline=yylineno;
}
<MULTICOMMENT>"*/" {
    BEGIN INITIAL;
    logout<<"Line no "<<yylineno <<": Token " <<"<COMMENT>"<<" Lexeme /*"<<currentcomment<<"*/ found\n\n";

}
<SINGLECOMMENT>\\\n     {
    
        currentcomment+="\\\n";
                }
<SINGLECOMMENT>\n {
    int linecount=yylineno-1;
    logout<<"Line no "<<linecount <<": Token " <<"<COMMENT>"<<" Lexeme //"<<currentcomment<<" found\n\n";
    currentcomment = "";
    BEGIN INITIAL;
}
<MULTICOMMENT>. { currentcomment += yytext;}
<MULTICOMMENT>\n {
    currentcomment+="\n";
}
<SINGLECOMMENT>. {currentcomment+=yytext;}

"\"" {
    BEGIN STRING;
    currentstringlexeme+="\"";
    stringstartline=yylineno;
}
<STRING>"\\\"" {
    currentstringlexeme+="\\\"";
    currentstring += "\"";
}
<STRING>"\"" {
    BEGIN INITIAL;
    currentstringlexeme+="\"";
    logout<<"Line no "<<yylineno <<": Token " <<"<STRING>"<<" Lexeme "<<currentstringlexeme<<" found --> <STRING, "<<currentstring<<">\n\n";
    tokenout<<"<STRING, "<<currentstring<<"> ";
    currentstring="";
    currentstringlexeme="";
}
<STRING>\\\n {
    currentstringlexeme += "\\\n";
}
<STRING>. {
    currentstring+=yytext;
    currentstringlexeme+=yytext;
}
<STRING>\n {
      logout<<"Error at line no "<<stringstartline<<": Unterminated string "<<currentstringlexeme<<"\n\n";
      BEGIN INITIAL;
      currentstringlexeme="";
      currentstring="";
    error_count++;  
}
<MULTICOMMENT><<EOF>> {
      logout<<"Error at line no "<<commentstartline<<": Unterminated comment /*"<<currentcomment<<"\n\n\n";
      error_count++;
      return 0;
}

{NEWLINE} ;
<<EOF>> {
    table->PrintNonempty(logout);
    logout<<"\n";
    return 0;
}
. {
    logout<<"Error at line no "<<yylineno<<": Unrecognized character "<<yytext<<"\n\n";
    error_count++;   
}

%%

int main(int argc, char *argv[]) {
    if (argc != 2) {
        cout << "Please provide input file name and try again\n";
        return 0;
    }

    FILE *fin = fopen(argv[1], "r");
    if (fin == NULL) {
        cout << "Cannot open specified file\n";
        return 0;
    }

    tokenout.open("token.txt");
    logout.open("log.txt");

    yyin = fin;
    yylex();

    logout << "Total lines: " << yylineno << endl;
    logout << "Total errors: " << error_count << endl;

    fclose(fin);
    tokenout.close();
    logout.close();
    return 0;
}
