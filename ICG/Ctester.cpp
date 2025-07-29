#include <iostream>
#include <fstream>
#include <string>
#include "antlr4-runtime.h"
#include "C2105071Lexer.h"
#include "C2105071Parser.h"

using namespace antlr4;
using namespace std;

ofstream parserLogFile; // global output stream
ofstream finalfile; // global error stream
ofstream lexLogFile; // global lexer log stream
ofstream codefile; // global code output stream
ofstream optcodefile; // global optimized code output stream    
int syntaxErrorCount;

int main(int argc, const char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <input_file>" << endl;
        return 1;
    }

    // ---- Input File ----
    ifstream inputFile(argv[1]);
    if (!inputFile.is_open()) {
        cerr << "Error opening input file: " << argv[1] << endl;
        return 1;
    }

    string outputDirectory = "output/";
    string parserLogFileName = outputDirectory + "parserLog.txt";
    string finalfileName = outputDirectory + "finalCode.asm";
    string lexLogFileName = outputDirectory + "lexerLog.txt";
    string codeFileName = outputDirectory + "code.asm";
    string optCodeFileName = outputDirectory + "optCode.asm";
    // create output directory if it doesn't exist
    system(("mkdir -p " + outputDirectory).c_str());

    // ---- Output Files ----
    parserLogFile.open(parserLogFileName);
    if (!parserLogFile.is_open()) {
        cerr << "Error opening parser log file: " << parserLogFileName << endl;
        return 1;
    }

    finalfile.open(finalfileName);
    if (!finalfile.is_open()) {
        cerr << "Error opening error log file: " << finalfileName << endl;
        return 1;
    }

    lexLogFile.open(lexLogFileName);
    if (!lexLogFile.is_open()) {
        cerr << "Error opening lexer log file: " << lexLogFileName << endl;
        return 1;
    }
    codefile.open(codeFileName);
    if (!codefile.is_open()) {  
        cerr << "Error opening code file: " << codeFileName << endl;
        return 1;
    }   
    optcodefile.open(optCodeFileName);
    if (!optcodefile.is_open()) {
        cerr << "Error opening optimized code file: " << optCodeFileName << endl;
        return 1;
    }
   
    // ---- Parsing Flow ----
    ANTLRInputStream input(inputFile);
    C2105071Lexer lexer(&input);
    CommonTokenStream tokens(&lexer);
    C2105071Parser parser(&tokens);

    // this is necessary to avoid the default error listener and use our custom error handling
    parser.removeErrorListeners();

    // start parsing at the 'start' rule
    parser.start();

    // clean up
    inputFile.close();
    parserLogFile.close();
    finalfile.close();
    lexLogFile.close();
    codefile.close();
    optcodefile.close();
    cout << "Parsing completed. Check the output files for details." << endl;
    return 0;
}
