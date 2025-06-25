#!/bin/bash

java -Xmx500M -cp "/usr/local/lib/antlr-4.13.2-complete.jar:$CLASSPATH" org.antlr.v4.Tool -Dlanguage=Cpp C2105071Lexer.g4
java -Xmx500M -cp "/usr/local/lib/antlr-4.13.2-complete.jar:$CLASSPATH" org.antlr.v4.Tool -Dlanguage=Cpp C2105071Parser.g4

g++ -std=c++17 -w -I/usr/local/include/antlr4-runtime -c C2105071Lexer.cpp C2105071Parser.cpp Ctester.cpp
g++ -std=c++17 -w C2105071Lexer.o C2105071Parser.o Ctester.o -L/usr/local/lib/ -lantlr4-runtime -o Ctester.out -pthread
LD_LIBRARY_PATH=/usr/local/lib ./Ctester.out $1
