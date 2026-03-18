package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"
)

type serviceStatus struct {
	Status string `json:"status"`
	Host   string `json:"host,omitempty"`
	Error  string `json:"error,omitempty"`
}

type healthResponse struct {
	Status   string                   `json:"status"`
	Uptime   string                   `json:"uptime"`
	Services map[string]serviceStatus `json:"services,omitempty"`
}

type app struct {
	startTime time.Time
	db        *database
}

func main() {
	cfg, err := loadConfig()
	if err != nil {
		log.Fatalf("loading config: %v", err)
	}

	a := &app{startTime: time.Now()}

	if cfg.DB.WriteDSN != "" {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		db, err := newDatabase(ctx, cfg.DB.WriteDSN, cfg.DB.ReadDSN)
		cancel()
		if err != nil {
			log.Fatalf("connecting to database: %v", err)
		}
		a.db = db

		logCtx, logCancel := context.WithTimeout(context.Background(), 3*time.Second)
		log.Printf("write pool connected: %s", poolHost(logCtx, db.WritePool))
		logCancel()

		logCtx, logCancel = context.WithTimeout(context.Background(), 3*time.Second)
		log.Printf("read pool connected: %s", poolHost(logCtx, db.ReadPool))
		logCancel()
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /", a.handleHealth)
	mux.HandleFunc("GET /healthz", a.handleHealthz)
	mux.HandleFunc("GET /readyz", a.handleReady)

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           mux,
		ReadTimeout:       5 * time.Second,
		ReadHeaderTimeout: 3 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Printf("listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("shutting down...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("server shutdown error: %v", err)
	}
	if a.db != nil {
		a.db.Close()
	}
	log.Println("stopped")
}

// handleHealth returns a JSON health report with the status of all configured services.
func (a *app) handleHealth(w http.ResponseWriter, r *http.Request) {
	resp := healthResponse{
		Status: "up",
		Uptime: time.Since(a.startTime).Round(time.Second).String(),
	}

	if a.db != nil {
		resp.Services = make(map[string]serviceStatus)

		ws := checkPool(r.Context(), a.db.WritePool)
		resp.Services["postgres-write"] = ws
		if ws.Status != "up" {
			resp.Status = "degraded"
		}

		rs := checkPool(r.Context(), a.db.ReadPool)
		resp.Services["postgres-read"] = rs
		if rs.Status != "up" {
			resp.Status = "degraded"
		}
	}

	code := http.StatusOK
	if resp.Status != "up" {
		code = http.StatusServiceUnavailable
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(resp)
}

// handleHealthz is a lightweight liveness probe (no dependency checks).
func (a *app) handleHealthz(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "ok")
}

// handleReady is the readiness probe — checks write DB connectivity.
func (a *app) handleReady(w http.ResponseWriter, r *http.Request) {
	if a.db != nil {
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()

		if err := a.db.WritePool.Ping(ctx); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprintln(w, "write db unreachable")
			return
		}
	}
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "ok")
}
