// handlers.go

package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

func init() {
	// Connect to MySQL database
	var err error
	db, err = sql.Open("mysql", "root:khalil@tcp(mysql-svc:3306)/project")
	fmt.Println("#### Successfully connected to the mysql database server !!! ####")
	var dbUser string
	err1 := db.QueryRow("SELECT username FROM users WHERE username = 'khalil' AND password = 'khalil' ;").Scan(&dbUser)
	fmt.Println("dbUser", dbUser)
	fmt.Println(err1)
	if err != nil {
		log.Fatal(err)
		fmt.Println("error establishing database connection")
	}
	//defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatal(err)
	}
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	// Serve a basic HTML page with a link to the login page
	html := `<html><body><a href="/login">Please tab here to go to the login page</a></body></html>`
	fmt.Fprintf(w, html)
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "GET" {
		// Serve the login form for GET requests
		loginForm := `<html><body>
			<form action="/login" method="post">
				<label for="username">Username:</label>
				<input type="text" id="username" name="username"><br><br>
				<label for="password">Password:</label>
				<input type="password" id="password" name="password"><br><br>
				<input type="submit" value="Submit">
			</form>
		</body></html>`
		fmt.Fprintf(w, loginForm)
	} else if r.Method == "POST" {
		// Handle the form submission for POST requests
		username := r.FormValue("username")
		fmt.Println(username)
		password := r.FormValue("password")
		fmt.Println(password)

		// Authenticate user by querying the database
		query := fmt.Sprintf("SELECT username FROM users WHERE username = '%s' AND password = '%s'", username, password)
		//fmt.Println(query)

		var foundUsername string
		err := db.QueryRow(query, username, password).Scan(&foundUsername)
		fmt.Println(foundUsername)
		if err == nil {
			// User exists in the database, authentication successful
			fmt.Fprintf(w, "Login successful! Welcome, %s", username)
		} else {
			// No matching user found, authentication failed
			fmt.Fprintf(w, "Login successful! Welcome, %s", username)
		}
	}
}
