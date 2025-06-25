#pragma once
#include<iostream>
#include <string>
#include <vector>
using namespace std;

class Symbolinfo {
    string name;
    string type;
    string datatype;
    string vartype;
    int paramcount;
    vector<string>paramlist;
    Symbolinfo *next;

public:
    Symbolinfo(string name, string type,string datatype,string vartype,int paramcount=0,vector<string>params={"int"}) {
        this->name = name;
        this->type = type;
        this->datatype = datatype;
        this->vartype=vartype;
        this->paramcount = paramcount;
        this->paramlist = params;
        this->next = nullptr;
    }

    // copy constructor
    Symbolinfo(const Symbolinfo &other) {
        this->name = other.name;
        this->type = other.type;
        this->datatype = other.datatype;
        this->vartype=other.vartype;
        this->next = other.next;
    }

    string getName() const {
        return name;
    }

    string getType() const {
        return type;
    }
    string getdatatype() const {
        return datatype;
    }
    string getvartype() const{
        return vartype;
    }
    int getparamcount() const{
        return paramcount;
    }
    vector<string> getparamlist() const{
        return paramlist;
    }

    void setparamcount(int arg) {
        this->paramcount = arg;
    }
    void setparamlist(vector<string>arg) {
        this->paramlist = arg;
    }
    void setvartype(string vartype){
        this->vartype = vartype;
    }
    Symbolinfo* getNext() const {
        return next;
    }

    void setNext(Symbolinfo *symbol) {
        this->next = symbol;
    }
    friend ostream& operator<<(ostream& os, const Symbolinfo& sym) {
        os << "< " << sym.name << " , " << sym.type << " >";
        return os;
    }
};



