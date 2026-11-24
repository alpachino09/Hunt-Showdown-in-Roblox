# Этап 04 — результаты проверок

## Исходная сборка

24.11.2026, МСК. Ревизия игрового кода `e58f0b258b42eb3cd1c96263ae78247ec8a6280b`. `./scripts/check.sh` успешно завершился в отдельном рабочем дереве. StyLua и Selene прошли, Lune проверил опору на трёх поверхностях, Rojo собрал Lobby, Expedition, Rush и HunterLab, анализ Luau завершился с кодом 0. Luau LSP сообщил о недоступной регистрации наблюдения за sourcemap.

## HunterLab, Studio Edit

Studio `0.748.0.7481526`, локальный `build/GreyOutpost-HunterLab.rbxl`, без клиентов. Открыт через **File → Open from File**, затем проверен через Roblox Studio MCP в Edit.

- `Workspace.CharacterQualityLab` загрузился. В `ServerStorage.HunterRoster` присутствуют `Veteran`, `Tracker`, `Marshal` и `Occult`. У всех четырёх Humanoid R15, есть `HumanoidRootPart` и по 17 `Motor6D`. Проверка имён `Bone`, содержащих `finger`, дала 0 на каждом риге. Возможность независимого управления пальцами потребует отдельной проверки и подготовки FPP-рига.
- В `ReplicatedStorage.HunterProps` найдены `Rifle` с `Mount.Support` и `Pistol` без Attachment. `WeaponPose.luau` вычисляет положение рук процедурно, используя `SupportHand` и `TriggerHand` на персонаже.
- `ReplicatedStorage.VeteranMotion` содержит 12 клипов в StringValue и отдельный StringValue `Joints`. Проверка подтвердила их наличие в Edit. Проигрывание клипов и игровой контакт рук в этой сессии не проверялись.
- MCP вернул пустой журнал Output в Edit. Место не сохранялось и не публиковалось.

## Expedition, Studio Edit и Solo

24.11.2026, Studio `0.748.0.7481526`, локальный `build/GreyOutpost-Expedition.rbxl`, ревизия исходного игрового кода `e58f0b2`.

- В Edit подтверждены `ServerStorage.ExpeditionMap` (Model, 203 потомка, 7 маркеров), `ServerScriptService.SharedServer.Raid` (ModuleScript), `ExpeditionServer.Host` (Script) и `StarterPlayer.StarterPlayerScripts.ExpeditionClient.Field` (LocalScript). Streaming включён, PlaceId равен 0.
- В Solo с одним клиентом дождались `RaidPhase = Alive`, `Workspace.ActiveRaid` и `LockFirstPerson`. Через действующий клиентский Combat воспроизвели Fire и Reload. Показания серверных атрибутов на клиенте: 6/24 → 5/24 → 6/23, `RaidReloading` включился на время перезарядки и сбросился. MCP вернул пустой Output. Play остановлен.
- Запросы поданы через Studio MCP в клиентской DataModel. Срабатывание клавиш и сетевой прогон с двумя клиентами остаются отдельными проверками.

## Оставшиеся проверки

После интеграции сервиса повторить исходный прогон Expedition. Когда появится новый изолированный стенд, проверить отмену до и после подтверждения вставки реквизита, повторный запрос и сброс персонажа. Для последующего покадрового и двухклиентного прогона записать FPP и TPP на одинаковой фазе; отдельно снять метрики производительности.
