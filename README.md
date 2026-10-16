Шашлык у пруда

Разработка продолжается в ветке `codex/graphics-rework`. Полная переработка графики и анимаций ещё не завершена.

- [Актуальное состояние и точка продолжения](docs/LATEST_STATE_RU.md).
- [План этапов](docs/WORK_PLAN_RU.md) и [сохранённые отчёты](docs/stages/README.md).
- [Замена основы и новый берег — промежуточная итерация 03](docs/stages/STAGE_01B_03_Base_Replacement_WIP_RU.md).
- [Предыдущий образец окружения](docs/stages/STAGE_01B_02_PBR_Location_RU.md), [его кадр 2560×1440](docs/stages/evidence/pbr-02/study-1440/overview.png).

Godot-проект находится в `game/`. Новые отдельные сцены — `game/lakeside_preview.tscn` (берег) и `game/character_base_study.tscn` (голова/мимика). Предыдущий образец — `game/quality_preview.tscn`; для описанного света используется Forward+. Обычная точка запуска сохранена. Для облачной разработки — инструкции и проверенные установщики в `tools/cloud/`.

Исходники, материалы и отчёты сохраняются отдельными коммитами. [Контрольные ZIP, SHA-256 и проверка распакованной версии](docs/stages/checkpoints/STAGE_01B_03_Backup.json). Производительность на пользовательском ПК с RTX 5080 и Windows ещё не измерена.
