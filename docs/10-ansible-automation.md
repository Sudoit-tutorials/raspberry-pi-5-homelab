# Automatyzacja backupu z Ansible

W tym etapie przygotowałem podstawową automatyzację z wykorzystaniem Ansible.

Ansible nie odtwarza jeszcze całego homelaba jednym poleceniem, ale automatyzuje powtarzalne kroki potrzebne po reinstalacji Raspberry Pi.

Na tym etapie przygotowałem playbooki, które odpowiadają za:

- instalację podstawowych pakietów,
- instalację Dockera i Docker Compose,
- utworzenie struktury katalogów `docker` i `docker/data`,
- utworzenie katalogów dla stacków Docker Compose,
- kopiowanie plików `compose.yaml`,
- kopiowanie konfiguracji Prometheusa,
- ustawienie wybranych uprawnień katalogów aplikacji,
- instalację Restic i rclone,
- kopiowanie skryptu backupowego,
- kopiowanie plików `systemd service/timer`,
- włączenie `systemd timer` dla backupu.

Dane usług są odtwarzane osobno z backupu Restic. Dzięki temu kontenery nie są uruchamiane na pustych katalogach przed przywróceniem danych.

---

## Krok 1: Przygotowanie Ansible w WSL

Ansible uruchamiam z komputera z Windowsem przez WSL.

Najpierw sprawdziłem dostępność WSL:

```powershell
wsl -l -v
```

Następnie uruchomiłem Ubuntu w WSL i zainstalowałem Ansible:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install ansible -y
```

Po instalacji sprawdziłem wersję:

```bash
ansible --version
ansible-playbook --version
```

Sprawdziłem też połączenie SSH z Raspberry Pi:

```bash
ssh patryk@192.168.0.100
```

---

## Krok 2: Klonowanie repozytorium projektu

W WSL przygotowałem katalog na projekty:

```bash
cd ~
mkdir -p projects
cd projects
```

Następnie sklonowałem repozytorium:

```bash
git clone https://github.com/Sudoit-tutorials/raspberry-pi-5-homelab.git
cd raspberry-pi-5-homelab
```

Repozytorium w WSL jest źródłem plików, które Ansible kopiuje na Raspberry Pi.

Na Raspberry Pi nie kopiuję całego repozytorium. Ansible przenosi tylko potrzebne pliki, między innymi:

```text
compose.yaml
prometheus.yml
backup-homelab.sh
restic-backup.service
restic-backup.timer
```

---

## Krok 3: Założenia po stronie Raspberry Pi

Przed uruchomieniem Ansible Raspberry Pi miało już przygotowane:

```text
- Raspberry Pi OS,
- działające SSH,
- użytkownika patryk,
- OpenMediaVault,
- zamontowany dysk w /srv/dev-disk-by-uuid-...
```

OpenMediaVault, montowanie dysków, udziały SMB oraz Tailscale zostawiłem jako kroki ręczne.

Ansible uruchamiam dopiero wtedy, gdy dysk jest zamontowany i dostępna jest ścieżka:

```text
/srv/dev-disk-by-uuid-...
```

---

## Krok 4: Struktura katalogów Ansible

W repozytorium przygotowałem strukturę katalogów:

```text
ansible/
├── inventory.ini
├── group_vars/
│   └── homelab.yml
└── playbooks/
    ├── 01-test-connection.yml
    ├── 02-install-base-packages.yml
    ├── 03-install-docker.yml
    ├── 04-prepare-docker-directories.yml
    ├── 05-copy-compose-files.yml
    ├── 06-fix-permissions.yml
    ├── 07-install-backup-tools.yml
    ├── 08-copy-backup-files.yml
    └── 09-enable-restic-timer.yml
```

---

## Krok 5: Inventory Ansible

Przygotowałem plik:

```text
ansible/inventory.ini
```

Zawartość:

[`ansible/inventory.ini`](../ansible/inventory.ini)

Plik inventory definiuje hosta Raspberry Pi, z którym łączy się Ansible. W tym miejscu ustawiam adres IP Raspberry Pi oraz użytkownika SSH używanego do uruchamiania playbooków.

Jeżeli Raspberry Pi dostanie inny adres IP, wystarczy zmienić wartość `ansible_host`.

---

## Krok 6: Zmienne projektu

Przygotowałem plik:

```text
ansible/group_vars/homelab.yml
```

Zawartość:
  
[`ansible/group_vars/homelab.yml`](../ansible/group_vars/homelab.yml)

Plik zawiera zmienne wspólne dla środowiska homelab, między innymi UUID dysku, ścieżki `docker_base_path` i `docker_data_path`, listę stacków Docker Compose oraz ścieżki do plików backupu.

Wartość:

```yaml
disk_uuid: "CHANGE_ME"
```

podmieniam na UUID dysku widoczny w OpenMediaVault.

W poradnikach dla poszczególnych usług ścieżki są pokazane w wersji ręcznej, z placeholderem:

```text
/srv/dev-disk-by-uuid-CHANGE_ME
```

W takim wariancie trzeba ręcznie podmienić `CHANGE_ME` w plikach `compose.yaml`.

Docelowo można pójść krok dalej i używać zmiennej:

```text
${DOCKER_DATA_PATH}
```

w plikach Compose. Wtedy Ansible może wygenerować pliki `.env` dla stacków na podstawie zmiennej `disk_uuid`.

Na tym etapie zostawiłem oba warianty:

```text
tryb ręczny      → /srv/dev-disk-by-uuid-CHANGE_ME w compose.yaml
wariant Ansible  → ${DOCKER_DATA_PATH} + .env generowany przez Ansible
```

Dzięki temu po reinstalacji Raspberry Pi i ewentualnej zmianie UUID dysku wystarczy zaktualizować jedną wartość:

```
disk_uuid: "NOWY_UUID_DYSKU"
```

a następnie uruchomić playbook Ansible.

---

## Krok 7: Test połączenia

Przygotowałem logowanie SSH z kluczem:

```bash
ssh-keygen -t ed25519 -C "patryk@lordran"
ssh-copy-id patryk@192.168.0.100
```

Sprawdziłem logowanie:

```bash
ssh patryk@192.168.0.100
```

Następnie uruchomiłem test Ansible z przygotowanego ku temu playbooka.

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/01-test-connection.yml
```

Zawartość:

[`ansible/playbooks/01-test-connection.yml`](../ansible/playbooks/01-test-connection.yml)

Playbook służy do sprawdzenia, czy Ansible poprawnie łączy się z Raspberry Pi przez SSH. To pierwszy test przed uruchamianiem kolejnych kroków automatyzacji.

Dodatkowo można wykonać test modułem `ping`:

```bash
ansible raspberrypi -i ansible/inventory.ini -m ping
```

Poprawny wynik powinien zawierać:

```text
pong
```

---

## Krok 8: Instalacja podstawowych pakietów

Przygotowałem playbook:

```text
ansible/playbooks/02-install-base-packages.yml
```

Zawartość:

[`ansible/playbooks/02-install-base-packages.yml`](../ansible/playbooks/02-install-base-packages.yml)

Playbook instaluje podstawowe pakiety administracyjne potrzebne do dalszej konfiguracji systemu, między innymi `curl`, `wget`, `git`, `mc`, `htop`, `nano` i narzędzia wymagane przez kolejne etapy.

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/02-install-base-packages.yml --ask-become-pass --check
```

---

## Krok 9: Instalacja Dockera i Docker Compose

Przygotowałem playbook:

```text
ansible/playbooks/03-install-docker.yml
```

Zawartość:

[`ansible/playbooks/03-install-docker.yml`](../ansible/playbooks/03-install-docker.yml)

Playbook instaluje Docker oraz Docker Compose plugin, uruchamia usługę Dockera i dodaje użytkownika Ansible do grupy `docker`.

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/03-install-docker.yml --ask-become-pass --check
```


---

## Krok 10: Odblokowanie portu 53

Port 53 powinien być wolny, dzięki czemu będę mógł uruchomić później adguarda. Statyczny plik **/etc/resolv.conf** zostawiłem z publicznymi DNS-ami, żeby Raspberry Pi nadal mogło pobierać pakiety i obrazy Docker przed uruchomieniem AdGuard Home.

Przygotowałem playbook:

```text
ansible/playbooks/04-disable-systemd-resolved.yml
```

Zawartość:

[`ansible/playbooks/04-disable-systemd-resolved.yml`](../ansible/playbooks/04-disable-systemd-resolved.yml)

Uruchomiłem go w trybie testowym:

```
ansible-playbook -i ansible/inventory.ini ansible/playbooks/04-disable-systemd-resolved.yml --ask-become-pass --check
```


---

## Krok 11: Przygotowanie katalogów Docker

Przygotowałem playbook:

```text
ansible/playbooks/05-prepare-docker-directories.yml
```

Zawartość:

[`ansible/playbooks/05-prepare-docker-directories.yml`](../ansible/playbooks/05-prepare-docker-directories.yml)

Playbook tworzy główną strukturę katalogów dla Dockera, w tym katalog `docker`, katalog `docker/data`, katalogi dla stacków Docker Compose oraz wybrane katalogi danych usług.

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/05-prepare-docker-directories.yml --check
```

---

## Krok 12: Kopiowanie plików Compose i konfiguracji Prometheusa

Przygotowałem playbook:

```text
ansible/playbooks/06-copy-compose-files.yml
```

Zawartość:

[`ansible/playbooks/06-copy-compose-files.yml`](../ansible/playbooks/06-copy-compose-files.yml)

Playbook kopiuje pliki `compose.yaml` z repozytorium do odpowiednich katalogów na Raspberry Pi. Kopiuje również konfigurację Prometheusa i generuje pliki `.env` dla stacków, zawierające między innymi `DOCKER_BASE_PATH` oraz `DOCKER_DATA_PATH`.

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/06-copy-compose-files.yml --check
```

Dzięki temu definicje stacków są przechowywane w GitHubie, a Raspberry Pi otrzymuje aktualne pliki Compose podczas uruchomienia playbooka.

---

## Krok 13: Ustawienie uprawnień dla wybranych usług

Przygotowałem playbook:

```text
ansible/playbooks/07-fix-permissions.yml
```

Zawartość:

[`ansible/playbooks/07-fix-permissions.yml`](../ansible/playbooks/07-fix-permissions.yml)

Playbook ustawia uprawnienia dla wybranych katalogów danych usług, między innymi Prometheusa, Grafany i Uptime Kuma. Dzięki temu kontenery mają dostęp do swoich katalogów po odtworzeniu danych z backupu.

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/07-fix-permissions.yml --check
```

Na tym etapie nie wykonuję agresywnego `chown -R` na całym `docker/data`, żeby nie naruszyć danych odtworzonych z backupu.

---

## Krok 14: Instalacja Restic i rclone

Przygotowałem playbook:

```text
ansible/playbooks/08-install-backup-tools.yml
```

Zawartość:

[`ansible/playbooks/08-install-backup-tools.yml`](../ansible/playbooks/08-install-backup-tools.yml)

Playbook instaluje narzędzia backupowe Restic i rclone. Restic odpowiada za tworzenie i odtwarzanie szyfrowanych snapshotów, a rclone za komunikację z Google Drive.

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/08-install-backup-tools.yml --check
```

---

## Krok 15: Kopiowanie skryptu backupowego i plików systemd

Przygotowałem playbook:

```text
ansible/playbooks/09-copy-backup-files.yml
```

Zawartość:

[`ansible/playbooks/09-copy-backup-files.yml`](../ansible/playbooks/09-copy-backup-files.yml)

Playbook kopiuje skrypt backupowy oraz pliki `systemd service` i `systemd timer` na Raspberry Pi. Przygotowuje w ten sposób automatyczne uruchamianie backupu.

```text
/opt/homelab-backup/backup-homelab.sh
/etc/systemd/system/restic-backup.service
/etc/systemd/system/restic-backup.timer
```

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/09-copy-backup-files.yml --check
```

---

## Krok 16: Włączenie timera Restic

Przygotowałem playbook:

```text
ansible/playbooks/10-enable-restic-timer.yml
```

Zawartość:

[`ansible/playbooks/10-enable-restic-timer.yml`](../ansible/playbooks/10-enable-restic-timer.yml)

Playbook przeładowuje konfigurację `systemd`, włącza i uruchamia timer `restic-backup.timer`, który odpowiada za cykliczne wykonywanie backupu.

Uruchomiłem go w trybie testowym:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/10-enable-restic-timer.yml --check
```

Status timera sprawdziłem poleceniem:

```bash
systemctl list-timers | grep restic
```

---

## Czego Ansible jeszcze nie robi

Na tym etapie Ansible nie wykonuje:

```text
- instalacji OpenMediaVault,
- konfiguracji dysków w OMV,
- montowania dysków,
- konfiguracji udziałów SMB,
- konfiguracji Tailscale,
- konfiguracji rclone Google Drive,
- tworzenia /root/.restic-password,
- tworzenia /opt/homelab-backup/.env,
- przywracania backupu Restic,
- uruchamiania stacków przed restore danych.
```

Te elementy zostawiłem jako kroki ręczne albo jako potencjalny kolejny etap automatyzacji.

---

## Miejsce Ansible w procedurze restore

Po reinstalacji Raspberry Pi planowana procedura wygląda tak:

```text
1. Instaluję Raspberry Pi OS.
2. Konfiguruję SSH.
3. Instaluję i konfiguruję OpenMediaVault.
4. Montuję dyski.
5. Konfiguruję Tailscale.
6. W WSL uruchamiam Ansible.
7. Ansible instaluje pakiety, Docker, Docker Compose, Restic i rclone.
8. Ansible tworzy katalogi docker i docker/data.
9. Ansible kopiuje compose.yaml, prometheus.yml, skrypty backupowe i pliki systemd.
10. Ansible ustawia wybrane uprawnienia katalogów usług.
11. Ręcznie odtwarzam sekrety:
    - /root/.restic-password
    - /home/patryk/.config/rclone/rclone.conf
    - /opt/homelab-backup/.env
12. Sprawdzam snapshoty Restic.
13. Odtwarzam backup do katalogu tymczasowego.
14. Kopiuję przywrócone docker/data do właściwej lokalizacji.
15. Weryfikuję i ewentualnie poprawiam uprawnienia.
16. Uruchamiam stacki Docker Compose.
17. Sprawdzam usługi.
18. Włączam timer backupu.
```

Najważniejsza zasada:

```text
Najpierw restore danych, dopiero potem uruchomienie stacków.
```

Dzięki temu kontenery nie startują na pustych katalogach i nie tworzą nowych danych przed przywróceniem backupu.

---

## Podsumowanie

W tym etapie przygotowałem praktyczne wykorzystanie Ansible w projekcie homelabowym.

Ansible automatyzuje przygotowanie Raspberry Pi po reinstalacji systemu, ale nie zastępuje backupu i nie przechowuje sekretów.

Podział ról wygląda następująco:

```text
GitHub  → przechowuje pliki Compose, konfiguracje i playbooki
Ansible → przygotowuje system, katalogi, uprawnienia i backup
Restic  → odpowiada za odtwarzanie danych
Docker  → uruchamia usługi
```
