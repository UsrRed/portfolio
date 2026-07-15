package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

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
	Email         string `json:"email,omitempty"`
	Phone         string `json:"phone,omitempty"`
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
	Hidden      bool   `json:"hidden"`
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

// En prod (admin désactivé), les projets masqués sont exclus de /api/get-data.
var adminEnabled bool

func setCORSHeaders(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func handlePreflight(w http.ResponseWriter, r *http.Request) bool {
	setCORSHeaders(w)
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return true
	}
	return false
}

func extractIDFromPath(path, prefix string) (int, error) {
	s := strings.TrimPrefix(path, prefix)
	s = strings.Trim(s, "/")
	if s == "" {
		return 0, fmt.Errorf("no id in path")
	}
	return strconv.Atoi(s)
}

func main() {
	var err error
	userInfo := url.UserPassword(os.Getenv("POSTGRES_USER"), os.Getenv("POSTGRES_PASSWORD"))
	connStr := fmt.Sprintf("postgres://%s@db:5432/%s?sslmode=disable",
		userInfo.String(),
		os.Getenv("POSTGRES_DB"))

	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	if err = db.Ping(); err != nil {
		log.Fatalf("Cannot connect to database: %v", err)
	}

	// Les volumes créés avant l'ajout de la colonne n'ont pas rejoué init.sql
	if _, err = db.Exec("ALTER TABLE project ADD COLUMN IF NOT EXISTS hidden BOOLEAN NOT NULL DEFAULT FALSE"); err != nil {
		log.Fatalf("Cannot migrate project table: %v", err)
	}

	http.HandleFunc("/api/get-data", getDataHandler)

	adminEnabled = os.Getenv("ENABLE_ADMIN") == "true"

	// Default-deny : les mutations ne sont exposées que si explicitement activées.
	// (L'ancienne condition != "false" ouvrait l'endpoint quand la variable était absente.)
	if os.Getenv("ENABLE_ADD_PROJECT") == "true" || adminEnabled {
		http.HandleFunc("/api/projects", projectsHandler)
		http.HandleFunc("/api/projects/", projectsHandler)
		log.Println("Projects endpoint enabled")
	}

	if adminEnabled {
		http.HandleFunc("/api/upload", uploadHandler)
		http.HandleFunc("/api/image-search", imageSearchHandler)
		http.HandleFunc("/api/image-import", imageImportHandler)
		http.HandleFunc("/api/person", personHandler)
		http.HandleFunc("/api/domains", domainsHandler)
		http.HandleFunc("/api/domains/", domainsHandler)
		http.HandleFunc("/api/skills", skillsHandler)
		http.HandleFunc("/api/skills/", skillsHandler)
		http.HandleFunc("/api/languages", languagesHandler)
		http.HandleFunc("/api/languages/", languagesHandler)
		http.HandleFunc("/api/hobbies", hobbiesHandler)
		http.HandleFunc("/api/hobbies/", hobbiesHandler)
		http.HandleFunc("/api/soft-skills", softSkillsHandler)
		http.HandleFunc("/api/soft-skills/", softSkillsHandler)
		http.HandleFunc("/api/educations", educationsHandler)
		http.HandleFunc("/api/educations/", educationsHandler)
		http.HandleFunc("/api/experiences", experiencesHandler)
		http.HandleFunc("/api/experiences/", experiencesHandler)
		log.Println("Admin endpoints enabled")
	}

	log.Println("Server started on :3000")
	log.Fatal(http.ListenAndServe(":3000", nil))
}

// ─── GET ALL DATA ────────────────────────────────────────────────────────────

func getDataHandler(w http.ResponseWriter, r *http.Request) {
	setCORSHeaders(w)
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	data, err := fetchPortfolioData()
	if err != nil {
		log.Printf("Error fetching data: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(data)
}

// ─── IMAGE RESIZE ────────────────────────────────────────────────────────────

// maxImageDim borne la plus grande dimension des images stockées : elles sont
// affichées au plus en ~640px CSS, 1600px couvre large (rétina + zoom détail).
const maxImageDim = 1600

// boundImageBytes réduit une image JPEG/PNG trop grande et la ré-encode.
// Tout autre format (GIF animé, WebP, SVG…) ou toute erreur → octets d'origine.
func boundImageBytes(data []byte) []byte {
	mime := http.DetectContentType(data)
	if mime != "image/jpeg" && mime != "image/png" {
		return data
	}
	src, format, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return data
	}
	b := src.Bounds()
	if b.Dx() <= maxImageDim && b.Dy() <= maxImageDim {
		return data
	}
	dst := downscale(src, maxImageDim)

	var buf bytes.Buffer
	switch format {
	case "jpeg":
		err = jpeg.Encode(&buf, dst, &jpeg.Options{Quality: 85})
	case "png":
		enc := png.Encoder{CompressionLevel: png.BestCompression}
		err = enc.Encode(&buf, dst)
	default:
		return data
	}
	if err != nil || buf.Len() >= len(data) {
		return data
	}
	log.Printf("Image resized: %dx%d -> %dx%d (%d -> %d bytes)",
		b.Dx(), b.Dy(), dst.Bounds().Dx(), dst.Bounds().Dy(), len(data), buf.Len())
	return buf.Bytes()
}

// downscale réduit src pour que sa plus grande dimension soit maxDim,
// par moyenne de zone (box filter) — adapté aux fortes réductions, stdlib only.
func downscale(src image.Image, maxDim int) *image.RGBA {
	b := src.Bounds()
	w, h := b.Dx(), b.Dy()
	scale := float64(maxDim) / float64(w)
	if h > w {
		scale = float64(maxDim) / float64(h)
	}
	nw := int(float64(w)*scale + 0.5)
	nh := int(float64(h)*scale + 0.5)
	if nw < 1 {
		nw = 1
	}
	if nh < 1 {
		nh = 1
	}

	dst := image.NewRGBA(image.Rect(0, 0, nw, nh))
	for y := 0; y < nh; y++ {
		sy0, sy1 := y*h/nh, (y+1)*h/nh
		if sy1 <= sy0 {
			sy1 = sy0 + 1
		}
		for x := 0; x < nw; x++ {
			sx0, sx1 := x*w/nw, (x+1)*w/nw
			if sx1 <= sx0 {
				sx1 = sx0 + 1
			}
			var r, g, bl, a, n uint64
			for sy := sy0; sy < sy1; sy++ {
				for sx := sx0; sx < sx1; sx++ {
					// RGBA() renvoie des composantes prémultipliées : leur moyenne
					// directe est correcte, y compris sur les bords transparents.
					pr, pg, pb, pa := src.At(b.Min.X+sx, b.Min.Y+sy).RGBA()
					r += uint64(pr)
					g += uint64(pg)
					bl += uint64(pb)
					a += uint64(pa)
					n++
				}
			}
			dst.SetRGBA(x, y, color.RGBA{
				R: uint8(r / n >> 8),
				G: uint8(g / n >> 8),
				B: uint8(bl / n >> 8),
				A: uint8(a / n >> 8),
			})
		}
	}
	return dst
}

// ─── UPLOAD ──────────────────────────────────────────────────────────────────

func uploadHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if err := r.ParseMultipartForm(10 << 20); err != nil {
		http.Error(w, "File too large", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		http.Error(w, "No image provided", http.StatusBadRequest)
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)

	data, err := io.ReadAll(file)
	if err != nil {
		log.Printf("Error reading upload: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	// Borne les images trop grandes avant stockage (JPEG/PNG uniquement)
	data = boundImageBytes(data)

	if err := os.MkdirAll("/uploads", 0755); err != nil {
		log.Printf("Error creating uploads dir: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if err := os.WriteFile(filepath.Join("/uploads", filename), data, 0644); err != nil {
		log.Printf("Error writing file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"url": "/user-uploads/" + filename})
}

// ─── IMAGE SEARCH ────────────────────────────────────────────────────────────

type ImageResult struct {
	Image     string `json:"image"`
	Thumbnail string `json:"thumbnail"`
	Title     string `json:"title"`
}

var ddgVqdRe = regexp.MustCompile(`vqd=['"]?([\d-]+)`)

const searchUserAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"

func imageSearchHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	query := strings.TrimSpace(r.URL.Query().Get("q"))
	if query == "" {
		http.Error(w, "Missing query", http.StatusBadRequest)
		return
	}

	results, err := searchDuckDuckGoImages(query)
	if err != nil {
		log.Printf("Error searching images: %v", err)
		http.Error(w, "Image search failed", http.StatusBadGateway)
		return
	}

	json.NewEncoder(w).Encode(map[string][]ImageResult{"results": results})
}

func searchDuckDuckGoImages(query string) ([]ImageResult, error) {
	client := &http.Client{Timeout: 15 * time.Second}

	// 1. Récupère le token vqd requis par l'API images de DuckDuckGo
	tokenURL := "https://duckduckgo.com/?" + url.Values{"q": {query}, "iax": {"images"}, "ia": {"images"}}.Encode()
	req, err := http.NewRequest(http.MethodGet, tokenURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", searchUserAgent)
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return nil, err
	}
	m := ddgVqdRe.FindSubmatch(body)
	if m == nil {
		return nil, fmt.Errorf("vqd token not found")
	}

	// 2. Recherche d'images (f=type:transparent favorise les PNG à fond transparent)
	imgURL := "https://duckduckgo.com/i.js?" + url.Values{
		"l":   {"fr-fr"},
		"o":   {"json"},
		"q":   {query},
		"vqd": {string(m[1])},
		"f":   {"type:transparent"},
		"p":   {"1"},
	}.Encode()
	req, err = http.NewRequest(http.MethodGet, imgURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", searchUserAgent)
	req.Header.Set("Referer", "https://duckduckgo.com/")
	resp, err = client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("image API returned %d", resp.StatusCode)
	}

	var parsed struct {
		Results []ImageResult `json:"results"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return nil, err
	}
	if len(parsed.Results) > 24 {
		parsed.Results = parsed.Results[:24]
	}
	return parsed.Results, nil
}

// ─── IMAGE IMPORT ────────────────────────────────────────────────────────────

func imageImportHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		URL string `json:"url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload.URL == "" {
		http.Error(w, "Missing url", http.StatusBadRequest)
		return
	}
	parsed, err := url.Parse(payload.URL)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") {
		http.Error(w, "Invalid url", http.StatusBadRequest)
		return
	}

	client := &http.Client{Timeout: 20 * time.Second}
	req, err := http.NewRequest(http.MethodGet, payload.URL, nil)
	if err != nil {
		http.Error(w, "Invalid url", http.StatusBadRequest)
		return
	}
	req.Header.Set("User-Agent", searchUserAgent)
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error downloading image: %v", err)
		http.Error(w, "Download failed", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		http.Error(w, "Download failed", http.StatusBadGateway)
		return
	}

	data, err := io.ReadAll(io.LimitReader(resp.Body, 10<<20))
	if err != nil {
		log.Printf("Error reading image: %v", err)
		http.Error(w, "Download failed", http.StatusBadGateway)
		return
	}

	ext := extensionForImage(data, parsed.Path)
	if ext == "" {
		http.Error(w, "Not an image", http.StatusBadRequest)
		return
	}
	// Borne les images trop grandes avant stockage (JPEG/PNG uniquement)
	data = boundImageBytes(data)

	if err := os.MkdirAll("/uploads", 0755); err != nil {
		log.Printf("Error creating uploads dir: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	if err := os.WriteFile(filepath.Join("/uploads", filename), data, 0644); err != nil {
		log.Printf("Error writing file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]string{"url": "/user-uploads/" + filename})
}

func extensionForImage(data []byte, urlPath string) string {
	switch http.DetectContentType(data) {
	case "image/png":
		return ".png"
	case "image/jpeg":
		return ".jpg"
	case "image/gif":
		return ".gif"
	case "image/webp":
		return ".webp"
	}
	// DetectContentType ne reconnaît pas les SVG ; repli sur l'extension de l'URL
	ext := strings.ToLower(filepath.Ext(urlPath))
	if ext == ".svg" || ext == ".ico" {
		return ext
	}
	return ""
}

// ─── PERSON ──────────────────────────────────────────────────────────────────

func personHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var p Person
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	_, err := db.Exec(
		`UPDATE person SET first_name=$1, last_name=$2, title=$3, description=$4, location=$5, driver_license=$6, linkedin_url=$7, image_url=$8, email=$9, phone=$10 WHERE id=1`,
		p.FirstName, p.LastName, p.Title, p.Description, p.Location, p.DriverLicense, p.LinkedinURL, p.ImageURL, p.Email, p.Phone,
	)
	if err != nil {
		log.Printf("Error updating person: %v", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	p.ID = 1
	json.NewEncoder(w).Encode(p)
}

// ─── DOMAINS ─────────────────────────────────────────────────────────────────

func domainsHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/domains")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var d Domain
		if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		err := db.QueryRow("INSERT INTO domain (name) VALUES ($1) RETURNING id", d.Name).Scan(&d.ID)
		if err != nil {
			log.Printf("Error creating domain: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(d)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var d Domain
		if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec("UPDATE domain SET name=$1 WHERE id=$2", d.Name, id); err != nil {
			log.Printf("Error updating domain: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		d.ID = id
		json.NewEncoder(w).Encode(d)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM domain WHERE id=$1", id); err != nil {
			log.Printf("Error deleting domain: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── SKILLS ──────────────────────────────────────────────────────────────────

func skillsHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/skills")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var s Skill
		if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		err := db.QueryRow(
			"INSERT INTO skill (domain_id, name, image_url, details) VALUES ($1, $2, $3, $4) RETURNING id",
			s.DomainID, s.Name, s.ImageURL, s.Details,
		).Scan(&s.ID)
		if err != nil {
			log.Printf("Error creating skill: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(s)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var s Skill
		if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec(
			"UPDATE skill SET domain_id=$1, name=$2, image_url=$3, details=$4 WHERE id=$5",
			s.DomainID, s.Name, s.ImageURL, s.Details, id,
		); err != nil {
			log.Printf("Error updating skill: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		s.ID = id
		json.NewEncoder(w).Encode(s)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM skill WHERE id=$1", id); err != nil {
			log.Printf("Error deleting skill: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── LANGUAGES ───────────────────────────────────────────────────────────────

func languagesHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/languages")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var l Language
		if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		err := db.QueryRow(
			"INSERT INTO language (person_id, name, level, image_url, certification_url) VALUES (1, $1, $2, $3, $4) RETURNING id",
			l.Name, l.Level, l.ImageURL, l.CertificationURL,
		).Scan(&l.ID)
		if err != nil {
			log.Printf("Error creating language: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(l)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var l Language
		if err := json.NewDecoder(r.Body).Decode(&l); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec(
			"UPDATE language SET name=$1, level=$2, image_url=$3, certification_url=$4 WHERE id=$5",
			l.Name, l.Level, l.ImageURL, l.CertificationURL, id,
		); err != nil {
			log.Printf("Error updating language: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		l.ID = id
		json.NewEncoder(w).Encode(l)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM language WHERE id=$1", id); err != nil {
			log.Printf("Error deleting language: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── HOBBIES ─────────────────────────────────────────────────────────────────

func hobbiesHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/hobbies")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var h Hobby
		if err := json.NewDecoder(r.Body).Decode(&h); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		err := db.QueryRow(
			"INSERT INTO hobby (person_id, name, image_url) VALUES (1, $1, $2) RETURNING id",
			h.Name, h.ImageURL,
		).Scan(&h.ID)
		if err != nil {
			log.Printf("Error creating hobby: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(h)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var h Hobby
		if err := json.NewDecoder(r.Body).Decode(&h); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec("UPDATE hobby SET name=$1, image_url=$2 WHERE id=$3", h.Name, h.ImageURL, id); err != nil {
			log.Printf("Error updating hobby: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		h.ID = id
		json.NewEncoder(w).Encode(h)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM hobby WHERE id=$1", id); err != nil {
			log.Printf("Error deleting hobby: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── SOFT SKILLS ─────────────────────────────────────────────────────────────

func softSkillsHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/soft-skills")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var s SoftSkill
		if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		err := db.QueryRow(
			"INSERT INTO soft_skill (person_id, name, image_url) VALUES (1, $1, $2) RETURNING id",
			s.Name, s.ImageURL,
		).Scan(&s.ID)
		if err != nil {
			log.Printf("Error creating soft skill: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(s)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var s SoftSkill
		if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec("UPDATE soft_skill SET name=$1, image_url=$2 WHERE id=$3", s.Name, s.ImageURL, id); err != nil {
			log.Printf("Error updating soft skill: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		s.ID = id
		json.NewEncoder(w).Encode(s)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM soft_skill WHERE id=$1", id); err != nil {
			log.Printf("Error deleting soft skill: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── EDUCATIONS ──────────────────────────────────────────────────────────────

func educationsHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/educations")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var e Education
		if err := json.NewDecoder(r.Body).Decode(&e); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		err := db.QueryRow(
			"INSERT INTO education (person_id, school, school_url, degree, details, start_date, status) VALUES (1, $1, $2, $3, $4, $5, $6) RETURNING id",
			e.School, e.SchoolURL, e.Degree, e.Details, e.StartDate, e.Status,
		).Scan(&e.ID)
		if err != nil {
			log.Printf("Error creating education: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(e)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var e Education
		if err := json.NewDecoder(r.Body).Decode(&e); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec(
			"UPDATE education SET school=$1, school_url=$2, degree=$3, details=$4, start_date=$5, status=$6 WHERE id=$7",
			e.School, e.SchoolURL, e.Degree, e.Details, e.StartDate, e.Status, id,
		); err != nil {
			log.Printf("Error updating education: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		e.ID = id
		json.NewEncoder(w).Encode(e)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM education WHERE id=$1", id); err != nil {
			log.Printf("Error deleting education: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── EXPERIENCES ─────────────────────────────────────────────────────────────

func experiencesHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/experiences")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var e Experience
		if err := json.NewDecoder(r.Body).Decode(&e); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		err := db.QueryRow(
			"INSERT INTO experience (person_id, company, company_url, role, details, start_date, duration, status) VALUES (1, $1, $2, $3, $4, $5, $6, $7) RETURNING id",
			e.Company, e.CompanyURL, e.Role, e.Details, e.StartDate, e.Duration, e.Status,
		).Scan(&e.ID)
		if err != nil {
			log.Printf("Error creating experience: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(e)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var e Experience
		if err := json.NewDecoder(r.Body).Decode(&e); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec(
			"UPDATE experience SET company=$1, company_url=$2, role=$3, details=$4, start_date=$5, duration=$6, status=$7 WHERE id=$8",
			e.Company, e.CompanyURL, e.Role, e.Details, e.StartDate, e.Duration, e.Status, id,
		); err != nil {
			log.Printf("Error updating experience: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		e.ID = id
		json.NewEncoder(w).Encode(e)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM experience WHERE id=$1", id); err != nil {
			log.Printf("Error deleting experience: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── PROJECTS ────────────────────────────────────────────────────────────────

func projectsHandler(w http.ResponseWriter, r *http.Request) {
	if handlePreflight(w, r) {
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/api/projects")
	path = strings.Trim(path, "/")

	if path == "" {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var p Project
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			http.Error(w, "Invalid JSON: "+err.Error(), http.StatusBadRequest)
			return
		}
		if p.Title == "" {
			http.Error(w, "title is required", http.StatusBadRequest)
			return
		}
		err := db.QueryRow(
			`INSERT INTO project (person_id, title, image_url, period, description, skills_human, skills_tech, link_url, hidden)
			 VALUES (1, $1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
			p.Title, p.ImageURL, p.Period, p.Description, p.SkillsHuman, p.SkillsTech, p.LinkURL, p.Hidden,
		).Scan(&p.ID)
		if err != nil {
			log.Printf("Error inserting project: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(p)
		return
	}

	id, err := strconv.Atoi(path)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodPut:
		var p Project
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if _, err := db.Exec(
			"UPDATE project SET title=$1, image_url=$2, period=$3, description=$4, skills_human=$5, skills_tech=$6, link_url=$7, hidden=$8 WHERE id=$9",
			p.Title, p.ImageURL, p.Period, p.Description, p.SkillsHuman, p.SkillsTech, p.LinkURL, p.Hidden, id,
		); err != nil {
			log.Printf("Error updating project: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		p.ID = id
		json.NewEncoder(w).Encode(p)

	case http.MethodDelete:
		if _, err := db.Exec("DELETE FROM project WHERE id=$1", id); err != nil {
			log.Printf("Error deleting project: %v", err)
			http.Error(w, "Database error", http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── FETCH ALL DATA ──────────────────────────────────────────────────────────

func fetchPortfolioData() (*PortfolioData, error) {
	var p PortfolioData

	err := db.QueryRow("SELECT id, first_name, last_name, COALESCE(to_char(birth_date, 'DD/MM/YYYY'), ''), COALESCE(driver_license, ''), COALESCE(location, ''), COALESCE(title, ''), COALESCE(description, ''), COALESCE(linkedin_url, ''), COALESCE(image_url, ''), COALESCE(email, ''), COALESCE(phone, '') FROM person WHERE id = 1").Scan(
		&p.Person.ID, &p.Person.FirstName, &p.Person.LastName, &p.Person.BirthDate, &p.Person.DriverLicense, &p.Person.Location, &p.Person.Title, &p.Person.Description, &p.Person.LinkedinURL, &p.Person.ImageURL, &p.Person.Email, &p.Person.Phone,
	)
	if err != nil {
		return nil, fmt.Errorf("error fetching person: %v", err)
	}

	// En prod (admin désactivé), email et téléphone ne sont jamais exposés
	// par l'API (anti-scraping). En dev, le CV complet est généré.
	if !adminEnabled {
		p.Person.Email = ""
		p.Person.Phone = ""
	}

	domainRows, err := db.Query("SELECT id, name FROM domain ORDER BY id ASC")
	if err != nil {
		return nil, fmt.Errorf("error fetching domains: %v", err)
	}
	defer domainRows.Close()

	for domainRows.Next() {
		var d Domain
		if err := domainRows.Scan(&d.ID, &d.Name); err != nil {
			return nil, err
		}
		skillRows, err := db.Query("SELECT id, domain_id, name, COALESCE(image_url, ''), COALESCE(details, '') FROM skill WHERE domain_id = $1 ORDER BY id ASC", d.ID)
		if err != nil {
			return nil, err
		}
		for skillRows.Next() {
			var s Skill
			if err := skillRows.Scan(&s.ID, &s.DomainID, &s.Name, &s.ImageURL, &s.Details); err != nil {
				skillRows.Close()
				return nil, err
			}
			d.Skills = append(d.Skills, s)
		}
		skillRows.Close()
		p.Domains = append(p.Domains, d)
	}

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

	projQuery := "SELECT id, title, COALESCE(image_url, ''), COALESCE(period, ''), COALESCE(description, ''), COALESCE(skills_human, ''), COALESCE(skills_tech, ''), COALESCE(link_url, ''), hidden FROM project WHERE person_id = $1"
	if !adminEnabled {
		projQuery += " AND NOT hidden"
	}
	projRows, err := db.Query(projQuery+" ORDER BY id ASC", p.Person.ID)
	if err != nil {
		return nil, err
	}
	defer projRows.Close()
	for projRows.Next() {
		var pr Project
		if err := projRows.Scan(&pr.ID, &pr.Title, &pr.ImageURL, &pr.Period, &pr.Description, &pr.SkillsHuman, &pr.SkillsTech, &pr.LinkURL, &pr.Hidden); err != nil {
			return nil, err
		}
		p.Projects = append(p.Projects, pr)
	}

	return &p, nil
}
