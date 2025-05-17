#pragma once
#include <iostream>
#include <fstream>
using namespace std;
#include "SymbolInfo.h"
#include "hashfunctions.h"


class Scopetable{
	Symbolinfo **table;
    int tableSize;
    Scopetable *parentScopeTable;
    int id;
    HashFunction func;
    int collision_count;
    string identifier;
	int calculate_index(string key){
		    int idx = ((func(key.c_str()))) % tableSize;
        	return idx;
	}

public:
    
    // Constructor 
	Scopetable(int bucket,HashFunction f=sdbmHash){
        func = f;
        tableSize = bucket;
        table = new Symbolinfo*[tableSize];
        collision_count=0;
        for(int i = 0;i<tableSize;i++){
        	table[i] = nullptr;
        }
	}

	void print(int indentLevel=1){
         string ind="\t";
         for(int i=0;i<(indentLevel-1);i++) ind += "\t"; 
         cout<<ind<<"ScopeTable# "<<id<<endl; 
         for(int i = 0;i<tableSize;i++){
         	cout<<ind<<i+1<<"--> ";
         	Symbolinfo* symbol = table[i];
         	while(symbol != nullptr){
         		cout<<*symbol<<" ";
         		symbol = symbol->getNext();
         	}
         	cout<<endl;
         }
	}
    bool insert(string name,string type,ofstream& logout)    {
        int idx = calculate_index(name);
        if (table[idx] == nullptr) 
        {
            table[idx] = new Symbolinfo(name, type);
            return true;
        }

        Symbolinfo *curr = table[idx];
        collision_count++;
        // cout<<"Coliiiiiiiiiiiiiiiisssssssssssssssssonnnnnnnnnnn";
        Symbolinfo *prev = nullptr;
        int position = 0;
        // go to the end of the list
        while (curr != nullptr)
        {
            //log(tag(tagMsg), curr, idx, position);
            if (curr->getName() == name)
            {
                collision_count--;
                logout <<*curr <<" already exists in ScopeTable# "<<identifier<<" at position "<<idx<<", "<<position<<endl;

                return false; // symbol already exist
            }
            position++;
            prev = curr;
            curr = curr->getNext();
        } 

        // insert new symbol at the end of the list
        prev->setNext(new Symbolinfo(name, type));
        return true;
    }

     Symbolinfo *lookup(string name)
    {
        int index = calculate_index(name);
        Symbolinfo *temp = table[index];
        int position = 1;
        while (temp != nullptr)
        {
            if (temp->getName() == name)
            {
                cout <<"\t"<<"'"<<name<< "' found in ScopeTable# " << id << " at position " << index+1<< ", " << position << endl;
                return temp;
            }
            position++;
            temp = temp->getNext();
        }
        return nullptr;
    }

    bool deletesymbol(string name){
    	int index = calculate_index(name);
    	Symbolinfo *tmp = table[index];
    	Symbolinfo *prev = nullptr;


    	int position = 1;
    	while(tmp != nullptr){
    		if(tmp -> getName() == name){
    			if(prev == nullptr){
    				// first node has to delete
    				table[index] = tmp -> getNext();
    			}
    			else{
    				prev -> setNext(tmp -> getNext());
    			}
    			 delete tmp;
    			 cout<<"\t"<<"Deleted '" <<name<< "' from ScopeTable# " <<id<< " at position " <<index+1<<", "<<position<<endl;
    			 return true;
    		}
    		prev = tmp;
    		tmp = tmp -> getNext();
    		position++;
    	}
        cout<<"\t"<<"Not found in the current ScopeTable"<<endl;

    	return false;
    }

	void set_parent_scope_table(Scopetable* parent){
		this->parentScopeTable = parent;
		
	}

	void set_id(int i){
		id = i;
	}
    void set_identifier(string i){
        identifier=i;
    }


	Scopetable* parent_scope(){
		return parentScopeTable;
	}

	int get_id(){return id;}

    float get_ratio(){
        return collision_count*1.0/tableSize;
    }

    void PrintNonempty(ofstream& tokenout){
        tokenout<<"ScopeTable # "<<identifier<<endl;
    for(int i = 0;i<tableSize;i++){
            Symbolinfo* symbol = table[i];
            Symbolinfo *tmp=symbol;
            if(symbol != nullptr){
                tokenout<<i<<" --> ";
            }
            while(symbol != nullptr){

                tokenout<<*symbol;
                symbol = symbol->getNext();
            }
            if(tmp != nullptr) tokenout<<endl;
         }  
    }
    // Destructor
    ~Scopetable()
    {
        for (int i = 0; i < tableSize; i++)
        {
            if(table[i]!=nullptr){
                Symbolinfo *symbol = table[i];
                while(symbol!=nullptr){
                    Symbolinfo *temp = symbol;
                    symbol = symbol->getNext();
                    delete temp;
                }
            }
        }

        // finally delete the table pointer
        delete[] table;

    }

};