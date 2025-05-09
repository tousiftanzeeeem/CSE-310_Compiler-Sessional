#include <iostream>
#include <string>
#include <sstream>
#include "2105071_SymbolTable.h"
#include "2105071_hashfunctions.h"
#include <iomanip>
using namespace std;
int main(int argc,char* argv[]){


   string inputFile,outputFile;
   string hashfunction;
   
    for (int i = 1; i < argc; i++) {
        string arg = argv[i];
        if (arg == "-i" && i + 1 < argc) {
            inputFile = argv[++i];
        } else if (arg == "-o" && i + 1 < argc) {
            outputFile = argv[++i];
        }

    }
     


    freopen(inputFile.c_str(), "r", stdin);

    int bucket; cin>>bucket;
    Symboltable *sdbm = new Symboltable(bucket,SDBMHash);
    Symboltable *djb2 = new Symboltable(bucket,DJB2Hash);
    Symboltable *poly = new Symboltable(bucket,pollynomial_rolling);


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
            freopen(outputFile.c_str(), "w", stdout);
            cout<<"HashFunction,Collision Ratio"<<endl;
            cout<<"SDBMHash,"<<fixed << std::setprecision(2) << sdbm->get_mean_collision_ratio() << std::endl;
            cout<<"DJB2Hash(Found at http://www.cse.yorku.ca/~oz/hash.html),"<<fixed << std::setprecision(2) << djb2->get_mean_collision_ratio() << std::endl;
            cout<<"Pollynomial rolling(From Cp algorithm ),"<<fixed << std::setprecision(2) << poly->get_mean_collision_ratio() << std::endl;


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
           cout<<line<<endl;
           sdbm->insert(name,type);
           djb2->insert(name,type);
           poly->insert(name,type);

        }
          else if(cmd == "S"){
          	    cout<<"S"<<endl;
				sdbm->EnterScope();
                djb2->EnterScope();
                poly->EnterScope();

    	}
    	else if(cmd == "D"){
    		string name;
    		   cout<<line<<endl;

    	}
    	else if(cmd == "P"){
    		cout<<line<<endl;

    	}
    	else if(cmd == "E"){
    		cout<<line<<endl;
            sdbm->ExitScope();
            djb2->ExitScope();
            poly->ExitScope();
    	}
    	else if(cmd=="L"){
    		cout<<line<<endl;
    		string name; ss>>name;

    	}
    	cnt++;
    }

    delete sdbm;
    delete djb2;
    delete poly;

    // Symbolsdbm *sdbm = new Symbolsdbm(7);
    // sdbm->insert("i","var");
    // sdbm->insert("23","NUMBER");
    // sdbm->PrintAll();
    // sdbm->EnterScope();
    // sdbm->insert("23","NUMBER");
    // sdbm->insert("28","NUMBER");
    // sdbm->PrintAll();
    // sdbm->lookup("23");
    // sdbm->ExitScope();
    // delete sdbm;
}