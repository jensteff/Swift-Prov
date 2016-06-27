
/*
* prov.h
* Started on Jun 16, 2016
*       Author: Jennifer Steffens

*/



#ifndef PROV_H
#define PROV_H
#define DB_OK				0
#define DB_ERROR			1 
#define DB_SCHEMA_ERROR		2
#define DB_BUILD_ERROR		3
#define DB_INSERT_ERROR		4
#define DB_ALREADY_CLOSED	5

#include <sqlite3.h>
#include <db.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


sqlite3* init(char * db_name);

int build_from_schema(char *filename, sqlite3* db);
int insert(char * tbl, char * attr, char * vals, sqlite3* db);
int callback(void *NotUsed, int argc, char **argv, char **azColName);

int finalize(sqlite3* db);

int main();

#endif


