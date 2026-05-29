# Raspberry Pi 5 HomeLab

Projekt domowego środowiska typu **NAS + self-hosted lab** opartego na **Raspberry Pi 5**, **OpenMediaVault**, **Dockerze** oraz prywatnym dostępie przez **Tailscale VPN**.  
  
Celem projektu jest zbudowanie lekkiej alternatywy dla dużych systemów NAS, takich jak TrueNAS Scale. Nie chodzi o budowę serwera klasy enterprise, tylko o praktyczne, energooszczędne środowisko do przechowywania plików, uruchamiania usług kontenerowych i nauki administracji systemami.

Projekt wykorzystuje:

- **Raspberry Pi 5** jako bazę homelaba
- **OpenMediaVault** do obsługi dysków, udziałów SMB i katalogów pod usługi
- **Docker / Docker Compose** do uruchamiania usług kontenerowych
- **Portainer** do wygodnego zarządzania kontenerami
- **Nextcloud** jako prywatną chmurę plików
- **Tailscale VPN** do bezpiecznego dostępu zdalnego
- **AdGuard Home** jako lokalny DNS, dziennik zapytań i filtr domen
- **Nginx Proxy Manager** jako reverse proxy dla usług lokalnych
- **Prometheus** do zbierania metryk
- **Node Exporter** do monitorowania Raspberry Pi
- **cAdvisor** do monitorowania kontenerów Docker
- **Grafana** do wizualizacji metryk i dashboardów
- **Uptime Kuma** do monitorowania dostępności usług
- **Restic** do tworzenia szyfrowanych backupów
- **rclone** do zapisu backupów w chmurze
- **systemd timer** do automatycznego uruchamiania backupu
- **Ansible** do automatyzacji przygotowania środowiska

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

- ✅ Uruchomienie Prometheus
- ✅ Uruchomienie Node Exporter
- ✅ Uruchomienie cAdvisor
- ✅ Uruchomienie Grafany
- ✅ Dodanie Prometheusa jako źródła danych w Grafanie
- ✅ Przygotowanie dashboardu dla Raspberry Pi
- ✅ Przygotowanie dashboardu dla kontenerów Docker
- ✅ Uruchomienie Uptime Kuma
- ✅ Dodanie monitorów dostępności usług

### Etap 5: Backup i utrzymanie

- ✅ Konfiguracja rclone z Google Drive
- ✅ Inicjalizacja repozytorium Restic w chmurze
- ✅ Testowy backup małego katalogu
- ✅ Test odtwarzania danych
- ✅ Backup katalogu `docker/data`
- ✅ Dump bazy MariaDB dla Nextcloud
- ✅ Skrypt backupowy
- ✅ Automatyzacja przez systemd timer

### Etap 6: Automatyzacja z Ansible  
  
- ⏳ Przygotowanie struktury katalogów Ansible  
- ⏳ Przygotowanie inventory dla Raspberry Pi  
- ⏳ Test połączenia z Raspberry Pi przez Ansible  
- ⏳ Instalacja podstawowych pakietów  
- ⏳ Instalacja Dockera i Docker Compose  
- ⏳ Tworzenie katalogu `docker`  
- ⏳ Tworzenie katalogu `docker/data`  
- ⏳ Tworzenie katalogów dla stacków Docker Compose  
- ⏳ Kopiowanie plików `compose.yaml`
- ⏳ Kopiowanie konfiguracji Prometheusa  
- ⏳ Ustawianie uprawnień katalogów aplikacji  
- ⏳ Instalacja Restic i rclone  
- ⏳ Kopiowanie skryptu backupowego  
- ⏳ Kopiowanie plików systemd service/timer  
- ⏳ Włączenie systemd timer przez Ansible  
  
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
├── Backup i odtwarzanie
│   ├── Restic
│   ├── rclone
│   ├── dump bazy MariaDB dla Nextcloud
│   ├── systemd timer
│   └── test odtwarzania danych do osobnego katalogu
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
└── backup/
└── ansible/
```

## Dokumentacja

Szczegółowa dokumentacja będzie rozwijana etapami w katalogu [docs/](docs/).

- [OpenMediaVault, dyski i udział SMB](docs/01-openmediavault.md)
- [Docker i Portainer](docs/02-docker-portainer.md)
- [Nextcloud](docs/03-nextcloud.md)
- [Tailscale VPN](docs/04-tailscale.md)
- [AdGuard Home](docs/05-adguard-home.md)
- [Nginx Proxy Manager](docs/06-nginx-proxy-manager.md)
- [Monitoring metryk: Prometheus i Grafana](docs/07-prometheus-grafana.md)
- [Monitoring dostępności: Uptime Kuma](docs/08-uptime-kuma.md)
- [backup i odtwarzanie](docs/09-restic-backup.md)
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
