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
    extern std::ofstream finalfile;
    extern std::ofstream codefile;
    extern std::ofstream optcodefile;
    extern int syntaxErrorCount;
}

@parser::members {
    int inc_label = -1;
    int code_file_line_number = 0;
    stack<int>start_label;
    stack<int>end_label;
    stack<int>conditional_end_label;
    stack<int>short_circuit_end_label;
    stack<int>return_line_number;
    stack<int>conditional_else_label;
    stack<int>short_circuit_else_label;
    bool inside_loop = false;
    bool condition = false;
    bool inside_if_else = false;
    bool inside_function = false;
    int offset = 0;
    bool is_global = true;
    bool code_printed=false;
    bool previously_declared =false;
    bool is_function_definition = false;
    bool assign_check = false;
    std::string current_type;
    std::string current_function_calling;
    bool is_function_calling = false;
    int current_argument = 0;
    int bucket = 7;
    int errors=0;
    stack<int>offsets;
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

        int writeIntoCodefile(const std::string message) {
        if (!codefile) {
            std::cout << "Error opening parserLogFile.txt" << std::endl;
            return -1;
        }

        codefile << message << std::endl;
        codefile.flush();
        code_file_line_number++;
        return code_file_line_number;
    }

    void writenewline(){
        writeIntoCodefile("new_line proc");
        writeIntoCodefile("\tpush ax");
        writeIntoCodefile("\tpush dx");
        writeIntoCodefile("\tmov ah,2");
        writeIntoCodefile("\tmov dl,0Dh");
        writeIntoCodefile("\tint 21h");
        writeIntoCodefile("\tmov ah,2");
        writeIntoCodefile("\tmov dl,0Ah");
        writeIntoCodefile("\tint 21h");
        writeIntoCodefile("\tpop dx");
        writeIntoCodefile("\tpop ax");
        writeIntoCodefile("\tret");
        writeIntoCodefile("new_line endp");

    }

    void writeIntoErrorFile(const std::string message) {
        if (!finalfile) {
            std::cout << "Error opening errorFile.txt" << std::endl;
            return;
        }
        finalfile << message << std::endl;
        finalfile.flush();
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

    bool headerPrinted = false;

void writePrintOutputProc() {
    writeIntoCodefile("print_output proc");
    writeIntoCodefile("\tpush ax");
    writeIntoCodefile("\tpush bx");
    writeIntoCodefile("\tpush cx");
    writeIntoCodefile("\tpush dx");
    writeIntoCodefile("\tpush si");
    writeIntoCodefile("\tlea si, number");
    writeIntoCodefile("\tmov bx, 10");
    writeIntoCodefile("\tadd si, 4");
    writeIntoCodefile("\tcmp ax, 0");
    writeIntoCodefile("\tjnge negate");

    writeIntoCodefile("\tprint:");
    writeIntoCodefile("\txor dx, dx");
    writeIntoCodefile("\tdiv bx");
    writeIntoCodefile("\tmov [si], dl");
    writeIntoCodefile("\tadd [si], '0'");
    writeIntoCodefile("\tdec si");
    writeIntoCodefile("\tcmp ax, 0");
    writeIntoCodefile("\tjne print");
    writeIntoCodefile("\tinc si");
    writeIntoCodefile("\tlea dx, si");
    writeIntoCodefile("\tmov ah, 9");
    writeIntoCodefile("\tint 21h");

    writeIntoCodefile("\tpop si");
    writeIntoCodefile("\tpop dx");
    writeIntoCodefile("\tpop cx");
    writeIntoCodefile("\tpop bx");
    writeIntoCodefile("\tpop ax");
    writeIntoCodefile("\tret");

    writeIntoCodefile("\tnegate:");
    writeIntoCodefile("\tpush ax");
    writeIntoCodefile("\tmov ah, 2");
    writeIntoCodefile("\tmov dl, '-'");
    writeIntoCodefile("\tint 21h");
    writeIntoCodefile("\tpop ax");
    writeIntoCodefile("\tneg ax");
    writeIntoCodefile("\tjmp print");

    writeIntoCodefile("print_output endp");
}
int label = 1;
void  writelabel(){
    string ans =  "L"+std::to_string(label)+":";
    label++;
    writeIntoCodefile(ans);
}
string nextlabel(){
    return "L"+std::to_string(label);
}

void insertLine(const string& filename, const string& newLine, int lineNumber) {
    ifstream fileIn(filename);
    if (!fileIn) return;

    vector<string> lines;
    string line;

    while (getline(fileIn, line)) {
        lines.push_back(line);
    }
    fileIn.close();

    if (lineNumber < 0) lineNumber = 0;
    if (lineNumber > lines.size()) lineNumber = lines.size();

    lines.insert(lines.begin() + lineNumber, newLine);

    ofstream fileOut(filename, ios::trunc); // safe rewrite
    for (const auto& l : lines) {
        fileOut << l << endl;
    }
    fileOut.close();
}

map<int,string>mp;

void backpatch(){
    cout<<"CAlling backpatch"<<endl;
    ifstream tempcodefile("output/code.asm");
    string line;
    int line_cnt = 0;
    while(getline(tempcodefile,line)){
        line_cnt++;
        finalfile<<line<<endl;
        if(mp[line_cnt] != "") finalfile<<mp[line_cnt]<<endl;
    }
}

bool is_array_reference(const string& input) {
    // Checks format like arr[0], temp[ 10 ], etc.
    regex array_regex(R"(^\s*[a-zA-Z_]\w*\s*\[\s*\d+\s*\]\s*$)");
    return regex_match(input, array_regex);
}
string extract_array_name(const string& input) {
    regex name_regex(R"(^\s*([a-zA-Z_]\w*)\s*\[\s*\d+\s*\]\s*$)");
    smatch match;

    if (regex_match(input, match, name_regex)) {
        return match[1];  // The identifier before the brackets
    }

    return "";  // Return empty string if invalid
}
int param_number = 0;

std::string trim(const std::string& str) {
    size_t first = str.find_first_not_of(" \t\r\n");
    size_t last = str.find_last_not_of(" \t\r\n");
    if (first == std::string::npos || last == std::string::npos) return "";
    return str.substr(first, (last - first + 1));
}

std::string get_register(const std::string& line) {
    std::istringstream iss(line);
    std::string op, reg;
    iss >> op >> reg;
    return reg;
}
bool is_redundant_math(const std::string& line) {
    std::string clean = trim(line);
    std::transform(clean.begin(), clean.end(), clean.begin(), ::toupper);

    // Normalize spacing
    std::istringstream iss(clean);
    std::string instr, reg, comma, imm;
    iss >> instr >> reg >> comma >> imm;

    // Remove comma if exists
    if (!reg.empty() && reg.back() == ',') {
        reg.pop_back();
        imm = comma;  // shift
    }

    if (instr == "ADD" && imm == "0") return true;
    if (instr == "SUB" && imm == "0") return true;
    if (instr == "MUL" && imm == "1") return true;

    return false;
}
void optimize(){
    std::ifstream infile("output/finalCode.asm");
    std::ofstream outfile("output/optCode.asm");

    if (!infile || !outfile) {
        std::cerr << "Error opening file.\n";
        return;
    }

    std::vector<std::string> lines;
    std::string line;

    // Read all lines into a vector
    while (std::getline(infile, line)) {
        lines.push_back(line);
    }

    for (size_t i = 0; i < lines.size(); ++i) {
        std::string current = trim(lines[i]);

        if (i + 1 < lines.size()) {
            std::string next = trim(lines[i + 1]);

            // Check for PUSH reg followed by POP reg with same register
            if (current.substr(0, 4) == "PUSH" && next.substr(0, 3) == "POP") {
                std::string reg1 = get_register(current);
                std::string reg2 = get_register(next);

                // If same register, skip both
                if (reg1 == reg2) {
                    i++; // Skip next line too
                    continue;
                }
            }
        }
        if (is_redundant_math(current)) {
            continue;
        }
        outfile << lines[i] << '\n';
    }
}
}

start : p=program
    {
        writeIntoCodefile("\tMOV AX,4CH");
        writeIntoCodefile("\tINT 21H");
        writenewline();
        writePrintOutputProc();
        writeIntoCodefile("END main");
        backpatch();
        optimize();
    }
    ;

program returns [str_list lst ,int line_cnt]: 
     {
        if (!headerPrinted) {
            writeIntoCodefile(".MODEL SMALL");
            writeIntoCodefile(".STACK 1000H");
            writeIntoCodefile(".Data");
            writeIntoCodefile("\tnumber DB \"00000$\"");
            headerPrinted = true;
        }
      }
      
|p=program u=unit {
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
    : t=type_specifier{
        is_global=false;
        offsets.push(offset);
        inside_function=true;
        if(code_printed==false){
            writeIntoCodefile(".CODE");
            code_printed=true;
        }
        param_number=0;

} id=ID{
       if($id->getText() == "main"){
        writeIntoCodefile("main PROC");
        writeIntoCodefile("\tMOV AX, @DATA");
        writeIntoCodefile("\tMOV DS,AX");
        writeIntoCodefile("\tPUSH BP");
        writeIntoCodefile("\tMOV BP,SP");
        is_global = false;
        }
        else {
        writeIntoCodefile($id->getText()+" PROC");
        writeIntoCodefile("\tPUSH BP");
        writeIntoCodefile("\tMOV BP,SP");
        offsets.push(offset);
           
        }
        offset = 0;
        if(table->insert($id->getText(),"ID",$t.name_line,"function")==false){
            previously_declared=true;
            auto entry = table->lookup($id->getText());
            if(entry != nullptr){
                std::string vartype = entry->getvartype();
                if(vartype == "function"){
                    entry->setvartype("defined");
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
                paramlist.push_back(paramName);
            }
            paramText.erase(0, pos + delimiter.length());
        }
        // Handle the last parameter
        if (!paramText.empty()) {
            size_t lastSpace = paramText.find_last_of(" ");
            if (lastSpace != std::string::npos) {
                std::string paramName = paramText.substr(lastSpace + 1);
                paramcount++;
                paramlist.push_back(paramName);
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

            }
            else{
                    entry->setparamcount(paramcount);
                    entry->setparamlist(paramlist);
            }
        }
        int totalsize = paramcount * 2 + 2;
        for(auto it:paramlist){
            auto entry = table->lookup(it);
            if(entry != nullptr){
               entry->offset = totalsize;
               totalsize-=2;
            }
        }

} RPAREN  cs=compound_statement {
        writeIntoparserLogFile("\nLine " + std::to_string($cs.line_cnt) + ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n");
        writeIntoparserLogFile($t.name_line + " " + $id->getText() + "("+$pl.text+")" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}\n");
        $text = $t.name_line + " " + $id->getText() + "("+$pl.text+")" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}";
        $line_cnt = $cs.line_cnt;
        is_function_definition=false;
        while(!return_line_number.empty()){
            int line_no = return_line_number.top();
            return_line_number.pop();

            string instruction  = "\tJMP L" + std::to_string(label-1);
            mp[line_no] = instruction;
        }
        writeIntoCodefile("\tADD SP,"+std::to_string(offset));
        writeIntoCodefile("\tPOP BP");
        int ret_num = param_number * 2;
        if($id->getText() != "main") {
            if(ret_num != 0){
            writeIntoCodefile("\tRET "+std::to_string(ret_num));
            }

        }
        writeIntoCodefile($id->getText()+" ENDP");
        if(!offsets.empty()){
            offset = offsets.top();
            offsets.pop();
        }

        param_number = 0;
    }
    | t=type_specifier{
        inside_function=true;
        is_global = false;
        if(code_printed==false){
            writeIntoCodefile(".CODE");
            code_printed=true;
        }
        param_number = 0;
    } 
    id=ID{
    if($id->getText() == "main"){
        writeIntoCodefile("main PROC");
        writeIntoCodefile("\tMOV AX, @DATA");
        writeIntoCodefile("\tMOV DS,AX");
        writeIntoCodefile("\tPUSH BP");
        writeIntoCodefile("\tMOV BP,SP");   
        is_global=false;    
        }
        else {
        writeIntoCodefile($id->getText()+" PROC");
        writeIntoCodefile("\tPUSH BP");
        writeIntoCodefile("\tMOV BP,SP");
        offsets.push(offset);
           
        }
        table->insert($id->getText(),"ID",$t.name_line,"function");
        } LPAREN{
        table->EnterScope(); is_function_definition=true;
        cout<<"turning on on "<<$id->getLine()<<endl;
        } RPAREN cs=compound_statement {

        writeIntoparserLogFile("\nLine " + std::to_string($cs.line_cnt) + ": func_definition : type_specifier ID LPAREN  RPAREN compound_statement\n");
        writeIntoparserLogFile($t.name_line + " " + $id->getText() + "()" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}\n");
        $text = $t.name_line + " " + $id->getText() + "()" + "\n{\n" +$cs.cmp_statement.get_list_as_newline_string() + "\n}";
        $line_cnt = $cs.line_cnt;
        is_function_definition=false;
        while(!return_line_number.empty()){
            int line_no = return_line_number.top();
            return_line_number.pop();
            string instruction  = "\tJMP L" + std::to_string(label-1);
            mp[line_no] = instruction;
        }
        writeIntoCodefile("\tADD SP,"+std::to_string(offset));
        writeIntoCodefile("\tPOP BP");
        int ret_num = param_number * 2;
        if($id->getText() != "main") {
            if(ret_num != 0){
            writeIntoCodefile("\tRET "+std::to_string(ret_num));
            }

        }
        writeIntoCodefile($id->getText()+" ENDP");

        if(!offsets.empty()){
            offset = offsets.top();
            offsets.pop();
        }
        param_number = 0;

    }
    ;


parameter_list returns [std::string text, int line_cnt]
    : pl=parameter_list COMMA t=type_specifier id=ID {
        param_number++;
        int param_offset = param_number * 2 + 2;
        table->insert($id->getText(), "ID",$t.name_line,"parameter",false,param_offset);
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
        param_number++;
        int param_offset = param_number * 2 + 2;
        table->insert($id->getText(), "ID",$t.name_line,"parameter",false,param_offset);
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
        }
        writeIntoparserLogFile($t.name_line + " " +$dl.var_list.get_list_as_string()+ ";\n");
        $name=""+$t.name_line+" "+$dl.var_list.get_list_as_string()+";";
        $line_num = $sm->getLine();
      }

    | t=type_specifier de=declaration_list_err sm=SEMICOLON {
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
            // Generate assembly code for global variables
            if(is_global) {
                table->insert($ID->getText(), "ID",current_type,current_type,is_global);
                if(current_type == "int") {
                    writeIntoCodefile("\t" + $ID->getText() + " DW 1 DUP (0000H)");
                } else if(current_type == "string") {
                    writeIntoCodefile("\t"+$ID->getText() + " DB \"00000$\"");
                }
            }
            else{
                offset += 2;
                writeIntoCodefile("\tSUB SP, 2");
                table->insert($ID->getText(), "ID",current_type,current_type,is_global,offset);
            }
            writeIntoparserLogFile("Line "+std::to_string($ID->getLine())+": declaration_list : declaration_list COMMA ID\n");
            writeIntoparserLogFile($var_list.get_list_as_string() + "\n");
            }
          | dl=declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
            if(is_global) {
                table->insert($ID->getText(), "ID",current_type,"array",is_global);
                if(current_type == "int") {
                    writeIntoCodefile("\t" + $ID->getText() + " DW "+$CONST_INT->getText()+" DUP (0000H)");
                } else if(current_type == "string") {
                    writeIntoCodefile("\t"+$ID->getText() + " DB \"00000$\"");
                }
            }
            else{
                int size = stoi($CONST_INT->getText()) * 2;
                offset += size;

                writeIntoCodefile("\tSUB SP, "+std::to_string(size));
                table->insert($ID->getText(), "ID",current_type,"array",is_global,offset);
            }
            writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n");
            writeIntoparserLogFile($dl.var_list.get_list_as_string() + "," + $ID->getText() + "[" + $CONST_INT->getText() + "]\n");
            $var_list.set_variables($dl.var_list.get_variables());
             $var_list.add($ID->getText() + "[" + $CONST_INT->getText() + "]");
          }
          | ID {
            if(is_global) {
                table->insert($ID->getText(), "ID",current_type,current_type,true);
                if(current_type == "int") {
                    writeIntoCodefile("\t"+$ID->getText() + " DW 1 DUP (0000H)");
                } else if(current_type == "string") {
                    writeIntoCodefile("\t"+$ID->getText() + " DB \"00000$\"");
                }
            } else {
                offset += 2;
                table->insert($ID->getText(), "ID",current_type,current_type,false,offset);
                writeIntoCodefile("\tSUB SP, 2");
                table->insert($ID->getText(), "ID",current_type,current_type,is_global,offset);
            }
            $var_list.add($ID->getText());
            writeIntoparserLogFile("Line "+std::to_string($ID->getLine())+": declaration_list : declaration_list COMMA ID\n");
            writeIntoparserLogFile($var_list.get_list_as_string() + "\n");

          }
          | ID LTHIRD CONST_INT RTHIRD {
            if(is_global) {
                table->insert($ID->getText(), "ID",current_type,"array",is_global);
                if(current_type == "int") {
                    writeIntoCodefile("\t" + $ID->getText() + " DW "+$CONST_INT->getText()+" DUP (0000H)");
                } else if(current_type == "string") {
                    writeIntoCodefile("\t"+$ID->getText() + " DB \"00000$\"");
                }
            }
            else{
                int size = stoi($CONST_INT->getText()) * 2;
                offset += size;

                writeIntoCodefile("\tSUB SP, "+std::to_string(size));
                table->insert($ID->getText(), "ID",current_type,"array",is_global,offset);
            }
            writeIntoparserLogFile("Line " + std::to_string($ID->getLine()) + ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n");
            writeIntoparserLogFile($ID->getText() + "[" + $CONST_INT->getText() + "]\n");

             $var_list.add($ID->getText() + "[" + $CONST_INT->getText() + "]");
          }
          | dl=declaration_list addop=ADDOP id=ID  {
                $var_list.set_variables($dl.var_list.get_variables());
                writeIntoparserLogFile("Error at line " + std::to_string($addop->getLine()) + ": syntax error, unexpected ADDOP, expecting COMMA or SEMICOLON\n");
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
         writelabel();
        
    }
      | estmt=expression_statement {
        $text = $estmt.text;
        $line_num = $estmt.line_num;
        writeIntoparserLogFile("Line " + std::to_string($estmt.line_num) + ": statement : expression_statement\n");
        writeIntoparserLogFile($text + "\n");
         writelabel();
    }
      | cstmt=compound_statement {
        $text = "{\n" + $cstmt.cmp_statement.get_list_as_newline_string() + "\n}";
        $line_num = $cstmt.line_cnt;
        writeIntoparserLogFile("Line " + std::to_string($cstmt.line_cnt) + ": statement : compound_statement\n");
        writeIntoparserLogFile($text + "\n");
        writelabel();
    }
      | FOR{inside_loop=true;} LPAREN init=expression_statement{
        writelabel();
      } cond1=expression_statement{
        start_label.push(label);
       // writeIntoCodefile("\tPOP AX");
        writeIntoCodefile("\tCMP AX,1");
        string statement_label = "L"+std::to_string(label+1);
        int line_no = writeIntoCodefile("\tJE "+statement_label);
        //string end_loop = "L"+std::to_string(label+4);
        //writeIntoCodefile("\tJMP "+end_loop);
        end_label.push(line_no);

        writelabel();
      } inc=expression{
        writeIntoCodefile("\tPOP AX");
        int loop_label_num = -1;
        if(!start_label.empty()) {
                loop_label_num = start_label.top();
                start_label.pop();
        }
        string loop = "L"+std::to_string(loop_label_num-4);
        writeIntoCodefile("\tJMP "+loop);
        inc_label = label - 1;
        writelabel();

      } RPAREN body=statement {
        $text = "for(" + $init.text + $cond1.text + ";" + $inc.text + ")\n" + $body.text;
        $line_num = $FOR->getLine();
        writeIntoparserLogFile("Line " + std::to_string($line_num) + ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
        string inc_label_str = "L"+std::to_string(inc_label);
        writeIntoCodefile("\tJMP "+inc_label_str);
        //writeIntoCodefile("here i  ");
        if(!end_label.empty()){
            int line_number = end_label.top();
            end_label.pop();
            string instruction  = "\tJMP L" + std::to_string(label);
            //insertLine("output/code.asm", instruction, line_number); 
            mp[line_number] = instruction;

        }
        writelabel();
        inside_loop=false;
    }
      | IF{inside_if_else=true;} LPAREN expr=expression{
        writeIntoCodefile("\tPOP AX \t; Line "+std::to_string($LPAREN->getLine()));
        writeIntoCodefile("\tCMP AX,1");
        string true_label = nextlabel();
        writeIntoCodefile("\tJE "+true_label);

    
        string false_label = "L"+std::to_string(label+1);
        writeIntoCodefile("\tJMP "+false_label);
        writelabel();

      } RPAREN stmt1=statement {
        $text = "if (" + $expr.text + ")\n" + $stmt1.text;
        $line_num = $stmt1.line_num;
        writeIntoparserLogFile("Line " + std::to_string($stmt1.line_num) + ": statement : IF LPAREN expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
        inside_if_else = false;
    }
      | IF{inside_if_else=true;} LPAREN expr=expression{
            writeIntoCodefile("\tPOP AX \t; Line "+std::to_string($LPAREN->getLine()));
            writeIntoCodefile("\tCMP AX,1");
            string true_label = nextlabel();
          short_circuit_end_label.push(code_file_line_number);
           // writeIntoCodefile("\tJE "+true_label);
            //string false_label = "L"+std::to_string(label+2);
            //writeIntoCodefile("\tJMP "+false_label);
            conditional_else_label.push(code_file_line_number+1);
            while(!short_circuit_end_label.empty()){
            int line_number = short_circuit_end_label.top();
            short_circuit_end_label.pop();
            string instruction  = "\tJE " + true_label;
            //insertLine("output/code.asm", instruction, line_number); 
            mp[line_number] = instruction;
            writeIntoCodefile(instruction);

        } 
            writelabel();        
      } RPAREN stmt1=statement{
        
            string end_label = "L"+std::to_string(label+1);
           // writeIntoCodefile("\tJMP "+end_label);
            //int line_number = writeIntoCodefile("");
            cout<<"line number is "<<code_file_line_number<<endl;
            conditional_end_label.push(code_file_line_number);
            writelabel();
            while(!conditional_else_label.empty()){
            int line_number = conditional_else_label.top();
            conditional_else_label.pop();
            string instruction  = "\tJMP L" + std::to_string(label-1);
            //insertLine("output/code.asm", instruction, line_number); 
            mp[line_number] = instruction;
        }
            while(!short_circuit_else_label.empty()){
            int line_number = short_circuit_else_label.top();
            short_circuit_else_label.pop();
            string instruction  = "\tJE L" + std::to_string(label-1);
            //insertLine("output/code.asm", instruction, line_number); 
            mp[line_number] = instruction;
        }
      } ELSE stmt2=statement {
        $text = "if (" + $expr.text + ")\n" + $stmt1.text + "\nelse\n" + $stmt2.text;
        $line_num = $stmt1.line_num;
        writeIntoparserLogFile("Line " + std::to_string($stmt2.line_num) + ": statement : IF LPAREN expression RPAREN statement ELSE statement\n");
        writeIntoparserLogFile($text + "\n");
        inside_if_else = false;
        if(!conditional_end_label.empty()){
            int line_number = conditional_end_label.top();
            conditional_end_label.pop();
            string instruction  = "\tJMP L" + std::to_string(label-1);
            //insertLine("output/code.asm", instruction, line_number); 
            mp[line_number] = instruction;
        }


    }
      | WHILE{inside_loop=true;} LPAREN{condition=true;} cond=expression{
        start_label.push(label);
        writeIntoCodefile("\tPOP AX");
        writeIntoCodefile("\tCMP AX,1");
        string statement_label = "L"+std::to_string(label);
       int line_no= writeIntoCodefile("\tJE "+statement_label);
        string end_loop = "L"+std::to_string(label+2);
        //int line_no = writeIntoCodefile("\tJMP "+end_loop);
        //writeIntoCodefile("Found line no "+std::to_string(line_no));
        end_label.push(line_no);
        writelabel();
        condition=false;
      } RPAREN body=statement {
        $text = "while (" + $cond.text + ")\n" + $body.text;
        $line_num = $WHILE->getLine();
        writeIntoparserLogFile("Line " + std::to_string($line_num) + ": statement : WHILE LPAREN expression RPAREN statement\n");
        writeIntoparserLogFile($text + "\n");
        int loop_label_num = -1;
        if(!start_label.empty()) {
                loop_label_num = start_label.top();
                start_label.pop();
        }
        string loop = "L"+std::to_string(loop_label_num-4);
        writeIntoCodefile("\tJMP "+loop);
        //writeIntoCodefile("here i a");
        if(!end_label.empty()){
            int line_number = end_label.top();
            end_label.pop();
            string instruction  = "\tJMP L" + std::to_string(label);
            //insertLine("output/code.asm", instruction, line_number); 
            mp[line_number] = instruction;
        }
        writelabel();
        inside_loop=false;
    }
      | PRINTLN LPAREN id=ID RPAREN sm=SEMICOLON {
        $text = "printf(" + $id->getText() + ");";
        $line_num = $sm->getLine();
        writeIntoparserLogFile("Line " + std::to_string($line_num) + ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n");
        auto entry = table->lookup($id->getText());
        if(entry != nullptr){
             if(entry->is_global){
                    writeIntoCodefile("\tMOV AX,"+($id->getText()) + "\t; Line "+std::to_string($id->getLine()));
                    writeIntoCodefile("\tCALL print_output");
                    writeIntoCodefile("\tCALL new_line");
             }
             else{
                    int offset = entry->offset;
                    writeIntoCodefile("\tMOV AX,[BP-"+std::to_string(offset)+"]");
                    writeIntoCodefile("\tCALL print_output");
                    writeIntoCodefile("\tCALL new_line");                
             }
        }
        writeIntoparserLogFile($text + "\n");
        if(!inside_if_else) writelabel();
    }
      | RETURN expr=expression sm=SEMICOLON {
        $text = "return " + $expr.text + ";";
        $line_num = $sm->getLine();
        writeIntoparserLogFile("Line " + std::to_string($sm->getLine()) + ": statement : RETURN expression SEMICOLON\n");
        writeIntoparserLogFile($text + "\n\n");
        writeIntoCodefile("\tPOP AX");
        return_line_number.push(code_file_line_number);

        writelabel();
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
        writeIntoCodefile("\tPOP AX");
    }
            ;
      
variable returns[std::string text,int line_num]: id=ID {
        writeIntoparserLogFile("Line " + std::to_string($id->getLine()) + ": variable : ID\n");
        if(table->lookup($id->getText()) == nullptr){         
           
        }
        if(is_function_calling){
            auto entry = table->lookup(current_function_calling);
            if(entry != nullptr){
                std::string arg_type = entry->getparamlist()[current_argument];
                current_argument++;
                auto entry = table->lookup($id->getText());
                if(entry != nullptr){
                    if(arg_type != entry->getvartype()){                  
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
        writeIntoparserLogFile($id->getText() + "[" + $expr.text + "]\n");
        $text = $id->getText()+"[" + $expr.text + "]";
        $line_num = $id->getLine();
        writeIntoCodefile("\tPOP BX \t;Line "+std::to_string($id->getLine()));
        writeIntoCodefile("\tMOV AX,2");
        writeIntoCodefile("\tCWD");
        writeIntoCodefile("\tMUL BX");
        writeIntoCodefile("\tPUSH AX");


    }
     ;
     
 expression : le=logic_expression {
        writeIntoparserLogFile("Line " + std::to_string($le.start->getLine()) + ": expression : logic expression\n");
        writeIntoparserLogFile($le.text + "\n");
    }	
       | var=variable ASSIGNOP le=logic_expression {
            string var_name = $var.text;
            if(is_array_reference($var.text)) {
                var_name = extract_array_name($var.text);
                }
            auto entry = table->lookup(var_name);
            writeIntoCodefile("\tPOP AX \t;Line "+std::to_string($ASSIGNOP->getLine()));
            if(entry != nullptr) {
                 if(entry->getvartype() != "array"){
                   if(entry->is_global){
                      writeIntoCodefile("\tMOV "+$var.text+" , AX\t;Line"+std::to_string($ASSIGNOP->getLine()));
                   }
                   else{
                      int offset = entry->offset;
                      if(entry->getvartype() == "parameter"){
                        writeIntoCodefile("\tMOV [BP+"+std::to_string(offset)+"],AX\t;Line"+std::to_string($ASSIGNOP->getLine()));
                      }
                      else{
                        writeIntoCodefile("\tMOV [BP-"+std::to_string(offset)+"],AX\t;Line"+std::to_string($ASSIGNOP->getLine()));
                      }
 
                   }
                 }
                 else{

                    cout<<"here i am"<<endl;
                        if(entry->is_global){
                            writeIntoCodefile("\tPOP BX\t;Line "+std::to_string($ASSIGNOP->getLine()));
                            writeIntoCodefile("\tMOV "+var_name+"[BX] , AX\t;Line"+std::to_string($ASSIGNOP->getLine()));
                   }
                         else{
                               writeIntoCodefile("\tPOP BX");
                               writeIntoCodefile("\tPUSH AX");
                               int cur_offset = entry->offset;
                               writeIntoCodefile("\tMOV AX,"+std::to_string(cur_offset));
                               writeIntoCodefile("\tSUB AX,BX");
                               writeIntoCodefile("\tMOV SI,AX");
                               writeIntoCodefile("\tNEG SI");
                               writeIntoCodefile("\tPOP AX");
                               writeIntoCodefile("\tMOV [BP+SI],AX");
                               writeIntoCodefile("\tPUSH AX");

                            }                 
                     
                 }
                }
            writeIntoCodefile("\tPUSH AX");
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
                    }
                }               
            }
            else if(varType == "int" && isInt == false){
                if(!char_in_string('%',$le.text)){  
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
         | re1=rel_expression logicop=LOGICOP{
        if($logicop->getText() == "||"){
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCMP AX,1");
            short_circuit_end_label.push(code_file_line_number); 
            writelabel();        
        }   
        else if($logicop->getText() == "&&"){
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCMP AX,0");
            short_circuit_else_label.push(code_file_line_number);
            writelabel();        

        }         
         } re2=rel_expression {
        writeIntoparserLogFile("Line " + std::to_string($logicop->getLine()) + ": logic_expression : rel_expression LOGICOP rel_expression\n");
        writeIntoparserLogFile($re1.text + $logicop->getText() + $re2.text + "\n");
        $text = $re1.text + $logicop->getText() + $re2.text;
        $line_num = $logicop->getLine();

        if($logicop->getText() == "||"){
           // writeIntoCodefile("\tPOP AX");
           // writeIntoCodefile("\tCMP AX,1");
           // string false1 = nextlabel();
           // writeIntoCodefile("\tJNE "+false1);
           // string true_label = "L"+std::to_string(label+1);

            //writeIntoCodefile("\tJMP "+true_label);
            writelabel();
 
            //writelabel();        
        }
        else if($logicop->getText() == "&&"){
            //writeIntoCodefile("\tPOP AX");
           // writeIntoCodefile("\tCMP AX,1");
           // string true1 = nextlabel();
           // writeIntoCodefile("\tJE "+true1);
           // string true_label = "L"+std::to_string(label+1);
          //  writeIntoCodefile("\tJMP "+true_label);
            //writelabel();        
        }
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
        if($relop->getText() == "<="){
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCMP AX,BX");
            string true_label = nextlabel();
            writeIntoCodefile("\tJLE "+true_label);
            string false_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+false_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,1");
            writeIntoCodefile("\tPUSH AX");
            string end_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+end_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,0");
            writeIntoCodefile("\tPUSH AX");
            writelabel();

        }
        else if($relop->getText() == "!="){
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCMP AX,BX");
            string true_label = nextlabel();
            writeIntoCodefile("\tJNE "+true_label);
            string false_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+false_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,1");
            writeIntoCodefile("\tPUSH AX");
            string end_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+end_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,0");
            writeIntoCodefile("\tPUSH AX");
            writelabel();            
        }
        else if($relop->getText() == "=="){
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCMP AX,BX");
            string true_label = nextlabel();
            writeIntoCodefile("\tJE "+true_label);
            string false_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+false_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,1");
            writeIntoCodefile("\tPUSH AX");
            string end_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+end_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,0");
            writeIntoCodefile("\tPUSH AX");
            writelabel();            
        }
        else if($relop->getText() == "<"){
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCMP AX,BX");
            string true_label = nextlabel();
            writeIntoCodefile("\tJL "+true_label);
            string false_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+false_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,1");
            writeIntoCodefile("\tPUSH AX");
            string end_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+end_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,0");
            writeIntoCodefile("\tPUSH AX");
            writelabel();            
        }
        else if($relop->getText() == ">"){
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCMP AX,BX");
            string true_label = nextlabel();
            writeIntoCodefile("\tJG "+true_label);
            string false_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+false_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,1");
            writeIntoCodefile("\tPUSH AX");
            string end_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+end_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,0");
            writeIntoCodefile("\tPUSH AX");
            writelabel();            
        }
    }	
        ;
            
simple_expression : t=term {
        writeIntoparserLogFile("Line " + std::to_string($t.start->getLine()) + ": simple_expression : term\n");
        writeIntoparserLogFile($t.text + "\n");
    }
          | se=simple_expression addop=ADDOP t=term {
        writeIntoparserLogFile("Line " + std::to_string($addop->getLine()) + ": simple_expression : simple_expression ADDOP term\n");
        writeIntoparserLogFile($se.text + $addop->getText() + $t.text + "\n");
        if($addop->getText() == "+"){
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tADD AX,BX");
            writeIntoCodefile("\tPUSH AX");
        }
        else{
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tSUB AX,BX");
            writeIntoCodefile("\tPUSH AX");            
        }


    }
    | se=simple_expression addop=ADDOP assignop=ASSIGNOP t=term{
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
        writeIntoparserLogFile($t.text + $mulop->getText() + $uexpr.text + "\n");
        $text = $t.text + $mulop->getText() + $uexpr.text;
        $line_num = $mulop->getLine();
        if($mulop->getText() == "%"){
            writeIntoCodefile("\tPOP BX \t; Line "+std::to_string($mulop->getLine()));
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tCWD");
            writeIntoCodefile("\tDIV BX");
            writeIntoCodefile("\tPUSH DX");            
        }
        else{
            writeIntoCodefile("\tPOP AX \t; Line "+std::to_string($mulop->getLine()));
            writeIntoCodefile("\tCWD");
            writeIntoCodefile("\tPOP BX");
            writeIntoCodefile("\tMUL BX");
            writeIntoCodefile("\tPUSH AX");
        }

     }
     ;

unary_expression returns [std::string text]
    : addop=ADDOP uexpr=unary_expression {
        $text = $addop->getText() + $uexpr.text;
        writeIntoparserLogFile("Line " + std::to_string($addop->getLine()) + ": unary_expression : ADDOP unary_expression\n");
        writeIntoparserLogFile($text + "\n");
        writeIntoCodefile("\tPOP AX");
        if($addop->getText() == "-"){
            writeIntoCodefile("\tNEG AX");
        }
        writeIntoCodefile("\tPUSH AX");

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
        string var_name = $var.text;
        if(is_array_reference($var.text)) var_name = extract_array_name($var.text);
        auto entry = table->lookup(var_name);
        if(entry != nullptr){
            if(entry->getvartype() != "array")
        {
            if(entry -> is_global){
                writeIntoCodefile("\tMOV AX,"+$var.text+"\t;Line "+std::to_string($var.start->getLine()));
                writeIntoCodefile("\tPUSH AX");
            }
            else{
                int offset = entry->offset;
                if(entry->getvartype() == "parameter"){
                    writeIntoCodefile("\tMOV AX,[BP+"+std::to_string(offset)+"]");
                }
                else{
                    writeIntoCodefile("\tMOV AX,[BP-"+std::to_string(offset)+"]");
                }

                writeIntoCodefile("\tPUSH AX");                
            }
        }
        else{
            if(entry -> is_global){
                    writeIntoCodefile("\tPOP BX\t;Line "+std::to_string($var.start->getLine()));
                    writeIntoCodefile("\tMOV AX,"+var_name+"[BX]\t;Line"+std::to_string($var.start->getLine()));
                    writeIntoCodefile("\tPUSH AX");
            }
            else{   
                         writeIntoCodefile("\tPOP BX");
                        int cur_offset = entry->offset;
                         writeIntoCodefile("\tMOV AX,"+std::to_string(cur_offset));
                        writeIntoCodefile("\tSUB AX,BX");
                         writeIntoCodefile("\tMOV SI,AX");
                        writeIntoCodefile("\tNEG SI");
                         writeIntoCodefile("\tPOP AX");
                        writeIntoCodefile("\tMOV [BP+SI],AX");
                        writeIntoCodefile("\tPUSH AX");           
            }            
        }
        }
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
        }

        writeIntoparserLogFile($id->getText() + "(" + $args.text + ")\n");
        current_argument=0;
        writeIntoCodefile("\tCALL "+$id->getText());
        writeIntoCodefile("\tPUSH AX");
    }
    | LPAREN expr=expression RPAREN {
        writeIntoparserLogFile("Line " + std::to_string($LPAREN->getLine()) + ": factor : LPAREN expression RPAREN\n");
        writeIntoparserLogFile("(" + $expr.text + ")\n");
    }
    | const_int=CONST_INT {
        writeIntoCodefile("\tMOV AX,"+$const_int->getText()+"\t; Line "+std::to_string($const_int->getLine()));
        writeIntoCodefile("\tPUSH AX");
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
        string var_name = $var.text;
        if(is_array_reference($var.text)) var_name = extract_array_name($var.text);
        auto entry = table->lookup(var_name);
        if(entry != nullptr){
            if(entry->getvartype() != "array"){

            
            if(entry -> is_global){
                writeIntoCodefile("\tMOV AX,"+$var.text+"\t;Line "+std::to_string($var.start->getLine()));
                writeIntoCodefile("\tINC AX");
                writeIntoCodefile("\tMOV "+$var.text+"AX\t;Line "+std::to_string($var.start->getLine()));
                writeIntoCodefile("\tPUSH AX");
            }
            else{
                int offset = entry->offset;
                if(entry->getvartype() != "parameter"){
                writeIntoCodefile("\tMOV AX,[BP-"+std::to_string(offset)+"]");
                }
                else{
                writeIntoCodefile("\tMOV AX,[BP+"+std::to_string(offset)+"]");
                }

                writeIntoCodefile("\tINC AX");
                if(entry->getvartype() != "parameter") 
                {
                    writeIntoCodefile("\tMOV [BP-"+std::to_string(offset)+"],AX\t;Line "+std::to_string($var.start->getLine()));
                }
                else{
                         writeIntoCodefile("\tMOV [BP+"+std::to_string(offset)+"],AX\t;Line "+std::to_string($var.start->getLine()));               
                }
                writeIntoCodefile("\tPUSH AX");                
            }
        }
        else{
            if(entry -> is_global){
                    writeIntoCodefile("\tPOP BX\t;Line "+std::to_string($var.start->getLine()));
                    writeIntoCodefile("\tMOV AX,"+var_name+"[BX]\t;Line"+std::to_string($var.start->getLine()));
                    writeIntoCodefile("\tPUSH AX");
                    writeIntoCodefile("\tADD AX,1");
                    writeIntoCodefile("\tMOV "+var_name+"[BX],AX\t;Line"+std::to_string($var.start->getLine()));
            }
            else{
                         writeIntoCodefile("\tPOP BX");
                        int cur_offset = entry->offset;
                         writeIntoCodefile("\tMOV AX,"+std::to_string(cur_offset));
                        writeIntoCodefile("\tSUB AX,BX");
                         writeIntoCodefile("\tMOV SI,AX");
                        writeIntoCodefile("\tNEG SI");
                         writeIntoCodefile("\tPOP AX");
                        writeIntoCodefile("\tMOV [BP+SI],AX");
                        writeIntoCodefile("\tPUSH AX");
                        writeIntoCodefile("\tADD AX,1");
                        writeIntoCodefile("\tMOV AX,[BP+SI]");
            }            
        }
        }
    }
    | var=variable dec=DECOP {
        writeIntoparserLogFile("Line " + std::to_string($var.start->getLine()) + ": factor : variable DECOP\n");
        writeIntoparserLogFile($var.text + $dec->getText() + "\n");
        auto entry = table->lookup($var.text);
        if(entry != nullptr){
            if(entry -> is_global){
                writeIntoCodefile("\tMOV AX,"+$var.text+"\t;Line "+std::to_string($var.start->getLine()));
                writeIntoCodefile("\tDEC AX");
                writeIntoCodefile("\tMOV "+$var.text+"AX\t;Line "+std::to_string($var.start->getLine()));
                writeIntoCodefile("\tPUSH AX");
            }
            else{
                int offset = entry->offset;
                writeIntoCodefile("\tMOV AX,[BP-"+std::to_string(offset)+"]");
                writeIntoCodefile("\tDEC AX");
                writeIntoCodefile("\tMOV [BP-"+std::to_string(offset)+"],AX\t;Line "+std::to_string($var.start->getLine()));
                writeIntoCodefile("\tPUSH AX");                
            }
        }
        if(condition){
            writeIntoCodefile("\tPOP AX");
            writeIntoCodefile("\tINC AX");
            string true_label = nextlabel();
            writeIntoCodefile("\tCMP AX,0");
            writeIntoCodefile("\tJNE "+true_label);
            string false_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+false_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,1");
            writeIntoCodefile("\tPUSH AX");
            string end_label = "L"+std::to_string(label+1);
            writeIntoCodefile("\tJMP "+end_label);
            writelabel();
            writeIntoCodefile("\tMOV AX,0");
            writeIntoCodefile("\tPUSH AX");
            writelabel();
            }
    } 
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


