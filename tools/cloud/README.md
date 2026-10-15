# Облачный программный Vulkan

Godot 4.5.1 и Xvfb должны быть подготовлены сохранённым установочным сценарием среды. Дополнение `setup_vulkan.sh` устанавливает Mesa из официальных подписанных репозиториев Debian trixie в `/workspace/.cloud-tools/`, не требуя root и не отключая проверки APT. Установщик проверен в прежней среде, включая повторную установку после перемещения локального драйвера.

```bash
bash /workspace/Game-AI-/tools/cloud/setup_vulkan.sh
source /workspace/.cloud-tools/godot-env.sh
SHASHLIK_CAPTURE_DIR=/workspace/shashlik-development/stage-01/graphics/check shashlik-forward-render --disable-render-loop --resolution 1280x720 --script res://tests/graphics_benchmark.gd -- --graphics-high --overview-only
```

Проверять новую метку `GRAPHICS_BENCHMARK_COMPLETE`, отсутствие ошибок, PNG и `capture-metadata.json`. Для всех пяти камер убрать `--overview-only`. Для исходного профиля убрать `--graphics-high`.

Это программный Vulkan lavapipe, а не GPU пользователя. `--disable-render-loop` предназначен для явного захвата кадров; эти команды не измеряют интерактивную производительность. Основной проект не переводится на Forward+ самим установщиком.

## Полная настройка и авторские инструменты

`bash /workspace/Game-AI-/tools/cloud/setup_environment.sh` повторяет проверенную полную настройку Godot/Xvfb/Python, импорт и self-test, затем устанавливает локальные Vulkan и Blender. Порядок целиком повторно выполнен с кодом 0. Исходники игры этот сценарий не заменяет и не генерирует.

Отдельный Blender: `bash tools/cloud/setup_blender.sh`, затем `blender-4.5.3 --disable-autoexec --background путь_к_копии.blend`. Официальная SHA-256 закреплена в установщике; скачивание, проверка, распаковка, повторный запуск и открытие исходника Алины проверены. Оригиналы не пересохранять. Новый экспорт изменённого персонажа пока не проверен.

Запуск исследуемой сцены: `shashlik-forward-render res://quality_preview.tscn`. В ней доступны исходные действия и управление; это отдельный образец, обычная точка запуска проекта сохранена. Проверка её взаимодействий: `shashlik-forward-render --disable-render-loop res://quality_preview.tscn -- --self-test`; наличие окна/процесса само по себе успехом не считать.
