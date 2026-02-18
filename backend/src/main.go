package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	_ "github.com/lib/pq"
)

// Structures matched to DB schema

type Person struct {
	ID            int    `json:"id"`
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	BirthDate     string `json:"birth_date,omitempty"`
	DriverLicense string `json:"driver_license,omitempty"`
	Location      string `json:"location,omitempty"`
	Title         string `json:"title,omitempty"`
	Description   string `json:"description,omitempty"`
	LinkedinURL   string `json:"linkedin_url,omitempty"`
	ImageURL      string `json:"image_url,omitempty"`
}

type Domain struct {
	ID     int     `json:"id"`
	Name   string  `json:"name"`
	Skills []Skill `json:"skills,omitempty"`
}

type Skill struct {
	ID       int    `json:"id"`
	DomainID int    `json:"domain_id"`
	Name     string `json:"name"`
	ImageURL string `json:"image_url,omitempty"`
	Details  string `json:"details,omitempty"`
}

type Language struct {
	ID               int    `json:"id"`
	Name             string `json:"name"`
	Level            string `json:"level,omitempty"`
	ImageURL         string `json:"image_url,omitempty"`
	CertificationURL string `json:"certification_url,omitempty"`
}

type Hobby struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	ImageURL string `json:"image_url,omitempty"`
}

type SoftSkill struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	ImageURL string `json:"image_url,omitempty"`
}

type Education struct {
	ID        int    `json:"id"`
	School    string `json:"school"`
	SchoolURL string `json:"school_url,omitempty"`
	Degree    string `json:"degree"`
	Details   string `json:"details,omitempty"`
	StartDate string `json:"start_date,omitempty"`
	Status    string `json:"status,omitempty"`
}

type Experience struct {
	ID         int    `json:"id"`
	Company    string `json:"company"`
	CompanyURL string `json:"company_url,omitempty"`
	Role       string `json:"role"`
	Details    string `json:"details,omitempty"`
	StartDate  string `json:"start_date,omitempty"`
	Duration   string `json:"duration,omitempty"`
	Status     string `json:"status,omitempty"`
}

type Project struct {
	ID          int    `json:"id"`
	Title       string `json:"title"`
	ImageURL    string `json:"image_url,omitempty"`
	Period      string `json:"period,omitempty"`
	Description string `json:"description,omitempty"`
	SkillsHuman string `json:"skills_human,omitempty"`
	SkillsTech  string `json:"skills_tech,omitempty"`
	LinkURL     string `json:"link_url,omitempty"`
}

type PortfolioData struct {
	Person      Person       `json:"person"`
	Domains     []Domain     `json:"domains"`
	Languages   []Language   `json:"languages"`
	Hobbies     []Hobby      `json:"hobbies"`
	SoftSkills  []SoftSkill  `json:"soft_skills"`
	Educations  []Education  `json:"educations"`
	Experiences []Experience `json:"experiences"`
	Projects    []Project    `json:"projects"`
}

var db *sql.DB

func main() {
	var err error
	// Construct connection string from env vars
	userInfo := url.UserPassword(os.Getenv("POSTGRES_USER"), os.Getenv("POSTGRES_PASSWORD"))
	connStr := fmt.Sprintf("postgres://%s@db:5432/%s?sslmode=disable",
		userInfo.String(),
		os.Getenv("POSTGRES_DB"))

	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	http.HandleFunc("/api/get-data", getDataHandler)

	log.Println("Server started on :3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}

func getDataHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*") // CORS for development

	data, err := fetchPortfolioData()
	if err != nil {
		log.Printf("Error fetching data: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(data)
}

func fetchPortfolioData() (*PortfolioData, error) {
	var p PortfolioData

	// 1. Fetch Person (assumes ID 1)
	err := db.QueryRow("SELECT id, first_name, last_name, COALESCE(to_char(birth_date, 'YYYY-MM-DD'), ''), COALESCE(driver_license, ''), COALESCE(location, ''), COALESCE(title, ''), COALESCE(description, ''), COALESCE(linkedin_url, ''), COALESCE(image_url, '') FROM person WHERE id = 1").Scan(
		&p.Person.ID, &p.Person.FirstName, &p.Person.LastName, &p.Person.BirthDate, &p.Person.DriverLicense, &p.Person.Location, &p.Person.Title, &p.Person.Description, &p.Person.LinkedinURL, &p.Person.ImageURL,
	)
	if err != nil {
		return nil, fmt.Errorf("error fetching person: %v", err)
	}

	// 2. Fetch Domains and Skills
	domainRows, err := db.Query("SELECT id, name FROM domain")
	if err != nil {
		return nil, fmt.Errorf("error fetching domains: %v", err)
	}
	defer domainRows.Close()

	for domainRows.Next() {
		var d Domain
		if err := domainRows.Scan(&d.ID, &d.Name); err != nil {
			return nil, err
		}

		// Fetch Skills for this domain
		skillRows, err := db.Query("SELECT id, domain_id, name, COALESCE(image_url, ''), COALESCE(details, '') FROM skill WHERE domain_id = $1", d.ID)
		if err != nil {
			return nil, err
		}
		defer skillRows.Close()

		for skillRows.Next() {
			var s Skill
			if err := skillRows.Scan(&s.ID, &s.DomainID, &s.Name, &s.ImageURL, &s.Details); err != nil {
				return nil, err
			}
			d.Skills = append(d.Skills, s)
		}
		p.Domains = append(p.Domains, d)
	}

	// 3. Fetch Languages
	langRows, err := db.Query("SELECT id, name, COALESCE(level, ''), COALESCE(image_url, ''), COALESCE(certification_url, '') FROM language WHERE person_id = $1", p.Person.ID)
	if err != nil {
		return nil, err
	}
	defer langRows.Close()
	for langRows.Next() {
		var l Language
		if err := langRows.Scan(&l.ID, &l.Name, &l.Level, &l.ImageURL, &l.CertificationURL); err != nil {
			return nil, err
		}
		p.Languages = append(p.Languages, l)
	}

	// 4. Fetch Hobbies
	hobbyRows, err := db.Query("SELECT id, name, COALESCE(image_url, '') FROM hobby WHERE person_id = $1", p.Person.ID)
	if err != nil {
		return nil, err
	}
	defer hobbyRows.Close()
	for hobbyRows.Next() {
		var h Hobby
		if err := hobbyRows.Scan(&h.ID, &h.Name, &h.ImageURL); err != nil {
			return nil, err
		}
		p.Hobbies = append(p.Hobbies, h)
	}

	// 5. Fetch Soft Skills
	softRows, err := db.Query("SELECT id, name, COALESCE(image_url, '') FROM soft_skill WHERE person_id = $1", p.Person.ID)
	if err != nil {
		return nil, err
	}
	defer softRows.Close()
	for softRows.Next() {
		var s SoftSkill
		if err := softRows.Scan(&s.ID, &s.Name, &s.ImageURL); err != nil {
			return nil, err
		}
		p.SoftSkills = append(p.SoftSkills, s)
	}

	// 6. Fetch Education
	eduRows, err := db.Query("SELECT id, school, COALESCE(school_url, ''), degree, COALESCE(details, ''), COALESCE(start_date, ''), COALESCE(status, '') FROM education WHERE person_id = $1 ORDER BY id DESC", p.Person.ID)
	if err != nil {
		return nil, err
	}
	defer eduRows.Close()
	for eduRows.Next() {
		var e Education
		if err := eduRows.Scan(&e.ID, &e.School, &e.SchoolURL, &e.Degree, &e.Details, &e.StartDate, &e.Status); err != nil {
			return nil, err
		}
		p.Educations = append(p.Educations, e)
	}

	// 7. Fetch Experience
	expRows, err := db.Query("SELECT id, company, COALESCE(company_url, ''), role, COALESCE(details, ''), COALESCE(start_date, ''), COALESCE(duration, ''), COALESCE(status, '') FROM experience WHERE person_id = $1 ORDER BY id DESC", p.Person.ID)
	if err != nil {
		return nil, err
	}
	defer expRows.Close()
	for expRows.Next() {
		var e Experience
		if err := expRows.Scan(&e.ID, &e.Company, &e.CompanyURL, &e.Role, &e.Details, &e.StartDate, &e.Duration, &e.Status); err != nil {
			return nil, err
		}
		p.Experiences = append(p.Experiences, e)
	}

	// 8. Fetch Projects
	projRows, err := db.Query("SELECT id, title, COALESCE(image_url, ''), COALESCE(period, ''), COALESCE(description, ''), COALESCE(skills_human, ''), COALESCE(skills_tech, ''), COALESCE(link_url, '') FROM project WHERE person_id = $1 ORDER BY id DESC", p.Person.ID)
	if err != nil {
		return nil, err
	}
	defer projRows.Close()
	for projRows.Next() {
		var pr Project
		if err := projRows.Scan(&pr.ID, &pr.Title, &pr.ImageURL, &pr.Period, &pr.Description, &pr.SkillsHuman, &pr.SkillsTech, &pr.LinkURL); err != nil {
			return nil, err
		}
		p.Projects = append(p.Projects, pr)
	}

	return &p, nil
}
