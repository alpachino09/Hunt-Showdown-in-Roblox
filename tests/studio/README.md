# Проверка отряда в Studio

Добавьте PartyCheck.server.luau как Script в ServerScriptService и PartyCheck.client.luau как LocalScript в StarterPlayerScripts отдельной копии Lobby. В режиме редактирования запустите из контекста плагина:

```luau
local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "GreyOutpostPartyCheck")
print(result)
```

Результат должен начинаться с PASS. Тест проверяет вход двух клиентов, объединение в отряд, готовность, запуск карты и независимый боезапас после первого выстрела, нокдаун от Смотрителя и поднятие товарища. Удалите оба временных скрипта из копии. Скрипты теста не входят в Rojo-сборки.

# Проверка опоры охотников

Откройте свежую сборку `build/GreyOutpost-HunterLab.rbxl`, запустите Solo Play и выполните `HunterGroundCheck.client.luau` в клиентском Command Bar. Сохраните возвращённые таблицы `floor`, `ramp` и `stairs`. Повторите для каждого охотника клавишами 1–4 и запишите движение сбоку. Поля `supportedMedian` и `supportedP90` учитывают только непрерывную опору на одной поверхности; перенос между ступенями исключён. Дополнительно осмотрите контур подошвы, перенос веса, края ступеней, остановку и повороты. Численный тест Lune не заменяет этот прогон.
