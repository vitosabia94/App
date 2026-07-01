# Guida: Calendario condiviso Macchina Pilota (Outlook / Microsoft 365)

Soluzione per gestire in Outlook il calendario della macchina pilota, condividerlo con le
risorse dell'ufficio, vedere insieme disponibilità pilota + colleghi, e trovare in automatico
le date libere per organizzare una nuova prova.

⏱️ Tempo di setup: ~30-40 minuti la prima volta (fatto dall'amministratore Microsoft 365).

---

## Panoramica della soluzione

- **1 cassetta postale condivisa** (`macchina.pilota@tuodominio.it`) con il proprio
  calendario: qui si registrano tutte le prove (data, cliente, note).
- **Tutte le risorse** hanno accesso (lettura/scrittura) a quel calendario.
- **I calendari personali** delle risorse restano quelli che già usano; vengono condivisi
  almeno a livello di "libero/occupato" con i colleghi.
- Un **Calendar Group** in Outlook per vedere pilota + risorse affiancati in un colpo d'occhio.
- Un **flusso Power Automate** che, dato un periodo e le risorse coinvolte in una nuova prova,
  calcola in automatico le date in cui pilota + risorse sono **tutti liberi**.

---

## Parte 1 — Creare la shared mailbox "Macchina Pilota"

1. **Microsoft 365 admin center** → Team e gruppi → **Cassette postali condivise** →
   **Aggiungi cassetta postale condivisa**.
   - Nome: `Macchina Pilota`
   - Email: `macchina.pilota@tuodominio.it`
2. **Aggiungi membri**: tutte le risorse dell'ufficio che devono usare il calendario
   (danno accesso "Full Access" alla cassetta).
3. Per essere sicuri che tutti possano **creare/modificare** eventi (non solo leggerli),
   imposta esplicitamente il permesso sulla cartella Calendario via PowerShell
   (Exchange Online PowerShell):
   ```powershell
   Connect-ExchangeOnline
   # Full Access alla cassetta (necessario per aprirla)
   Add-MailboxPermission -Identity "macchina.pilota@tuodominio.it" -User "mario.rossi@tuodominio.it" -AccessRights FullAccess -AutoMapping $true

   # Permesso "Editor" sul calendario (creare/modificare eventi)
   Set-MailboxFolderPermission -Identity "macchina.pilota@tuodominio.it:\Calendario" -User "mario.rossi@tuodominio.it" -AccessRights Editor
   ```
   Ripeti le due righe per ogni risorsa (o per un gruppo di sicurezza "Ufficio" se preferisci
   assegnare i permessi tutti insieme).
4. **Ogni risorsa aggiunge la cassetta in Outlook**:
   - *Outlook desktop*: con Full Access la cassetta compare in automatico sotto le tue
     cartelle dopo un riavvio di Outlook. In alternativa: File → Apri ed esporta →
     Apri cassetta postale di un altro utente.
   - *Outlook Web*: Calendario → Aggiungi calendario → Da rubrica → cerca
     "Macchina Pilota".

---

## Parte 2 — Convenzione per registrare le prove

Per avere dati coerenti e utili (anche per ricerche future), usa sempre lo stesso schema
quando crei un appuntamento sul calendario pilota:

| Campo | Cosa scrivere |
|---|---|
| **Oggetto** | `Cliente – Tipo prova` (es. `ACME Srl – Test drive`) |
| **Categoria** | una tra: `Test Drive`, `Manutenzione`, `Fiera/Evento`, `Consegna`, `Altro` |
| **Luogo** | sede/indirizzo dove si svolge la prova |
| **Partecipanti** | aggiungi come invitati le **risorse coinvolte** nella prova (non solo
  come promemoria: così l'evento compare automaticamente come "occupato" anche nel loro
  calendario personale — utile per il flusso di ricerca disponibilità nella Parte 5) |
| **Corpo** | template minimo:<br>`Cliente: ...`<br>`Referente/telefono: ...`<br>`Note: ...` |

Le **categorie** non si sincronizzano automaticamente tra account diversi: la prima volta
che accedi alla cassetta condivisa, crea le stesse categorie (stesso nome e colore) con
tasto destro su un appuntamento → *Categorizza* → *Tutte le categorie* → *Nuovo*, così
restano coerenti tra tutte le risorse.

---

## Parte 3 — Vedere insieme calendario pilota e calendari risorse

1. In Outlook: **Calendario** → **Aggiungi calendario** → **Da rubrica** → aggiungi la
   cassetta pilota e i colleghi che vuoi vedere.
2. Crea un **gruppo di calendari** chiamato `Disponibilità Ufficio` che contenga:
   pilota + tutte le risorse (tasto destro sull'elenco calendari a sinistra →
   *Crea nuovo gruppo di calendari*).
3. Attiva la **vista sovrapposta** (overlay) per confrontare a colpo d'occhio chi è libero
   e quando la pilota è impegnata.

> Per vedere il **dettaglio** (oggetto/cliente) del calendario di un collega, e non solo
> "libero/occupato", quel collega deve condividere il proprio calendario con almeno il
> livello "Dettagli completi" (vedi Parte 4).

---

## Parte 4 — Condivisione dei calendari personali tra le risorse

Ogni risorsa, dal proprio Outlook: **Calendario** → **Condividi calendario** → seleziona i
colleghi → livello di permesso consigliato:
- **"Può vedere quando sono occupato"** — minimo indispensabile per il flusso di
  disponibilità della Parte 5.
- **"Dettagli completi"** — se in ufficio si vuole anche leggere l'oggetto degli impegni.

Per farlo in un colpo solo per tutta l'azienda, l'amministratore può assegnare il permesso a
un gruppo di sicurezza via PowerShell, iterando su tutte le mailbox del gruppo, ad esempio:
```powershell
$gruppo = "Ufficio@tuodominio.it"
Get-DistributionGroupMember -Identity $gruppo | ForEach-Object {
    Set-MailboxFolderPermission -Identity "$($_.PrimarySmtpAddress):\Calendario" -User $gruppo -AccessRights Reviewer
}
```

---

## Parte 5 — Flusso Power Automate: trovare le date disponibili

**Obiettivo**: dato un periodo di riferimento e le risorse coinvolte in una nuova prova, il
flusso restituisce le date in cui la pilota **e tutte le risorse selezionate** sono libere.

### Trigger
Consigliato: **Microsoft Forms** — crea un form "Richiesta prova pilota" con i campi:
- Cliente
- Data inizio periodo da valutare
- Data fine periodo da valutare
- Risorse coinvolte (scelta multipla, con le email)

Trigger del flow: *Quando viene inviata una nuova risposta* (connettore Microsoft Forms).
(In alternativa, per una prima prova rapida, usa un trigger manuale "Attiva flusso manualmente".)

### Passi del flow
1. **Get response details** (Forms) — leggi i valori inseriti.
2. **Compose – ElencoPartecipanti**: array con l'email della cassetta pilota +
   le email delle risorse selezionate, es.:
   ```
   union(
     createArray('macchina.pilota@tuodominio.it'),
     split(triggerBody()?['RisorseCoinvolte'], ';')
   )
   ```
3. Azione **Office 365 Outlook → "Get availability of a user (V2)"** (usa l'API
   `getSchedule`):
   - `Schedule`: `outputs('ElencoPartecipanti')`
   - `StartTime`: Data inizio periodo
   - `EndTime`: Data fine periodo
   - `AvailabilityViewInterval`: `1440` (un carattere per giorno)

   L'output restituisce per ciascun indirizzo una stringa `availabilityView` di caratteri:
   `0` = libero, `1` = provvisorio, `2` = occupato, `3` = fuori sede, `4` = lavora altrove.

4. **Initialize variable – GiorniDisponibili** (tipo Array, valore iniziale vuoto).
5. **Compose – NumeroGiorni**:
   ```
   div(sub(ticks(variables('DataFine')), ticks(variables('DataInizio'))), 864000000000)
   ```
6. **Apply to each** su `range(0, outputs('NumeroGiorni'))`:
   - **Set variable – TuttiLiberi** = `true`
   - **Apply to each** mailbox nell'output di *Get availability of a user*:
     - Estrai il carattere del giorno corrente:
       `substring(item()?['availabilityView'], items('Apply_to_each_giorno'), 1)`
     - **Condition**: se il carattere è diverso da `0` → `Set variable TuttiLiberi = false`
   - **Condition**: se `TuttiLiberi = true` →
     `Append to array variable GiorniDisponibili` con
     `addDays(variables('DataInizio'), items('Apply_to_each_giorno'), 'yyyy-MM-dd')`
7. **Esito**: invia il risultato a chi ha fatto la richiesta (email, messaggio Teams, o riga
   scritta in una lista SharePoint/Excel "Richieste prova") con l'elenco `GiorniDisponibili`.
8. *(Opzionale)* crea automaticamente un evento **provvisorio (tentative)** sul calendario
   pilota nella prima data libera trovata, invitando le risorse, da confermare a mano.

### Note tecniche
- Se vuoi considerare "libero" anche lo stato *provvisorio*, cambia la condizione del punto 6
  da "carattere diverso da `0`" a "carattere diverso da `0` **e** diverso da `1`".
- L'azione *Get availability of a user* funziona per gli account nel tenant senza permessi
  aggiuntivi: la disponibilità (libero/occupato) è visibile di default a tutti gli utenti
  interni di un tenant Microsoft 365.

### Alternativa senza Power Automate (per il giorno per giorno)
Per una singola prova da fissare a breve, non serve il flusso: crea un nuovo appuntamento
sul calendario pilota, aggiungi come partecipanti le risorse coinvolte, e apri
**Assistente Pianificazione** (Scheduling Assistant) — mostra subito le fasce libere/occupate
di tutti e propone il primo slot libero comune. Il flusso Power Automate sopra serve quando
si vuole cercare su un intervallo lungo (es. qualche mese) o dare ai colleghi un modo
self-service per richiedere una data senza dover aprire Outlook.

---

## Checklist di setup

- [ ] Shared mailbox `Macchina Pilota` creata, con calendario
- [ ] Permessi calendario (Editor) assegnati a tutte le risorse
- [ ] Categorie standard concordate e create (Test Drive, Manutenzione, Fiera/Evento,
      Consegna, Altro)
- [ ] Calendar Group "Disponibilità Ufficio" creato
- [ ] Calendari personali condivisi tra le risorse (almeno "libero/occupato")
- [ ] Form "Richiesta prova pilota" creato (se si vuole il flusso self-service)
- [ ] Flow Power Automate "Trova date disponibili macchina pilota" costruito e testato
