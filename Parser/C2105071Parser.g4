parser grammar C2105071Parser;

options {
    tokenVocab = C2105071Lexer;
}

@parser::header {
    #include <iostream>
    #include <fstream>
    #include <string>
    #include <regex>
    #include <sstream>
    #include <vector>
    #include <cstdlib>
    #include <cctype>
    #include "C2105071Lexer.h"
    #include "2105071_SymbolTable.h"
    #include "str_list.cpp"

    extern std::ofstream parserLogFile;
    extern std::ofstream errorFile;

    extern int syntaxErrorCount;
}

@parser::members {
    bool previously_declared =false;
    bool is_function_definition = false;
    bool assign_check = false;
    std::string current_type;
    std::string current_function_calling;
    bool is_function_calling = false;
    int current_argument = 0;
    int bucket = 7;
    int errors=0;
    std::string current_function_definition;
    Symboltable *table = new Symboltable(bucket);
    void writeIntoparserLogFile(const std::string message) {
        if (!parserLogFile) {
            std::cout << "Error opening parserLogFile.txt" << std::endl;
            return;
        }

        parserLogFile << message << std::endl;
        parserLogFile.flush();
    }

    void writeIntoErrorFile(const std::string message) {
        if (!errorFile) {
            std::cout << "Error opening errorFile.txt" << std::endl;
            return;
        }
        errorFile << message << std::endl;
        errorFile.flush();
    }

    string trim(string s) {
    s.erase(0, s.find_first_not_of(" \t\n\r\f\v"));
    s.erase(s.find_last_not_of(" \t\n\r\f\v") + 1);
    return s;
}

bool int_checker(const std::string& query) {
    std::regex int_regex(R"([+-]?\d+)");
    return std::regex_match(trim(query), int_regex);
}

bool float_checker(const std::string& query) {
    std::regex float_regex(R"([+-]?((\d+\.\d*)|(\.\d+)|(\d+\.\d+))([eE][+-]?\d+)?)");
    return std::regex_match(trim(query), float_regex);
}

    string datatype(std::string query){
        if (int_checker(query)) return "int";
        else if (float_checker(query)) return "float";
        else return "invalid";
    }

    std::vector<std::string> split_by_comma(const std::string& input) {
        std::vector<std::string> result;
        std::stringstream ss(input);
        std::string token;

        while (std::getline(ss, token, ',')) {
            result.push_back(token);
        }

        return result;
    }


    bool is_valid_number(const std::string& s) {
    size_t start = s.find_first_not_of(" \t\n\r\f\v");
    size_t end = s.find_last_not_of(" \t\n\r\f\v");
    if (start == std::string::npos) return false; 
    std::string str = s.substr(start, end - start + 1);
    std::regex pattern(R"([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$)");
    return std::regex_match(str, pattern);
    }
bool char_in_string(char target, const std::string& str) {
    return str.find(target) != std::string::npos;
}
    bool is_function_call(const std::string& input) {
        std::regex func_regex(R"(^[a-zA-Z_]\w*\s*\(([^()]*)\)$)");
        return std::regex_match(input, func_regex);
    }
    string extract_function_name(const string& input) {
    std::regex func_regex(R"(^\s*([a-zA-Z_]\w*)\s*\(.*\)\s*$)");
    std::smatch match;
    
    if (std::regex_match(input, match, func_regex)) {
        return match[1];  // Group 1 is the function name
    }
    return ""; // Not a valid function call
}

#include <iostream>
#include <string>
#include <vector>
#include <regex>

std::vector<std::string> split_by_operators(const std::string& input) {
    std::regex op_regex(R"([\+\-\*])"); // escape + and * in regex
    std::sregex_token_iterator it(input.begin(), input.end(), op_regex, -1);
    std::sregex_token_iterator end;

    std::vector<std::string> tokens;
    while (it != end) {
        if (!it->str().empty())
            tokens.push_back(it->str());
        ++it;
    }

    return tokens;
}

}


start : p=program
	{
        writeIntoparserLogFile("Line "+std::to_string($p.line_cnt)+": start : program\n");
        table->PrintAll(parserLogFile);
        writeIntoparserLogFile("\n");
        writeIntoparserLogFile("Total number of lines: " + std::to_string($p.line_cnt) + "\n");
        writeIntoparserLogFile("Total number of errors: " + std::to_string(errors) + "\n");
	}
	;

program returns [str_list lst ,int line_cnt]: p=program u=unit {
        writeIntoparserLogFile("Line " + std::to_string($u.line_cnt) + ": program : program unit\n");
        $lst.set_variables($p.lst.get_variables());
        $lst.add($u.text);
        writeIntoparserLogFile($lst.get_list_as_newline_string()+"\n");
        $line_cnt = $u.line_cnt;

}
	| u=unit{
        writeIntoparserLogFile("Line " + std::to_string($u.line_cnt) + ": program : unit\n");
        writeIntoparserLogFile($u.text+"\n\n");
        $lst.add($u.text);
        $line_cnt = $u.line_cnt;
    }
	;
	
unit returns [std::string text, int line_cnt]: vr=var_declaration{
    writeIntoparserLogFile("Line "+std::to_string($vr.line_num)+" unit : var_declaration\n");
    writeIntoparserLogFile($vr.name + "\n\n");
    $text = $vr.name;
    $line_cnt = $vr.line_num;

}
     | fd=func_declaration{
        writeIntoparserLogFile("Line "+std::to_string($fd.line_cnt)+" unit : func_declaration\n");
        writeIntoparserLogFile($fd.text + "\n\n");
        $text = $fd.text;
        $line_cnt = $fd.line_cnt;

     }
     | fdef=func_definition{
        writeIntoparserLogFile("Line "+std::to_string($fdef.line_cnt)+" unit : func_definition\n");
        writeIntoparserLogFile($fdef.text + "\n\n");
        $text = $fdef.text;
        $line_cnt = $fdef.line_cnt;
     }
     ;
     
func_declaration returns [std::string text, int line_cnt]
: t=type_specifier id=ID{
    table->insert($id->getText(), "ID",$t.name_line,"function");
} LPAREN pl=parameter_list{

        std::string paramText = $pl.text;
        cout<<$pl.text<<endl;
        std::string delimiter = ",";
        size_t pos = 0;
        std::string token;
        int paramcount=0;
        vector<string>paramlist;
        while ((pos = paramText.find(delimiter)) != std::string::npos) {
            token = paramText.substr(0, pos);
            // Extract the parameter name (last word in the token)
            size_t lastSpace = token.find_last_of(" ");
            if (lastSpace != std::string::npos) {
                std::string paramName = token.substr(lastSpace + 1);
                paramcount++;
                paramlist.push_back(token.substr(0,lastSpace));
            }
            paramText.erase(0, pos + delimiter.length());
        }
        // Handle the last parameter
        if (!paramText.empty()) {
            size_t lastSpace = paramText.find_last_of(" ");
            if (lastSpace != std::string::npos) {
                std::string paramName = paramText.substr(lastSpace + 1);
                paramcount++;
                paramlist.push_back(paramText.substr(0,lastSpace));
            }
        }
        for(auto it:paramlist){
            cout<<it<<endl;
        }
        auto entry = table->lookup($id->getText());
        if(entry != nullptr){
            entry->setparamcount(paramcount);
            entry->setparamlist(paramlist);
        }

} RPAREN sm=SEMICOLON {
        $text = $t.name_line + " " + $id->getText() + "(" + $pl.text + ");";
        $line_cnt = $sm->getLine();
        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n");
        writeIntoparserLogFile($text + "\n\n");
    }
	| t=type_specifier id=ID{
        table->insert($id->getText(), "ID",$t.name_line,"function");
    } LPAREN RPAREN sm=SEMICOLON{
        $text = $t.name_line + " " + $id->getText() + "(" + ");";
        $line_cnt = $sm->getLine();
        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n");
        writeIntoparserLogFile($text + "\n\n");
        }
		;
		 
func_definition returns [string text,int line_cnt]
    : t=type_specifier id=ID{
        if(table->insert($id->getText(),"ID",$t.name_line,"function")==false){
            previously_declared=true;
            auto entry = table->lookup($id->getText());
            if(entry != nullptr){
                std::string vartype = entry->getvartype();
                if(vartype == "function"){
                    entry->setvartype("defined");
                }
                else{
            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of " + $id->getText() + "\n");
            errors++;
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of  " + $id->getText() + "\n");
                }
            }
        } 
} LPAREN {table->EnterScope();is_function_definition=true;
cout<<"turning on on "<<$id->getLine()<<endl;
}pl=parameter_list{
        auto entry2 = table->lookup($id->getText());
        std::string vartype;
        if(entry2 != nullptr) vartype = entry2->getvartype();
        std::string paramText = $pl.text;
        cout<<$pl.text<<endl;
        std::string delimiter = ",";
        size_t pos = 0;
        std::string token;
        int paramcount=0;
        vector<string>paramlist;
        while ((pos = paramText.find(delimiter)) != std::string::npos) {
            token = paramText.substr(0, pos);
            // Extract the parameter name (last word in the token)
            size_t lastSpace = token.find_last_of(" ");
            if (lastSpace != std::string::npos) {
                std::string paramName = token.substr(lastSpace + 1);
                paramcount++;
                paramlist.push_back(token.substr(0,lastSpace));
            }
            paramText.erase(0, pos + delimiter.length());
        }
        // Handle the last parameter
        if (!paramText.empty()) {
            size_t lastSpace = paramText.find_last_of(" ");
            if (lastSpace != std::string::npos) {
                std::string paramName = paramText.substr(lastSpace + 1);
                paramcount++;
                paramlist.push_back(paramText.substr(0,lastSpace));
            }
        }
        for(auto it:paramlist){
            cout<<it<<endl;
        }
        auto entry = table->lookup($id->getText());
        if(entry != nullptr){
            cout<<"Printing from function defintion "<<$id->getText()<<" "<<previously_declared<<endl;
            if(previously_declared && (entry->getvartype()=="defined")){
                int cnt = entry->getparamcount();
                    if(cnt != paramcount){
                    writeIntoErrorFile("Error at line "+std::to_string($id->getLine())+": Total number of arguments mismatch with declaration in function var\n");
                    errors++;
                    }

            }
            else{
                    entry->setparamcount(paramcount);
                    entry->setparamlist(paramlist);
            }
            previously_declared=false;
        }
} RPAREN {
        auto entry1 = table->lookup($id->getText());
            if(entry1 != nullptr){
                    std::string return_type=entry1->getdatatype();
                    if(return_type != $t.name_line){
                            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Return type mismatch of " + $id->getText() + "\n");
                            errors++;
                            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Return type mismatch with  " + $id->getText() + "\n");
                    }
            }
} cs=compound_statement {
        if($t.name_line == "void"){
            vector<string>all_statement = $cs.cmp_statement.get_variables();
            for(auto it:all_statement){
                std::string extracter = it.substr(0,6);
                if(extracter == "return"){
                    if(it[6] != ';'){
                    writeIntoErrorFile("Error at line " + std::to_string($cs.line_cnt) + ": Cannot return value from function " + ($id->getText()) + " with void return type \n");
                    errors++;
                    writeIntoparserLogFile("\nError at line " + std::to_string($cs.line_cnt) + ": Cannot return value from function " + ($id->getText()) + " with void return type \n");
                    }
                }
            }
        }
        writeIntoparserLogFile("\nLine " + std::to_string($cs.line_cnt) + ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
        writeIntoparserLogFile($t.name_line + " " + $id->getText() + "("+$pl.text+")" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}\n");
        $text = $t.name_line + " " + $id->getText() + "("+$pl.text+")" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}";
        $line_cnt = $cs.line_cnt;
        is_function_definition=false;
    }
    | t=type_specifier id=ID{table->insert($id->getText(),"ID",$t.name_line,"function");} LPAREN{
        table->EnterScope(); is_function_definition=true;
        cout<<"turning on on "<<$id->getLine()<<endl;
        } RPAREN cs=compound_statement {

        writeIntoparserLogFile("\nLine " + std::to_string($cs.line_cnt) + ": func_definition : type_specifier ID LPAREN  RPAREN compound_statement\n");
        writeIntoparserLogFile($t.name_line + " " + $id->getText() + "()" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}\n");
        $text = $t.name_line + " " + $id->getText() + "()" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}";
        $line_cnt = $cs.line_cnt;
        is_function_definition=false;
    }
    ;


parameter_list returns [std::string text, int line_cnt]
    : pl=parameter_list COMMA t=type_specifier id=ID {
        if(is_function_definition){
            cout<<"printing error"<<endl;
            if(table->insert($id->getText(), "ID",$t.name_line,"parameter")==false){
                writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of " + $id->getText() + " in parameter\n");
                errors++;
                writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of " + $id->getText() + " in parameter\n");
            }
        }

        $text = $pl.text + "," + $t.name_line + " " + $id->getText();
        $line_cnt = $id->getLine();
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": parameter_list : parameter_list COMMA type_specifier ID\n");
        writeIntoparserLogFile($text + "\n");
    }
    | pl=parameter_list COMMA t=type_specifier {
        $text = $pl.text + "," + $t.name_line;
        $line_cnt = $t.line_num;
        writeIntoparserLogFile("Line " + std::to_string($t.line_num) + ": parameter_list : parameter_list COMMA type_specifier\n");
        writeIntoparserLogFile($text + "\n");
        cout<<"matching function param , type_specifier "<<endl;
    }
    | t=type_specifier id=ID {
        if(is_function_definition){
            if(table->insert($id->getText(), "ID",$t.name_line,"parameter")==false){
            writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of " + $id->getText() + " in parameter\n");
            errors++;
            writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Multiple declaration of " + $id->getText() + " in parameter\n");
        }
        }
        $text = $t.name_line + " " + $id->getText();
        $line_cnt = $id->getLine();
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": parameter_list : type_specifier ID\n");
        writeIntoparserLogFile($text + "\n");
        cout<<"matching function param type_specifier id "<<$id->getText()<<endl;
    }
    | t=type_specifier {
        $text = $t.name_line;
        $line_cnt = $t.line_num;
        cout<<"matching function param type_specifier "<<endl;
        writeIntoparserLogFile("Line " + std::to_string($t.line_num) + ": parameter_list : type_specifier\n");
        writeIntoparserLogFile($text + "\n");
    }
    | pl=parameter_list addop=ADDOP{
                $text = $pl.text;
                 writeIntoparserLogFile("Error at line " + std::to_string($addop->getLine()) + ": syntax error, unexpected ADDOP, expecting RPAREN or COMMA\n");
                writeIntoErrorFile("Error at line " + std::to_string($addop->getLine()) + ": syntax error, unexpected ADDOP, expecting RPAREN or COMMA\n"); 
                errors++;       
    }
    ;

 		
compound_statement returns [str_list cmp_statement,int line_cnt]: lcurl=LCURL{
    if(!is_function_definition){
        table->EnterScope();
    }
    else{
        is_function_definition=false;
    }
} stmts=statements rcurl=RCURL {

        writeIntoparserLogFile("Line " + std::to_string($rcurl->getLine()) + ": compound_statement : LCURL statements RCURL\n");
        writeIntoparserLogFile("{\n" + $stmts.statement_list.get_list_as_newline_string() + "\n}\n");
        $cmp_statement = $stmts.statement_list;
        $line_cnt = $rcurl->getLine();
        table->PrintAll(parserLogFile);
        table->ExitScope();
    } 
 	 | lcurl=LCURL{
    if(!is_function_definition){
        table->EnterScope();
    }
    else{
        is_function_definition=false;
    }
} rcurl=RCURL{
            writeIntoparserLogFile("Line " + std::to_string($rcurl->getLine()) + ": compound_statement : LCURL  RCURL\n");
            writeIntoparserLogFile("{\n\n}\n");
             $line_cnt = $rcurl->getLine();
            table->PrintAll(parserLogFile);
            table->ExitScope();
}
 		    ;
 		    
var_declaration returns [std::string name, int line_num]
    : t=type_specifier dl=declaration_list sm=SEMICOLON {

        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + " var_declaration: type_specifier declaration_list SEMICOLON\n");

        if($t.name_line == "void"){
            writeIntoErrorFile("Error at line "+std::to_string($sm->getLine())+": Variable type cannot be void\n");
            errors++;
            writeIntoparserLogFile("Error at line "+std::to_string($sm->getLine())+" : Variable type cannot be void\n");
        }
        writeIntoparserLogFile($t.name_line + " " +$dl.var_list.get_list_as_string()+ ";\n");
        $name=""+$t.name_line+" "+$dl.var_list.get_list_as_string()+";";
        $line_num = $sm->getLine();
      }

    | t=type_specifier de=declaration_list_err sm=SEMICOLON {
        writeIntoErrorFile(
            std::string("Line# ") + std::to_string($sm->getLine()) +
            " with error name: " + $de.error_name +
            " - Syntax error at declaration list of variable declaration"
        );
            errors++;
        $name="error";
        $line_num = $sm->getLine();


        errors++;
      }
    ;

declaration_list_err returns [std::string error_name]: {
        $error_name = "Error in declaration list";
    };

 		 
type_specifier returns [std::string name_line , int line_num]	
        : INT {
            $name_line = "int";
            writeIntoparserLogFile("Line " + std::to_string($INT->getLine()) + ": type_specifier : INT\n");
             writeIntoparserLogFile($INT->getText()+"\n");
             $line_num = $INT->getLine();
            current_type = "int";

        }
 		| FLOAT {
            $name_line = "float";
            writeIntoparserLogFile("Line " + std::to_string($FLOAT->getLine()) + ": type_specifier : FLOAT\n");
             writeIntoparserLogFile($FLOAT->getText()+"\n");
             $line_num = $FLOAT->getLine();
             current_type = "float";
        }
 		| VOID {
            $name_line = "void";
            writeIntoparserLogFile("Line " + std::to_string($VOID->getLine()) + ": type_specifier : VOID\n");
             writeIntoparserLogFile($VOID->getText()+"\n");
             $line_num = $VOID->getLine();
             current_type = "void";
        }
 		;
 		
declaration_list returns [str_list var_list]: dl=declaration_list COMMA ID{
                $var_list.set_variables($dl.var_list.get_variables());
                $var_list.add($ID->getText());
            if(!table->insert($ID->getText(), "ID",current_type,current_type)){
                writeIntoparserLogFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
                writeIntoErrorFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
            errors++;
            }
                writeIntoparserLogFile("Line "+std::to_string($ID->getLine())+": declaration_list : declaration_list COMMA ID\n");
                writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
            }
          | dl=declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
            if(!table->insert($ID->getText(), "ID",current_type,"array")){
                writeIntoparserLogFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
                writeIntoErrorFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
                            errors++;
            }
            writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n");
            writeIntoparserLogFile($dl.var_list.get_list_as_string() + "," + $ID->getText() + "[" + $CONST_INT->getText() + "]\n");
            $var_list.set_variables($dl.var_list.get_variables());
             $var_list.add($ID->getText() + "[" + $CONST_INT->getText() + "]");
          }
          | ID {
            if(!table->insert($ID->getText(), "ID",current_type,current_type)){
                writeIntoparserLogFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
                writeIntoErrorFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
                            errors++;
            }
            writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : ID\n");
             writeIntoparserLogFile($ID->getText()+"\n");
             $var_list.add($ID->getText());
          }
          | ID LTHIRD CONST_INT RTHIRD {
            if(!table->insert($ID->getText(), "ID",current_type,"array")){
                writeIntoparserLogFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
                writeIntoErrorFile("Error at line " + std::to_string($ID->getLine())+": Multiple declaration of " + $ID->getText()+"\n");
                            errors++;
            }
            writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n");
            writeIntoparserLogFile($ID->getText() + "[" + $CONST_INT->getText() + "]\n");

             $var_list.add($ID->getText() + "[" + $CONST_INT->getText() + "]");
          }
          | dl=declaration_list addop=ADDOP id=ID  {
                $var_list.set_variables($dl.var_list.get_variables());
                writeIntoparserLogFile("Error at line " + std::to_string($addop->getLine()) + ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON\n");
                writeIntoErrorFile("Error at line " + std::to_string($addop->getLine()) + ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON\n"); 
                errors++;                   
          }
          ;
 		  
statements returns [str_list statement_list] : stmt=statement {
        writeIntoparserLogFile("Line " + std::to_string($stmt.line_num) + ": statements : statement\n");
        $statement_list.add($stmt.text);
        writeIntoparserLogFile($stmt.text + "\n\n");
    }
	   | stl=statements stmt=statement{
        $statement_list.set_variables($stl.statement_list.get_variables());
        $statement_list.add($stmt.text);
        writeIntoparserLogFile("Line " + std::to_string($stmt.line_num) + ": statements : statements statement\n");
        writeIntoparserLogFile($statement_list.get_list_as_newline_string());
        writeIntoparserLogFile("\n");     
       }
	   ;
	   
statement returns [std::string text, int line_num] : vdecl=var_declaration{
        $text = $vdecl.name;
        $line_num = $vdecl.line_num;
        writeIntoparserLogFile("Line " + std::to_string($vdecl.line_num) + ": statement : var_declaration\n");
        writeIntoparserLogFile($text + "\n");
    }
	  | estmt=expression_statement {
        $text = $estmt.text;
        $line_num = $estmt.line_num;
        writeIntoparserLogFile("Line " + std::to_string($estmt.line_num) + ": statement : expression_statement\n");
        writeIntoparserLogFile($text + "\n");
    }
	  | cstmt=compound_statement {
        $text = "{\n" + $cstmt.cmp_statement.get_list_as_newline_string() + "\n}";
        $line_num = $cstmt.line_cnt;
        writeIntoparserLogFile("Line " + std::to_string($cstmt.line_cnt) + ": statement : compound_statement\n");
        writeIntoparserLogFile($text + "\n");
    }
	  | FOR LPAREN init=expression_statement cond1=expression_statement inc=expression RPAREN body=statement {
        $text = "for(" + $init.text + $cond1.text + ";" + $inc.text + ")\n" + $body.text;
        $line_num = $FOR->getLine();
        writeIntoparserLogFile("Line " + std::to_string($line_num) + ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
    }
	  | IF LPAREN expr=expression RPAREN stmt1=statement {
        $text = "if (" + $expr.text + ")\n" + $stmt1.text;
        $line_num = $stmt1.line_num;
        writeIntoparserLogFile("Line " + std::to_string($stmt1.line_num) + ": statement : IF LPAREN expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
    }
	  | IF LPAREN expr=expression RPAREN stmt1=statement ELSE stmt2=statement {
        $text = "if (" + $expr.text + ")\n" + $stmt1.text + "\nelse\n" + $stmt2.text;
        $line_num = $stmt1.line_num;
        writeIntoparserLogFile("Line " + std::to_string($stmt2.line_num) + ": statement : IF LPAREN expression RPAREN statement ELSE statement\n");
        writeIntoparserLogFile($text + "\n");
    }
	  | WHILE LPAREN cond=expression RPAREN body=statement {
        $text = "while (" + $cond.text + ")\n" + $body.text;
        $line_num = $WHILE->getLine();
        writeIntoparserLogFile("Line " + std::to_string($line_num) + ": statement : WHILE LPAREN expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
    }
	  | PRINTLN LPAREN id=ID RPAREN sm=SEMICOLON {
        $text = "printf(" + $id->getText() + ");";
        $line_num = $sm->getLine();
        writeIntoparserLogFile("Line " + std::to_string($line_num) + ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n");
        auto entry = table->lookup($id->getText());
        if(entry == nullptr){
            writeIntoErrorFile("Error at line "+std::to_string($id->getLine())+": Undeclared variable "+$id->getText()+"\n");
            writeIntoparserLogFile("Error at line "+std::to_string($id->getLine())+": Undeclared variable "+$id->getText()+"\n");
            errors++;
        }
        writeIntoparserLogFile($text + "\n");
    }
	  | RETURN expr=expression sm=SEMICOLON {
        $text = "return " + $expr.text + ";";
        $line_num = $sm->getLine();
        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + ": statement : RETURN expression SEMICOLON\n");
        writeIntoparserLogFile($text + "\n\n");
    }
	  ;
	  
expression_statement returns [std::string text, int line_num] : SEMICOLON {
        $text = ";";
        $line_num = $SEMICOLON->getLine();
        writeIntoparserLogFile("Line " + std::to_string($SEMICOLON->getLine()) + ": expression_statement : SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }			
			| expr=expression SEMICOLON {
        $text = $expr.text + ";";
        $line_num = $SEMICOLON->getLine();
        writeIntoparserLogFile("Line " + std::to_string($SEMICOLON->getLine()) + ": expression_statement : expression SEMICOLON\n");
        writeIntoparserLogFile($text + "\n");
    }
			;
	  
variable returns[std::string text,int line_num]: id=ID {
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": variable : ID\n");
        if(table->lookup($id->getText()) == nullptr){
            writeIntoErrorFile("Error at line "+std::to_string($id->getLine())+": Undeclared variable "+$id->getText()+"\n");
                        errors++;
            writeIntoparserLogFile("Error at line "+std::to_string($id->getLine())+": Undeclared variable "+$id->getText()+"\n");            
           
        }
        if(is_function_calling){
            auto entry = table->lookup(current_function_calling);
            if(entry != nullptr){
                std::string arg_type = entry->getparamlist()[current_argument];
                current_argument++;
                auto entry = table->lookup($id->getText());
                if(entry != nullptr){
                    if(arg_type != entry->getvartype()){
                    writeIntoErrorFile("Error at line "+std::to_string($id->getLine())+": Type mismatch, "+$id->getText()+" is an "+entry->getvartype()+"\n");
                                errors++;
                    writeIntoparserLogFile("Error at line "+std::to_string($id->getLine())+": Type mismatch, "+$id->getText()+" is an "+entry->getvartype()+"\n");                         
                    }
                }

                
            }
        }
        writeIntoparserLogFile($id->getText() + "\n");
        $text = $id->getText();
        $line_num = $id->getLine();
    }		
	 | id=ID LTHIRD expr=expression RTHIRD {
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": variable : ID LTHIRD expression RTHIRD\n");
 bool isInt = true;
    for (char c : $expr.text) {
        if (!isdigit(c) && c != '-') { isInt = false; break; }
    }
    if (!isInt) {
        writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": Expression inside third brackets not an integer\n");
        writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": Expression inside third brackets not an integer\n");
                    errors++;

    }
       auto entry = table->lookup($id->getText());
       if(entry != nullptr){
           if(entry->getvartype() != "array"){
                writeIntoErrorFile("Error at line " + std::to_string($id->getLine()) + ": " + $id->getText() + " not an array\n");
                            errors++;
                writeIntoparserLogFile("Error at line " + std::to_string($id->getLine()) + ": " + $id->getText() + " not an array\n");

           }
       }
        writeIntoparserLogFile($id->getText() + "[" + $expr.text + "]\n");
        $text = $id->getText()+"[" + $expr.text + "]";
        $line_num = $id->getLine();
    }
	 ;
	 
 expression : le=logic_expression {
        writeIntoparserLogFile("Line " + std::to_string($le.start->getLine()) + ": expression : logic expression\n");
        writeIntoparserLogFile($le.text + "\n");
    }	
	   | var=variable{
            auto entry = table->lookup($var.text);
            if(entry != nullptr) {
                     std::string vartype = entry->getvartype();
                if(vartype == "array"){
                    writeIntoErrorFile("Error at line "+std::to_string($var.line_num)+": Type mismatch, "+$var.text+" is an array "+"\n");
                errors++;
                    writeIntoparserLogFile("Error at line "+std::to_string($var.line_num)+": Type mismatch, "+$var.text+" is an array "+"\n");           


                }
                }
            }
        ASSIGNOP le=logic_expression {
        writeIntoparserLogFile("Line " + std::to_string($ASSIGNOP->getLine()) + ": expression : variable ASSIGNOP logic_expression\n");

        std::string left_var;
        cout<<"variable info is "<<$var.text<<endl;
            std::regex array_regex(R"(^\s*([a-zA-Z_]\w*)\s*\[\s*\d+\s*\]\s*$)");
            std::smatch match;

        if (std::regex_match($var.text, match, array_regex)) {
        left_var = match[1];
    }
    else{
        left_var = $var.text;
    }
        //std::string exprType = getType($le.text);
        if(table->lookup(left_var) != nullptr){
            std::string varType = table->lookup(left_var)->getdatatype();
            cout<<"var type is "<<varType<<endl;
            bool isInt = true;
            bool checked = false;
            vector<string>expressions = split_by_operators($le.text);
            cout<<"Expressions are "<<endl;
            for(auto it:expressions){
                cout<<it<<endl;
            if(float_checker(it)){isInt=false;break;}
            else if(is_function_call(it)){
                std::string func_name = extract_function_name(it);
                auto entry = table->lookup(func_name);
                if(entry != nullptr){
                    if(entry->getdatatype() == "float") {isInt=false;               
                    break;}
                }
            }
            }
            if(is_function_call(expressions[0]) && expressions.size() == 1){
                 std::string func_name = extract_function_name(expressions[0]);
                auto entry = table->lookup(func_name);
                if(entry != nullptr){
                    if(entry->getdatatype() == "void") {
                            writeIntoErrorFile("Error at line " + std::to_string($ASSIGNOP->getLine()) + ": Void function used in expression\n");
                            errors++;
                            writeIntoparserLogFile("Error at line " + std::to_string($ASSIGNOP->getLine()) + ": Void function used in expression\n");
                    }
                }               
            }
            else if(varType == "int" && isInt == false){
                if(!char_in_string('%',$le.text)){
                writeIntoErrorFile("Error at line " + std::to_string($ASSIGNOP->getLine()) + ": Type Mismatch\n");
                            errors++;
                writeIntoparserLogFile("Error at line " + std::to_string($ASSIGNOP->getLine()) + ": Type Mismatch\n");   
                }            
            }            
        }




        writeIntoparserLogFile($var.text + $ASSIGNOP->getText() + $le.text + "\n");
    }	
	   ;
			
logic_expression returns [std::string text, int line_num]: re=rel_expression {
        writeIntoparserLogFile("Line " + std::to_string($re.start->getLine()) + ": logic_expression : rel_expression\n");
        writeIntoparserLogFile($re.text + "\n");
        $text = $re.text;
        $line_num = $re.start->getLine();
    }	
		 | re1=rel_expression logicop=LOGICOP re2=rel_expression {
        writeIntoparserLogFile("Line " + std::to_string($logicop->getLine()) + ": logic_expression : rel_expression LOGICOP rel_expression\n");
        writeIntoparserLogFile($re1.text + $logicop->getText() + $re2.text + "\n");
        $text = $re1.text + $logicop->getText() + $re2.text;
        $line_num = $logicop->getLine();
    }	
		 ;
			
rel_expression returns [std::string text, int line_num]: se=simple_expression {
        writeIntoparserLogFile("Line " + std::to_string($se.start->getLine()) + ": rel_expression : simple_expression\n");
        writeIntoparserLogFile($se.text + "\n");
        $text = $se.text;
        $line_num = $se.start->getLine();
    }
		| se1=simple_expression relop=RELOP se2=simple_expression {
        writeIntoparserLogFile("Line " + std::to_string($relop->getLine()) + ": rel_expression : simple_expression RELOP simple_expression\n");
        writeIntoparserLogFile($se1.text + $relop->getText() + $se2.text + "\n");
        $text = $se1.text + $relop->getText() + $se2.text;
        $line_num = $relop->getLine();
    }	
		;
			
simple_expression : t=term {
        writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": simple_expression : term\n");
        writeIntoparserLogFile($t.text + "\n");
    }
		  | se=simple_expression addop=ADDOP t=term {
        writeIntoparserLogFile("Line " + std::to_string($addop->getLine()) + ": simple_expression : simple_expression ADDOP term\n");
        writeIntoparserLogFile($se.text + $addop->getText() + $t.text + "\n");
    }
    | se=simple_expression addop=ADDOP assignop=ASSIGNOP t=term{
         writeIntoparserLogFile("Error at line " + std::to_string($addop->getLine()) + ": syntax error, unexpected ASSIGNOP\n");
         writeIntoErrorFile("Error at line " + std::to_string($addop->getLine()) + ": syntax error, unexpected ASSIGNOP\n"); 
         errors++;     
    }
		  ;
					
term returns [std::string text, int line_num]:	unary_expr=unary_expression {
        writeIntoparserLogFile("Line " + std::to_string($unary_expr.start->getLine()) + ": term : unary_expression\n");
        writeIntoparserLogFile($unary_expr.text + "\n");
        $text = $unary_expr.text;
        $line_num = $unary_expr.start->getLine();
    }
     |  t=term mulop=MULOP uexpr=unary_expression {
        writeIntoparserLogFile("Line " + std::to_string($mulop->getLine()) + ": term : term MULOP unary_expression\n");
        bool function_call = is_function_call($uexpr.text);
        if(function_call){
               std::string function_name = extract_function_name($uexpr.text);
                writeIntoparserLogFile(function_name+"\n");
                auto entry = table->lookup(function_name);
                if(entry != nullptr){
                        std::string return_type = entry->getdatatype();
                        if(return_type == "void"){
                            writeIntoErrorFile("Error at line " + std::to_string($mulop->getLine()) + ": Void function used in expression\n");
                            errors++;
                            writeIntoparserLogFile("Error at line " + std::to_string($mulop->getLine()) + ": Void function used in expression\n");

                        }
                }
                else{
                        writeIntoErrorFile("Error at line " + std::to_string($mulop->getLine()) + ": Undefined function " + $uexpr.text + "\n");
                        errors++;
                        writeIntoparserLogFile("Error at line " + std::to_string($mulop->getLine()) + ": Undefined function " + $uexpr.text + "\n");

                }

        }
        else{
        bool isInt = true;
            for (char c : $t.text) {
                if (!isdigit(c) && c != '-') { isInt = false; break; }
            }
            if(isInt == false && $mulop ->getText()=="%"){
                writeIntoErrorFile("Error at line " + std::to_string($mulop->getLine()) + ": Non-Integer operand on modulus operator\n");
                            errors++;
                 writeIntoparserLogFile("Error at line " + std::to_string($mulop->getLine()) + ": Non-Integer operand on modulus operator\n");              
            }
            if($uexpr.text == "0" && $mulop ->getText()=="%"){
                writeIntoErrorFile("Error at line " + std::to_string($mulop->getLine()) + ": Modulus by Zero\n");
                            errors++;
                 writeIntoparserLogFile("Error at line " + std::to_string($mulop->getLine()) + ": Modulus by Zero\n");              
            }
for (char c : $uexpr.text) {
                if (!isdigit(c) && c != '-') { isInt = false; break; }
            }
            if(isInt == false && $mulop ->getText()=="%"){
                writeIntoErrorFile("Error at line " + std::to_string($mulop->getLine()) + ": Non-Integer operand on modulus operator\n");
                           errors++;
                 writeIntoparserLogFile("Error at line " + std::to_string($mulop->getLine()) + ": Non-Integer operand on modulus operator\n");              
            } 

        }

        writeIntoparserLogFile($t.text + $mulop->getText() + $uexpr.text + "\n");
        $text = $t.text + $mulop->getText() + $uexpr.text;
        $line_num = $mulop->getLine();
     }
     ;

unary_expression returns [std::string text]
    : addop=ADDOP uexpr=unary_expression {
        $text = $addop->getText() + $uexpr.text;
        writeIntoparserLogFile("Line " + std::to_string($addop->getLine()) + ": unary_expression : ADDOP unary_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | notop=NOT uexpr=unary_expression {
        $text = $notop->getText() + $uexpr.text;
        writeIntoparserLogFile("Line " + std::to_string($notop->getLine()) + ": unary_expression : NOT unary_expression\n");
        writeIntoparserLogFile($text + "\n");
    }
    | fact=factor {
        $text = $fact.text;
        writeIntoparserLogFile("Line " + std::to_string($fact.start->getLine()) + ": unary_expression : factor\n");
        writeIntoparserLogFile($fact.text + "\n");
    }
    ;
	
factor	: var=variable {
        writeIntoparserLogFile("Line " + std::to_string($var.start->getLine()) + ": factor : variable\n");
        writeIntoparserLogFile($var.text + "\n");
    }
	| id=ID{
        current_function_calling=$id->getText();
        is_function_calling = true;
    } LPAREN args=argument_list{
            is_function_calling=false;
            
    } RPAREN {

        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": factor : ID LPAREN argument_list RPAREN\n");

        auto entry = table->lookup(current_function_calling);
        if(entry != nullptr){
            int params = entry->getparamcount();
            vector<string>arguments = split_by_comma($args.text);

            if((params != arguments.size())){
                writeIntoErrorFile("Error at line "+std::to_string($id->getLine())+": Total number of arguments mismatch with declaration in function "+current_function_calling+"\n");
                            errors++;
                writeIntoparserLogFile("Error at line "+std::to_string($id->getLine())+": Total number of arguments mismatch with declaration in function "+current_function_calling+"\n");
            }
            for(int i=0;i<std::min(params, static_cast<int>(arguments.size()));i++){
                std::string arg_type = entry->getparamlist()[i];
                if(!is_valid_number(arguments[i])) continue;
                if(arg_type != datatype(arguments[i])){
                writeIntoErrorFile("Error at line "+std::to_string($id->getLine())+": "+std::to_string(i+1)+"th argument mismatch in function "+$id->getText()+"\n");
                            errors++;
                writeIntoparserLogFile("Error at line "+std::to_string($id->getLine())+": "+std::to_string(i+1)+"th argument mismatch in function "+$id->getText()+"\n");
                break;
                }
            }
        }
        else{
            writeIntoErrorFile("Error at line "+std::to_string($id->getLine())+": Undefined function "+$id->getText()+"\n");
            writeIntoparserLogFile("Error at line "+std::to_string($id->getLine())+": Undefined function "+$id->getText()+"\n");
            errors++;
        }

        writeIntoparserLogFile($id->getText() + "(" + $args.text + ")\n");
        current_argument=0;
    }
	| LPAREN expr=expression RPAREN {
        writeIntoparserLogFile("Line " + std::to_string($LPAREN->getLine()) + ": factor : LPAREN expression RPAREN\n");
        writeIntoparserLogFile("(" + $expr.text + ")\n");
    }
	| const_int=CONST_INT {
        writeIntoparserLogFile("Line " + std::to_string($const_int->getLine()) + ": factor : CONST_INT\n");
        writeIntoparserLogFile($const_int->getText() + "\n");
    }
	| const_float=CONST_FLOAT {
        writeIntoparserLogFile("Line " + std::to_string($const_float->getLine()) + ": factor : CONST_FLOAT\n");
        writeIntoparserLogFile($const_float->getText() + "\n");
    }
	| var=variable inc=INCOP {
        writeIntoparserLogFile("Line " + std::to_string($var.start->getLine()) + ": factor : variable INCOP\n");
        writeIntoparserLogFile($var.text + $inc->getText() + "\n");
    }
	| var=variable dec=DECOP {
        writeIntoparserLogFile("Line " + std::to_string($var.start->getLine()) + ": factor : variable DECOP\n");
        writeIntoparserLogFile($var.text + $dec->getText() + "\n");
    } 
    | errorToken
	;
	
argument_list returns [std::string text, int line_num] : args=arguments {
        writeIntoparserLogFile("Line " + std::to_string($args.line_num) + ": argument_list : arguments\n");
        writeIntoparserLogFile($args.text + "\n");
        $text = $args.text;
        $line_num = $args.line_num;
    }
			  | 
			  ;
	
arguments returns [std::string text, int line_num]: args=arguments COMMA le=logic_expression {
        writeIntoparserLogFile("Line " + std::to_string($le.line_num) + ": arguments : arguments COMMA logic_expression\n");
        writeIntoparserLogFile($args.text + "," + $le.text + "\n");
        $text = $args.text + "," + $le.text;
        $line_num = $le.line_num;
    }
	      | le=logic_expression {
        writeIntoparserLogFile("Line " + std::to_string($le.line_num) + ": arguments : logic_expression\n");
        writeIntoparserLogFile($le.text + "\n");
        $text = $le.text;
        $line_num = $le.line_num;
    }
	      ;
errorToken
    : ERROR {
        writeIntoparserLogFile("Error at line " + std::to_string($ERROR->getLine()) + ": Unrecognized character " + $ERROR->getText() + "\n");
        writeIntoErrorFile("Error at line " + std::to_string($ERROR->getLine()) + ": Unrecognized character " + $ERROR->getText() + "\n");
    }
    ;


