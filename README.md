# Raspberry Pi 5 HomeLab

Projekt domowego środowiska typu **NAS + self-hosted lab** opartego na **Raspberry Pi 5**, **OpenMediaVault**, **Dockerze** oraz prywatnym dostępie przez **Tailscale VPN**.  
  
Celem projektu jest zbudowanie lekkiej alternatywy dla dużych systemów NAS, takich jak TrueNAS Scale. Nie chodzi o budowę serwera klasy enterprise, tylko o praktyczne, energooszczędne środowisko do przechowywania plików, uruchamiania usług kontenerowych i nauki administracji systemami.

Projekt wykorzystuje:  
- Raspberry Pi 5  
- OpenMediaVault  
- Docker / Portainer  
- Nextcloud  
- Tailscale VPN  
- AdGuard Home  
- Nginx Proxy Manager  
- Vaultwarden    
- Grafana
- Uptime Kuma

## Cel projektu  

Chciałem zbudować środowisko, które pozwoli mi:  
- przechowywać pliki lokalnie na własnym sprzęcie,  
- synchronizować dane między urządzeniami,  
- korzystać z prywatnej chmury przez telefon i komputer,  
- uruchamiać własne usługi kontenerowe,  
- testować rozwiązania self-hosted,  
- uczyć się Linuksa, sieci, Dockera, VPN i bezpieczeństwa dostępu.

To środowisko nie ma zastępować dużego serwera produkcyjnego. Ma być praktycznym homelabem, z którego da się realnie korzystać na co dzień.

## Status projektu  
  
Status: w trakcie budowy  
  
Aktualny etap: dokumentowanie środowiska i konfiguracja usług kontenerowych.

## Roadmapa projektu

### Etap 1: Podstawowa instalacja

- ✅ Instalacja Raspberry Pi 5
- ✅ Instalacja OpenMediaVault
- ✅ Konfiguracja dysków
- ✅ Konfiguracja SMB

### Etap 2: Kontenery i prywatna chmura

- ⏳ Instalacja Dockera i Portainera
- ⏳ Instalacja File Browser
- ⏳ Uruchomienie Nextcloud
- ⏳ Konfiguracja Tailscale

### Etap 3: Usługi sieciowe

- ⏳ Uruchomienie AdGuard Home
- ⏳ Konfiguracja Nginx Proxy Manager
- ⏳ Test Vaultwarden

### Etap 4: Monitoring i utrzymanie

- ⏳ Uruchomienie Uptime Kuma
- ⏳ Konfiguracja monitoringu dostępności usług
- ⏳ Uruchomienie Grafany
- ⏳ Przygotowanie dashboardów w Grafanie
- ⏳ Uporządkowanie backupów
- ⏳ Dokumentacja konfiguracji DNS
- ⏳ Automatyzacja aktualizacji kontenerów
- ⏳ Test odtwarzania danych po awarii
  
## Dlaczego Raspberry Pi 5?  

Raspberry Pi 5 dobrze pasuje do takiego projektu, ponieważ:  
  
- pobiera mało energii,  
- zajmuje niewiele miejsca,  
- działa stabilnie jako mały serwer domowy,  
- pozwala uruchomić Dockera i kilka usług self-hosted,  
- dobrze nadaje się do nauki administracji systemami i sieciami.  
  
W porównaniu do TrueNAS Scale takie rozwiązanie jest lżejsze i prostsze sprzętowo, ale nadal pozwala zbudować funkcjonalne środowisko NAS + homelab.

## Architektura projektu  

Planowana architektura:  
```

Raspberry Pi 5  
│  
├── OpenMediaVault  
│ ├── SMB/CIFS  
│ ├── BTRFS / RAID 1  
│ └── zarządzanie dyskami  
│  
├── Docker / Portainer  
│ ├── Nextcloud  
│ ├── AdGuard Home  
│ ├── Nginx Proxy Manager  
│ ├── Vaultwarden  
│ ├── Grafana  
│ └── Uptime Kuma  
│  
└── Tailscale VPN  
└── prywatny zdalny dostęp do usług

```

Dostęp do usług zdalnych będzie realizowany przez **Tailscale**, dzięki czemu usługi nie muszą być wystawione bezpośrednio do internetu.

## Planowana struktura repozytorium

Docelowo repozytorium będzie podzielone na dokumentację, pliki Docker Compose i skrypty pomocnicze.

```
raspberry-pi-5-homelab/
├── README.md
├── .gitignore
├── .env.example
├── docs/
├── docker/
└── scripts/
```

## Dokumentacja

Szczegółowa dokumentacja będzie rozwijana etapami w katalogu [docs/](docs/).

- [OpenMediaVault, dyski i udział SMB](docs/01-openmediavault.md)
- Docker i Portainer
- Nextcloud
- Tailscale
- AdGuard Home
- Nginx Proxy Manager
- Vaultwarden
- File Browser
- monitoring
- backup i odtwarzanie
- lokalny DNS
- bezpieczeństwo
- aktualizacje kontenerów
- troubleshooting

## Pliki Docker Compose

Pliki Docker Compose będą przechowywane w katalogu `docker/`.

Każda usługa będzie miała osobny katalog z własnym plikiem `compose.yaml`.

Planowana struktura:

```
docker/
├── portainer/
│   └── compose.yaml
├── nextcloud/
│   └── compose.yaml
├── adguard-home/
│   └── compose.yaml
├── nginx-proxy-manager/
│   └── compose.yaml
├── vaultwarden/
│   └── compose.yaml
├── grafana/
│   └── compose.yaml
└── uptime-kuma/
    └── compose.yaml
```

## Bezpieczeństwo

W projekcie stosuję kilka podstawowych zasad:

- usługi administracyjne nie są wystawiane bezpośrednio do internetu,
- dostęp zdalny działa przez Tailscale VPN,
- sekrety nie są przechowywane w repozytorium,
- panele administracyjne są dostępne tylko z sieci lokalnej lub VPN,
- dostęp do Docker socket powinien być ograniczony,
- hasła powinny być silne i unikalne.
