## 모듈 함수
### PathfindingModule.new
```
PathfindingModule.new(Character) -> MoveHandler
```

``Character``에 대한 [MoveHandler](#MoveHandler-api)를 생성합니다.

!!!warning
    Character안에는 ``HumanoidRootPart``와 ``Humanoid``개체가 존재해야 합니다.

# MoveHandler Api
## Methods
### MoveHandler:FindTarget
```
MoveHandler:FindTarget(TargetFindRange: number?, Parent: Instance?) -> TargetFindResult?
```
- TargetFindRange : 타겟을 찾을 범위입니다. 기본값 : inf
- Parent : 타겟이 속해있는 위치입니다. 기본값 : workspace

등록된 ``Character``의 ``Team``값이 다른 ``Humanoid``객체를 가진 Model을 찾습니다.

### MoveHandler:CanSeeTarget
```
MoveHandler:CanSeeTarget(Target: TargetFindResult) -> boolean
```
타겟의 HumanoidRootPart방향으로 40Stud만큼 레이케스팅을 합니다. 
만약 타겟의 Model안에있는 BasePart가 감지되면 ``true``를 반환하고,
아무것도 감지가 되지 않거나, 다른 BasePart가 감지되면 ``false``를 반환합니다.

### MoveHandler:MoveTo
```
MoveHandler:MoveTo(TargetFindRange: number?, Parent: Instance, Target: TargetFindResult?) -> nil
```
- TargetFindRange : 타겟을 찾을 범위입니다. 기본값 : inf
- Parent : 타겟이 속해있는 위치입니다. 기본값 : workspace
- Target : [MoveHandler:FindTarget](#MoveHandler:FindTarget)으로 찾은 TargetFindResult값 입니다. 기본값 : nil

등록된 ``Character``가 타겟에게 이동하게 합니다.

!!!warning
    이 함수는 이동이 끝날때까지 다음 명령으로 넘어가지 않습니다.
    이를 해결하려면 coroutine.wrap을 이용하십시오.

### MoveHandler:MoveToByPosition
```
MoveHandler:MoveToByPosition(TargetPosition: Vector3) -> nil
```
- TargetPosition : ``Character``가 도착할 위치입니다.

등록된 ``Character``이 ``TargetPosition``으로 이동하게 합니다.

!!!warning
    이 함수는 이동이 끝날때까지 다음 명령으로 넘어가지 않습니다.
    이를 해결하려면 coroutine.wrap을 이용하십시오.

### MoveHandler:StopFollowing
```
MoveHandler:StopFollowing() -> nil
```

이동중인 ``Character``의 이동을 중지시킵니다.

### MoveHandler:SetNetworkOwner
```
MoveHandler:SetNetworkOwner(Owner: any) -> nil
```

``Character``의 NetworkOwner을 설정합니다

!!! tip
    만약 Character가 Server의 것이라면 기본적으로 nil로 설정되고,
    플레이어의 것이라면 해당 플레이어로 설정됩니다.

### MoveHandler:FindTrusses
```
MoveHandler:FindTrusses(Distance: number?, Parent: Instance?) -> {TrussPart}
```
- Distance : TrussPart를 찾을 범위입니다. 기본값 : inf
- Parent : TrussPart들이 들어있는 객체입니다. 기본값 : workspace

[AgentCanMoveWithTrussParts]속성값이 켜져있을때 TrussPart들을 구하는 함수입니다.

### MoveHandler:GetTopnBottom
```
MoveHandler:GetTopnBottom(Truss: TrussPart) -> Top: Vector3, Bottom: Vector3
```
- Truss : 타기 시작할 곳, 끝날곳을 구할 TurssPart입니다.
- Top : TrussPart를 타고 올라갔을때의 도착지점입니다.
- Bottom: TrussPart를 타기 시작할 위치입니다.

## MoveHandler Properties
### Model
- Read-Only
```
MoveHandler.Model -> Model
```

[.new()](#pathfindingmodulenew)를 할때 Character값으로 넣은 모델입니다.

### MyRoot
- Read-Only
```
MoveHandler.MyRoot -> BasePart
```

[Model](#model)에 있는 ``HumanoidRootPart``라는 이름을 가진 BasePart객체 입니다.

### Humanoid
- Read-Only
```
MoveHandler.Humanoid -> Humanoid
```

[Model](#model)에 있는 ``Humanoid``의 ClassName값을 가진객체 입니다.

### PathfindingParams
- 기본값 : {AgentRadius = 2.5}
```
MoveHandler.PathfindingParams -> table
```

PathfindingService에 사용하는 테이블값입니다.
자세한 정보는 [Character Pathfinding 자료](https://developer.roblox.com/en-us/articles/Pathfinding)를 참고하세요.

### Team
- 기본값 : [Character](#model)의 이름
```
MoveHandler.Team -> string
```

!!! tip
    같은 이름을 가진 Character끼리는 타겟으로 삼지 않습니다.   
    그러므로 Team을 랜덤하게 변경해 주면 서로 공격합니다.

[:FindTarget](#movehandlerfindtarget)에 사용하는 팀 값입니다.

### AgentCanMoveWithTrussParts
- 기본값 : false
```
MoveHandler.AgentCanMoveWithTrussParts -> boolean
```

[:MoveTo](#movehandlermoveto)또는 [:MoveToByPosition](#movehandlermovetobyposition)에서 이동할때,
TrussPart를 사용하여 이동할건지 여부입니다.

!!! notice
    `해당 변수가 켜져있으면 맵 전채를 확인하므로 게임에 랙을 걸리게 할수 있습니다.`   
    V 1.0.4에서 한번만 확인하도록 수정되었습니다.

### Following
- Read-Only
- 기본값 : false
```
MoveHandler.Following -> boolean
```

현제 [Character](#model)가 이동중인지 알려줍니다.