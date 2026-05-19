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
- Grafana
- Uptime Kuma
- Prometheus

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

- ✅ Instalacja Dockera i Portainera
- ✅ Uruchomienie Nextcloud
- ✅ Konfiguracja Tailscale

### Etap 3: Usługi sieciowe

- ✅ Uruchomienie AdGuard Home
- ✅ Konfiguracja Nginx Proxy Manager

### Etap 4: Monitoring

- ⏳ Uruchomienie Prometheus
- ⏳ Uruchomienie Node Exporter
- ⏳ Uruchomienie cAdvisor
- ⏳ Uruchomienie Grafany
- ⏳ Dodanie Prometheusa jako źródła danych w Grafanie
- ⏳ Przygotowanie dashboardu dla Raspberry Pi
- ⏳ Przygotowanie dashboardu dla kontenerów Docker
- ⏳ Uruchomienie Uptime Kuma
- ⏳ Dodanie monitorów dostępności usług

### Etap 5: Backup i utrzymanie

- ⏳ Uporządkowanie backupów
- ⏳ Backup danych Nextcloud
- ⏳ Backup konfiguracji AdGuard Home
- ⏳ Backup konfiguracji Nginx Proxy Manager
- ⏳ Backup danych Grafany i Prometheusa
- ⏳ Automatyzacja aktualizacji kontenerów
- ⏳ Test odtwarzania danych po awarii

### Etap 6: Automatyzacja z Ansible

- ⏳ Przygotowanie inventory Ansible
- ⏳ Test połączenia z Raspberry Pi
- ⏳ Tworzenie katalogów Dockera przez playbook
- ⏳ Ustawianie uprawnień katalogów aplikacji
- ⏳ Kopiowanie plików Docker Compose
- ⏳ Przygotowanie środowiska pod odtworzenie po reinstalacji
  
## Dlaczego Raspberry Pi 5?  

Raspberry Pi 5 dobrze pasuje do takiego projektu, ponieważ:  
  
- pobiera mało energii,  
- zajmuje niewiele miejsca,  
- działa stabilnie jako mały serwer domowy,  
- pozwala uruchomić Dockera i kilka usług self-hosted,  
- dobrze nadaje się do nauki administracji systemami i sieciami.  
  
W porównaniu do TrueNAS Scale takie rozwiązanie jest lżejsze i prostsze sprzętowo, ale nadal pozwala zbudować funkcjonalne środowisko NAS + homelab.

## Architektura projektu  

```
Planowana architektura:

Raspberry Pi 5
│
├── OpenMediaVault
│   ├── SMB/CIFS
│   ├── BTRFS / RAID 1
│   └── zarządzanie dyskami
│
├── Docker / Portainer
│   ├── Nextcloud
│   ├── AdGuard Home
│   ├── Nginx Proxy Manager
│   ├── Prometheus
│   ├── Grafana
│   └── Uptime Kuma
│
├── Tailscale VPN
│   ├── prywatny zdalny dostęp
│   └── subnet router
│
├── Monitoring
│   ├── Prometheus
│   ├── Node Exporter
│   ├── cAdvisor
│   ├── Grafana
│   └── Uptime Kuma
│
├── Backup i utrzymanie
│   ├── backup danych
│   ├── aktualizacje kontenerów
│   └── test odtwarzania po awarii
│
└── Ansible
    ├── automatyzacja konfiguracji
    └── przygotowanie pod odtworzenie środowiska
```

Dostęp do usług zdalnych będzie realizowany przez **Tailscale**, dzięki czemu usługi nie muszą być wystawione bezpośrednio do internetu.

## Planowana struktura repozytorium

Docelowo repozytorium będzie podzielone na dokumentację, pliki Docker Compose i skrypty pomocnicze.

```
raspberry-pi-5-homelab/
├── README.md
├── docs/
├── docker/
└── scripts/
```

## Dokumentacja

Szczegółowa dokumentacja będzie rozwijana etapami w katalogu [docs/](docs/).

- [OpenMediaVault, dyski i udział SMB](docs/01-openmediavault.md)
- [Docker i Portainer](docs/02-docker-portainer.md)
- [Nextcloud](docs/03-nextcloud.md)
- [Tailscale VPN](docs/04-tailscale.md)
- [AdGuard Home](docs/05-adguard-home.md)
- [Nginx Proxy Manager](docs/06-nginx-proxy-manager.md)
- Monitoring metryk: Prometheus i Grafana
- Monitoring dostępności: Uptime Kuma
- backup i odtwarzanie
- Automatyzacja z Ansible

## Pliki Docker Compose

Pliki Docker Compose będą przechowywane w katalogu [docker](docker/).

Każda usługa będzie miała osobny katalog z własnym plikiem `compose.yaml`.

Planowana struktura:

```
```text
docker/
├── portainer/
│   └── compose.yaml
├── nextcloud/
│   └── compose.yaml
├── adguard-home/
│   └── compose.yaml
├── nginx-proxy-manager/
│   └── compose.yaml
├── prometheus-grafana/
│   ├── compose.yaml
│   └── prometheus.yml
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
