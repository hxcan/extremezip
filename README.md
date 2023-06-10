EXtremeZip，极限压缩
===

快速体验
==

```Shell
gem install EXtremeZip
wget https://github.com/hxcan/extremezip/releases/download/2021.6.23/extremezip.w.exz
exuz extremezip.w.exz
exz extremezip.w
```

说明
==

使用 VictoriaFreSh 来实现类似于 tar 的目录树打包和解包。

使用 ruby-lzma 来实现类似于 xz 的字节流压缩和解压缩。

使用 CBOR 作为整个压缩包的文件格式结构基础。

使用多进程模式来并行压缩，以减少压缩过程所需时间。

性能比较
==

单层目录结构，4371个子文件，所有文件总大小505.7MiB，文件的尺寸都接近，平均大小118.5KiB。CPU为Intel(R) Core(TM) i3-2350M CPU @ 2.30GHz，双核四线程。

使用EXtremeZip压缩，耗时6分1秒60毫秒，压缩包尺寸83.8MiB。这个版本，使用了磁盘缓存，会牺牲一些时间性能，另一方面会利用多进程并行压缩，尽量缩短压缩所需时间。
```Shell
exz StockDataTools/
```

使用tar加xz压缩，耗时9分40秒380毫秒，压缩包尺寸84.3MiB。使用默认参数，因而会使用单进程来进行压缩。
```Shell
tar -caf StockDataTools.tar.xz StockDataTools
```

使用tar加xz压缩，耗时4分6秒190毫秒，压缩包尺寸82.4MiB。使用特殊参数，要求xz使用全部可用的CPU线程来进行压缩。
```Shell
tar -c -I 'xz -T0'   -f StockDataTools.tar.xz StockDataTools
```
