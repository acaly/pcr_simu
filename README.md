# 公主连接Re:Dive战斗模拟器

这个项目的最终目标是可以做到给定阵容，在游戏之外进行模拟战斗，并列出战斗中发生的事件以及最终的结果。项目完全使用Lua语言（开发使用的是最新的5.3.5版本）。

目前这个项目完成了入场和基本的技能循环的框架部分，技能效果的部分还没有实现。

## 示例

### 入场位置和时间的计算
目前可以自动计算任意阵容的入场停止的位置和时间。使用的攻击距离数据可能不全，如果需要可以向```src/pcrcommon.lua```中手动补充。

计算宫子对战宫子需要从项目目录/test中执行
```
lua entering_manual.lua miyako miyako
```
每个队伍多个角色用逗号分隔，例如
```
lua entering_manual.lua lima,yukari,mitsuki,rino,yuki nozomi,makoto,tamaki,maho,kyouka
```
目前会输出三列数字，分别为停止坐标（以双方出场位置中点为原点）、停止时的帧数（以时钟1:30跳到1:29为第60帧，显示的是最后一次移动的帧数）、相对停止时间（以最先停下的角色为0，负值越大越晚）。

例如双方镜像阵容宫子+望+后排，双方望的停止帧数都是59(-13)，我方会先手眩晕成功：
```
lua entering_manual.lua miyako,nozomi miyako,nozomi
```
而去掉宫子后是对方望先一帧停下，我方45(-1)，对方44(0)，对方会眩晕成功：
```
lua entering_manual.lua nozomi nozomi
```

### 技能时间轴的计算
目前只填了宫子和真琴两个角色的时间轴，其他角色还只有空技能所以无法计算。宫子的无敌技能默认使用的是154级的数据（可以从miyako.lua中修改）。

时间轴计算目前没有直接输出结果的方法，只能手动逐帧检查。以宫子对阵真琴为例，我方的宫子在199帧（时钟跳到1:27后的第19帧）开始一个普攻动作。从项目目录/test中启动lua解释器并执行：
```lua
pcr = require("env")
miyako = pcr.characters.miyako.default() --创建miyako角色
makoto = pcr.characters.makoto.default() --创建makoto角色
frame0 = pcr.utils.makebattle({ miyako }, { makoto }) --创建一场战斗（的第一帧状态）

frame198 = pcr.core.simulation.run(frame0, nil, 198) --模拟到198帧
print(frame198.state.team1[1].skillid) --输出198帧我方队伍1号角色的当前技能id（应当显示0，表示前一技能刚刚结束）

frame199 = pcr.core.simulation.run(frame0, nil, 199) --模拟到199帧
print(frame199.state.team1[1].skillid) --输出199帧我方队伍1号角色的当前技能id（应当显示3，对应于miyako.lua中注册的第3个技能，也就是普攻）
```

对于其他角色，如果有攻击距离数据（在pcrcommon.lua中），也可以放到场上（会影响双方的入场距离和时间，因此会对先后手有影响，但是没有技能，不能计算时间轴）。
这些角色可以直接使用字符串名称来创建，例如
```lua
pcr = require("env")
miyako = pcr.characters.miyako.default() --创建miyako角色
makoto = pcr.characters.makoto.default() --创建makoto角色
frame0 = pcr.utils.makebattle({ miyako }, { "nozomi", "makoto", "tamaki", "maho", "kyouka" }) --创建一场战斗（的第一帧状态）
```

