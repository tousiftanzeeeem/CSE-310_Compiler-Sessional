#pragma once
#include <iostream>
#include <fstream>
using namespace std;
#include "2105071_ScopeTable.h"




class Symboltable{
     Scopetable* currentscope;
     int bucketsize;
     int scopecount;
     float collision_ratio;

public:
	Symboltable(int bucket){
		bucketsize = bucket;
		scopecount = 0;
		currentscope = nullptr;
    collision_ratio=0;
		EnterScope();
	}

	void EnterScope(){
       scopecount++;
       cout<<"\t"<<"ScopeTable# "<<scopecount<<" created"<<endl;
       Scopetable* temp = new Scopetable(bucketsize);
       temp->set_parent_scope_table(currentscope);
       temp->set_id(scopecount);
       currentscope = temp;
	}

	void ExitScope(){
		Scopetable* temp = currentscope;
		if(currentscope->parent_scope() == nullptr) {
      cout<<"\t"<<"Root Scope Can not be deleted"<<endl;
      return;
    }
    collision_ratio += currentscope->get_ratio();

		cout<<"\t"<<"ScopeTable# "<<currentscope->get_id()<<" removed"<<endl;
		currentscope = currentscope -> parent_scope();
		delete temp;
	}
	bool insert(string name,string type,string datatype,string vartype){
        return currentscope->insert(name,type,datatype,vartype);
	}
	void PrintAll(ofstream &log) {
    	Scopetable* curr = currentscope;
    	int level = 1;
    	while (curr != nullptr) {
			log<<"ScopeTable # "<<curr->get_id()<<endl;
        	curr->print(log,level);
        	curr = curr->parent_scope();
        	level++;
    	}
	}
    void PrintCurrent(ofstream &log){
    	currentscope->print(log,1);
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