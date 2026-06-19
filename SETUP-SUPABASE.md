# Guida: attivare la versione condivisa online (Supabase)

Questa guida ti fa passare dalla versione locale (`index.html`) a quella **condivisa**
(`cloud.html`), dove più persone vedono e modificano la **stessa cassa** da dispositivi
diversi, con login personale e sincronizzazione in tempo reale.

⏱️ Tempo richiesto: ~10 minuti, una volta sola.

---

## 1) Crea il progetto Supabase (gratis)
1. Vai su **https://supabase.com** → **Start your project** → registrati (anche con Google).
2. **New project**:
   - Name: `gestione-istria`
   - Database Password: scegline una e **salvala** (serve solo a Supabase, non all'app)
   - Region: **West EU (Ireland)** o **Central EU (Frankfurt)**
3. Attendi 1-2 minuti che il progetto sia pronto.

## 2) Crea le tabelle
1. Menù a sinistra → **SQL Editor** → **New query**.
2. Apri il file **`schema-supabase.sql`**, copia **tutto** il contenuto e incollalo.
3. Premi **Run** (in basso a destra). Deve comparire "Success".

## 3) Copia le due chiavi del progetto
1. Menù a sinistra → **Project Settings** (l'ingranaggio) → **API**.
2. Copia questi due valori:
   - **Project URL** (es. `https://abcd1234.supabase.co`)
   - **anon public** (una lunga chiave) — è pubblica, si può mettere nel file in sicurezza.

## 4) Inserisci le chiavi nell'app
1. Apri **`cloud.html`** con un editor di testo (Blocco note va bene).
2. In alto, nella sezione **CONFIG**, sostituisci:
   ```js
   const SUPABASE_URL="INCOLLA_QUI_PROJECT_URL";
   const SUPABASE_ANON_KEY="INCOLLA_QUI_ANON_PUBLIC_KEY";
   ```
   con i tuoi valori (lasciando le virgolette). Salva il file.

> In alternativa puoi mandarmi tu i due valori e li inserisco io nel file.

## 5) Crea gli utenti (uno per persona)
1. Menù a sinistra → **Authentication** → **Users** → **Add user** → **Create new user**.
2. Inserisci **email** e **password** della persona e spunta **Auto Confirm User**
   (così può accedere subito senza email di conferma).
3. Ripeti per ogni dirigente.
4. (Consigliato) Per impedire registrazioni esterne: **Authentication → Sign In / Providers
   → Email** e disattiva **Allow new users to sign up**. Così solo tu crei gli account.

## 6) Avvia
1. Apri **`cloud.html`** nel browser (doppio clic) → fai **login** con un utente creato.
2. Al primo accesso la cassa è vuota. Per partire dai dati che hai già nella versione
   locale: vai su **Backup → Importa backup** e carica il file JSON esportato da `index.html`.
   (Oppure **Carica dati di esempio** per fare una prova.)
3. Distribuisci `cloud.html` + `logo.png`/`logo.svg` alle altre persone: ognuno apre il file
   e accede col proprio utente. Tutti vedono gli stessi dati, aggiornati in tempo reale.

---

## Ruoli: amministratori e giocatori
L'app ha due tipi di accesso:

- **Amministratore** — vede e modifica tutto (bilancio, movimenti, quote, certificati, calendario).
  Gli admin sono definiti per email nel file `cloud.html`, nella sezione CONFIG:
  ```js
  const ADMIN_EMAILS=["vitosabia3@gmail.com"];
  ```
  Aggiungi qui le email (separate da virgola) di chi deve avere accesso completo.

- **Giocatore** — chi accede con un'email **non** presente in `ADMIN_EMAILS` entra in **sola lettura**
  e vede soltanto: i **propri** pagamenti quote, il **proprio** certificato medico e il
  **calendario/risultati** della squadra. Non vede bilancio, movimenti né pulsanti di modifica.

### Collegare un account giocatore alla sua scheda
1. Crea l'utente del giocatore in **Authentication → Users** (email + password + Auto Confirm).
2. Da admin, apri la scheda del giocatore (**Giocatori → ✏️**) e inserisci la **stessa email**
   nel campo *"Email account giocatore"*. Salva.
3. Quando il giocatore accede con quell'email, vedrà automaticamente solo i propri dati.

> ⚠️ Nota sicurezza: questa separazione è a livello di interfaccia (come concordato). I dati
> tecnici risiedono in un unico contenitore: è la scelta "semplice". Se in futuro vorrai una
> protezione totale (i giocatori non possono accedere ai dati finanziari nemmeno tecnicamente),
> si può evolvere separando i dati con regole sul server.

## Note utili
- **Backup**: i dati sono nel cloud, ma esporta ogni tanto un JSON come copia di sicurezza.
- **Modifiche contemporanee**: se due persone salvano nello stesso identico momento, vince
  l'ultimo salvataggio. Grazie alla sincronizzazione in tempo reale è una situazione molto rara.
- **Password dimenticata**: il link "Password dimenticata?" invia un'email di reset
  (richiede che l'invio email sia attivo sul progetto Supabase).
- **Versione locale**: `index.html` continua a funzionare da sola, senza internet, come prima.
