#pragma once
#include <iostream>
using namespace std;
#include "2105071_SymbolInfo.h"
#include "2105071_hashfunctions.h"


class Scopetable{
	Symbolinfo **table;
    int tableSize;
    Scopetable *parentScopeTable;
    int id;
    HashFunction func;
    int collision_count;

	int calculate_index(string key){
		    int idx = (func(key,tableSize)) % tableSize;
        	return idx;
	}

public:
    
    // Constructor 
	Scopetable(int bucket,HashFunction f=SDBMHash){
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
    bool insert(string name,string type)    {
        int idx = calculate_index(name);
        if (table[idx] == nullptr) 
        {
            table[idx] = new Symbolinfo(name, type);
            cout <<"\t"<< "Inserted in ScopeTable# " << id << " at position " << idx+1<< ", " << 1 << endl;
            return true;
        }

        Symbolinfo *curr = table[idx];
        collision_count++;
        // cout<<"Coliiiiiiiiiiiiiiiisssssssssssssssssonnnnnnnnnnn";
        Symbolinfo *prev = nullptr;
        int position = 1;
        // go to the end of the list
        while (curr != nullptr)
        {
            //log(tag(tagMsg), curr, idx, position);
            if (curr->getName() == name)
            {
                cout <<"\t"<< "'"<<curr->getName() <<"'"<< " already exists in the current ScopeTable" <<endl;
                collision_count--;
                return false; // symbol already exist
            }
            position++;
            prev = curr;
            curr = curr->getNext();
        } 

        // insert new symbol at the end of the list
        prev->setNext(new Symbolinfo(name, type));
        cout <<"\t"<< "Inserted in ScopeTable# " << id << " at position " << idx+1 << ", " << position << endl;

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

	Scopetable* parent_scope(){
		return parentScopeTable;
	}

	int get_id(){return id;}

    float get_ratio(){
        return collision_count*1.0/tableSize;
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