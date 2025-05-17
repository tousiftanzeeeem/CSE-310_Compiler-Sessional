#pragma once
#include <iostream>
#include <fstream>
using namespace std;
#include "ScopeTable.h"
#include "SymbolInfo.h"
#include "hashfunctions.h"
class Symboltable{
     Scopetable* currentscope;
     int bucketsize;
     int scopecount;
     HashFunction func;
     float collision_ratio;
     string identifier;

public:
	Symboltable(int bucket,HashFunction f=sdbmHash){
		func = f;
		bucketsize = bucket;
		scopecount = 0;
		currentscope = nullptr;
    collision_ratio=0;
    identifier="1";
		EnterScope();
	}

	void EnterScope(){
       scopecount++;
       Scopetable* temp = new Scopetable(bucketsize,func);
       temp->set_parent_scope_table(currentscope);
       temp->set_id(scopecount);
       temp->set_identifier(identifier);
       currentscope = temp;
       identifier=identifier+".1";
	}

	void ExitScope(){
		Scopetable* temp = currentscope;
		if(currentscope->parent_scope() == nullptr) {
      return;
    }
    collision_ratio += currentscope->get_ratio();

		currentscope = currentscope -> parent_scope();
		delete temp;
	}
	bool insert(string name,string type,ofstream& logout){
        return currentscope->insert(name,type,logout);
	}
	void PrintAll() {
    	Scopetable* curr = currentscope;
    	int level = 1;
    	while (curr != nullptr) {
        	curr->print(level);
        	curr = curr->parent_scope();
        	level++;
    	}
	}

    void PrintNonempty(ofstream& tokenout) {
      Scopetable* curr = currentscope;
      while (curr != nullptr) {
          curr->PrintNonempty(tokenout);
          curr = curr->parent_scope();
      }
  }
    void PrintCurrent(){
    	currentscope->print(1);
    }
    bool remove(string name){
    	return currentscope->deletesymbol(name);
    }
    Symbolinfo* lookup(string name){
    	Scopetable* curr = currentscope;
    	Symbolinfo* temp = nullptr;
    	while(curr != nullptr){
    		temp = curr->lookup(name);
    		if( temp != nullptr){
    			break;
    		}
    		curr = curr -> parent_scope();
    	}
    	if(!temp) cout<<"\t"<<"'"<<name<<"' not found in any of the ScopeTables"<<endl;
    	return temp;
    } 


   void RemoveAll(){
   	   while(currentscope != nullptr){
   	   		Scopetable* temp = currentscope;
			cout<<"\t"<<"ScopeTable# "<<currentscope->get_id()<<" removed"<<endl;   	   	
   	   		currentscope = currentscope -> parent_scope();
   	   		delete temp;
   	   }
   }

  


  float get_mean_collision_ratio(){
       Scopetable *cur =  currentscope;
       while(cur != nullptr){
        collision_ratio += cur->get_ratio();
        cur = cur -> parent_scope();
       }

       return collision_ratio*1.0/scopecount;
  }

	~Symboltable()
    {
        Scopetable *temp = currentscope;
        while (temp != nullptr)
        {
            currentscope = currentscope->parent_scope();
            delete temp;
            temp = currentscope;
        }
    }
};