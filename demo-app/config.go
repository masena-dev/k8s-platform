package main

import "github.com/kelseyhightower/envconfig"

type config struct {
	Port string `envconfig:"PORT" default:"8080"`
	DB   dbConfig
}

type dbConfig struct {
	WriteDSN string `envconfig:"DATABASE_WRITE_URL"`
	ReadDSN  string `envconfig:"DATABASE_READ_URL"`
}

func loadConfig() (config, error) {
	var cfg config
	if err := envconfig.Process("", &cfg); err != nil {
		return cfg, err
	}
	// Read pool falls back to write DSN when not explicitly configured.
	if cfg.DB.ReadDSN == "" {
		cfg.DB.ReadDSN = cfg.DB.WriteDSN
	}
	return cfg, nil
}
