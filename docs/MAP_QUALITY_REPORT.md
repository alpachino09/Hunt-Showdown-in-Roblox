# Оценка качества карты Mammon's Gulch

Дата проверки: 25.11.2026. Оценка относится к **географическому макету**, а не к финальной карте.

## Фактические captures

- [North-up](images/map/mammons-gulch-north-up.jpg): общий вид сверху; север в отрицательный Roblox Z.
- [Terrain](images/map/mammons-gulch-terrain-overview.jpg): два горных массива, реки и измеренные высоты.
- [Транспортный каркас](images/map/mammons-gulch-routes-overview.jpg).
- [La Plata Mine greybox](images/map/mammons-gulch-la-plata-blockout.jpg).
- [Underground greybox](images/map/mammons-gulch-underground-greybox.jpg): локальное освещение ещё не реализовано; визуальное одобрение интерьера отсутствует.
- [Debug tools](images/map/mammons-gulch-debug-tools.jpg).

## Оценка макета

| Категория | 0–10 | Обоснование |
|---|---:|---|
| Географическая точность | 9 | 16 compounds по измеренным координатам, source polygons, row-delta Terrain и вода; масштаб 3 studs/м — ADAPTED |
| Архитектурная точность | 1 | Только ReferenceMassing, нет подтверждённых фасадов, крыш и точных открытий |
| Сходство с референсами | 2 | Рельеф узнаваем по данным, здания и детали ещё не сравнены по всем ракурсам |
| Качество моделей | 3 | Детерминированный greybox, нет production MeshParts для архитектуры |
| Материалы | 3 | Встроенные greybox Terrain/Part materials; PBR library ещё не применена |
| Освещение | 4 | Дневной Realistic preset, но нет отдельной interior/weather проверки |
| Интерьеры | 0 | Нет законченных интерьеров; underground greybox тёмный и не одобрен |
| Маршруты | 6 | Roads/rail/bridges/underground collision и два клиента проверены, но centerlines преимущественно APPROXIMATED |
| Интерактивность | 4 | Studio-only teleport и overlays работают; двери, лестницы, окна, elevators не реализованы |
| Производительность | 8 | 60,07 FPS, p95 18,25 мс на M1 Pro; нет 1% low, standalone Player или 12 игроков |
| **Итого** | **40/100** | Не оценка готовой карты и не автоматический целевой 90/100 |

## Проверки

- 34 Python tests, два Lune-теста, StyLua/Selene/Rojo/Luau LSP проходят.
- Studio self-test, Solo Play Terrain/Water/routes/debug UI проходят.
- Два клиента прошли встречный маршрут по одному тоннелю (19,20 и 15,41 studs).
- Повторное восстановление Terrain завершено и сохранено локально.
- Фактические values и ограничения: `TEST_REPORT.md`, `MAP_OPTIMIZATION.md`.

## Отклонения и невыполненное

1. Все 16 зданий и интерьеры ещё требуют исследования и детализации.
2. Дороги и главная линия векторизованы по Survey/In-game, но не являются подтверждёнными оригинальными центральными линиями.
3. Остовный граф шахт и прямоугольные floor/roof — APPROXIMATED; полная оригинальная топология не заявлена.
4. Подземное освещение, звук/реверберация, отсутствие внешних просветов и все elevators требуют La Plata QA.
5. Карта-интерфейс, компас, погода, звук окружения, точки боссов/улик как рабочая механика и Bounty Hunt не завершены.
6. Нет standalone Player, cold load, 1% low, мобильного профиля или 12 игроков.

## Phase gate

**GEOGRAPHY_BLOCKOUT_ACCEPTED_FOR_LA_PLATA**. Критических дефектов самих базовых координат, Terrain, water, road/bridge collision или server debug gate после исправлений не осталось. Это разрешение начать **La Plata Mine — Phase C**, а не завершение этапа 3 и не итоговая визуальная приёмка.
