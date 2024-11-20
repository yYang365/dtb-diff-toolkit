# 对比 DTB 的工具套件

## 目的

* 我有一个未知的 RK3399 开发板，它的原系统是 Android。
* 我给它安装了一个已有的 Armbian 系统，能运行但是有些硬件不工作。
* 如果我想让这些硬件正常工作，就需要把原始的 Android DTB 文件，反编译再改造成一个可以用于 Linux 的 DTB 文件。即魔改 DTB 文件。
* 我需要一些对比 DTB 的工具，让我知道有哪些需要改。
  1. 对比原始的 Android DTB 和魔改 DTB，让我明确自己已经改了哪些地方。
  2. 对比魔改 DTB 和已经正常工作的 Linux DTB，找出我还有哪些地方可能需要改。
  3. 对比官方源码标准开发板的 Android DTB 和 Linux DTB，找出从 Android 改造成 Linux 需要注意修改的地方。
* 直接对比 DTS 文件存在的问题：
  * 源码 DTS 的文件结构很灵活，有很多 include。很难对比。
  * 反编译出来的 DTS 文件，结构很简单，但是很难分辨参数中的哪些数据是 phandle。并且 phandle 的值是不稳定的，会产生很多额外的差异。

## 思路

* 这套工具的主要原理：把 DTB 文件反编译成排序过的 DTS 文件，然后把其中的 phandle 全部替换成 node 路径。这样 DTS 文件就变得稳定了，可以用于对比。
  * 为了方便Python 分析 DTS，会把 DTS 转换为 YAML。
  * 为了获得 node 中哪些属性的哪些参数是 phandle。会通过 kernel 源码中的 DTS 文件，自动搜集 phandle 的类型数据（*.type.yaml）。
  * 反编译出的 DTS 文件会搜集其中所有的 phandle，输出 *.pmap 文件。然后利用 phandle 的类型数据，把所有参数中的 phandle 数值替换成 node 路径。输出 *.p.yaml 文件。

## 使用方法

* 请阅读 Makefile 文件。
* `dump/rk3399-tps781-android.dtb` 是我从原版 Android 系统中提取出来的 DTB 文件。
* `dump/rk3399-tvi3315a.dtb.dtb` 是我从能运行但是有点硬件故障的 Armbian 系统中提取出来的 DTB 文件。
* `mod/rk3399-tps781-linux-wild-salad.dts` 是我魔改后的 DTS 文件。
