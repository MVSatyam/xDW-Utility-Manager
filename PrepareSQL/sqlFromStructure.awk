#!/bin/awk -f

# usage: ./sqlFromStructure.awk <schema_name> <table_name> < <table_structure_file>

BEGIN {
    FS = " "  # Use regex to handle spaces and commas
    # read schema and table name from command line
    schema_name = ARGV[1]
    table_name = ARGV[2]

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
        if (data_type ~ /INT/) {
            printf "COALESCE(%s, 0) AS %s\n", column_name, column_name
        } else if (data_type ~ /DECIMAL/) {
            printf "COALESCE(%s, 0.0) AS %s\n", column_name, column_name
        } else if (data_type ~ /VARCHAR/) {
            printf "COALESCE(%s, '') AS %s\n", column_name, column_name
        } else if (data_type ~ /DATE/) {
            printf "COALESCE(%s, '0101-01-01') AS %s\n", column_name, column_name
        } else if (data_type ~ /BOOLEAN/) {
            printf "COALESCE(%s, FALSE) AS %s\n", column_name, column_name
        } else if (data_type ~ /TIMESTAMP/) {
            printf "COALESCE(%s, '0101-01-01 00:00:00') AS %s\n", column_name, column_name
        } else {
            printf "COALESCE(%s, '') AS %s\n", column_name, column_name
        }
    }
}

END {
    print "FROM " schema_name "." table_name ";"
}