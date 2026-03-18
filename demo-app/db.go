package main

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type database struct {
	WritePool *pgxpool.Pool
	ReadPool  *pgxpool.Pool
}

func newDatabase(ctx context.Context, writeDSN, readDSN string) (*database, error) {
	writePool, err := newPool(ctx, writeDSN)
	if err != nil {
		return nil, fmt.Errorf("write pool: %w", err)
	}
	readPool, err := newPool(ctx, readDSN)
	if err != nil {
		writePool.Close()
		return nil, fmt.Errorf("read pool: %w", err)
	}
	return &database{WritePool: writePool, ReadPool: readPool}, nil
}

func newPool(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("parsing config: %w", err)
	}
	cfg.MaxConns = 5
	cfg.MinConns = 2
	return pgxpool.NewWithConfig(ctx, cfg)
}

func (d *database) Close() {
	d.WritePool.Close()
	d.ReadPool.Close()
}

func poolHost(ctx context.Context, pool *pgxpool.Pool) string {
	var host string
	err := pool.QueryRow(ctx,
		"SELECT coalesce(inet_server_addr()::text, 'unix') || ':' || inet_server_port()",
	).Scan(&host)
	if err != nil {
		return ""
	}
	return host
}

func checkPool(ctx context.Context, pool *pgxpool.Pool) serviceStatus {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	if err := pool.Ping(ctx); err != nil {
		return serviceStatus{Status: "down", Error: err.Error()}
	}
	return serviceStatus{Status: "up", Host: poolHost(ctx, pool)}
}
