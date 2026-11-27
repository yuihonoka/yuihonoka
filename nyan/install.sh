#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka —— 猫娘 nyan 全家桶一键安装（需要先装好 nyan 本体）
set -e; B=$PREFIX/bin
[ -f $B/nyan ] || { echo "没找到 nyan 本体，先装猫娘Termux 的 nyan"; exit 1; }
cat > $B/nyan-x <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# 猫娘 Shizuku 小工具 · Author: yuihonoka
pink(){ printf '\e[38;5;218m%s\e[0m\n' "$*"; }
r(){ rish -c "$*"; }
case "$(rish -c id 2>&1)" in uid=*) ;; *) pink "Shizuku 没在跑哦，先用 Dhizuku 拉起来嘛"; exit 1;; esac
pk(){ # 模糊找包名
  r "pm list packages $2" | sed 's/^package://' | grep -i -- "$1" | head -n1; }
ask(){ read -r -p "$1 输入 喵 确认：" a; [ "$a" = "喵" ]; }
c="$1"; shift
case "$c" in
  电量)
    nyan-bat
    ;;
  动画)
    v="${1:-0.5}"; case "$v" in 0|0.5|1|1.5|2) ;; *) pink "给 0、0.5、1、1.5 或 2 嘛"; exit 1;; esac
    r "settings put global window_animation_scale $v; settings put global transition_animation_scale $v; settings put global animator_duration_scale $v"
    pink "动画调成 ${v}x 啦，手机变快快～"
    ;;
  清后台)
    r "am kill-all" && pink "后台清掉啦（正在用的不会动）"
    ;;
  冻结|解冻)
    [ -n "$1" ] || { pink "告诉我名字嘛，比如 nyan 冻结 huawei.appmarket"; exit 1; }
    p=$(pk "$1"); [ -n "$p" ] || { pink "找不到 $1 呀"; exit 1; }
    if [ "$c" = 冻结 ]; then ask "要冻结 $p 哦，系统组件冻错了可能开不了机相关功能。" || exit 0
      r "pm disable-user --user 0 $p" && pink "$p 睡着啦，nyan 解冻 $1 就能叫醒"
    else r "pm enable $p" && pink "$p 醒啦"; fi
    ;;
  冻结列表)
    r "pm list packages -d" | sed 's/^package:/  /'; ;;
  禁后台|放后台)
    [ -n "$1" ] || { pink "告诉我哪个 App 嘛，比如 nyan 禁后台 taobao"; exit 1; }
    p=$(pk "$1" -3); [ -n "$p" ] || { pink "没找到 $1（只认自己装的 App）"; exit 1; }
    if [ "$c" = 禁后台 ]; then r "cmd appops set $p RUN_ANY_IN_BACKGROUND ignore" && pink "$p 不许偷偷在后台跑啦"
    else r "cmd appops set $p RUN_ANY_IN_BACKGROUND allow" && pink "$p 可以后台了"; fi
    ;;
  截屏)
    f=/sdcard/Pictures/nyan_$(date +%Y%m%d_%H%M%S).png
    r "screencap -p $f" && pink "截好啦：$f"
    ;;
  包名)
    r "pm list packages -3" | sed 's/^package://' | grep -i -- "${1:-.}" | sort
    ;;
  *)
    pink "小工具这些哦："
    echo "  nyan 电量              电量、温度"
    echo "  nyan 动画 [0.5]        动画速度（0 关，1 原速）"
    echo "  nyan 清后台            杀后台进程"
    echo "  nyan 冻结/解冻 <名字>  冻结 App（会确认）"
    echo "  nyan 冻结列表          看冻了哪些"
    echo "  nyan 禁后台/放后台 <名字>  不让 App 偷跑后台"
    echo "  nyan 截屏              存到 Pictures"
    echo "  nyan 包名 [关键词]     查自己装的 App 包名"
    ;;
esac
NEKOEOF
chmod +x $B/nyan-x
cat > $B/nyan-app <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 做App：基于 ~/app-template 一键新建、编译、安装 App
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
T="$HOME/app-template"; A="$HOME/apps"
c="$1"; shift
[ -d "$T" ] || { pink "没找到 ~/app-template，先跑之前那条一键命令喵"; exit 1; }
mkdir -p "$A"
install_apk() {
  f=$(ls -t "$1"/*.apk 2>/dev/null | head -1)
  [ -n "$f" ] || { pink "没编出 apk，看看上面的报错"; exit 1; }
  cp "$f" "/sdcard/Download/$2.apk" && termux-open "/sdcard/Download/$2.apk"
  pink "装包弹窗出来就点安装～ 文件在 /sdcard/Download/$2.apk"
}
case "$c" in
  制作APP|制作App|做App|做APP|新App)
    name="$1"; pkg="$2"
    [ -n "$name" ] || { pink "用法：nyan 做App <名字> [包名]，例如 nyan 做App 猫猫 com.yuihonoka.neko"; exit 1; }
    [ -n "$pkg" ] || pkg="com.yuihonoka.app$(date +%m%d%H%M)"
    echo "$pkg" | grep -Eq '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$' || { pink "包名要像 com.xxx.yyy，只能小写字母数字"; exit 1; }
    d="$A/$name"
    [ -e "$d" ] && { pink "已经有叫 $name 的了，换个名字，或者 nyan 编译 $name"; exit 1; }
    cp -r "$T" "$d" && cd "$d" || exit 1
    rm -rf .git build *.apk
    old="com.flipphoneguy.app"; np=$(echo "$pkg" | tr '.' '/')
    mkdir -p "src/$np"
    if [ "src/com/flipphoneguy/app" != "src/$np" ]; then
      mv src/com/flipphoneguy/app/*.java "src/$np/"
      rm -rf src/com/flipphoneguy; rmdir src/com 2>/dev/null
    fi
    grep -rl "$old" src AndroidManifest.xml | xargs sed -i "s/$old/$pkg/g"
    sed -i "s/\"package\": *\"[^\"]*\"/\"package\": \"$pkg\"/; s/\"name\": *\"[^\"]*\"/\"name\": \"$name\"/" project.json
    sed -i "s|<string name=\"app_name\">[^<]*</string>|<string name=\"app_name\">$name</string>|" res/values/strings.xml
    pink "新建好了：$d（包名 $pkg），开始编译～"
    ./build.sh && install_apk "$d" "$name" ;;
  编译)
    name="$1"; d="$A/$name"
    [ -d "$d" ] || { pink "没有叫 $name 的 App，nyan App列表 看看"; exit 1; }
    cd "$d" && rm -f *.apk && ./build.sh && install_apk "$d" "$name" ;;
  App列表|APP列表)
    ls "$A" 2>/dev/null | sed 's/^/  · /'; [ -n "$(ls "$A" 2>/dev/null)" ] || pink "还没有 App，nyan 做App <名字> 来一个" ;;
  *)
    pink "nyan 做App <名字> [包名]   新建并编译安装"
    pink "nyan 编译 <名字>           改完代码重新编译安装"
    pink "nyan App列表               看做过的 App"
    pink "代码在 ~/apps/<名字>/src，界面在 res/layout" ;;
esac
NEKOEOF
chmod +x $B/nyan-app
cat > $B/nyan-media <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 放歌 / 解析：在 Termux 里放音乐、看视频信息
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
UA="Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36"
c="$1"; shift
src() {
  s="$1"
  [ -z "$s" ] && { pink "要给文件路径或链接喵"; exit 1; }
  if echo "$s" | grep -Eq '^[0-9]{3,}$'; then id="$s"
  else id=$(echo "$s" | grep -Eo '(id=|song/)[0-9]+' | grep -Eo '[0-9]+' | head -1); fi
  if [ -n "$id" ] && { echo "$s" | grep -q 163 || [ "$s" = "$id" ]; }; then
    echo "https://music.163.com/song/media/outer/url?id=$id.mp3"; return
  fi
  if echo "$s" | grep -q '163cn.tv'; then
    real=$(curl -sIL -A "$UA" "$s" -o /dev/null -w '%{url_effective}')
    id=$(echo "$real" | grep -Eo '(id=|song/)[0-9]+' | grep -Eo '[0-9]+' | head -1)
    [ -n "$id" ] && { echo "https://music.163.com/song/media/outer/url?id=$id.mp3"; return; }
  fi
  echo "$s"
}
case "$c" in
  放歌|听)
    command -v mpv >/dev/null || { pink "先装：pkg install -y mpv"; exit 1; }
    u=$(src "$*")
    pink "开放～ 空格暂停，q 退出，←→ 快进快退"
    mpv --no-video --ao=opensles --user-agent="$UA" --referrer="https://music.163.com/" "$u" || pink "放不了：VIP/没版权的歌拿不到音源，或者网络不通" ;;
  后台放歌)
    command -v mpv >/dev/null || { pink "先装：pkg install -y mpv"; exit 1; }
    u=$(src "$*")
    nohup mpv --no-video --ao=opensles --really-quiet --user-agent="$UA" --referrer="https://music.163.com/" "$u" >/dev/null 2>&1 &
    pink "在后台放啦，nyan 停歌 就停" ;;
  停歌)
    pkill -f "mpv --no-video" && pink "停了" || pink "本来就没在放" ;;
  解析)
    command -v ffprobe >/dev/null || { pink "先装：pkg install -y ffmpeg"; exit 1; }
    f="$*"; [ -n "$f" ] || { pink "用法：nyan 解析 <视频文件或直链>"; exit 1; }
    ffprobe -v error -user_agent "$UA" -show_entries format=format_long_name,duration,size,bit_rate:stream=codec_type,codec_name,width,height,r_frame_rate,sample_rate,channels -of json "$f" | jq -r '
      .format as $f |
      "格式：\($f.format_long_name)",
      "时长：\(($f.duration // "0") | tonumber | floor | "\(./60|floor):\(.%60|tostring|if length<2 then "0"+. else . end)")",
      (if $f.size then "大小：\((($f.size|tonumber)/1048576*100|floor)/100) MB" else empty end),
      (if $f.bit_rate then "码率：\(($f.bit_rate|tonumber)/1000|floor) kbps" else empty end),
      (.streams[] | if .codec_type=="video" then "视频：\(.codec_name) \(.width)×\(.height) \(.r_frame_rate | split("/") | if (.[1]|tonumber)>0 then ((.[0]|tonumber)/(.[1]|tonumber)*100|floor/100|tostring) else .[0] end) fps"
        elif .codec_type=="audio" then "音频：\(.codec_name) \(.sample_rate) Hz \(.channels) 声道" else "其它轨：\(.codec_type) \(.codec_name)" end)' || pink "解析不了，文件路径或链接对吗？" ;;
  *)
    pink "nyan 放歌 <文件/网易云链接或id>   放音乐"
    pink "nyan 后台放歌 <...>  /  nyan 停歌"
    pink "nyan 解析 <视频文件或直链>       看时长、分辨率、编码、帧率" ;;
esac
NEKOEOF
chmod +x $B/nyan-media
cat > $B/nyan-bili <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan B站：扫码登录自己的哔哩哔哩账号，看信息和关注动态
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
D="$HOME/.nyan"; CK="$D/bili.cookie"; mkdir -p "$D"; chmod 700 "$D"
UA="Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36"
for t in curl jq qrencode; do command -v $t >/dev/null || { pink "先装工具：pkg install -y curl jq libqrencode"; exit 1; }; done
api() { curl -s -A "$UA" -e "https://www.bilibili.com/" -b "$CK" "$@"; }
c="$1"; shift
case "$c" in
  登录)
    J=$(curl -s -A "$UA" https://passport.bilibili.com/x/passport-login/web/qrcode/generate)
    URL=$(echo "$J" | jq -r .data.url); KEY=$(echo "$J" | jq -r .data.qrcode_key)
    [ -n "$KEY" ] && [ "$KEY" != null ] || { pink "拿不到二维码，网络不通？"; exit 1; }
    qrencode -t ANSIUTF8 -m 1 "$URL"
    qrencode -s 10 -o /sdcard/Download/bili_qr.png "$URL" 2>/dev/null && pink "二维码也存到了 下载/bili_qr.png"
    pink "打开 B站 App → 扫一扫 → 右上角相册 → 选 bili_qr.png → 确认登录"
    pink "（3 分钟内有效，等你喵…）"
    for i in $(seq 1 90); do
      sleep 2
      R=$(curl -s -A "$UA" -c "$CK.tmp" "https://passport.bilibili.com/x/passport-login/web/qrcode/poll?qrcode_key=$KEY")
      case "$(echo "$R" | jq -r .data.code)" in
        0) mv "$CK.tmp" "$CK"; chmod 600 "$CK"; rm -f /sdcard/Download/bili_qr.png; pink "登录成功！"; exec "$0" 我 ;;
        86090) [ -z "$s" ] && { pink "扫到啦，在 App 里点确认～"; s=1; } ;;
        86038) rm -f "$CK.tmp"; pink "二维码过期了，再 nyan B站 登录"; exit 1 ;;
      esac
    done
    rm -f "$CK.tmp"; pink "等太久了，再来一次吧"; exit 1 ;;
  我|信息)
    [ -f "$CK" ] || { pink "还没登录，先 nyan B站 登录"; exit 1; }
    api https://api.bilibili.com/x/web-interface/nav | jq -r 'if .data.isLogin then "昵称：\(.data.uname)\nUID：\(.data.mid)\n等级：Lv\(.data.level_info.current_level)（经验 \(.data.level_info.current_exp)）\n硬币：\(.data.money)\n大会员：\(if .data.vipStatus==1 then "是" else "否" end)" else "登录失效了，重新 nyan B站 登录" end' ;;
  动态)
    [ -f "$CK" ] || { pink "还没登录，先 nyan B站 登录"; exit 1; }
    n="${1:-10}"
    api "https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/all?type=all" | jq -r --argjson n "$n" '
      if .code != 0 then "拿不到动态：\(.message)（\(.code)）" else
      .data.items[:$n][] | .modules as $m |
      "· \($m.module_author.name)  \($m.module_author.pub_time)\n  \(
        ($m.module_dynamic.major.archive.title // $m.module_dynamic.major.opus.title // $m.module_dynamic.desc.text // "（图片/转发）") | tostring | .[0:60])\(
        if $m.module_dynamic.major.archive.bvid then "\n  https://b23.tv/" + $m.module_dynamic.major.archive.bvid else "" end)" end' ;;
  退出)
    rm -f "$CK"; pink "已经删掉本机的 B站 登录了" ;;
  *)
    pink "nyan B站 登录     扫码登录（不用输密码）"
    pink "nyan B站 我       看昵称、等级、硬币"
    pink "nyan B站 动态 [条数]  看关注的人最新动态"
    pink "nyan B站 退出     删掉本机登录"
    pink "登录信息只存在 ~/.nyan/bili.cookie，别发给别人" ;;
esac
NEKOEOF
chmod +x $B/nyan-bili
cat > $B/nyan-bili-search.py <<'NEKOEOF'
# Author: yuihonoka
# nyan B站 搜：按关键词搜B站视频（wbi 签名）
import sys, json, time, hashlib, urllib.parse, urllib.request, http.cookiejar, os
UA="Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36"
ck=os.path.expanduser("~/.nyan/bili.cookie")
jar=http.cookiejar.MozillaCookieJar()
if os.path.exists(ck):
    try: jar.load(ck, ignore_discard=True, ignore_expires=True)
    except Exception: pass
op=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
def get(u):
    r=urllib.request.Request(u, headers={"User-Agent":UA,"Referer":"https://www.bilibili.com/"})
    return op.open(r, timeout=15).read()
if not any(c.name=="buvid3" for c in jar): get("https://www.bilibili.com/")
nav=json.loads(get("https://api.bilibili.com/x/web-interface/nav"))["data"]["wbi_img"]
k=lambda u:u.rsplit("/",1)[1].split(".")[0]
raw=k(nav["img_url"])+k(nav["sub_url"])
T=[46,47,18,2,53,8,23,32,15,50,10,31,58,3,45,35,27,43,5,49,33,9,42,19,29,28,14,39,12,38,41,13,37,48,7,16,24,55,40,61,26,17,0,1,60,51,30,4,22,25,54,21,56,59,6,63,57,62,11,36,20,34,44,52]
mk="".join(raw[i] for i in T)[:32]
a=sys.argv[1:]
if not a: print("用法：nyan B站 搜 <关键词> [条数]"); sys.exit(1)
n=10
if len(a)>1 and a[-1].isdigit(): n=int(a.pop())
kw=" ".join(a)
p={"search_type":"video","keyword":kw,"page":1,"wts":int(time.time())}
p={a:"".join(ch for ch in str(b) if ch not in "!'()*") for a,b in sorted(p.items())}
q=urllib.parse.urlencode(p,quote_via=urllib.parse.quote)
q+="&w_rid="+hashlib.md5((q+mk).encode()).hexdigest()
d=json.loads(get("https://api.bilibili.com/x/web-interface/wbi/search/type?"+q))
if d.get("code")!=0: print("搜不到：",d.get("message"),d.get("code")); sys.exit(1)
if "result" not in d["data"]: print("被B站风控了喵，先 nyan B站 登录，登录后再搜"); sys.exit(1)
import re
for v in (d["data"].get("result") or [])[:n]:
    t=re.sub("<[^>]+>","",v["title"])
    print(f"· {t}\n  UP：{v['author']}  播放 {v['play']}  时长 {v['duration']}\n  https://b23.tv/{v['bvid']}")
NEKOEOF
chmod +x $B/nyan-bili-search.py
cat > $B/nyan-util <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 实用工具：下载、空间、进程、配置、发文件、收文件
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
need() { command -v "$1" >/dev/null || { pink "先装：pkg install -y $2"; exit 1; }; }
c="$1"; shift
case "$c" in
  下载)
    need aria2c aria2
    [ -n "$1" ] || { pink "用法：nyan 下载 <链接>"; exit 1; }
    aria2c -x 16 -s 16 -k 1M --file-allocation=none -d /sdcard/Download "$@" && pink "下好了，在 下载 文件夹" ;;
  空间)
    need ncdu ncdu
    pink "↑↓ 选，回车进入，d 删除（会先问），q 退出"
    ncdu "${1:-/sdcard}" ;;
  进程)
    need htop htop
    pink "F9 结束进程，F10 或 q 退出"
    htop ;;
  配置)
    need fastfetch fastfetch
    fastfetch ;;
  发文件)
    need croc croc
    [ -e "$1" ] || { pink "用法：nyan 发文件 <文件或文件夹>"; exit 1; }
    pink "把下面出现的口令告诉对方，对方 nyan 收文件 <口令>"
    croc send "$@" ;;
  收文件)
    need croc croc
    [ -n "$1" ] || { pink "用法：nyan 收文件 <口令>"; exit 1; }
    cd /sdcard/Download && CROC_SECRET="$1" croc --yes && pink "收到了，在 下载 文件夹" ;;
  *)
    pink "nyan 下载 <链接>      16 线程下载到 下载 文件夹"
    pink "nyan 空间 [文件夹]    看什么占空间（默认整个存储）"
    pink "nyan 进程             看谁在吃 CPU 和内存"
    pink "nyan 配置             看手机配置"
    pink "nyan 发文件 <文件>    / nyan 收文件 <口令>" ;;
esac
NEKOEOF
chmod +x $B/nyan-util
cat > $B/nyan-net <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 换源：开着 VPN 走官方源，没开走国内镜像（pkg / pip / npm / git）
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
Q=""; [ "$2" = "-q" ] && Q=1
say() { [ -n "$Q" ] || pink "$*"; }
SL="$PREFIX/etc/apt/sources.list"; ST="$HOME/.nyan/net.mode"; mkdir -p "$HOME/.nyan"
OFF="https://packages-cf.termux.dev/apt/termux-main"
CN="https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main"
vpn_on() {
  ls /sys/class/net 2>/dev/null | grep -Eq '^(tun|ppp|wg)' && return 0
  command -v ifconfig >/dev/null && ifconfig 2>/dev/null | grep -Eq '^(tun|ppp|wg)' && return 0
  return 1
}
apply() {
  mode="$1"
  if [ "$mode" = 官方 ]; then url="$OFF"; else url="$CN"; fi
  old=$(cat "$ST" 2>/dev/null)
  if [ "$old" != "$mode" ] || ! grep -q "^deb $url " "$SL"; then
    cp -n "$SL" "$SL.nyanbak" 2>/dev/null
    echo "deb $url stable main" > "$SL"
    if [ "$mode" = 官方 ]; then
      command -v pip >/dev/null && pip config unset global.index-url >/dev/null 2>&1
      command -v npm >/dev/null && npm config delete registry >/dev/null 2>&1
      git config --global --unset-all url."https://gitclone.com/github.com/".insteadOf 2>/dev/null
      git config --global --unset-all url."https://github.com/".pushInsteadOf 2>/dev/null
    else
      command -v pip >/dev/null && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple >/dev/null 2>&1
      command -v npm >/dev/null && npm config set registry https://registry.npmmirror.com >/dev/null 2>&1
      git config --global --replace-all url."https://gitclone.com/github.com/".insteadOf "https://github.com/"
      git config --global --replace-all url."https://github.com/".pushInsteadOf "https://github.com/"
    fi
    echo "$mode" > "$ST"
    say "已切到 $mode 源"
    [ -n "$NYAN_NOUPDATE" ] || apt update -qq >/dev/null 2>&1
  else
    say "现在就是 $mode 源"
  fi
}
case "$1" in
  自动|"") if vpn_on; then say "检测到 VPN 开着"; apply 官方; else say "没开 VPN"; apply 国内; fi ;;
  官方) apply 官方 ;;
  国内) apply 国内 ;;
  状态) pink "VPN：$(vpn_on && echo 开着 || echo 没开)  当前源：$(cat "$ST" 2>/dev/null || echo 未设置)"; grep '^deb' "$SL" ;;
  关自动) sed -i '/# >>> nyan-net >>>/,/# <<< nyan-net <<</d' ~/.bashrc; pink "关掉自动换源了，重开 Termux 生效" ;;
  *) pink "nyan 换源 [自动|官方|国内|状态|关自动]" ;;
esac
NEKOEOF
chmod +x $B/nyan-net
cat > $B/nyan-sys <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 系统：猫猫图案 + 手机系统版本
g() { getprop "$1" 2>/dev/null; }
name=$(g ro.product.marketname); [ -n "$name" ] || name="$(g ro.product.brand) $(g ro.product.model)"
emui=$(g ro.build.version.emui)
art=(
"     /\\_____/\\     "
"    /  o   o  \\    "
"   ( ==  ^  == )   "
"    )         (    "
"   (           )   "
"  ( (  )   (  ) )  "
" (__(__)___(__)__) "
"        喵～       "
"                   "
)
info=(
"$(whoami)@$(g ro.product.model)"
"────────────────"
"机型：$name"
"安卓：Android $(g ro.build.version.release)（API $(g ro.build.version.sdk)）"
"${emui:+EMUI：$emui}"
"版本：$(g ro.build.display.id)"
"补丁：$(g ro.build.version.security_patch)"
"内核：$(uname -r)"
"架构：$(g ro.product.cpu.abi)"
)
for i in "${!art[@]}"; do
  printf '\033[38;5;211m%s\033[0m  \033[38;5;117m%s\033[0m\n' "${art[$i]}" "${info[$i]}"
done
printf '%21s' ''; for c in 211 218 225 159 117 147 183; do printf '\033[48;5;%sm   \033[0m' $c; done; echo
NEKOEOF
chmod +x $B/nyan-sys
cat > $B/nyan-ds <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan deepseek：开关 DeepSeek Harness
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
[ -f ~/dsh/start_dsh.sh ] || { pink "还没装 DeepSeek Harness，先跑安装命令喵"; exit 1; }
case "$1" in
  ""|开|启动) pink "启动中～ 浏览器会打开 127.0.0.1:3080"; bash ~/dsh/start_dsh.sh ;;
  关|停) bash ~/dsh/stop_dsh.sh && pink "关掉啦" ;;
  日志) tail -n 40 ~/dsh/storage/dsh.log ;;
  重装|更新) cd ~/deepseek-harness-android && git pull && bash setup.sh ;;
  *) pink "nyan deepseek [开|关|日志|重装]" ;;
esac
NEKOEOF
chmod +x $B/nyan-ds
cat > $B/nyan-cat <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
printf '\033[38;5;211m'
cat <<'CAT'
     /\_____/\
    /  o   o  \
   ( ==  ^  == )
    )         (
   (           )
  ( (  )   (  ) )
 (__(__)___(__)__)
        喵～
CAT
printf '\033[0m'
NEKOEOF
chmod +x $B/nyan-cat
cat > $B/nyan-help <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 教程：所有 nyan 命令
C='\033[38;5;211m'; B='\033[38;5;117m'; N='\033[0m'
cat <<'TXT' | sed -e "s/^【\(.*\)】$/$(printf "$C")【\1】$(printf "$N")/" -e "s/^  \(nyan[^ ]* [^ ]*\)/  $(printf "$B")\1$(printf "$N")/"
嗯嗯，这些我都会哦～ 不带参数输子命令也会教你怎么用
【手机与权限】
  nyan 状态              看 Shizuku / Dhizuku 在不在
  nyan 开机              重启后恢复 adb 5555 和 Shizuku（先用 Dhizuku 拉起 Shizuku）
  nyan 激活              把 Dhizuku 设成设备所有者（一次性）
  nyan 取消激活          告诉你怎么撤销
  nyan 无线adb           把 adb 端口设成 5555
  nyan shell             进 Shizuku 权限的 shell
  nyan 系统              猫猫图案 + 安卓、EMUI、补丁、内核
【小工具（要 Shizuku）】
  nyan 电量              电量、温度
  nyan 动画 0.5          动画速度（0 关，1 原速）
  nyan 清后台            杀后台进程
  nyan 冻结 <名字>       冻结 App（会先确认），nyan 解冻 <名字>
  nyan 冻结列表          看冻了哪些
  nyan 禁后台 <名字>     不让偷跑后台，nyan 放后台 <名字>
  nyan 截屏              存到 Pictures
  nyan 包名 <关键词>     查 App 包名
【外观】
  nyan 换背景 <文件>     图片/GIF/视频当背景，nyan 换背景 关
  nyan 暗度 45           背景压暗（0-95）
【音乐与视频】
  nyan 放歌 <文件/网易云链接或id>   空格暂停，q 退出
  nyan 后台放歌 <...>    nyan 停歌 停
  nyan 解析 <视频>       时长、分辨率、编码、帧率
【哔哩哔哩】
  nyan B站 登录          扫码登录（B站 App 扫一扫→相册选 下载/bili_qr.png）
  nyan B站 我            昵称、等级、硬币
  nyan B站 动态 10       关注的人最新动态
  nyan B站 搜 猫娘 5     搜视频
  nyan B站 退出          删掉本机登录
【做 App】
  nyan 做App <名字>      新建、编译、弹安装
  nyan 编译 <名字>       改完代码重新编译
  nyan App列表           看做过的 App（代码在 ~/apps/<名字>）
【实用】
  nyan 下载 <链接>       16 线程下载到 下载 文件夹
  nyan 空间 [文件夹]     看什么占空间
  nyan 进程              看谁在吃 CPU（q 退出）
  nyan 配置              手机配置总览
  nyan 发文件 <文件>     nyan 收文件 <口令>
【换源】
  nyan 换源              VPN 开走官方，没开走国内（用 pkg/pip/git 前自动切）
  nyan 换源 状态         也可以 官方 / 国内 / 关自动
【DeepSeek】
  nyan deepseek          启动，浏览器开 127.0.0.1:3080
  nyan deepseek 关       也可以 日志 / 重装
【画画、VNC 和 turtle】
  nyan vnc               开 VNC + 掉线自动拉起 + 打开猫娘AVNC，nyan vnc 关
  nyan turtle            turtle 11 课，nyan turtle 3 看第 3 课并画出来
  nyan 画 [文件.py]      画小猫或你的 turtle 程序，nyan 停画 关掉
【Python 打包 APK】
  nyan 打包py <脚本.py> [App名]   传到 GitHub 云端打包
  nyan 取apk                       打包好后下载到 下载 文件夹并安装
【Java、模块和 QQ 脚本】
  nyan java              Java 11 课，nyan java 3 看第 3 课并运行
  nyan 模块 新 <名字>    建 Shizuku 桥模块，nyan 模块 试/改/包 <名字>
  nyan qq 新 <名字>      建 QEdge(QQ) Java 脚本，nyan qq 改/包 <名字>
【小提示】
  粘贴命令前看一眼开头，别多出 / 或 -
  输 nyan 教程 随时再看这页
TXT
NEKOEOF
chmod +x $B/nyan-help
cat > $B/nyan-vnc <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan vnc：开/关 VNC、掉线自动拉起、一键打开猫娘AVNC（自动填地址和密码）
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
SOCK="$PREFIX/tmp/.X11-unix/X1"; PID="$HOME/.nyan/vnc-guard.pid"; mkdir -p "$HOME/.nyan"
VP=$(cat "$HOME/.nyan/vncpass" 2>/dev/null)
URI="vnc://127.0.0.1:5901?${VP:+VncPassword=$VP&}ConnectionName=%E7%8C%AB%E5%A8%98Termux"
alive() { [ -S "$SOCK" ] && pgrep -f "Xvnc :1" >/dev/null; }
start() {
  alive && return 0
  vncserver -kill :1 >/dev/null 2>&1; rm -f "$SOCK" "$PREFIX/tmp/.X1-lock"
  vncserver :1 -localhost yes -geometry 1080x1920 >/dev/null 2>&1; sleep 2; alive
}
guard_on() {
  [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null && return
  command -v termux-wake-lock >/dev/null && termux-wake-lock
  nohup bash -c 'while true; do if ! { [ -S "'"$SOCK"'" ] && pgrep -f "Xvnc :1" >/dev/null; }; then vncserver -kill :1 >/dev/null 2>&1; rm -f "'"$SOCK"'" "'"$PREFIX"'/tmp/.X1-lock"; vncserver :1 -localhost yes -geometry 1080x1920 >/dev/null 2>&1; fi; sleep 10; done' >/dev/null 2>&1 &
  echo $! > "$PID"
}
openv() {
  am start -a android.intent.action.VIEW -d "$URI" com.yuihonoka.nekoavnc >/dev/null 2>&1 \
  || am start -a android.intent.action.VIEW -d "$URI" >/dev/null 2>&1 \
  || pink "手动打开猫娘AVNC，连 127.0.0.1:5901"
}
case "$1" in
  ""|开) start && pink "VNC 开好啦" || { pink "VNC 开不了，看 ~/.vnc/localhost:1.log"; exit 1; }; guard_on; pink "掉线会自动拉起（每 10 秒检查）"; openv ;;
  连) openv ;;
  关) [ -f "$PID" ] && kill "$(cat "$PID")" 2>/dev/null; rm -f "$PID"; vncserver -kill :1 >/dev/null 2>&1; command -v termux-wake-unlock >/dev/null && termux-wake-unlock; pink "VNC 和守护都关掉啦" ;;
  状态) alive && pink "VNC：在跑" || pink "VNC：没跑"; [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null && pink "守护：开着" || pink "守护：没开" ;;
  *) pink "nyan vnc [开|连|关|状态]" ;;
esac
NEKOEOF
chmod +x $B/nyan-vnc
cat > $B/nyan-turtle <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan turtle：turtle 从零到会，11 课
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
D="$HOME/turtle"; mkdir -p "$D"
install_lessons() {
cat > "$D/01.py" <<'LESSON'
# 第1课：直线和转弯
# forward(距离) 往前走，right(角度)/left(角度) 转弯。走4次转4次90度就是正方形。
import turtle as t
t.shape("turtle")
for i in range(4):
    t.forward(200)
    t.right(90)
t.done()
LESSON
cat > "$D/02.py" <<'LESSON'
# 第2课：颜色和粗细
# color(颜色) 换笔的颜色，width(数字) 换粗细，bgcolor 换背景。
import turtle as t
t.bgcolor("black"); t.width(6)
for c in ["red", "orange", "yellow", "lime"]:
    t.color(c); t.forward(200); t.left(90)
t.done()
LESSON
cat > "$D/03.py" <<'LESSON'
# 第3课：循环画多边形
# n 条边，每次转 360/n 度。改 n 试试 3、6、12。
import turtle as t
n = 6
t.color("hotpink"); t.width(4)
for i in range(n):
    t.forward(150); t.left(360 / n)
t.done()
LESSON
cat > "$D/04.py" <<'LESSON'
# 第4课：圆和填充
# circle(半径) 画圆；begin_fill() 和 end_fill() 之间画的形状会被涂满。
import turtle as t
t.color("orange", "yellow")
t.begin_fill(); t.circle(120); t.end_fill()
t.done()
LESSON
cat > "$D/05.py" <<'LESSON'
# 第5课：抬笔移动
# penup() 抬笔走路不留痕，goto(x, y) 跳到坐标，pendown() 放下笔。
import turtle as t
t.speed(0)
for x in range(-240, 241, 120):
    t.penup(); t.goto(x, -40); t.pendown()
    t.color("deepskyblue", "lightblue")
    t.begin_fill(); t.circle(40); t.end_fill()
t.done()
LESSON
cat > "$D/06.py" <<'LESSON'
# 第6课：函数：画星星
# def 定义一个函数，以后一句话就能画一颗星。星星每次转 144 度。
import turtle as t
def star(x, y, size, c):
    t.penup(); t.goto(x, y); t.pendown()
    t.color(c); t.begin_fill()
    for i in range(5):
        t.forward(size); t.right(144)
    t.end_fill()
t.speed(0); t.bgcolor("midnightblue")
star(-200, 100, 120, "gold"); star(50, 150, 80, "white"); star(0, -150, 160, "pink")
t.hideturtle(); t.done()
LESSON
cat > "$D/07.py" <<'LESSON'
# 第7课：彩虹螺旋
# 每次多走一点再转一点，就会转出螺旋。颜色轮流用。
import turtle as t
t.bgcolor("black"); t.speed(0); t.width(2)
colors = ["red", "orange", "yellow", "lime", "cyan", "blue", "violet"]
for i in range(300):
    t.color(colors[i % 7]); t.forward(i * 1.5); t.left(59)
t.done()
LESSON
cat > "$D/08.py" <<'LESSON'
# 第8课：写字
# write(文字, align, font) 在当前位置写字。
import turtle as t
t.hideturtle(); t.color("hotpink")
t.write("喵～ 你好 turtle", align="center", font=("Arial", 40, "bold"))
t.done()
LESSON
cat > "$D/09.py" <<'LESSON'
# 第9课：键盘控制小海龟
# onkey(函数, 按键) 绑定按键，listen() 开始听。在 AVNC 里按方向键试试。
import turtle as t
t.shape("turtle"); t.color("green"); t.width(3)
t.onkey(lambda: t.forward(30), "Up")
t.onkey(lambda: t.backward(30), "Down")
t.onkey(lambda: t.left(30), "Left")
t.onkey(lambda: t.right(30), "Right")
t.onkey(t.clear, "c")
t.listen(); t.done()
LESSON
cat > "$D/10.py" <<'LESSON'
# 第10课：点击画画
# onscreenclick 点哪里海龟就跑去哪里，边跑边画。
import turtle as t
t.shape("circle"); t.color("hotpink"); t.width(4); t.speed(0)
t.onscreenclick(t.goto)
t.done()
LESSON
cat > "$D/11.py" <<'LESSON'
# 第11课：小动画：转圈的花
# tracer(0) 关掉自动刷新，update() 手动刷新，就能做流畅动画。
import turtle as t
t.tracer(0); t.hideturtle(); t.bgcolor("white")
a = 0
def frame():
    global a
    t.clear(); t.setheading(a)
    for i in range(12):
        t.color("hotpink" if i % 2 else "violet")
        t.circle(100, 60); t.left(120); t.circle(100, 60); t.left(30 + 120)
    t.update(); a += 3
    t.ontimer(frame, 30)
frame(); t.done()
LESSON
}
[ -f "$D/11.py" ] || install_lessons
list() {
  pink "🐢 turtle 教程（代码在 ~/turtle）"
  echo "  01  直线和转弯"
  echo "  02  颜色和粗细"
  echo "  03  循环画多边形"
  echo "  04  圆和填充"
  echo "  05  抬笔移动"
  echo "  06  函数：画星星"
  echo "  07  彩虹螺旋"
  echo "  08  写字"
  echo "  09  键盘控制小海龟"
  echo "  10  点击画画"
  echo "  11  小动画：转圈的花"
  pink "nyan turtle 3      看第 3 课讲解和代码，然后画出来"
  pink "nyan turtle 改 3   用 nano 改第 3 课（Ctrl+O 存，Ctrl+X 退）"
  pink "nyan turtle 重置   把课程恢复成原样"
}
n=$(printf '%02d' "${2:-$1}" 2>/dev/null)
case "$1" in
  ""|列表) list ;;
  重置) install_lessons; pink "课程恢复好啦" ;;
  改) [ -f "$D/$n.py" ] && nano "$D/$n.py" || pink "没有第 $2 课" ;;
  *) f="$D/$n.py"; [ -f "$f" ] || { pink "没有第 $1 课"; list; exit 1; }
     printf '\033[38;5;117m'; sed -n '1,2p' "$f"; printf '\033[0m'; sed '1,2d' "$f"; echo
     nyan-vnc 开 >/dev/null; nyan-vnc 连
     pink "在猫娘AVNC 里看海龟画画，看完关窗口或 Ctrl+C"
     DISPLAY=:1 python "$f" ;;
esac
NEKOEOF
chmod +x $B/nyan-turtle
cat > $B/nyan-draw <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 画：一键开 VNC（带掉线守护）并跑 turtle
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
[ "$1" = 停 ] && exec nyan-vnc 关
f="${1:-$HOME/cat.py}"; [ -f "$f" ] || f="$HOME/$1"
[ -f "$f" ] || { pink "找不到 $1，用法：nyan 画 [文件.py]"; exit 1; }
nyan-vnc 开 >/dev/null || { pink "VNC 开不了"; exit 1; }
nyan-vnc 连
pink "开画～ 在猫娘AVNC 里看，画完关窗口或 Ctrl+C"
DISPLAY=:1 python "$f"
NEKOEOF
chmod +x $B/nyan-draw
cat > $B/nyan-pyapk <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 打包py：把 py 传到 GitHub 仓库 yuihonoka/yuihonoka 的 pyapk/，云端自动打包成 APK
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
R="${NYAN_REPO:-yuihonoka/yuihonoka}"
f="$1"; [ -f "$f" ] || { pink "用法：nyan 打包py <脚本.py> [App名]"; exit 1; }
name="${2:-$(basename "$f" .py)}"
gh auth status >/dev/null 2>&1 || { pink "先连 GitHub：gh auth login"; exit 1; }
put() { sha=$(gh api "repos/$R/contents/$1" -q .sha 2>/dev/null); gh api -X PUT "repos/$R/contents/$1" -f message="nyan 打包 $name" -f content="$(base64 -w0 "$2")" ${sha:+-f sha=$sha} >/dev/null; }
printf '%s' "$name" > $PREFIX/tmp/nyan_name.txt
put pyapk/name.txt $PREFIX/tmp/nyan_name.txt && put pyapk/user_script.py "$f" || { pink "上传失败"; exit 1; }
pink "传上去啦，云端开始打包（第一次大约 20 分钟），好了运行：nyan 取apk"
NEKOEOF
chmod +x $B/nyan-pyapk
cat > $B/nyan-getapk <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
R="${NYAN_REPO:-yuihonoka/yuihonoka}"
set -- $(gh run list -R "$R" -w neko-pyapk -L 1 --json databaseId,status,conclusion -q '.[0] | "\(.databaseId) \(.status) \(.conclusion)"')
[ -n "$1" ] || { pink "还没有打包记录，先 nyan 打包py"; exit 1; }
[ "$2" = completed ] || { pink "还在打包（$2），等等再来喵"; exit 0; }
[ "$3" = success ] || { pink "打包失败了，日志：gh run view $1 -R $R --log-failed | tail -40"; exit 1; }
rm -rf ~/pyapk/out && gh run download "$1" -R "$R" -n apk -D ~/pyapk/out || exit 1
a=$(ls ~/pyapk/out/*.apk | head -1); cp "$a" /sdcard/Download/ && pink "APK 放到 下载 文件夹啦" && termux-open "/sdcard/Download/$(basename "$a")"
NEKOEOF
chmod +x $B/nyan-getapk
cat > $B/nyan-java <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan java：Java 从零到会，11 课
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
D="$HOME/java"; mkdir -p "$D"
install_lessons() {
cat > "$D/L01.java" <<'LESSON'
// 第1课：你好世界
// 每个 Java 程序从 main 开始，System.out.println 打印一行。
public class L01 {
    public static void main(String[] args) {
        System.out.println("喵～ 你好 Java！");
    }
}
LESSON
cat > "$D/L02.java" <<'LESSON'
// 第2课：变量和类型
// int 整数，double 小数，String 文字，boolean 真假。
public class L02 {
    public static void main(String[] args) {
        int age = 18; double h = 1.62; String name = "小汐"; boolean cat = true;
        System.out.println(name + " " + age + " 岁，身高 " + h + "，是猫娘：" + cat);
    }
}
LESSON
cat > "$D/L03.java" <<'LESSON'
// 第3课：判断 if
// if / else if / else 按条件走不同的路。
public class L03 {
    public static void main(String[] args) {
        int score = 85;
        if (score >= 90) System.out.println("优秀喵");
        else if (score >= 60) System.out.println("及格啦");
        else System.out.println("要加油哦");
    }
}
LESSON
cat > "$D/L04.java" <<'LESSON'
// 第4课：循环 for / while
// for 适合数次数，while 适合等条件。
public class L04 {
    public static void main(String[] args) {
        for (int i = 1; i <= 5; i++) System.out.println("第 " + i + " 声：喵");
        int n = 3;
        while (n > 0) { System.out.println("倒数 " + n); n--; }
    }
}
LESSON
cat > "$D/L05.java" <<'LESSON'
// 第5课：数组
// 一排同类型的数据，下标从 0 开始。
public class L05 {
    public static void main(String[] args) {
        String[] cats = {"橘猫", "黑猫", "三花"};
        for (String c : cats) System.out.println(c);
        System.out.println("一共 " + cats.length + " 只");
    }
}
LESSON
cat > "$D/L06.java" <<'LESSON'
// 第6课：方法
// 把一段代码起个名字，需要时调用，可以有参数和返回值。
public class L06 {
    static int add(int a, int b) { return a + b; }
    static void meow(int times) { for (int i = 0; i < times; i++) System.out.print("喵"); System.out.println(); }
    public static void main(String[] args) {
        System.out.println("3 + 4 = " + add(3, 4));
        meow(5);
    }
}
LESSON
cat > "$D/L07.java" <<'LESSON'
// 第7课：类和对象
// class 是图纸，new 出来的是对象，每个对象有自己的属性。
public class L07 {
    static class Cat {
        String name; int age;
        Cat(String n, int a) { name = n; age = a; }
        void say() { System.out.println(name + "（" + age + " 岁）：喵～"); }
    }
    public static void main(String[] args) {
        new Cat("小汐", 2).say();
        new Cat("团子", 1).say();
    }
}
LESSON
cat > "$D/L08.java" <<'LESSON'
// 第8课：输入 Scanner
// Scanner 读你在键盘上打的字。
import java.util.Scanner;
public class L08 {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        System.out.print("你叫什么名字？");
        String name = in.nextLine();
        System.out.println("你好 " + name + "，喵～");
    }
}
LESSON
cat > "$D/L09.java" <<'LESSON'
// 第9课：集合 ArrayList 和 HashMap
// ArrayList 能变长的列表，HashMap 用名字查东西。
import java.util.*;
public class L09 {
    public static void main(String[] args) {
        List<String> food = new ArrayList<>(List.of("小鱼干", "猫条"));
        food.add("牛奶");
        Map<String, Integer> price = new HashMap<>();
        price.put("小鱼干", 15); price.put("猫条", 8);
        System.out.println(food + "，猫条 " + price.get("猫条") + " 元");
    }
}
LESSON
cat > "$D/L10.java" <<'LESSON'
// 第10课：异常 try/catch
// 出错时不闪退，接住错误自己处理。
public class L10 {
    public static void main(String[] args) {
        try {
            int x = Integer.parseInt("喵");
        } catch (NumberFormatException e) {
            System.out.println("这不是数字喵：" + e.getMessage());
        }
    }
}
LESSON
cat > "$D/L11.java" <<'LESSON'
// 第11课：小游戏：猜数字
// 把前面学的合起来：随机数、循环、判断、输入。
import java.util.*;
public class L11 {
    public static void main(String[] args) {
        int ans = new Random().nextInt(100) + 1, n = 0;
        Scanner in = new Scanner(System.in);
        System.out.println("我想了一个 1~100 的数，猜猜看喵");
        while (true) {
            System.out.print("> "); int g = in.nextInt(); n++;
            if (g < ans) System.out.println("小了"); else if (g > ans) System.out.println("大了");
            else { System.out.println("猜对啦！用了 " + n + " 次"); break; }
        }
    }
}
LESSON
}
[ -f "$D/L11.java" ] || install_lessons
list() {
  pink "☕ Java 教程（代码在 ~/java）"
  echo "  01  你好世界"
  echo "  02  变量和类型"
  echo "  03  判断 if"
  echo "  04  循环 for / while"
  echo "  05  数组"
  echo "  06  方法"
  echo "  07  类和对象"
  echo "  08  输入 Scanner"
  echo "  09  集合 ArrayList 和 HashMap"
  echo "  10  异常 try/catch"
  echo "  11  小游戏：猜数字"
  pink "nyan java 3      看第 3 课讲解和代码，然后运行"
  pink "nyan java 改 3   用 nano 改第 3 课"
  pink "nyan java 跑 文件.java   运行你自己写的"
  pink "nyan java 重置   恢复课程"
}
command -v java >/dev/null || { pink "先装 Java（只装一次）"; pkg install -y openjdk-17 || exit 1; }
n=$(printf '%02d' "${2:-$1}" 2>/dev/null)
case "$1" in
  ""|列表) list ;;
  重置) install_lessons; pink "课程恢复好啦" ;;
  改) [ -f "$D/L$n.java" ] && nano "$D/L$n.java" || pink "没有第 $2 课" ;;
  跑) [ -f "$2" ] && java "$2" || pink "找不到 $2" ;;
  *) f="$D/L$n.java"; [ -f "$f" ] || { pink "没有第 $1 课"; list; exit 1; }
     printf '\033[38;5;117m'; sed -n '1,2p' "$f"; printf '\033[0m'; sed '1,2d' "$f"; echo
     pink "▶ 运行结果："; java "$f" ;;
esac
NEKOEOF
chmod +x $B/nyan-java
cat > $B/nyan-make <<'NEKOEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Author: yuihonoka
# nyan 模块 / nyan qq：一键建 Shizuku 桥模块、QEdge(QQ) Java 脚本模板，试跑并打包
pink() { printf '\033[38;5;211m%s\033[0m\n' "$*"; }
kind="$1"; act="$2"; name="$3"; id="${4:-neko_$(date +%s)}"
case "$kind" in 模块) base="$HOME/mods" ;; qq) base="$HOME/qq" ;; *) exit 1 ;; esac
d="$base/$name"
usage() { pink "nyan $kind 新 <名字> [id]   建模板"; pink "nyan $kind 改 <名字>        用 nano 改"; [ "$kind" = 模块 ] && pink "nyan 模块 试 <名字>        用 rish 试跑 action.sh"; pink "nyan $kind 包 <名字>        打包到 下载 文件夹"; pink "nyan $kind 列表"; }
[ "$act" = 列表 ] && { ls "$base" 2>/dev/null || pink "还没有"; exit; }
[ -n "$name" ] || { usage; exit; }
case "$kind:$act" in
  模块:新)
    mkdir -p "$d/webui"
    printf 'id=%s\nname=%s\nversion=1.0\nversionCode=1\nauthor=yuihonoka\ndescription=%s · by yuihonoka\n' "$id" "$name" "$name" > "$d/module.prop"
    cat > "$d/action.sh" <<'SH'
#!/system/bin/sh
# Author: yuihonoka
echo "喵～模块在线"
id | cut -d' ' -f1
dumpsys battery | grep -E " level| temperature"
SH
    cat > "$d/webui/index.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<!-- Author: yuihonoka -->
<style>body{font-family:sans-serif;background:#fff0f5;color:#c2185b;padding:16px}button{background:#ff6f9f;color:#fff;border:0;border-radius:12px;padding:12px 18px;margin:6px;font-size:16px}pre{background:#fff;border-radius:12px;padding:12px;white-space:pre-wrap}</style></head>
<body><h2>喵～我的模块</h2>
<button onclick="run('dumpsys battery | grep -E \' level| temperature\'')">电量温度</button>
<button onclick="run('settings get global animator_duration_scale')">动画速度</button>
<pre id="o">点按钮试试</pre>
<script>
var Z=window.Shizuku;
function run(c){var o=document.getElementById('o');if(!Z){o.textContent='没有 window.Shizuku：长按模块选 Trust 或开 Full 模式';return}
try{var r=JSON.parse(Z.exec(c));o.textContent=r.stderr?('出错了：'+r.stderr):r.stdout}catch(e){o.textContent=String(e)}}
</script></body></html>
HTML
    pink "建好啦：$d（改 action.sh 和 webui/index.html）" ;;
  模块:改) nano "$d/action.sh" ;;
  模块:试) command -v rish >/dev/null || { pink "没有 rish，先 nyan 开机"; exit 1; }; rish -c "$(cat "$d/action.sh")" ;;
  qq:新)
    mkdir -p "$d"
    printf 'id=%s_yuihonoka\npluginName=%s\nauthor=yuihonoka\nversionCode=1.0\n' "$id" "$name" > "$d/info.prop"
    printf '%s · 喵～\nAuthor: yuihonoka\n' "$name" > "$d/desc.txt"
    echo "Author: yuihonoka" > "$d/AUTHOR.txt"
    cat > "$d/main.java" <<'JAVA'
// Author: yuihonoka
// QEdge 脚本模板：在 QQ 里运行，菜单里会出现下面两个按钮
addItem("喵一下", "onMeow");
addItem("看日志", "onShow");
int count = 0;

void onMeow(int chatType, String peerUin, String name) {
    count++;
    toast("喵～这是第 " + count + " 次");
    log("neko.log", "喵了一下，第 " + count + " 次\n");
}

void onShow(int chatType, String peerUin, String name) {
    toast("一共喵了 " + count + " 次");
}
JAVA
    pink "建好啦：$d（改 main.java）" ;;
  qq:改) nano "$d/main.java" ;;
  *:包) [ -d "$d" ] || { pink "没有 $name"; exit 1; }; command -v zip >/dev/null || pkg install -y zip
       out="/sdcard/Download/$name-1.0.zip"; rm -f "$out"; (cd "$d" && zip -qr "$out" .) && pink "打包好啦：$out" ;;
  *) usage ;;
esac
NEKOEOF
chmod +x $B/nyan-make
cp $B/nyan $B/nyan.bak.$(date +%s)
sed -i '/# >>> nyan-routes >>>/,/# <<< nyan-routes <<</d' $B/nyan
cat > $PREFIX/tmp/nyan_routes <<'NEKOEOF'
  # >>> nyan-routes >>>
  电量|动画|清后台|冻结|解冻|冻结列表|禁后台|放后台|截屏|包名|工具) exec nyan-x "$@" ;;
  制作APP|制作App|做App|做APP|新App|编译|App列表|APP列表) exec nyan-app "$@" ;;
  放歌|听|后台放歌|停歌|解析) exec nyan-media "$@" ;;
  B站|b站|哔哩哔哩) shift; exec nyan-bili "$@" ;;
  下载|空间|进程|配置|发文件|收文件|实用) exec nyan-util "$@" ;;
  换源) shift; exec nyan-net "$@" ;;
  系统|版本) exec nyan-sys ;;
  deepseek|DeepSeek|ds|DS) shift; exec nyan-ds "$@" ;;
  vnc|VNC) shift; exec nyan-vnc "$@" ;;
  turtle|海龟) shift; exec nyan-turtle "$@" ;;
  画) shift; exec nyan-draw "$@" ;;
  停画) exec nyan-draw 停 ;;
  打包py) shift; exec nyan-pyapk "$@" ;;
  取apk) shift; exec nyan-getapk "$@" ;;
  java|Java) shift; exec nyan-java "$@" ;;
  模块|qq|QQ) k=$1; [ "$k" = QQ ] && k=qq; shift; exec nyan-make "$k" "$@" ;;
  # <<< nyan-routes <<<
NEKOEOF
if ! python3 - "$B/nyan" "$PREFIX/tmp/nyan_routes" <<'PY' 2>/dev/null
import sys,re
p=sys.argv[1]; s=open(p,encoding="utf-8").read(); r=open(sys.argv[2],encoding="utf-8").read()
keys=["nyan-java","nyan-make","nyan-x","nyan-app","nyan-media","nyan-bili","nyan-util","nyan-net","nyan-sys","nyan-ds","nyan-vnc","nyan-turtle","nyan-draw","nyan-pyapk","nyan-getapk"]
s="\n".join(l for l in s.split("\n") if not (re.search(r"exec ("+"|".join(map(re.escape,keys))+r")\b",l)))
s=s.replace("  shell)\n", r+"  shell)\n",1)
open(p,"w",encoding="utf-8").write(s)
PY
then awk -v r="$(cat $PREFIX/tmp/nyan_routes)" '/^  shell\)$/ && !d {print r; d=1} {print}' "$B/nyan" > "$B/nyan.new" && mv "$B/nyan.new" "$B/nyan"; fi
chmod +x $B/nyan
grep -q '^  ""|help|帮助|教程)' $B/nyan || sed -i 's/^  ""|help|帮助)$/  ""|help|帮助|教程)\n    exec nyan-help ;;\n  旧帮助)/' $B/nyan
grep -q '^nyan-cat$' ~/.bashrc || echo nyan-cat >> ~/.bashrc
mkdir -p ~/.nyan
echo; $B/nyan-cat; echo "喵～ nyan 全家桶装好啦，输 nyan 看教程"
