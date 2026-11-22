# Проверка отряда в Studio

Добавьте PartyCheck.server.luau как Script в ServerScriptService и PartyCheck.client.luau как LocalScript в StarterPlayerScripts отдельной копии Lobby. В режиме редактирования запустите из контекста плагина:

```luau
local result = game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, "GreyOutpostPartyCheck")
print(result)
```

Результат должен начинаться с PASS. Тест проверяет вход двух клиентов, объединение в отряд, готовность, запуск карты и независимый боезапас после первого выстрела. Удалите оба временных скрипта из копии. Скрипты теста не входят в Rojo-сборки.
