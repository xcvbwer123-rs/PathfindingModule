PathfindingModule은 아주 사용하기 간단합니다. 기본적인 사용법은 다음 예제 코드에서 확인하실수 있습니다.

```lua
local Assets = game:GetService("ServerStorage").Assets
local PathfindingModule = require(Assets.PathfindingModule)
local NPC = script.Parent
local MoveHandler = PathfindingModule.new(NPC)

MoveHandler:MoveToByPosition(Vector3.new(0, 0, 0))
```