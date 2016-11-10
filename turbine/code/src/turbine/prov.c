/*
* prov.c    Source Code version
* Started on Jun 16, 2016
*       Author: Jennifer Steffens
    * gcc -o db db.c -lsqlite3 -std=c99

    *gcc -c prov.c -o prov.o && swig -tcl prov.i && gcc -c prov_wrap.c -o prov_wrap.o && gcc -dynamiclib -framework Tcl -lsqlite3  prov.o prov_wrap.o -o prov.so
*   swig -tcl prov.i 
*   gcc -c prov_wrap.c -o prov_wrap.o
*   gcc -dynamiclib -framework Tcl  test.o test_wrap.o -o test.so
*/

#include "prov.h"


//swift-t/turbine/code/src/turbine ??


 /*int main() {
    
      *db = prov_init("a.db");

     if (!db) 
         {   puts("not working\n");
             return 0;}

     puts("should be working\n");
    // printf("%d\n", prov_build_from_schema("../DB_Stuff/MTCProv.sql", db));
    prov_insert("VariableAnnotation","", "peace, love", db);


  prov_finalize(db);

     return 0;
  }*/



sqlite3* prov_init(char * db_name) //works

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

//     prov_build_from_schema("SteffProv.sql", db);


     return db;


}

int prov_finalize(sqlite3 *db)  //works
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

int prov_build_from_schema(sqlite3 *db) //works

{
char * schema = "CREATE TABLE IF NOT EXISTS ApplicationCatalog "
"("
"   hashValue char(128) PRIMARY KEY,"
"   catalogEntries text"
");"
"CREATE TABLE IF NOT EXISTS ApplicationExecution ("
"applicationExecutionId char(128) PRIMARY KEY,"
"tries                      int,"
"   startTime               datetime,"
"   try_duration                int,"
"   total_duration              int,"
"   command                 char(128),"
"   stdios                  char(128),"
"   arguments               char(128),"
"   site                    char(128),"
"   notes                   text"
");"

"CREATE TABLE IF NOT EXISTS ApplicationFunctionCall"
"("
"   startTime           datetime, "
"   duration            int,"
"   finalState          char(128),"
"   app_catalog_name    char(128)"
");"
"CREATE TABLE IF NOT EXISTS ConsumesProperty"
"("
"   parameter       char(128)"
");"
"CREATE TABLE IF NOT EXISTS FunctionCall"
"("
"   functionCallId  char(128) PRIMARY KEY,"
"   type            char(128),"
"   name            char(128),"
"   notes           text"
");"
"CREATE TABLE IF NOT EXISTS Mapped"
"("
"   filename        char(128)"
");"
"CREATE TABLE IF NOT EXISTS Primitive"
"("
"   value           text"
");"
"CREATE TABLE IF NOT EXISTS ProducesProperty"
"("
"   parameter       char(128)"
");"
"CREATE TABLE IF NOT EXISTS RuntimeSnapshot"
"("
"   timestamp       datetime PRIMARY KEY,"
"   cpuUsage        float,"
"   maxPhysMem      int,"
"   maxVirtMem      int,"
"   ioRead          int,"
"   ioWrite         int"
");"
"CREATE TABLE IF NOT EXISTS  Script"
"("
"   hashValue       char(128) PRIMARY KEY,"
"   sourceCode      text"
");"
"CREATE TABLE IF NOT EXISTS ScriptRun"
"("
"   scriptRunId             char(128) PRIMARY KEY, "
"   scriptFileName          char(128),"
"   logFileName             char(128),         "
"   swiftVersion            char(128),"
"   cogVersion              char(128),"
"   finalState              char(128),"
"   starttime               datetime,"
"   duration                int,"
"   scriptHash              char(128),"
"   applicationCatalogHash  char(128),"
"   siteCatalogHash         char(128)"
");"
"CREATE TABLE IF NOT EXISTS ScriptRunAnnotation"
"("
"   key             char(128) PRIMARY KEY,"
"   value           text"
");"
"CREATE TABLE IF NOT EXISTS SiteCatalog"
"("
"   hashValue       char(128) PRIMARY KEY,"
"   catalogEntries  text"
");"
"CREATE TABLE IF NOT EXISTS Variable"
"("
"   variableId      char(128) PRIMARY KEY"
");"
"CREATE TABLE IF NOT EXISTS VariableAnnotation"
"("
"   key             char(128) PRIMARY KEY,"
"   value           text            "
");"
""
"CREATE TABLE IF NOT EXISTS compare_run_by_annot_num_type"
"("
"   run_id varchar,"
"   name varchar,"
"   value numeric"
");"
"CREATE TABLE IF NOT EXISTS compare_run_by_annot_txt_type"
"("
"   run_id varchar,"
"   name varchar,"
"   value varchar"
");"
"CREATE TABLE IF NOT EXISTS compare_run_by_key_numeric_type"
"(   run_id varchar,"
"   name varchar,"
"   value numeric"
");"
"CREATE TABLE IF NOT EXISTS compare_run_by_key_text_type"
"(   run_id varchar,"
"   name varchar,"
"   value varchar"
");"
"CREATE TABLE IF NOT EXISTS compare_run_by_parameter_type"
"(   run_id varchar,"
"   parameter varchar,"
"   value varchar"
");";

    
    char * err_msg;
    int rc = sqlite3_exec(db, schema, 0, 0, &err_msg);
    if (rc != SQLITE_OK ) {
        
        //fprintf(stderr, "Failed to build.\n");
       
        printf("SQL error: %s\n", err_msg);
        printf("%s", schema);
        sqlite3_free(err_msg);
        sqlite3_close(db);
        db = NULL;


        return DB_BUILD_ERROR;
        

        } 
        
    sqlite3_free(err_msg);
    

    return DB_OK;


}



int prov_insert(char * tbl, char * inputattr, char * vals, sqlite3 *db) { //works with any insert

    int attributesize = ((strlen(inputattr))+3); //two for "()" and one more for \0
    char attr[attributesize];

    if (strcmp(inputattr, "*")) //if attr is NOT equal to *
    {
        sprintf(attr,"(%s)", inputattr);      
    } 
    else
    {
        sprintf(attr, "%s", "");
    }


    char * err_msg;
    int allocated;
    int size_old = strlen(vals);
    int size_new;
   
    int i, count;
    int c = 0;

    for (i=0, count=3; vals[i]; i++)
        {
        count += (2*(vals[i] == ','));    
        count -= (vals[i] == '\'');
        count -= (vals[i] == ' ' && (i == 0 || vals[i-1] == ','));
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
            if (vals[i+1] == ',' && vals[i] == ',')
            {
               if (vals[i-1] != '\'')
        {
           string_args[c] = '\'';
           c++;
        }
         string_args[c] = vals[i];
                c++;
                string_args[c] = '\'';
        c++;
        string_args[c] = '\'';
        i++;
            

            }
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
            if ( i < size_old){    
                string_args[c] = vals[i];
                c++;
                }
        }

    string_args[c] = '\'';
    string_args[c+1] = '\0';
    
    char * query = malloc(strlen(attr) + strlen(string_args) + strlen(tbl) + 30);


    sprintf(query, "INSERT INTO %s %s VALUES (%s)", tbl, attr, string_args);
    

    int rc = sqlite3_exec(db, query, 0, 0, &err_msg);
   if (rc != SQLITE_OK) {
      // fprintf(stdout, "Failed to insert. SQL error: %s\nQuery: %s\n", err_msg, query);
        sqlite3_free(err_msg);
        free(query);
        free(string_args);
        //sqlite3_free(attr);
        return DB_INSERT_ERROR;
    }
    //printf("inserted: %s\n.", query);
    sqlite3_free(err_msg);
    free(query);
    free(string_args);
    //sqlite3_free(attr);

    return DB_OK;
}

/*
int prov_check_build(sqlite3 *db)
{

}

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

int prov_callback(void *NotUsed, int argc, char **argv, 
                    char **azColName) {
    
    NotUsed = 0;

    for (int i = 0; i < argc; i++) {

        printf("%s\n", argv[i] ? argv[i] : "NULL");
    }
    
    return DB_OK;
}
