package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestLoginHandler_InvalidCredentials(t *testing.T) {
	formData := strings.NewReader("username=invalid&password=credentials")
	req, err := http.NewRequest("POST", "/login", formData)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(loginHandler)

	handler.ServeHTTP(rr, req)

	expected := "Invalid credentials"
	if rr.Body.String() != expected {
		t.Errorf("Expected response %q; got %q", expected, rr.Body.String())
	}
}
