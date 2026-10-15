# Сохранённые этапы

Рабочая ветка: `codex/graphics-rework`. Полное графическое ТЗ ещё выполняется. Отдельный технический PASS не означает художественную готовность.

| Этап | Отчёт | Статус |
|---|---|---|
| 00 | [Сохранение и уровень графики](STAGE_00_Backup_and_Quality_RU.md) | Организация сохранения выполнена |
| 01 | [Первичная ревизия](STAGE_01_Initial_Audit_RU.md) | Промежуточный результат; сравнение ресурсов открыто |
| 01Б | [Рендер и материалы](STAGE_01B_Graphics_Study_RU.md) | Исследование; целевое качество не достигнуто |
| 01Б, итерация 02 | [PBR-материалы и геометрия локации](STAGE_01B_02_PBR_Location_RU.md) | Проверен отдельный интерактивный образец; большой этап открыт |

[Реестр требований](REQUIREMENTS_REGISTER.md), [подробный JSON](REQUIREMENTS_REGISTER.json), [CSV](REQUIREMENTS_REGISTER.csv).

Актуальная точка продолжения: [LATEST_STATE_RU.md](../LATEST_STATE_RU.md). Новый образец: [общий вид](evidence/pbr-02/study/overview.png), [пруд](evidence/pbr-02/study/pond.png), [стол](evidence/pbr-02/study/table.png). [Базовая серия](evidence/pbr-02/baseline/) снята с теми же камерами. Старые материалы ниже сохранены как история исследования.

[Общий вид в исходных 2560×1440](evidence/pbr-02/study-1440/overview.png). Разрешение кадра не является доказательством художественной готовности или производительности RTX 5080.

## Материалы проверки

- [Лица](evidence/audit/sheets/faces.png), [фазы движений](evidence/audit/sheets/motion-keyframes.png).
- Реакции: [Алина](evidence/audit/sheets/reactions-0.png), [Круглик](evidence/audit/sheets/reactions-1.png), [Крысюк](evidence/audit/sheets/reactions-2.png).
- Общий вид: [базовый профиль](evidence/graphics/final-baseline/overview.png), [опытный профиль](evidence/graphics/final-study/overview.png).
- Стол: [базовый профиль](evidence/graphics/final-baseline/table.png), [опытный профиль](evidence/graphics/final-study/table.png).
- В этих же каталогах сохранены мангал, Алина, пруд и метаданные. В обоих профилях используется Forward+; изменены свет и пробные материалы, поэтому разницу нельзя приписывать только одному шейдеру. Это реальные кадры программного рендера, не оценка FPS RTX 5080.
- [Проверка и SHA-256 избранных файлов](evidence/verification.json).

Прочие исходные кадры находятся в `/workspace/shashlik-development/stage-01/` и отдельном проверенном архиве. Доступность локального пути вне текущей среды не гарантируется. Подтверждение отправки версии и сведения об архивах сохраняются отдельно от неподтверждённых намерений.
