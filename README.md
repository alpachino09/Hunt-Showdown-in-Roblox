# Серая застава

Самостоятельный PvPvE extraction-хоррор в Roblox. В локальном прототипе можно открыть 3D-лобби, посмотреть охотника, пройти по разделам меню и выключить анимацию ожидания.

## Локальный запуск

Требуются Python 3.10+, Roblox Studio и инструменты из `rokit.toml`. Установите Rokit из [официального релиза](https://github.com/rojo-rbx/rokit/releases), затем выполните `rokit install` и `./scripts/build.sh` из папки проекта. Если Rokit спросит о доверии, сверяйте владельцев инструментов с `rokit.toml`.

Откройте `build/GreyOutpost-Lobby.rbxl` в Studio и запустите **Play**. Остальные два файла содержат каркас игровых мест. Скрипт сборки заново создаёт сцену и интерфейс из `scripts/generate_lobby.py`. Изменения из Studio переносите в исходники перед следующей сборкой.

- [План разработки](PROJECT_PLAN.md)
- [Дизайн](GAME_DESIGN.md)
- [Архитектура](ARCHITECTURE.md)
- [Что сделано](DEVELOPMENT_PROGRESS.md)
- [Следующие шаги](NEXT_STEPS.md)
