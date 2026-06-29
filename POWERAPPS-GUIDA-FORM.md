# Power Apps — Galleria + Form (Visualizza / Modifica / Nuovo)

Guida per "Gestione Progetti": una galleria di progetti, una schermata di **dettaglio
in sola lettura**, e **una sola** schermata Form riutilizzata sia per **modificare** una
riga esistente sia per **creare** un nuovo progetto da zero.

## Idea di base

In Power Apps un controllo **Form** (Modulo di modifica, `Edit form`) ha 3 modalità:

| Modalità         | Costante Power Fx | A cosa serve                          |
|------------------|-------------------|---------------------------------------|
| Visualizzazione  | `FormMode.View`   | Mostra i dati in sola lettura         |
| Modifica         | `FormMode.Edit`   | Modifica la riga selezionata          |
| Nuovo            | `FormMode.New`    | Crea una nuova riga (campi vuoti)     |

Useremo **3 schermate**:

1. `scrGalleria` — la pagina principale con la galleria + pulsante **"+ Nuovo progetto"**.
2. `scrDettaglio` — il form in **sola lettura** della riga cliccata + pulsante **"Modifica"**.
3. `scrForm` — **una sola** schermata Form usata sia per **Modifica** sia per **Nuovo**.

Origine dati di esempio: una tabella/lista chiamata **`Progetti`** (SharePoint, Dataverse,
SQL... il principio non cambia). Sostituisci `Progetti` con il nome reale.

---

## 1) Schermata Galleria — `scrGalleria`

### Galleria `galProgetti`
- **Items:**
  ```powerfx
  Progetti
  ```
  (oppure con filtri, es. `Filter(Progetti, ...)`)

- **OnSelect della galleria** (o di un'icona/pulsante "dettaglio" dentro la card):
  ```powerfx
  // memorizzo la riga cliccata e vado al dettaglio in sola lettura
  Set(varProgetto, ThisItem);
  Navigate(scrDettaglio, ScreenTransition.Cover)
  ```
  > `ThisItem` esiste solo **dentro** la galleria. Per questo salviamo la riga in
  > `varProgetto`, così è disponibile anche nelle altre schermate.

### Pulsante "+ Nuovo progetto" (in alto a destra)
- **OnSelect:**
  ```powerfx
  // modalità "Nuovo": nessuna riga selezionata, form a campi vuoti
  Set(varProgetto, Blank());
  Set(varModalita, FormMode.New);
  Navigate(scrForm, ScreenTransition.Cover)
  ```

---

## 2) Schermata Dettaglio (sola lettura) — `scrDettaglio`

Aggiungi un controllo **Modulo di modifica** (Form) e chiamalo `frmDettaglio`.

- **DataSource:**
  ```powerfx
  Progetti
  ```
- **Item:**
  ```powerfx
  varProgetto
  ```
- **DefaultMode:**
  ```powerfx
  FormMode.View
  ```
  Così il form mostra i dati ma **non** è modificabile.

Aggiungi i campi che vuoi vedere (Nome, Plant, PM, Sponsor, Stato, link cartella...)
tramite **Modifica campi** sul form.

### Pulsante "Modifica"
- **OnSelect:**
  ```powerfx
  // riuso la stessa riga, ma apro la schermata Form in modalità Modifica
  Set(varModalita, FormMode.Edit);
  Navigate(scrForm, ScreenTransition.Cover)
  ```

### Pulsante "Indietro" (opzionale)
- **OnSelect:**
  ```powerfx
  Back()
  ```

---

## 3) Schermata Form — `scrForm` (Modifica **e** Nuovo)

Questa è la schermata "a doppio uso". Aggiungi un **Modulo di modifica** `frmProgetto`.

- **DataSource:**
  ```powerfx
  Progetti
  ```
- **Item:**
  ```powerfx
  varProgetto
  ```
  (in modalità Nuovo `varProgetto` è `Blank()`, quindi i campi partono vuoti)

- **DefaultMode:**
  ```powerfx
  varModalita
  ```
  È qui la magia: la stessa schermata diventa **Nuovo** o **Modifica** a seconda
  della variabile impostata prima del `Navigate`.

### Titolo dinamico (etichetta in alto)
- **Text:**
  ```powerfx
  If(varModalita = FormMode.New, "Nuovo progetto", "Modifica progetto")
  ```

### Pulsante "Salva"
- **OnSelect:**
  ```powerfx
  SubmitForm(frmProgetto)
  ```
- **DisplayMode** (opzionale, si attiva solo se ci sono modifiche valide):
  ```powerfx
  If(frmProgetto.Valid && frmProgetto.Unsaved, DisplayMode.Edit, DisplayMode.Disabled)
  ```

### Form `frmProgetto` — **OnSuccess** (dopo salvataggio riuscito)
```powerfx
// aggiorno la riga selezionata con quanto appena salvato e torno indietro
Set(varProgetto, frmProgetto.LastSubmit);
Notify("Progetto salvato", NotificationType.Success);
Navigate(scrGalleria, ScreenTransition.UnCover)
```
> Se preferisci tornare al dettaglio dopo una **modifica**, usa:
> ```powerfx
> Navigate(If(varModalita = FormMode.New, scrGalleria, scrDettaglio));
> ```

### Form `frmProgetto` — **OnFailure** (opzionale)
```powerfx
Notify("Errore nel salvataggio: " & frmProgetto.Error, NotificationType.Error)
```

### Pulsante "Annulla"
- **OnSelect:**
  ```powerfx
  ResetForm(frmProgetto);
  Back()
  ```

---

## Riepilogo del flusso

```
scrGalleria
 ├─ clic su item        → Set(varProgetto, ThisItem)            → scrDettaglio (View)
 └─ "+ Nuovo progetto"  → Set(varModalita, FormMode.New),
                          Set(varProgetto, Blank())             → scrForm (New)

scrDettaglio (frmDettaglio: DefaultMode = View, Item = varProgetto)
 └─ "Modifica"          → Set(varModalita, FormMode.Edit)       → scrForm (Edit)

scrForm (frmProgetto: DefaultMode = varModalita, Item = varProgetto)
 └─ "Salva" → SubmitForm → OnSuccess → torna a galleria/dettaglio
```

## Variabili usate

| Variabile      | Dove si imposta                        | Significato                          |
|----------------|----------------------------------------|--------------------------------------|
| `varProgetto`  | OnSelect galleria / "Nuovo"            | La riga selezionata (o `Blank()`)    |
| `varModalita`  | "+ Nuovo" e "Modifica"                 | `FormMode.New` oppure `FormMode.Edit`|

## Note utili

- **Non** serve duplicare il form: una sola `scrForm` gestisce sia creazione che modifica.
  Il segreto è `DefaultMode = varModalita` e `Item = varProgetto`.
- `frmProgetto.LastSubmit` contiene la riga appena salvata (utile per aggiornare il
  dettaglio senza ricaricare l'origine dati).
- Se l'origine dati è SharePoint/Dataverse, i campi di tipo Choice/Lookup vengono
  gestiti automaticamente dal Form: usa il pulsante **"Modifica campi"** per aggiungerli.
- Per il link "Cartella progetto" (campo URL) usa `Launch(varProgetto.UrlCartella)`
  su un pulsante nella schermata di dettaglio.
```
