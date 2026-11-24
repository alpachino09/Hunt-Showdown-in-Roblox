# Проверка отряда в Studio

Добавьте PartyCheck.server.luau как Script в ServerScriptService и PartyCheck.client.luau как LocalScript в StarterPlayerScripts отдельной копии Lobby. В режиме редактирования запустите из контекста плагина:

```luau
local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "GreyOutpostPartyCheck")
print(result)
```

Результат должен начинаться с PASS. Тест проверяет вход двух клиентов, объединение в отряд, готовность, запуск карты и независимый боезапас после первого выстрела, нокдаун от Смотрителя и поднятие товарища. Удалите оба временных скрипта из копии. Скрипты теста не входят в Rojo-сборки.

# Проверка опоры охотников

Откройте свежую сборку `build/GreyOutpost-HunterLab.rbxl`, запустите Solo Play и выполните `HunterGroundCheck.client.luau` в клиентском Command Bar. Сохраните возвращённые таблицы `floor`, `ramp` и `stairs`. Повторите для каждого охотника клавишами 1–4 и запишите движение сбоку. Поля `supportedMedian` и `supportedP90` учитывают только непрерывную опору на одной поверхности; перенос между ступенями исключён. Дополнительно осмотрите контур подошвы, перенос веса, края ступеней, остановку и повороты. Численный тест Lune не заменяет этот прогон.


# Проверка оружейного стенда

Откройте свежий `build/GreyOutpost-WeaponLab.rbxl`, запустите Solo и выполните `WeaponLabCheck.client.luau` в клиентском Command Bar. Проверка переключает четырёх охотников, измеряет хват в готовой позе и через обычный WeaponLabInput проверяет Fire, Reload и Cancel. Для проверки клавиш и камер используйте ПКМ и V. Файл теста не входит в карту.

# Проверка WeaponLab с двумя клиентами

В отдельной локальной копии свежей сборки добавьте `WeaponLabNetworkCheck.server.luau` в ServerScriptService и `WeaponLabNetworkCheck.client.luau` в StarterPlayerScripts. Запустите из контекста плагина в Edit:

```luau
local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "GreyOutpostWeaponLabNetwork")
print(result)
```

Скрипты ждут обоих участников, проводят раннюю отмену и полный цикл через действующий WeaponLabInput, проверяют обе пары боезапаса и фактическое положение чужого ствола и заряда. При сбое фазы журнал показывает таблицы сервера и наблюдателя. После теста удалите временные скрипты из локальной копии. [StudioTestService](https://create.roblox.com/docs/reference/engine/classes/StudioTestService)
