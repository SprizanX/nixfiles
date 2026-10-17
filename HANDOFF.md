# HANDOFF — адаптация форка nixfiles под личную машину

> Этот файл — задание для новой сессии. Прочитай его целиком, потом проверь репозиторий.
> Задача новой сессии: **проверить, исправить и улучшить** то, что уже сделано, а не начинать заново.

## 1. Что вообще нужно

Есть форк репозитория `redxtech/nixfiles` — NixOS-флейк с оконным менеджером niri и
шеллом Noctalia v5. Он настроен под железу и привычки автора (Gabe Dunn). Нужно
превратить его в **личную систему пользователя** на его собственном железе.

Установка **отложена**: сейчас задача — только файлы конфигурации. Nix на машине
разработки нет (Windows), проверять `nix eval` / `nix flake check` невозможно —
это главный источник рисков.

## 2. Где что лежит

- Локальный путь: `C:\Users\Sans\Documents\Проект по умолчанию\nixfiles`
  (в пути кириллица и пробел — в PowerShell всегда кавычить; `git` требует
  обновления `$env:Path` из Machine+User переменных в начале сессии)
- GitHub: `https://github.com/SprizanX/nixfiles` (origin), upstream `redxtech/nixfiles`
- Ветка: `sprizan/host-setup`
- База: коммит `0bd55ccb` (идентичен upstream) + наши изменения
- Хост: `sprizan`, пользователь: `sans`

## 3. Архитектура репозитория (важно понять до правок)

- **den** (dendritic pattern): всё описывается «аспектами» `den.aspects.<name>`.
  Аспект содержит `settings` (декларации опций хоста), `nixos`, `homeManager`,
  `includes` (другие аспекты) и `perSystem`.
- Аспекты **ленивые**: файл, который никто не включил, не вычисляется. Но мусор
  всё равно надо чистить.
- **flake-file** генерирует `flake.nix` из объявлений `flake-file.inputs.*`,
  разбросанных по файлам рядом с кодом, который их использует.
  `flake.nix` **руками не редактировать**. Пересборка: `nix run .#write-flake`.
- **import-tree** подключает `modules/` и `packages/`.
- Настройки конкретной машины живут в `den.hosts.x86_64-linux.<host>.settings`,
  а опции для них объявляются в `settings` соответствующего аспекта.
- Главные аспекты: `base` (общее) и `workstation` (десктоп). Хост `sprizan`
  включает `sprizan-fs`, `workstation`, `gpu`, `hermes`.

## 4. Железо

| Компонент | Что |
|---|---|
| Мать | MSI A520M-A PRO (UEFI, Secure Boot выключен) |
| CPU | Ryzen 5 5600 — **без встроенного GPU** (никакого prime/offload) |
| GPU | RTX 3080 → `nvidia-open`, `nvidia-drm.fbdev=1`, modesetting |
| RAM | 32 ГБ DDR4-3200 |
| Диск | Fanxiang S880 1 ТБ NVMe (Windows на нём же, dual boot) |
| Сеть | Realtek GbE, Wi-Fi нет |
| Мониторы | 2560×1440@180 (основной), 1920×1080, 1080×1920 (вертикальный) |
| Звук | Focusrite Scarlett 2i2 3rd gen, Fifo AM8, JBL Tune 770NC (BT) |
| Прочее | Flydigi Direwolf 4, Cidoo QK75, Mambasnake M5 Ultra |

Dual boot: Windows остаётся, `C:` ужимается до ~400 ГБ. Windows **не трогаем**:
у него свой 200 МБ ESP, у NixOS — отдельный 1 ГБ ESP, Windows грузится из
меню прошивки (F11). Шифрования (LUKS) нет.

## 5. Принятые решения (не пересматривать без причины)

1. **Никаких секрет-менеджеров.** sops-nix и age вырезаны полностью: все ключи
   были зашифрованы на YubiKey, которого больше нет. Единственное исключение —
   Hermes читает необязательный плейн-файл `~/.hermes/hermes.env`.
2. **`cudaSupport` не привязан к `gpu.nvidia.enable`** — иначе включение видеокарты
   вызывает массовую пересборку nixpkgs. Включается отдельным флагом `gpu.nvidia.cuda`.
3. **Noctalia v5, не v4.** IPC — `noctalia msg <command>`, конфиг — TOML,
   целевой модуль stylix — `stylix.targets.noctalia`. Примеры в интернете
   (oddlama, notohh, Mange) — это **v4**, их синтаксис копировать нельзя.
   Пин флейка: `github:noctalia-dev/noctalia/cachix`, rev `63685992f8`.
4. **Тема**: stylix `base16Scheme` = dracula + `stylix.targets.noctalia`,
   то есть палитра идёт во все приложения. Включать палитру «по обоям» пока не стали.
5. **Док в стиле macOS** — `[dock]` в Noctalia внизу с увеличением.
6. **Раскладки us,ru**, переключение Alt+Shift (в `niri.nix`).
7. **CI, deploy-rs, серверные и сетевые аспекты удалены** — это одна домашняя машина.
8. **AI-стек минимальный**: Hermes CLI + дашборд. Приватные MCP-серверы
   (fastmail, karakeep, kagi, strava, liftosaur, hass) и `cliproxyapi` вырезаны.

## 6. Что уже сделано

**Новое:**
- `modules/hosts/sprizan/sprizan.nix` — хост: настройки, 3 монитора, звук, NVIDIA,
  `specialisation.nvidia-less` (загрузка без драйвера, если что-то сломается)
- `modules/hosts/sprizan/filesystem.nix` — UUID-заглушки + рецепт разметки в комментариях
- `modules/users/sans/sans.nix` — юзер, `initialPassword = "nixos"`, группы

**Переписано/почищено (~35 файлов):**
- `modules/features/gpu.nix` — полностью переписан под nvidia-open + опциональный CUDA
- `modules/features/base/base.nix` — `primaryUser = "sans"`, `Europe/Moscow`,
  `en_US.UTF-8` + `ru_RU.UTF-8`, чистка includes
- `modules/features/base/boot.nix` — таймаут 5 с, `ntfs` в supportedFilesystems
- `modules/features/workstation/bar/noctalia.nix` + `noctalia-config.toml` — док, чистка
- `modules/features/style.nix` — `stylix.targets.noctalia.enable = true`
- `modules/features/workstation/wm/niri.nix` — раскладки us/ru
- `modules/features/base/cli/{cli,config,fish,gpg}.nix`, `modules/{nix,shell,vm,update-pkgs}.nix`,
  `ssh.nix`, `spotify.nix`, `firefox.nix`, `git.nix`, `hermes/*`, `mcp.nix` — вычищены
  секреты, чужие пути, приватные сервисы, чужие аккаунты
- `AGENTS.md`, `readme.md` — переписаны под текущее состояние

**Удалено:** `secrets/`, `.sops.yaml`, `modules/secrets.nix`, хосты bastion/quasar/voyager,
`modules/features/server/**`, `network/**`, `features/network-mounts.nix`, `deploy.nix`,
`ci.nix`, `acme.nix`, `cliproxyapi.nix`, `agentsview/`, `pi-web.nix`, `auto-mount.nix`,
`backup.nix`, `moshi.nix`, `tailscale.nix`, `prime.nix`, `travel.nix`, `keymasq*`,
`workstation/apps/email/` — всего 134 файла.

## 7. Известные риски (проверить в первую очередь)

1. **Нет ни одной проверки сборки.** Ни `nix eval`, ни `nix flake check` не запускались.
   Ожидай опечатки и несуществующие атрибуты.
2. **Имена мониторов угаданы** (`DP-1`, `HDMI-A-1`, `DP-2`). Правильные знает
   только сама машина: `niri msg outputs`.
3. **UUID в `filesystem.nix` — заглушки.** Заполнить после разметки.
4. **`noctalia-config.toml`** — это оригинальный экспорт автора, у которого
   убраны чужие пути и приватные плагины. В нём остались блоки `[widget.*]` и
   `[lockscreen_widgets]` под чужие мониторы/плагины. Проверить, что Noctalia
   не ругается, и вычистить лишнее.
5. **`flake.nix` содержит входы, объявления которых больше нет** (sops-nix, deploy-rs,
   odu, disko, keymasq, drishti). Это безопасно, но перед первой сборкой надо
   сделать `nix run .#write-flake`. Он же уберёт лишнее из `flake.lock`.
6. **Проверить, что не осталось ссылок на необъявленные входы** — искать
   `inputs'.<name>` и `inputs.<name>` и сверять с `flake.nix`.
7. **plymouth + NVIDIA**: если при загрузке чёрный экран — `boot.plymouth.enable = false`.
8. **Realtek GbE**: `r8169` против `r8168`, может понадобиться `boot.kernelModules`.
9. **niri-flake**: используется форк `epireyn/niri-flake` ради
   `xwayland-satellite-unstable`. Переходить на upstream `sodiboo/niri-flake`
   только после проверки, что нужный пакет там есть.
10. **Часть пакетов из chaotic** (`proton-cachyos`, `gamescope_git`, `pwvucontrol_git`,
    `yt-dlp_git`) — вход оставлен намеренно, `useCachy = false`.

## 8. TODO для новой сессии — по порядку

1. Пройтись по всем `modules/**` и найти **синтаксические и семантические ошибки**
   Nix (незакрытые скобки, забытые `;`, несуществующие опции, мёртвые ссылки).
2. Проверить, что каждый аспект из `includes` где-то определён, и что каждый
   `host.settings.*`, который читается, объявлен в `settings` аспекта, который
   хост включает.
3. Сверить опции модуля Noctalia v5 с реальным исходником
   (`nix/home-module.nix`, `nix/nixos-module.nix`, `example.toml` на пине rev) —
   не выдумать ни одного ключа.
4. Проверить `modules/features/workstation/bar/noctalia-config.toml` на соответствие
   схеме (в нем есть `noctalia config validate` при сборке через `checkConfig`).
5. Проверить остальные аспекты workstation на чужие сервисы/аккаунты/пути.
6. Причесать `flake-file.inputs` и список входов.
7. Просмотреть diff целиком и оценить, не сломали ли чего-то в upstream-логике.

## 9. Полезные команды (на машине с Nix)

```fish
# пересобрать flake.nix из объявлений входов
nix run .#write-flake

# проверить конкретную опцию / конфиг
nix eval .#nixosConfigurations.sprizan.config.<путь>

# полная проверка (долго: соберёт всё, включая VM и 60+ пакетов)
nix flake check

# собрать систему без переключения
nix build .#nixosConfigurations.sprizan.config.system.build.toplevel

# форматирование
nix fmt
```

## 10. Правила работы с этим репозиторием

- `flake.nix` руками не править — его генерирует flake-file.
- Коммитить только явные пути: `git add <path>`, не `git add .`.
- Новые файлы перед проверкой стейджить (`git add -N <file>`), иначе Nix их не увидит.
- Комментарии объясняют **почему**, а не **что**.
- Изменения минимальные: не рефакторить то, что не просили.
- Не возвращать sops/age и любые другие секрет-менеджеры.

## 11. Как проходить установку (лестница)

1. Обычный NixOS с USB → разметка по рецепту из `filesystem.nix` → реальные UUID.
2. Скопировать репозиторий на машину, `nix run .#write-flake`.
3. Собрать минимальный конфиг (без Hermes), получить рабочий niri.
4. Включить Noctalia, проверить док и раскладки.
5. Включить Hermes, создать `~/.hermes/hermes.env`.
6. Сменить пароль (`mkpasswd -m sha-512`) и убрать `initialPassword`.
