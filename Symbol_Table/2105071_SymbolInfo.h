#pragma once
#include<iostream>
#include <string>
using namespace std;



class Symbolinfo
{
    string name;
    string type;
    Symbolinfo *next;

public:
    Symbolinfo(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->next = nullptr;
    }

    // copy constructor
    Symbolinfo(const Symbolinfo &other)
    {
        this->name = other.name;
        this->type = other.type;
        this->next = other.next;
    }
    
    string getName() const {
        return name;
    }

    string getType() const {
        return type;
    }

    Symbolinfo* getNext() const {
        return next;
    }

    void setNext(Symbolinfo *symbol){
    	this->next = symbol;
    }


};

ostream& operator<<(ostream& os, const Symbolinfo& p) {
    os << "<" << p.getName() << "," << p.getType() << ">";
    return os;
}