/*
* db.c
* Started on Jun 16, 2016
*       Author: Jennifer Steffens
    * gcc -o db db.c -lsqlite3 -std=c99
*/

#include "prov.h"


//swift-t/turbine/code/src/turbine ??


int main() { //main is just for testing in a c enviorment
    
    sqlite3 *db = init("a.db");

    if (!db) 
        {   puts("not working\n");
            return 0;}

    puts("should be working\n");
    printf("%d\n", build_from_schema("../DB_Stuff/MTCProv.sql", db));
    insert("VariableAnnotation", "key, value", "boop, 20", db);


    finalize(db);

    return 0;
 }

sqlite3* init(char * db_name) //works

{
    sqlite3 *temp;
    sqlite3 *db = malloc(sizeof(temp));
    

    int rc = sqlite3_open(db_name, &db);
    if (rc != SQLITE_OK) {
        
        printf("Cannot open database: %s\n", 
                sqlite3_errmsg(db));
        sqlite3_close(db);
        db = NULL;

      
     }

     return db;


}

int finalize(sqlite3 *db)  //works
{
    if (!db)
        {return DB_ALREADY_CLOSED;}
    int rc = sqlite3_close(db);
    if (rc != SQLITE_OK){

        //printf("Could not be closed. %s\n", sqlite3_errmsg(db));
        

        return DB_ERROR;

    }
    return DB_OK;
}

int build_from_schema(char *filename, sqlite3 *db) //works

{

    FILE *fp;
    char * err_msg;
    
    fp = fopen(filename, "r");

    if (!fp)
         {
            //printf(".sql file not opened.\n");
            return DB_SCHEMA_ERROR;
        }
    else
       // printf("ok");

    fseek(fp, 0, SEEK_END);
    long fsize = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    char *schema = malloc(fsize + 1);
    fread(schema, fsize, 1, fp);
    
    fclose(fp);

    int rc = sqlite3_exec(db, schema, 0, 0, &err_msg);
    if (rc != SQLITE_OK ) {
        
        //fprintf(stderr, "Failed to build.\n");
       // fprintf(stderr, "SQL error: %s\n", err_msg);

        sqlite3_free(err_msg);
        sqlite3_free(schema);
        sqlite3_close(db);
        db = NULL;

        return DB_BUILD_ERROR;

        } 
    sqlite3_free(err_msg);
    sqlite3_free(schema);
    

    return DB_OK;


}



int insert(char * tbl, char * attr, char * vals, sqlite3 *db) { //works with any insert

    char * err_msg;
    int allocated;
    int size_old = strlen(vals);
    int size_new;
   
    int i, count;
    int c = 0;

    for (i=0, count=2; vals[i]; i++)
        {
        count += (2*(vals[i] == ','));
        count -= (vals[i] == '\'');
        count -= (vals[i] == ' ');
        }
    

    size_new = size_old + count;
    char * string_args =  malloc(size_new);

    if(vals[0] != '\'')
            {
                string_args[0] = '\'';
                c = 1;
            }
   

    for(i=0; i < size_old; i++)
        {
            if (vals[i] == ',' && vals[i-1] != '\'')
            {
                string_args[c] = '\'';
                c++;
                
            }

            if (vals[i] == ',' && vals[i+1] != '\'') 
            {

                string_args[c] = vals[i];
                if (vals[i+1] == ' ' && vals[i+2] != '\'')
                    {i++;}
                c++; i++;
                string_args[c] = '\'';
                c++;
                
            }

                string_args[c] = vals[i];
                c++;

            
        }

    string_args[c] = '\'';
    string_args[c+1] = '\0';
    

    char * query = malloc(strlen(attr) + strlen(string_args) + strlen(tbl) + 30);

    sprintf(query, "INSERT INTO %s (%s) VALUES (%s)", tbl, attr, string_args);
    

    int rc = sqlite3_exec(db, query, 0, 0, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to insert. SQL error: %s\n", err_msg);
        sqlite3_free(err_msg);
        sqlite3_free(query);
        sqlite3_free(string_args);

        return DB_INSERT_ERROR;
    }
    //printf("inserted.");
    sqlite3_free(err_msg);
    sqlite3_free(query);
    sqlite3_free(string_args);

    return DB_OK;
}

   

/*
char * show_table_contents(char * tbl, sqlite3 *db){

   char * err_msg;
   sqlite3_stmt *stmt;
   char * result;
   int rc;



    char * query = malloc(strlen(tbl) + 20);
    rc = sqlite3_exec(db, query, callback, 0, &err_msg);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "Failed to get. SQL error: %s\n", err_msg);
        sqlite3_free(err_msg);
        sqlite3_free(query);

        return DB_ERROR;
    }
    //printf("inserted.");
    sqlite3_free(err_msg);
    sqlite3_free(query);

    return DB_OK;


}



 */

int callback(void *NotUsed, int argc, char **argv, 
                    char **azColName) {
    
    NotUsed = 0;

    for (int i = 0; i < argc; i++) {

        printf("%s\n", argv[i] ? argv[i] : "NULL");
    }
    
    return DB_OK;
}
