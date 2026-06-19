-- ============================================================
--  GESTIONE ISTRIA — Database di appoggio
--  F.C. Istria (calcio) & Istria Volley (pallavolo) — cassa unica
--  Schema SQL compatibile con SQLite / MySQL / PostgreSQL.
--  Rispecchia il modello dati dell'app web (index.html) ed è
--  pronto per un futuro passaggio a backend con database condiviso.
-- ============================================================

-- ---------- SQUADRE ----------
CREATE TABLE squadre (
    id          VARCHAR(20)  PRIMARY KEY,   -- 'calcio' | 'volley'
    nome        VARCHAR(100) NOT NULL,       -- 'F.C. Istria' | 'Istria Volley'
    sport       VARCHAR(50)  NOT NULL
);

INSERT INTO squadre (id, nome, sport) VALUES
    ('calcio', 'F.C. Istria',   'Calcio'),
    ('volley', 'Istria Volley', 'Pallavolo');

-- ---------- CAMPI / LUOGHI ----------
CREATE TABLE campi (
    id    INTEGER PRIMARY KEY,
    nome  VARCHAR(120) NOT NULL
);

-- ---------- GIOCATORI ----------
-- genere: 'M' (Uomo) | 'F' (Donna)
-- Quote standard: Uomo 30/mese + 20 iscr. · Donna 20/mese + 50 iscr.
CREATE TABLE giocatori (
    id               VARCHAR(20)  PRIMARY KEY,
    nome             VARCHAR(150) NOT NULL,
    squadra_id       VARCHAR(20)  NOT NULL REFERENCES squadre(id),
    genere           CHAR(1)      NOT NULL DEFAULT 'M' CHECK (genere IN ('M','F')),
    quota_mensile    DECIMAL(10,2) NOT NULL DEFAULT 0,
    quota_iscrizione DECIMAL(10,2) NOT NULL DEFAULT 0
);

-- ---------- ISCRIZIONI (una tantum a inizio stagione) ----------
CREATE TABLE iscrizioni (
    id            INTEGER PRIMARY KEY,
    giocatore_id  VARCHAR(20)  NOT NULL REFERENCES giocatori(id),
    stagione      INTEGER      NOT NULL,            -- anno di inizio stagione (es. 2025)
    importo       DECIMAL(10,2) NOT NULL,
    data          DATE         NOT NULL,
    movimento_id  VARCHAR(20)  REFERENCES movimenti(id),
    UNIQUE (giocatore_id, stagione)
);

-- ---------- MOVIMENTI (entrate / uscite) ----------
-- tipo:   'entrata' | 'uscita'
-- classe: 'standard' | 'straordinaria' | 'accessoria'
CREATE TABLE movimenti (
    id           VARCHAR(20)  PRIMARY KEY,
    squadra_id   VARCHAR(20)  NOT NULL REFERENCES squadre(id),
    tipo         VARCHAR(10)  NOT NULL CHECK (tipo   IN ('entrata','uscita')),
    classe       VARCHAR(15)  NOT NULL CHECK (classe IN ('standard','straordinaria','accessoria')),
    categoria    VARCHAR(80)  NOT NULL,
    importo      DECIMAL(10,2) NOT NULL CHECK (importo >= 0),
    data         DATE         NOT NULL,
    note         VARCHAR(255),
    giocatore_id VARCHAR(20)  REFERENCES giocatori(id),  -- valorizzato se è una quota
    mese_quota   CHAR(7)                                 -- 'YYYY-MM' se è una quota mensile
);

-- ---------- PAGAMENTI QUOTE MENSILI ----------
-- Una riga per ogni mese pagato da un giocatore.
-- Collegata al movimento (entrata) generato automaticamente.
CREATE TABLE pagamenti_quote (
    id            INTEGER PRIMARY KEY,
    giocatore_id  VARCHAR(20)  NOT NULL REFERENCES giocatori(id),
    mese          CHAR(7)      NOT NULL,           -- 'YYYY-MM'
    importo       DECIMAL(10,2) NOT NULL,
    data          DATE         NOT NULL,
    movimento_id  VARCHAR(20)  REFERENCES movimenti(id),
    UNIQUE (giocatore_id, mese)
);

-- ---------- EVENTI (calendario: allenamenti / partite) ----------
-- Per le partite: gol_fatti / gol_subiti (NULL se non ancora giocata).
CREATE TABLE eventi (
    id          VARCHAR(20)  PRIMARY KEY,
    squadra_id  VARCHAR(20)  NOT NULL REFERENCES squadre(id),
    tipo        VARCHAR(15)  NOT NULL CHECK (tipo IN ('allenamento','partita')),
    data        DATE         NOT NULL,
    ora         VARCHAR(5),                        -- 'HH:MM'
    campo       VARCHAR(120),
    avversario  VARCHAR(150),                      -- solo per le partite
    gol_fatti   INTEGER,                           -- risultato: gol/punti della squadra
    gol_subiti  INTEGER,                           -- risultato: gol/punti avversario
    note        VARCHAR(255)
);

-- ---------- MARCATORI (solo calcio) ----------
CREATE TABLE marcatori (
    id            INTEGER PRIMARY KEY,
    evento_id     VARCHAR(20)  NOT NULL REFERENCES eventi(id),
    giocatore_id  VARCHAR(20)  NOT NULL REFERENCES giocatori(id),
    gol           INTEGER      NOT NULL DEFAULT 1
);

-- ---------- INDICI ----------
CREATE INDEX idx_mov_squadra  ON movimenti (squadra_id);
CREATE INDEX idx_mov_data     ON movimenti (data);
CREATE INDEX idx_mov_classe   ON movimenti (classe);
CREATE INDEX idx_gio_squadra  ON giocatori (squadra_id);
CREATE INDEX idx_eve_data     ON eventi (data);

-- ============================================================
--  VISTE DI RIEPILOGO
-- ============================================================

-- Saldo per squadra + saldo cassa unica (totale)
CREATE VIEW v_saldi AS
SELECT
    s.id   AS squadra_id,
    s.nome AS squadra,
    COALESCE(SUM(CASE WHEN m.tipo='entrata' THEN m.importo END),0) AS entrate,
    COALESCE(SUM(CASE WHEN m.tipo='uscita'  THEN m.importo END),0) AS uscite,
    COALESCE(SUM(CASE WHEN m.tipo='entrata' THEN m.importo ELSE -m.importo END),0) AS saldo
FROM squadre s
LEFT JOIN movimenti m ON m.squadra_id = s.id
GROUP BY s.id, s.nome;

-- Riepilogo per tipologia (standard / straordinaria / accessoria)
CREATE VIEW v_per_tipologia AS
SELECT
    classe,
    SUM(CASE WHEN tipo='entrata' THEN importo ELSE 0 END) AS entrate,
    SUM(CASE WHEN tipo='uscita'  THEN importo ELSE 0 END) AS uscite
FROM movimenti
GROUP BY classe;

-- Quote: previsto vs incassato per giocatore (su 10 mesi di stagione Set-Giu)
CREATE VIEW v_quote_giocatori AS
SELECT
    g.id, g.nome, g.squadra_id,
    g.quota_mensile,
    COALESCE(SUM(p.importo),0)         AS incassato,
    COUNT(p.id)                        AS mesi_pagati
FROM giocatori g
LEFT JOIN pagamenti_quote p ON p.giocatore_id = g.id
GROUP BY g.id, g.nome, g.squadra_id, g.quota_mensile;
