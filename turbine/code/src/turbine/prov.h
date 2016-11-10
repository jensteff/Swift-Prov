
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

#include "sqlite3.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>


sqlite3* prov_init(char * db_name);

int prov_build_from_schema(sqlite3* db);
int prov_insert(char * tbl, char * attr, char * vals, sqlite3* db);
int prov_callback(void *NotUsed, int argc, char **argv, char **azColName);

int prov_finalize(sqlite3* db);


#endif


