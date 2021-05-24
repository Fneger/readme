# git常用命令

## 将本地文件添加到远程仓库

git init 
git clone '你的仓库url'

git add .
git commit -m '上传1'
git remote add origin '远程仓库url'
这时候直接push不行，需要：
git pull --rebase origin master
git push -u origin master

其中master为远程仓库主分支名称



## 合并分支

1.进入要合并的分支
git checkout (master)
git pull

2.查看所有分支是否都pull下来
git branch -a

3.使用merge合并开发分支
git merch (branch)

4.查看合并状态
git status

5.有冲突的话通过IDE解决冲突
6.解决冲突之后，将冲突文件提交暂存区
git add 冲突文件 或
git add . （提交所有文件）

删除文件
git rm --cached -r 文件名

7.提交merge之后的结果
git commit 或
git commit -m "备注内容"
如果不是使用git commit -m "备注" ，那么git会自动将合并的结果作为备注，提交本地仓库

8.本地仓库代码提交远程仓库
git push 或

git push origin master



## 设置和取消代理

```
//设置全局代理
//http
git config --global https.proxy http://127.0.0.1:1080
//https
git config --global https.proxy https://127.0.0.1:1080
//使用socks5代理的 例如ss，ssr 1080是windows下ss的默认代理端口,mac下不同，或者有自定义的，根据自己的改
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080

//只对github.com使用代理，其他仓库不走代理
git config --global http.https://github.com.proxy socks5://127.0.0.1:1080
git config --global https.https://github.com.proxy socks5://127.0.0.1:1080
//取消github代理
git config --global --unset http.https://github.com.proxy
git config --global --unset https.https://github.com.proxy

//取消全局代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

SSH协议

```
//对于使用git@协议的，可以配置socks5代理
//在~/.ssh/config 文件后面添加几行，没有可以新建一个
//socks5
Host github.com
User git
ProxyCommand connect -S 127.0.0.1:1080 %h %p

//http || https
Host github.com
User git
ProxyCommand connect -H 127.0.0.1:1080 %h %p
```

