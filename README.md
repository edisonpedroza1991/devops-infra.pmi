# 🛡️ DevOps Infrastruttura IT per PMI

> **Automazione completa di backup, monitoraggio 24/7 e pipeline CI/CD**  
> Progettato per proteggere le piccole e medie imprese italiane da downtime, perdita di dati ed errori umani nei deploy.

---

## 📋 Cosa fa questo progetto

Questo repository contiene gli strumenti operativi utilizzati nel servizio **Gestione Infrastruttura IT per PMI** — un retainer mensile che automatizza completamente la gestione del server di un'azienda, eliminando i tre rischi più costosi per una PMI:

| Rischio | Costo medio per PMI | Soluzione inclusa |
|---|---|---|
| Perdita di dati (backup assenti) | €5.000 – €50.000 | ✅ Backup automatici giornalieri verificati |
| Downtime non rilevato | €2.000 – €10.000 / giorno | ✅ Monitoraggio 24/7 con allerte WhatsApp |
| Errori nei deploy manuali | €500 – €5.000 / incidente | ✅ Pipeline CI/CD automatica con GitHub Actions |

---

## 🗂️ Struttura del Repository

```
devops-infra-pmi/
│
├── scripts/
│   └── backup.sh          # Script backup automatico con verifica integrità
│
├── .github/
│   └── workflows/
│       └── deploy.yml     # Pipeline CI/CD — deploy automatico su VPS
│
├── Dockerfile             # Containerizzazione app per deploy portabile
│
└── README.md              # Documentazione completa del progetto
```

---

## ⚙️ Componenti Principali

### 1. 🔒 Backup Automatico Giornaliero (`scripts/backup.sh`)

Script Bash professionale che:
- Esegue backup completo dei dati critici ogni giorno alle 02:00
- Verifica l'integrità di ogni backup tramite checksum MD5
- Invia notifica via email al completamento o in caso di errore
- Mantiene gli ultimi **30 giorni** di backup con rotazione automatica
- Registra ogni operazione in un log strutturato con timestamp

```bash
# Esecuzione manuale
chmod +x scripts/backup.sh
./scripts/backup.sh

# Configurazione cron automatica (ogni giorno alle 02:00)
0 2 * * * /path/to/scripts/backup.sh >> /var/log/backup.log 2>&1
```

---

### 2. 🚀 Pipeline CI/CD (`/.github/workflows/deploy.yml`)

Deploy automatico su server VPS ad ogni push sul branch `main`:
- Esegue i test automatici prima di ogni deploy
- Connessione sicura al server tramite SSH con chiavi crittografate
- Zero downtime durante il deploy grazie a rolling update
- Notifica Slack/email al completamento del deploy
- Rollback automatico in caso di fallimento

```
Push → GitHub Actions → Test → Build → Deploy SSH → Verifica → ✅
```

---

### 3. 🐳 Containerizzazione con Docker (`Dockerfile`)

Applicazione containerizzata per:
- Deploy identico in qualsiasi ambiente (sviluppo, staging, produzione)
- Isolamento completo delle dipendenze
- Scalabilità immediata senza riconfigurazioni
- Aggiornamenti senza interruzione del servizio

---

## 📊 Cosa riceve il cliente ogni mese

```
✅  Backup giornalieri verificati        → Protezione totale dei dati
✅  Monitoraggio 24/7 attivo             → Allerta prima che lo notino i clienti  
✅  Deploy automatizzati                 → Zero errori umani, zero blocchi
✅  Gestione continua del server         → Aggiornamenti e sicurezza inclusi
✅  Report mensile 2 pagine in italiano  → Visibilità completa senza tecnicismi
```

---

## 🛠️ Stack Tecnologico

![Linux](https://img.shields.io/badge/Linux-Ubuntu_24.04-E95420?style=flat&logo=ubuntu&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED?style=flat&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?style=flat&logo=github-actions&logoColor=white)
![DigitalOcean](https://img.shields.io/badge/DigitalOcean-VPS-0080FF?style=flat&logo=digitalocean&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-Scripting-4EAA25?style=flat&logo=gnu-bash&logoColor=white)

---

## 💼 Servizio Commerciale

Questo progetto è la base tecnica del servizio **Gestione Infrastruttura IT per PMI**.

**Retainer mensile: €990 / mese — tutto incluso**

> *"Se entro 30 giorni non sei completamente soddisfatto, rimborso integrale. Senza domande."*

**Edison Pedroza Candado**  
Consulente Infrastruttura IT · DevOps Specialist  
📍 Basato in Spagna · Opera con PMI italiane in tutta Europa  
📩 edisonpedroza76@gmail.com  
🔗 [linkedin.com/in/edisonpedroza](https://linkedin.com/in/edisonpedroza)

---

## 📬 Vuoi sapere se posso aiutare la tua azienda?

**Prenota una chiamata gratuita di 20 minuti →** Scrivimi su LinkedIn o via email.  
Rispondo entro 24 ore.

---

*Documentazione aggiornata · Edison Pedroza · 2025*
