# GUI lib for OpenComputers

OpenComputersでのGUI開発用ライブラリです

## 全体的な仕様
画面全体で使用可能なwindowを定義し，その中で自由なコンポーネント（ラベル，テキストフィールド等を構成していく）  
ほとんどの関数で第一変数に自身を使用するため，糖衣構文が基本となっている．

## 全般的な関数

- `gui:newWindow(x:number or nil, y:number or nil, width:number or nil, height:number or nil, screen_address:string or nil): table`  
新しくWindowを生成し，windowオブジェクトを返す．  
各変数が設定されなかった時はcfgのデフォルト値が適用される

- `gui:update()`  
各ウィンドウの描写処理を行う．

- `gui:setBackgroundColor(color:number)`  
背景色を変更する

- `gui:exit()`  
guiライブラリの終了処理を行う

- `gui:init()`  
guiライブラリの初期化を行う．  
具体的な処理内容はビッグフォントライブラリのロード

## windowオブジェクトが実行可能な関数

- `window:draw()`  
gui:updateを待たずに描写したい場合に使う．（gui:update内部でも実行される）  
このwindow内部の各コンポーネントも描写される．

- `window:close()`  
このウィンドウを閉じる

- `window:setWindowName(name:string)`  
ウィンドウ名を変更する

- `window:setWindowNameColor(color:number)`  
ウィンドウ名の色を変更する

- `window:setCloseButtonColor(color:number)`  
ウィンドウの閉じるボタンの色を変更する

- `window:setFrameColor(color:number)`  
ウィンドウのフレームの色を変更する

- `window:setCloseButtonCallback(callback:function)`  
ウィンドウの閉じるボタンが押された時に呼ばれる関数を設定する

- `window:setMoveability(boolean:boolean)`  
ウィンドウが画面内で移動することを許可するか設定する

- `window:update()`  
gui:updateを待たずに描写したい場合に使う．（gui:update内部でも実行される）  
このwindow内部の各コンポーネントも描写される．

- `window:newTabBar():table`  
tabBarオブジェクトを生成しtabBarを返す

- `window:newButton(x:number or nil, y:number or nil, width:number or nil, height:number or nil ,callback:function or nil):table`  
Buttonオブジェクトを生成しButtonを返す  
各変数が設定されなかった時はcfgのデフォルト値が適用される  
ボタンを押した時にCallback関数が呼ばれる  

- `window:newSwitch(x:number or nil, y:number or nil, width:number or nil, height:number or nil, onCallback:function or nil, offCallback:function or nil):table`
Switchオブジェクトを生成しSwitchを返す  
各変数が設定されなかった時はcfgのデフォルト値が適用される  
SwitchがOnになった時にonCallback関数が呼ばれ，Offになった時ににoffCallback関数が呼ばれる  

- `window:newLabel(x:number or nil, y:number or nil, text:string or nil):table`  
Labelオブジェクトを生成しLabelを返す  

- `window:newProgress(x:number or nil, y:number or nil, width:number or nil):table`  
Progressオブジェクトを生成しProgressを返す  

- `window:newTextField(x:number or nil, y:number or nil, width:number or nil):table`  
TextFieldオブジェクトを生成しTextFieldを返す  

- `window:newList(x:number or nil, y:number or nil, width:number or nil):table`  
Listオブジェクトを生成しListを返す  
