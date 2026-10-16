# Исходники и воспроизведение исследования

Это инструменты подготовки ресурсов, они не нужны для запуска игры. Версия Blender — 4.5.3; исходные `.blend` открывать с `--disable-autoexec`. Исследуемая голова пока не заменяет Алину в игре.

## Восстановить проверенные CC0-оригиналы

Из корня репозитория:

```bash
python3 tools/fetch_authoring_sources.py --output /workspace/shashlik-authoring-sources
```

Скрипт получает бесплатные файлы официальным публичным API BlenderKit и проверяет закреплённые SHA-256. Не сохраняет временные подписанные адреса в репозиторий, не использует пароль/токен и не совершает покупок. Если источник изменится или станет недоступен, проверка остановится; это не означает утрату уже сохранённых GLB и JPEG.

## Подготовить игровые ресурсы

```bash
blender-4.5.3 --background --disable-autoexec --python game/tools/authoring/build_birches.py
blender-4.5.3 --background --disable-autoexec --python game/tools/authoring/prepare_bark.py -- --source=/workspace/shashlik-authoring-sources/European_White_Birch_Bark.blend
blender-4.5.3 --background --disable-autoexec --python game/tools/authoring/prepare_head_study.py -- --source=/workspace/shashlik-authoring-sources/Selunae.blend
```

Вне этой облачной среды вместо `blender-4.5.3` указать путь к совместимому Blender. `build_birches.py` загружает отдельный инструмент Sapling по закреплённым адресам/хешам. Авторский исходник и его лицензия остаются в кэше, исходный код инструмента не включается в игру. `SHASHLIK_AUTHORING_CACHE` задаёт другой путь кэша.

Генераторы перезаписывают только явно указанные производные ресурсы проекта; сначала испытывать изменения в рабочей копии, сохранять предыдущую версию. После экспорта нужно обновить SHA-256 в реестрах, импортировать проект и получить новые кадры. Сам факт экспорта не доказывает правильность лица, волос, мимики или посадки.

## Посмотреть и проверить

```bash
source /workspace/.cloud-tools/godot-env.sh
shashlik-forward-render res://character_base_study.tscn
shashlik-forward-render res://lakeside_preview.tscn
shashlik-forward-render --disable-render-loop --script res://tests/lakeside_validation.gd
shashlik-forward-render --disable-render-loop res://lakeside_preview.tscn -- --self-test
```

`character_base_study.tscn` — вращение головы, приближение и четыре варианта выражения. Вариант кожи без исходных татуировок/фиолетового макияжа сохранён отдельно с provenance.json; это проверка новой основы, не окончательный образ Алины. `lakeside_preview.tscn` — отдельный интерактивный образец прежней игровой локации. Оба требуют проверки на целевой видеокарте; облачный программный Vulkan не измеряет её FPS.


## Полная сборка Алины — итерация 04

```bash
blender-4.5.3 --background --disable-autoexec --python game/tools/authoring/build_alina_revision.py
shashlik-godot --headless --editor --import --quit
shashlik-forward-render res://alina_preview.tscn
```

Сборка проверяет SHA обоих исходных GLB. Генерирует новый AlinaRevision.glb и базовый реестр; после импорта сохранить извлечённые AlinaRevision_*.png/jpg вместе с `.import`, включить mipmaps и отключить автоматические LOD этой исследовательской модели. Окончательный реестр дополняется SHA извлечённых карт. Не удалять исходные Refined_Alina и AlternativeHeadStudy. Это совместимая сборка на прежнем теле/клипах, не завершённая замена всей анатомии и одежды.
