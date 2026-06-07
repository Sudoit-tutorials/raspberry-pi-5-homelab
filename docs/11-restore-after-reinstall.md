# Odtwarzanie środowiska po reinstalacji Raspberry Pi

Ta procedura opisuje sposób odtworzenia homelaba po reinstalacji Raspberry Pi z wykorzystaniem Ansible, Restic, rclone oraz plików Docker Compose przechowywanych w repozytorium GitHub.

Główna zasada:

```text
Najpierw przygotowanie systemu i odtworzenie danych,
dopiero potem uruchomienie stacków Docker Compose.
```

Dzięki temu kontenery nie uruchamiają się na pustych katalogach i nie tworzą nowych danych przed przywróceniem backupu.

---

### 1. Przygotowanie systemu i storage

Najpierw ręcznie przygotowuję podstawowe środowisko:

```text
- instalacja Raspberry Pi OS,
- włączenie SSH,
- instalacja i konfiguracja OpenMediaVault,
- zamontowanie dysków,
- sprawdzenie ścieżki /srv/dev-disk-by-uuid-...,
- ustawienie udziałów SMB, jeżeli są używane.
```

OpenMediaVault oraz montowanie dysków zostają krokiem ręcznym, ponieważ OMV odpowiada za warstwę storage, udziały SMB i ścieżki montowania dysków.

Ansible zaczyna pracę dopiero po tym, jak dysk jest zamontowany i dostępna jest ścieżka w stylu:

```text
/srv/dev-disk-by-uuid-...
```

Po reinstalacji sprawdzam aktualny UUID dysku i aktualizuję go w pliku:

```text
ansible/group_vars/homelab.yml
```

Przykład:

```yaml
disk_uuid: "NOWY_UUID_DYSKU"

docker_base_path: "/srv/dev-disk-by-uuid-{{ disk_uuid }}/docker"
docker_data_path: "{{ docker_base_path }}/data"
```

---

### 2. Uwaga dotycząca ścieżek w plikach Compose

W poradnikach dla poszczególnych usług ścieżki są pokazane w wersji ręcznej, z placeholderem:

```text
/srv/dev-disk-by-uuid-CHANGE_ME
```

W takim wariancie po reinstalacji trzeba ręcznie podmienić `CHANGE_ME` w plikach `compose.yaml` na właściwy UUID dysku widoczny w OpenMediaVault.

W wariancie bardziej zautomatyzowanym można przenieść ścieżki do pliku `.env` generowanego przez Ansible i w plikach `compose.yaml` używać zmiennej:

```text
${DOCKER_DATA_PATH}
```

Wtedy po zmianie UUID dysku wystarczy zaktualizować jedną wartość w:

```text
ansible/group_vars/homelab.yml
```

a Ansible wygeneruje poprawne pliki `.env` dla stacków.

Na tym etapie projekt może działać w dwóch trybach:

```text
tryb ręczny:
  /srv/dev-disk-by-uuid-CHANGE_ME w compose.yaml

wariant Ansible:
  ${DOCKER_DATA_PATH} + .env generowany przez Ansible
```

Ja zmieniłem   /srv/dev-disk-by-uuid-CHANGE_ME w compose.yaml na   ${DOCKER_DATA_PATH}


---

### 3. Przygotowanie połączenia SSH po reinstalacji  
  
Po reinstalacji Raspberry Pi może zmienić się klucz hosta SSH na WSL. Jeżeli Raspberry Pi ma ten sam adres IP co wcześniej, komputer administracyjny może nadal pamiętać stary klucz w pliku `known_hosts`.  
  
Dlatego przed uruchomieniem playbooków Ansible wykonuję stały krok przygotowania SSH:  
  
```text  
1. Usuwam stary wpis z known_hosts, jeśli Raspberry Pi ma ten sam adres IP.  
2. Loguję się ręcznie przez SSH.  
3. Kopiuję klucz SSH przez ssh-copy-id.  
4. Dopiero potem uruchamiam Ansible.
```

W praktyce wykonuję:

```
ssh-keygen -f "/home/patryk/.ssh/known_hosts" -R "192.168.0.100"
ssh patryk@192.168.0.100
ssh-copy-id patryk@192.168.0.100
ansible-playbook -i ansible/inventory.ini ansible/playbooks/01-test-connection.yml
```

Dzięki temu Ansible może łączyć się z Raspberry Pi po SSH bez ręcznego wpisywania hasła przy każdym uruchomieniu.

### 4. Uruchomienie Ansible z WSL

Z komputera z Windowsem uruchamiam WSL i przechodzę do katalogu projektu:

```bash
cd ~/projects/raspberry-pi-5-homelab
```

Następnie uruchamiam playbooki Ansible:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/01-test-connection.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/02-install-base-packages.yml --ask-become-pass
ansible-playbook -i ansible/inventory.ini ansible/playbooks/03-install-docker.yml --ask-become-pass
ansible-playbook -i ansible/inventory.ini ansible/playbooks/04-disable-systemd-resolved.yml --ask-become-pass
ansible-playbook -i ansible/inventory.ini ansible/playbooks/05-prepare-docker-directories.yml --ask-become-pass
ansible-playbook -i ansible/inventory.ini ansible/playbooks/06-copy-compose-files.yml --ask-become-pass
ansible-playbook -i ansible/inventory.ini ansible/playbooks/08-install-backup-tools.yml --ask-become-pass
ansible-playbook -i ansible/inventory.ini ansible/playbooks/09-copy-backup-files.yml --ask-become-pass
```

Na tym etapie Ansible przygotowuje Raspberry Pi:

```text
- instaluje podstawowe pakiety,
- instaluje Docker i Docker Compose,
- tworzy katalog docker,
- tworzy katalog docker/data,
- zwalnia port 53 na potrzeby uruchomienia adguard.
- tworzy katalogi dla stacków,
- kopiuje pliki compose.yaml,
- kopiuje konfigurację Prometheusa,
- instaluje Restic i rclone,
- kopiuje skrypt backupowy,
- kopiuje pliki systemd service/timer.
```

Ansible nie powinien jeszcze uruchamiać stacków. Dane usług zostaną odtworzone osobno z backupu Restic.

---

### 5. Ręczne odtworzenie sekretów

Sekrety nie są przechowywane w repozytorium i nie są tworzone przez Ansible.

Po reinstalacji ręcznie odtwarzam pliki:

```text
/root/.restic-password
/home/patryk/.config/rclone/rclone.conf
/opt/homelab-backup/.env
```

Plik:

```text
/root/.restic-password
```

zawiera hasło do repozytorium Restic.

Plik:

```text
/home/patryk/.config/rclone/rclone.conf
```

zawiera konfigurację dostępu do Google Drive przez rclone.

Plik:

```text
/opt/homelab-backup/.env
```

zawiera dane potrzebne do wykonania dumpa bazy MariaDB dla Nextcloud.

Przykładowa zawartość:

```env
NEXTCLOUD_DB_CONTAINER=nextcloud-db
NEXTCLOUD_DB_NAME=nextcloud
NEXTCLOUD_DB_USER=nextcloud
NEXTCLOUD_DB_PASSWORD=CHANGE_ME_NEXTCLOUD_DB_PASSWORD
```

Po utworzeniu pliku ustawiam uprawnienia:

```bash
sudo chown root:root /opt/homelab-backup/.env
sudo chmod 600 /opt/homelab-backup/.env
```

---

### 6. Sprawdzenie snapshotów Restic

Po odtworzeniu sekretów sprawdzam, czy Raspberry Pi widzi snapshoty w repozytorium Restic:

```bash
sudo RCLONE_CONFIG=/home/patryk/.config/rclone/rclone.conf restic \
  -r rclone:gdrive:homelab-backups \
  --password-file /root/.restic-password \
  snapshots
```

Jeżeli lista snapshotów jest widoczna, można przejść do przywracania danych.

---

### 7. Przywrócenie backupu do katalogu tymczasowego

Nie przywracam danych od razu do katalogu produkcyjnego.

Najpierw tworzę katalog tymczasowy:

```bash
sudo mkdir -p /tmp/restic-restore
```

Następnie odtwarzam najnowszy snapshot:

```bash
sudo RCLONE_CONFIG=/home/patryk/.config/rclone/rclone.conf restic \
  -r rclone:gdrive:homelab-backups \
  --password-file /root/.restic-password \
  restore latest \
  --target /tmp/restic-restore
```

Po zakończeniu sprawdzam, gdzie znajduje się odtworzony katalog `docker/data`:

```bash
sudo find /tmp/restic-restore -type d -path "*docker/data"
```

Sprawdzam również, czy został odtworzony dump bazy Nextcloud:

```bash
sudo find /tmp/restic-restore -name "nextcloud-db.sql"
```

---

### 8. Przeniesienie odtworzonych danych do `docker/data`

Po sprawdzeniu zawartości przenoszę dane z katalogu tymczasowego do właściwej lokalizacji `docker/data`.

Przykład:

```bash
sudo rsync -aHAX --info=progress2 \
  /tmp/restic-restore/srv/dev-disk-by-uuid-OLD_UUID/docker/data/ \
  /srv/dev-disk-by-uuid-NEW_UUID/docker/data/
```

Jeżeli UUID dysku po reinstalacji jest taki sam, ścieżki będą podobne.

Jeżeli UUID się zmienił, ścieżkę źródłową można znaleźć poleceniem:

```bash
sudo find /tmp/restic-restore -type d -path "*docker/data"
```

Docelowa ścieżka powinna wskazywać na aktualny katalog danych, np.:

```text
/srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/data/
```

---

### 9. Poprawienie uprawnień

Po przeniesieniu danych uruchamiam playbook ustawiający uprawnienia:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/07-fix-permissions.yml --ask-become-pass
```

Playbook ustawia uprawnienia dla wybranych usług, np.:

```text
- Prometheus,
- Grafana,
- Uptime Kuma.
```

Nie wykonuję agresywnego `chown -R` na całym katalogu `docker/data`, żeby nie naruszyć danych odtworzonych z backupu.

Jeżeli po uruchomieniu stacków konkretna usługa zgłosi problem z zapisem, poprawiam uprawnienia tylko dla jej katalogu.

---

### 10. Sprawdzenie plików Compose przed uruchomieniem

Przed uruchomieniem stacków sprawdzam, czy Ansible skopiował pliki `compose.yaml` do katalogów usług.

Przykład:

```bash
ls -la /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/nextcloud
```

Powinien być widoczny plik:

```text
compose.yaml
```

Jeżeli pliki Compose nadal korzystają z placeholdera:

```text
/srv/dev-disk-by-uuid-CHANGE_ME
```

sprawdzam wystąpienia:

```bash
grep -R "CHANGE_ME" /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker
```

Jeżeli są wyniki, trzeba podmienić `CHANGE_ME` na aktualny UUID dysku.

Jeżeli pliki Compose korzystają ze zmiennej:

```text
${DOCKER_DATA_PATH}
```

sprawdzam, czy w katalogu stacka istnieje plik `.env` wygenerowany przez Ansible:

```bash
ls -la /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/nextcloud/.env
```

---

### 11. Uruchomienie stacków Docker Compose

Stacki uruchamiam z terminala przez `docker compose`, korzystając z plików `compose.yaml` skopiowanych wcześniej przez Ansible.

Nie muszę dodawać stacków ręcznie w Portainerze.

Przykład uruchomienia Portainera:

```bash
cd /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/portainer
sudo docker compose up -d
```

Następnie uruchamiam pozostałe stacki:

```bash
cd /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/adguard-home
sudo docker compose up -d

cd /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/nginx-proxy-manager
sudo docker compose up -d

cd /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/nextcloud
sudo docker compose up -d

cd /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/prometheus-grafana
sudo docker compose up -d

cd /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/uptime-kuma
sudo docker compose up -d
```

Uruchomiłem je w poniższej kolejności, ponieważ lokalne domeny zależą od AdGuard Home i Nginx Proxy Managera.

```text
1. portainer
2. adguard-home
3. nginx-proxy-manager
4. nextcloud
5. prometheus-grafana
6. uptime-kuma
```


---

### 12. Rola Portainera w procedurze restore

W procedurze odtwarzania Portainer nie jest wymagany do uruchomienia stacków.

Źródłem prawdy pozostają pliki `compose.yaml` przechowywane w repozytorium GitHub i kopiowane przez Ansible na Raspberry Pi.

Stacki uruchamiam z terminala za pomocą:

```bash
docker compose up -d
```

Portainer traktuję jako panel administracyjny do:

```text
- podglądu kontenerów,
- sprawdzania logów,
- restartowania usług,
- kontroli stanu środowiska.
```

Dzięki temu nawet jeżeli Portainer jeszcze nie działa, całe środowisko można odtworzyć z terminala.

---

### 13. Import dumpa bazy Nextcloud

Backup obejmuje cały katalog `docker/data` oraz dump bazy MariaDB dla Nextcloud.

Jeżeli po przywróceniu katalogu `docker/data` Nextcloud działa poprawnie, import dumpa może nie być konieczny.

Dump bazy jest planem awaryjnym, gdyby pliki bazy po restore były niespójne.

Jeżeli import jest potrzebny, najpierw znajduję plik:

```bash
sudo find /tmp/restic-restore -name "nextcloud-db.sql"
```

Następnie importuję dump do kontenera bazy:

```bash
sudo docker exec -i nextcloud-db mariadb \
  -u nextcloud \
  -p'CHANGE_ME_NEXTCLOUD_DB_PASSWORD' \
  nextcloud < /tmp/restic-restore/tmp/homelab-backup/nextcloud-db.sql
```

Hasło powinno odpowiadać wartości z pliku:

```text
/opt/homelab-backup/.env
```

---

### 14. Sprawdzenie działania kontenerów

Sprawdzam uruchomione kontenery:

```bash
sudo docker ps
```

Sprawdzam logi konkretnego stacka:

```bash
cd /srv/dev-disk-by-uuid-NOWY_UUID_DYSKU/docker/nextcloud
sudo docker compose logs -f
```

---

### 15. Sprawdzenie usług

Po uruchomieniu stacków testuję:

```text
- Nextcloud,
- AdGuard Home,
- Nginx Proxy Manager,
- Prometheus,
- Grafana,
- Uptime Kuma,
- Portainer.
```

Sprawdzam również lokalne domeny, np.:

```text
nextcloud.lumiere.local
grafana.lumiere.local
prometheus.lumiere.local
uptime.lumiere.local
```

Jeżeli lokalne domeny nie działają, weryfikuję kolejno:

```text
- AdGuard Home,
- wpisy DNS,
- Nginx Proxy Manager,
- certyfikat,
- Tailscale, jeżeli korzystam ze zdalnego dostępu.
```

---

### 16. Troubleshooting: Uptime Kuma nie rozwiązywała lokalnych domen po restore

To nie jest obowiązkowy krok restore, tylko przykład rozwiązania problemu, który może pojawić się przy lokalnych domenach i osobnych sieciach Docker. Po odtworzeniu środowiska Uptime Kuma pokazywała część usług jako niedostępne, mimo że działały poprawnie w przeglądarce.

W monitorach pojawiały się błędy:

```text
getaddrinfo EAI_AGAIN
getaddrinfo ENOTFOUND
queryA ETIMEOUT
```

Oznaczało to problem z rozwiązywaniem lokalnych domen z poziomu kontenera Uptime Kuma.

W moim przypadku AdGuard Home działał poprawnie i rozwiązywał lokalne domeny z poziomu Raspberry Pi. Problem dotyczył kontenera Uptime Kuma, który działał w osobnej sieci Docker.

Najpierw sprawdziłem, czy AdGuard poprawnie rozwiązuje lokalną domenę z poziomu hosta:

```bash
dig @192.168.0.100 grafana.lumiere.local
```

Odpowiedź wskazywała na Raspberry Pi:

```text
grafana.lumiere.local.  10  IN  A  192.168.0.100
```

Następnie sprawdziłem gateway sieci Docker, w której działa Uptime Kuma:

```bash
sudo docker network inspect uptime-kuma_default --format '{{(index .IPAM.Config 0).Gateway}}'
```

W moim przypadku wynik był przykładowo taki:

```text
172.20.0.1
```

Potem przetestowałem rozwiązywanie DNS z tej samej sieci Docker, w której działa kontener Uptime Kuma:

```bash
GW=$(sudo docker network inspect uptime-kuma_default --format '{{(index .IPAM.Config 0).Gateway}}')

sudo docker run --rm \
  --network uptime-kuma_default \
  --dns $GW \
  busybox nslookup grafana.lumiere.local
```

Po wskazaniu gatewaya sieci Docker jako DNS, zapytanie zaczęło zwracać poprawny adres:

```text
Name: grafana.lumiere.local
Address: 192.168.0.100
```

To potwierdziło, że problem nie leżał w AdGuard Home, tylko w sposobie, w jaki kontener Uptime Kuma korzystał z DNS.

Jako rozwiązanie można tymczasowo ustawić w `compose.yaml` Uptime Kuma DNS na aktualny gateway sieci Docker:

```yaml
dns:
  - 172.20.0.1
  - 1.1.1.1
```

Trzeba jednak pamiętać, że adres gateway może się zmienić po wykonaniu:

```bash
sudo docker compose down
```

ponieważ ta komenda usuwa sieć stacka, a Docker może później utworzyć ją z innym adresem.

Dlatego do publicznego pliku `compose.yaml` w repozytorium nie wpisuję na sztywno adresu typu `172.20.0.1`, ponieważ jest zależny od lokalnej konfiguracji Dockera.

Jeżeli chcę mieć bardziej przewidywalne rozwiązanie, mogę zdefiniować dla Uptime Kuma stałą sieć Docker z własnym subnetem i gatewayem:

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3002:3001"
    dns:
      - 172.30.0.1
      - 1.1.1.1
    volumes:
      - ${DOCKER_DATA_PATH}/uptime-kuma/data:/app/data

networks:
  default:
    ipam:
      config:
        - subnet: 172.30.0.0/16
          gateway: 172.30.0.1
```

Takie rozwiązanie sprawia, że gateway sieci Uptime Kuma jest stały i nie zmienia się po ponownym utworzeniu stacka.

Przed zastosowaniem takiego wariantu trzeba jednak upewnić się, że wybrany subnet, np. `172.30.0.0/16`, nie koliduje z innymi sieciami Docker ani z siecią lokalną.

---
### 17. Ręczne odtworzenie Tailscale jako zdalnego dostępu

Po reinstalacji Raspberry Pi ponownie skonfigurowałem Tailscale, ponieważ nowe środowisko systemowe nie korzystało już ze starej autoryzacji urządzenia.

Najpierw zalogowałem się do panelu Tailscale w przeglądarce i uporządkowałem listę urządzeń. Usunąłem stare, nieaktywne wpisy po poprzedniej instalacji Raspberry Pi oraz urządzenia, których nie chciałem już używać do dostępu do homelaba.

Następnie ponownie dodałem Raspberry Pi oraz pozostałe urządzenia, z których chcę mieć dostęp do homelaba przez VPN.


---
### 18. Włączenie timera backupu

Po sprawdzeniu działania środowiska włączam timer backupu:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/10-enable-restic-timer.yml --ask-become-pass
```

Sprawdzam:

```bash
systemctl list-timers | grep restic
```

Można też uruchomić testowy backup ręcznie:

```bash
sudo systemctl start restic-backup.service
```

Po zakończeniu sprawdzam snapshoty:

```bash
sudo RCLONE_CONFIG=/home/patryk/.config/rclone/rclone.conf restic \
  -r rclone:gdrive:homelab-backups \
  --password-file /root/.restic-password \
  snapshots
```

---

## Podsumowanie

Odtworzenie środowiska po reinstalacji Raspberry Pi wygląda następująco:

```text
1. Instaluję Raspberry Pi OS.
2. Konfiguruję SSH.
3. Instaluję i konfiguruję OpenMediaVault.
4. Montuję dyski.
5. Aktualizuję UUID dysku w Ansible.
6. Uruchamiam playbooki Ansible.
7. Ręcznie odtwarzam sekrety.
8. Sprawdzam snapshoty Restic.
9. Odtwarzam backup do katalogu tymczasowego.
10. Kopiuję docker/data do właściwej lokalizacji.
11. Ustawiam uprawnienia.
12. Sprawdzam pliki compose.yaml i ścieżki.
13. Uruchamiam stacki przez docker compose.
14. W razie potrzeby importuję dump bazy Nextcloud.
15. Opcjonalnie konfiguruję Tailscale.
16. Sprawdzam działanie usług.
17. Włączam timer backupu.
18. Wykonuję test backupu po odtworzeniu.
```

Najważniejszy podział ról:

```text
GitHub      → przechowuje dokumentację i konfigurację
Ansible     → przygotowuje system, katalogi, Compose i backup
Restic      → odtwarza dane
Docker      → uruchamia usługi
Portainer   → opcjonalny panel administracyjny
```

