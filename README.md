# Gestione Istria ⚽🏐

Web app per la gestione delle finanze di **F.C. Istria** (calcio) e **Istria Volley** (pallavolo):
due gestioni separate ma con **cassa unica**.

## Come si usa
Apri il file **`index.html`** con un qualsiasi browser (computer o telefono).
Non serve installare nulla e funziona anche offline.

> 📱 Su telefono puoi salvare la pagina nella schermata Home per usarla come un'app.

## Funzioni
- **Riepilogo** — saldo della cassa unica + saldi separati per squadra, grafico andamento mensile e grafici entrate/uscite per categoria.
- **Movimenti** — registra entrate e uscite (con data, squadra, categoria, note). Filtra per squadra dall'alto.
- **Giocatori & Quote** — elenco giocatori, quota stagionale prevista e pagamenti. Ogni pagamento crea automaticamente un'entrata in cassa.
- **Calendario** — allenamenti e partite con campo/luogo e avversario, con gestione dei campi disponibili.
- **Backup** — esporta/importa un backup completo (JSON), esporta i movimenti (CSV) e stampa il riepilogo in PDF.

## Dati
I dati sono salvati **solo su questo dispositivo** (localStorage del browser).
👉 Esporta regolarmente un backup JSON dalla scheda **Backup** per non perderli e per trasferirli su un altro dispositivo.

Per provarla subito: scheda **Backup → "Carica dati di esempio"**.
