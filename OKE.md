# OKE Libray

OpenComputersのロボット用に作ったライブラリです

- [ナビゲーション系関数](#ナビゲーション系関数)
- [インベントリ操作系関数](#インベントリ操作系関数)
- [移動系関数](#移動系関数)
- [その他の関数](#その他の関数)

## How to install

OpenOSをインストールしたrobot内のディレクトリ`/home/lib/`内にoke.luaを置く

### ナビゲーション系関数

#### 自身との相対座標系により移動の管理を行える

- `oke.compass.init()`  
自身の座標を相対座標の原点として初期化する

- `oke.compass.getPos() : number, number, number`  
現在位置の相対座標を得る

- `oke.compass.moveTo(x:number, y:number, z:number)`  
自身との相対座標で特定の座標まで移動する，移動した後の向きは不定

### インベントリ操作系関数


インベントリコントローラーが必要  
local FUEL_SLOT = 1` など，スロットを管理する必要がなくなる  
例として上部インベントリからCoarse Dirtをロボットのインベントリに64個まで入れたい場合


```
local oke = require("oke")
local sides = require("sides")

local filter = {
  coarse_dirt = function(stack)
    return stack.name == "minecraft:dirt" and stack.damage == 1
  end
}

oke.pullStack(sides.up, filter.coarse_dirt, 64 - oke.countStack(filter.coarse_dirt)) 

if oke.countStack(filter.coarse_dirt) < 64 then
  print("Not enough coarse dirt!")
end

```
と書ける

- `oke.countStack(filter:function) : number`  
Inventroy Controller が必要  
フィルターに合致するインベントリ内のアイテムの数を返す，ツールスロットは含まない

- `oke.countToolStack(filter:function) : number`  
フィルターに合致するツールスロット内のアイテムの数を返す，インベントリは含まない

- `oke.ejectStack(side:number, filter:function, count:number) : boolean`  
side方向にfilterに合致するアイテムをロボットのインベントリ内からcount個移動する  
１つでもアイテムが移動すればtrueを返す 

- `oke.pullStack(side:number, filter:function, count:number) : boolean`  
side方向のインベントリからfilterに合致するアイテムをcount個移動する  
１つでもアイテムが移動すればtrueを返す

- `oke.merge()`  
インベントリ内の重複しているアイテムをスタック限界までスタックする

- `oke.equip()`  
`component.inventory_controller.equip()`と同じ

- `oke.placeStack(direction, filter, soft)`  
directionの方向にfilterのマッチするブロックの設置を試みる  
softにtrueを入力せず設置位置にブロックがあった場合破壊を試みる
設置位置に同じブロックがあった場合破壊も設置もしない

### 検知系関数

- `oke.compare(side, fuzzy) : boolean`  
現在選択されているスロット内のアイテムスタックとside方向のブロックが一致するか調べる

- `oke.detect(side) : table`  
side方向のブロックの位置情報を得る

### 移動系関数

- `oke.move(side:number, distance:number, soft:boolean, nil)`  
side方向にdistanceの距離だけ移動する  
softをtrueにしない場合移動できない場合はswingして障害物の破壊を試みる  
移動が成功するまで制御は帰ってこない

- `oke.forward(distance, soft)`   
oke.move(sides.forward, distance, number)のwrap
- `oke.up(distance, soft)`  
oke.move(sides.up, distance, number)のwrap
- `oke.down(distance, soft)`  
oke.move(sides.down, distance, number)のwrap
- `oke.turn(clockwise:boolean, nil)`  
`clockwise = true`で時計回りに回転する，nilの場合は左回転
- `oke.turnAround(clockwise:boolean, nil)`  
`oke.turn()`二回と等しい，nilの場合は左回転

### 他コンポーネント系関数

- `oke.suckAll()`
tractor beamをアイテムが回収できなくなるまで照射する

### その他の関数

- `oke.prompt(message) : boolean`
meesageを表示しyes/noを選択させる

- `oke.getEnergyRatio() : number`
貯蔵されているエネルギー量(0 ~ 1, 1が最大値)を返す

- `oke.recharge() : boolean`
ロボットが充電状態にあるとして，充電完了まで待つ


