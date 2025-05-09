#include <iostream>
#include <string>
#include <sstream>
#include "2105071_SymbolTable.h"
#include "2105071_hashfunctions.h"

using namespace std;
int main(int argc,char* argv[]){
	// freopen("sample_input.txt", "r", stdin);
 //    freopen("integer.txt", "w", stdout);
   string inputFile,outputFile;
   string hashfunction;
    for (int i = 1; i < argc; i++) {
        string arg = argv[i];
        if (arg == "-i" && i + 1 < argc) {
            inputFile = argv[++i];
        } else if (arg == "-o" && i + 1 < argc) {
            outputFile = argv[++i];
        }
        else if (arg == "-h" && i + 1 < argc) {
        hashfunction = argv[++i];
    }
    }
    freopen(inputFile.c_str(), "r", stdin);
    freopen(outputFile.c_str(), "w", stdout);

     HashFunction func = SDBMHash;
     if(hashfunction == "1"){
         func = DJB2Hash;
     }
     else if(hashfunction == "2"){
        func = pollynomial_rolling;
     }

    int bucket; cin>>bucket;
    Symboltable *table = new Symboltable(bucket,func);


    int no_of_cmd = 0;


    string line;
    int cnt = 1;
    while (getline(cin, line)) {
        if (line.empty()) continue;
        istringstream ss(line);
        string cmd;
        ss >> cmd;
        cout<<"Cmd "<<cnt<<": ";
        
        if (cmd == "Q") {
        	cout<<line<<endl;
            string name; ss>>name;
            if((ss>>name)) {
                cout<<"\t"<<"Number of parameters mismatch for the command L"<<endl;
            }
            table->RemoveAll();
            break;
        }

        else if (cmd == "I") {
            string name, type;
            ss >> name >> type;
            type.erase(0,type.find_first_not_of(" \t"));
            string rest;
            string token;
            if(type == "FUNCTION"){
        		string returnType, param;
        		ss >> returnType;
        		type += "," + returnType + "<==(";

        		string funcSignature = "";
        		bool first = true;

        	while (ss >> param) {
            	if (!first) funcSignature += ",";
            	funcSignature += param;
            	first = false;
        	}

        		type += funcSignature + ")";

            }
            else if(type == "STRUCT" || type == "UNION"){
 				type += ",{";
                bool first = true;
                while (ss >> token) {
                    string t1 = token;
                    if (!(ss >> token)) break;
                    string t2 = token;

                    if (!first) type += ",";
                    type += "(" ;
                    type += t1 ;
                    type += "," ;
                    type += t2 += ")";
                    first = false;
                }
                type += "}";

            }
            line.erase(line.find_last_not_of(" \t\n\r\f\v") + 1);
           cout<<line<<endl;
           table->insert(name,type);

        }
          else if(cmd == "S"){
          	    cout<<"S"<<endl;
            string name; ss>>name;
            if((ss>>name)) {
                cout<<"\t"<<"Number of parameters mismatch for the command L"<<endl;
            }
				table->EnterScope();
    	}
    	else if(cmd == "D"){
    		string name;
    		   cout<<line<<endl;
               if(!(ss>>name)){
               	cout<<"\t"<<"Number of parameters mismatch for the command D"<<endl;
               }
               else {
               	table->remove(name);
               }
    	}
    	else if(cmd == "P"){
    		cout<<line<<endl;
             string type; ss>>type;
             if(type == "A"){
               table->PrintAll();
             }
             else if(type == "C"){
               table->PrintCurrent();
             }
    	}
    	else if(cmd == "E"){
    		cout<<line<<endl;
            string name; ss>>name;
            if((ss>>name)) {
                cout<<"\t"<<"Number of parameters mismatch for the command L"<<endl;
            }
                table->ExitScope();
    	}
    	else if(cmd=="L"){
    		cout<<line<<endl;
    		string name; ss>>name;
    		if((ss>>name)) {
    			cout<<"\t"<<"Number of parameters mismatch for the command L"<<endl;
    		}
    		else{
    			table->lookup(name);
    		}
    	}
    	cnt++;

    }

    delete table;

    // Symboltable *table = new Symboltable(7);
    // table->insert("i","var");
    // table->insert("23","NUMBER");
    // table->PrintAll();
    // table->EnterScope();
    // table->insert("23","NUMBER");
    // table->insert("28","NUMBER");
    // table->PrintAll();
    // table->lookup("23");
    // table->ExitScope();
    // delete table;
}