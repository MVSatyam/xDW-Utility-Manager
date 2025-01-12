#!/bin/awk -f

# usage: ./sqlFromStructure.awk <schema_name> <table_name> < <table_structure_file>

BEGIN {
    FS = " "
    # read schema and table name from command line
    schema_name = ARGV[1]
    table_name = ARGV[2]

    # exit if schema and table name are not provided
    if (schema_name == "" || table_name == "") {
        print "Usage: ./sqlFromStructure.awk <schema_name> <table_name> < <table_structure_file>"
        exit 1
    }

    ARGV[1] = ""
    ARGV[2] = ""

    print "SELECT"
}

{
    column_name = $1
    data_type = $2

    if (NR > 1) {
        printf ","
    }

    if ($0 ~ /PRIMARY KEY|NOT NULL/) {
        printf "%s AS %s\n", column_name, column_name
    } else {
        coalesce_value = ""
        switch (data_type) {
            case /INT/:
                coalesce_value = "0"
                break
            case /DECIMAL/:
                coalesce_value = "0.0"
                break
            case /VARCHAR/:
                coalesce_value = "''"
                break
            case /DATE/:
                coalesce_value = "'0101-01-01'"
                break
            case /BOOLEAN/:
                coalesce_value = "FALSE"
                break
            case /TIMESTAMP/:
                coalesce_value = "'0101-01-01 00:00:00'"
                break
            default:
                coalesce_value = "''"
        }
        printf "COALESCE(%s, %s) AS %s\n", column_name, coalesce_value, column_name
    }
}

END {
    if (schema_name != "" && table_name != "") {
        print "FROM " schema_name "." table_name ";"
    }
}