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

以宫子对阵真琴为例，我方的宫子在199帧（时钟跳到1:27后的第19帧）开始一个普攻动作。从项目目录/test中启动lua解释器并执行：
```lua
pcr = require("env")
miyako = pcr.characters.miyako.default() --创建miyako角色的实例

--创建一场战斗（的第一帧状态），进攻方使用带时间轴的miyako（用上面创建的角色实例），防守方使用无时间轴的nozomi（用字符串指定）
frame0 = pcr.utils.makebattle({ miyako }, { "nozomi" }) 

--创建一个函数来输出技能开始事件
h=function(f)
  for _,ee in next,f.eventlist do
    if ee.name == "skillstart" then
      local skill = f.state:findcharacter(ee.team, ee.character).character.skills[ee.skillid]
      if not skill.idle then
        print(f.state:clocktime("m:s+f") .. "  " .. ee.character .. "  " .. skill.name)
      end
    end
  end
end

lastframe = pcr.core.simulation.run(frame0, h, 5460) --模拟到91秒
```
从输出中可以看到```01:27+19  miyako  attack```即为宫子的第一个攻击技能。

