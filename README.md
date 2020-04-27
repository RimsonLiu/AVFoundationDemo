# AVFoundationDemo

显示隐藏文件：

```
defaults write com.apple.finder AppleShowAllFiles -bool true
```

隐藏隐藏文件：

```
defaults write com.apple.finder AppleShowAllFiles -bool false
```

访达 command + shift + G 进入模拟器路径：

```
/Users/xxx/Library/Developer/CoreSimulator/Devices/
```

具体模拟器及应用路径，可通过打印 NSHomeDirectory() 获得，生成视频路径：

/Users/xxx/Library/Developer/CoreSimulator/Devices/xxx/data/Containers/Data/Application/xxx/Documents/test.mov

