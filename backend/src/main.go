package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

func main() {
    http.HandleFunc("/get-data", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, `{"data": "Données traitées par Go"}`)
    })
    log.Fatal(http.ListenAndServe(":3000", nil))
}
