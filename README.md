### Auto Skill Bootstrap

#### Справка от автора "на пальцах"
Главная идея была в том, что бы агент поняв о чем задача - сперва нашел подходящие "бест практишь", а потом начал с вами её планировать. Определился с языками? - сходил нашел скилы под них.

Что я накрутил - агент анализирует запрос пользователя и выявляет домены и потребности знаний по ним, а затем топает в skills.sh и ищет там подходящие. Есть allow-list (настраиваемый) от крупных поставщиков (типа антропиков), чьи скилы он ставит автоматом. 
Другие подходящие скилы он предлагает к установке, показывая на выбор - вот есть 3 скила под эту потребность, 4 скила вот под эту - выбери, друг, что мне тебе установить.

Анализирует какие скилы уже стоят в проекте. Также он анализирует запросы и смотрит появился ли в нем Новая потребность.

Что бы не перегружать контекст навыками (выделил 4 стадии проекта: ознакомление, исследование, кодинг, тестинг - для каждой стадии он свои домены определяет). Вся эта петрушка с инженерным уклоном (потому что у нас в основном задачи на разработку)... но вроде он ловит и не инженерные задачи и предлагает скилы.

Поиски, сравнения и прочее - реализованы через скрипты, так что токенов особо не жрут. Агент работает только с запросом пользователя (просто держа в уме когда надо задействовать эту схему) и со списком доменов и "типовых потребностей" (список штук на 100 где то классических инженерных.. но может и что то своё добавить).

Думаю там, где ты сам профи и знаешь предметную область, то твой глаз или твой самописный скил может быть лучше публичного.
НО если ты не профи, то мне кажется такой скил может улучшить результат по сравнению со "знаниями сетки по умолчанию"

Также "в комплекте" лежит базовый навык от ресурса skills.sh (разработчик вроде vercel-lab, крупная ит-компания), который позволяет искать навыки по запросу пользователя в произвольном формате

## Правильное описание
`auto-skill-bootstrap` — это детерминированный “pre-flight” механизм, который:

- **инвентаризирует** уже имеющиеся в проекте навыки (skills) в манифест
- **сопоставляет** задачу с набором “capabilities” (что нужно уметь для выполнения)
- **находит пробелы** (какие capabilities не покрыты текущими skills)
- **ищет кандидатов** на `skills.sh` через Skills CLI (`npx skills find ...`)
- **фильтрует** кандидатов по trust policy (allowlist)
- **фиксирует состояние** (state) и формирует список кандидатов (candidates)
- **опционально** устанавливает только allowlisted навыки (без “угадывания”)

Важно: по умолчанию дизайн “fail-closed” — если для нужной capability есть только **не-доверенные** кандидаты, механизм **блокирует** продолжение и требует явного решения пользователя.

### Где лежат файлы в этом проекте

- **Правило (always apply)**: `rules/auto-skill-bootstrap.mdc`
- **Навык**: `skills/auto-skill-bootstrap/`
  - `SKILL.md` — описание процесса и команд
  - `bin/update-manifest.py` — генерация манифеста текущих skills
  - `bin/auto-skill-bootstrap.py` — оценка покрытия, поиск кандидатов, политика доверия, (опционально) установка allowlisted
  - `capabilities.json` — словарь capabilities → keywords/queries
  - `trust-policy.json` — trust policy (allowlist/denylist)
  - `state.json` — “память” последнего прогона (идемпотентность + решения)
  - `candidates.json` — кандидаты, найденные по capabilities

### Канонические пути, которые ожидают скрипты

Скрипты в `bin/` жёстко ориентируются на расположение под `.cursor/skills/...`:

- `.cursor/skills/skills-manifest.json`
- `.cursor/skills/auto-skill-bootstrap/{capabilities.json,trust-policy.json,state.json,candidates.json}`

В этой песочнице файлы навыка лежат в `skills/` и `rules/` (как “зеркало”). Если запускать скрипты без адаптации путей, они будут искать/писать данные в `.cursor/skills/...`.

### Основная идея: “capabilities coverage” вместо угадываний

Механизм заставляет агента **не выдавать уверенные рекомендации и не лезть в реализацию**, пока не проверено, что в проекте есть нужные “скиллы” (или осознанно решено работать без них).

Правило (`rules/auto-skill-bootstrap.mdc`) вводит “gating”:

- **Gate A (Planning Gate)**: до того как агент выдаёт план/спеку/архит-решение/«как правильно».
- **Gate B (Implementation Gate)**: до любых правок кода/конфигов/инфры.

До закрытия gate агенту разрешены только действия вокруг bootstrap: прочитать результаты, спросить решение, установить allowlisted (если разрешено политикой/пользователем).

### Что делает `update-manifest.py`

Скрипт строит инвентарь skills проекта и пишет манифест.

- **Источник данных**: все файлы `SKILL.md` под `.cursor/skills/**/SKILL.md`
- **Как читается metadata**:
  - парсит YAML frontmatter между `---`
  - берёт `name`, `description`, `capabilities`
  - `capabilities` ожидаются как строка со списком (через запятую; формат `[a, b]` тоже пережёвывается)
- **Выход**: `.cursor/skills/skills-manifest.json`
  - `skills[]`: `{ name, description, path, scope: "project", capabilities[] }`

Ключевое: манифест **генерируется** — руками JSON не правится.

### Что делает `auto-skill-bootstrap.py`

Скрипт — центральный оркестратор. Он:

- Загружает:
  - манифест `.cursor/skills/skills-manifest.json`
  - capability mapping `.cursor/skills/auto-skill-bootstrap/capabilities.json`
  - trust policy `.cursor/skills/auto-skill-bootstrap/trust-policy.json`
  - прошлое состояние `.cursor/skills/auto-skill-bootstrap/state.json`
- Принимает на вход список capabilities: `--cap <cap>` (повторяемый)

#### 1) Считает покрытие (coverage)

Для каждой capability определяет, есть ли уже skill, который её покрывает:

- если у skill в манифесте есть `capabilities[]`, то покрытие — строго по совпадению capability
- иначе пытается угадать покрытие по ключевым словам: ищет `keywords` capability (или имя capability) в `name/description` skill

Важно: есть “meta skills”, которые **не считаются покрытием домена**, даже если присутствуют:

- `find-skills`
- `auto-skill-bootstrap`
- `sandbox-framework`

#### 2) Определяет `missing_caps`

`missing_caps` — это capabilities без покрытия, за вычетом тех, от которых пользователь явно отказался.

Отказ/игнорирование capability:

- передаётся как `--ignore-cap <cap>` (повторяемый)
- сохраняется в `state.json` как `ignored_caps`
- применяется **только к capabilities текущего запуска** (чтобы не было “глобальных сюрпризов”)

#### 3) Ищет кандидатов на `skills.sh` через Skills CLI

Для каждой missing capability берёт список поисковых запросов:

- обычно из `capabilities.json`: `queries[]`
- если `queries` не задан, использует саму capability как запрос

Дальше выполняет `npx skills find <query>` (через `npx.cmd` на Windows) и парсит вывод.

Парсер ожидает строки вида:

- `<owner>/<repo>@<skill>`
- URL обычно на следующей строке (если есть)

Кандидаты дедуплицируются по `package`.

#### 4) Применяет trust policy (allowlist)

`trust-policy.json`:

- `mode`: сейчас используется `allowlist_only`
- `allow[]`: список шаблонов `owner/repo` (поддерживается `*` как glob-like wildcard)
- `deny[]`: список шаблонов для исключения

Для каждого кандидата вычисляется `allowlisted: true/false`.

#### 5) Пишет артефакты и решает “надо ли блокировать”

Скрипт всегда пишет:

- `.cursor/skills/auto-skill-bootstrap/candidates.json`
- `.cursor/skills/auto-skill-bootstrap/state.json`

В `state.json` фиксируются (ключевые поля):

- `caps`: capabilities текущего запуска
- `missing_caps`
- `no_candidates_caps`: где поиск ничего не нашёл
- `non_allowlisted_only_caps`: где есть кандидаты, но все они `allowlisted=false`
- `adhoc_queries`: если запуск был с ad-hoc поиском (см. ниже)
- `ignored_caps`
- `installed`: что реально было установлено (если включена авто-установка allowlisted)

Механизм “fail-closed”:

- если `non_allowlisted_only_caps` не пуст и `--non-allowlisted block` (по умолчанию),
  скрипт завершится с **exit code 2**, печатая `USER ACTION REQUIRED...`

Это сделано специально, чтобы агент **остановился** и спросил у пользователя, ставим ли мы не-доверенные пакеты.

#### 6) Опциональная авто-установка allowlisted

Если передан флаг `--install-allowlisted` и НЕ передан `--no-install`, тогда:

- для каждой capability берутся allowlisted кандидаты
- устанавливаются первые N, где N = `--max-per-cap` (по умолчанию 1)
- установка идёт через `npx skills add <owner/repo@skill> -y`

Никакие non-allowlisted кандидаты скрипт сам не ставит.

### Ad-hoc режим (capability `other`)

Если capability плохо маппится на словарь, есть режим “other”:

- обязательно: `--cap other` и минимум один `--query "..."`.
- запросы будут записаны в `state.json` как `adhoc_queries`.

### Типовой рабочий цикл (по смыслу правила)

1) **Собрать инвентарь skills** (генерация манифеста).
2) **Выбрать capabilities** под текущую задачу (обычно 3–8).
3) **Запустить поиск кандидатов** (без установки).
4) Если есть `non_allowlisted_only_caps` — **решение пользователя обязательно**:
   - ставим конкретные non-allowlisted пакеты (строго выбранные)
   - или явно отказываемся и фиксируем отказ (`--ignore-cap` / `--non-allowlisted ignore`)
5) Если авто-установка allowlisted разрешена — можно поставить allowlisted.
6) После любых установок — **пересобрать манифест**, чтобы новые skills стали видимыми.

### Что здесь НЕ делает bootstrap

- не “выбирает лучший skill” из нескольких без решения пользователя (правило требует выбор per capability)
- не ставит ничего из non-allowlisted источников автоматически
- не заменяет доменную экспертизу: он лишь гарантирует, что агент не игнорит инженерные области и не работает “вслепую”

### Требования (prerequisites)

`Skills CLI` **не хранится в репозитории**. Он берётся как внешний npm CLI‑пакет `skills`, который запускается через `npx`.

Значит, на машине/в контейнере должно быть:

- **Node.js + npm** (чтобы работал `npx`)

Именно это вызывает скрипт:

- Windows: `npx.cmd --yes skills find ...` / `npx.cmd --yes skills add ...`
- Linux/macOS: `npx --yes skills find ...` / `npx --yes skills add ...`

### Команды (как задумано автором навыка)

Ниже — команды в “каноническом” виде (путь `.cursor/...`), ровно в той форме, как это описано в `SKILL.md`/правиле.

Обновить инвентарь:

```bash
python .cursor/skills/auto-skill-bootstrap/bin/update-manifest.py
```

Поиск кандидатов без установки:

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py --no-install \
  --cap docker --cap github --cap devcontainers
```

Авто-установка только allowlisted (лимит на capability):

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py \
  --install-allowlisted --max-per-cap 1 \
  --cap docker --cap github
```

Явный отказ от capability (чтобы не спрашивать повторно):

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py --no-install \
  --cap <cap1> --cap <cap2> \
  --ignore-cap <cap1>
```

Ad-hoc поиск (capability `other`):

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py --no-install \
  --cap other \
  --query "react best practices" \
  --query "testing patterns"
```

