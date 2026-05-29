# =============================================================================
# Dockerfile — Containerizzazione Applicazione Web per PMI
# =============================================================================
# Autore:  Edison Pedroza Candado
# Scopo:   Deploy portabile e ripetibile su qualsiasi server
#
# UTILIZZO:
#   docker build -t pmi-app .
#   docker run -d -p 80:3000 --name pmi-app pmi-app
#
# VANTAGGI PER LA PMI:
#   ✅ Identico in sviluppo, staging e produzione
#   ✅ Zero conflitti di dipendenze
#   ✅ Aggiornamento senza interruzione del servizio
#   ✅ Rollback immediato alla versione precedente
# =============================================================================

# ─── STAGE 1: BUILD ──────────────────────────────────────────────────────────
# Usa immagine Node.js leggera (Alpine = solo 5MB vs 900MB standard)
FROM node:20-alpine AS builder

# Metadati dell'immagine
LABEL maintainer="Edison Pedroza Candado <edisonpedroza76@gmail.com>"
LABEL description="Applicazione web per PMI — containerizzata per deploy automatico"
LABEL version="1.0.0"

# Imposta la cartella di lavoro dentro il container
WORKDIR /app

# Copia prima solo i file delle dipendenze (ottimizza la cache di Docker)
# Se package.json non cambia, Docker riusa il layer delle dipendenze → build più veloce
COPY package*.json ./

# Installa solo le dipendenze di produzione (--omit=dev = più leggero)
RUN npm ci --omit=dev && \
    npm cache clean --force

# Copia il resto del codice sorgente
COPY . .

# Esegui la build dell'applicazione (es. TypeScript, bundler, ecc.)
RUN npm run build 2>/dev/null || echo "Nessun comando build definito — skip"


# ─── STAGE 2: PRODUZIONE ─────────────────────────────────────────────────────
# Usa una seconda immagine pulita: così l'immagine finale non include
# gli strumenti di build (riduce la dimensione e la superficie di attacco)
FROM node:20-alpine AS production

# Installa curl per l'health check
RUN apk add --no-cache curl

# Crea un utente non-root per sicurezza (best practice)
# Mai eseguire applicazioni come root in produzione
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copia solo gli artefatti di build dallo stage precedente
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

# Passa all'utente non-root
USER appuser

# Espone la porta dell'applicazione (documentazione, non apre la porta da sola)
EXPOSE 3000

# Health check: Docker verifica ogni 30s che l'app stia rispondendo
# Se fallisce 3 volte, il container viene segnato come "unhealthy"
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Comando di avvio dell'applicazione
CMD ["node", "dist/index.js"]
