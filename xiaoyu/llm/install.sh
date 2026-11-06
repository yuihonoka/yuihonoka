#!/bin/bash
# 小鱼yu 手机本地小模型（离线兜底）安装脚本
# 在小鱼yu App「终端」里运行，先在首页停止 AstrBot。
set -eu
D=/persistent/xiaoyu-llm
DATA=/persistent/astrbot/data
PY=/opt/astrbot-venv/bin/python; [ -x "$PY" ] || PY=python3
PAGES=https://yuihonoka.github.io/yuihonoka/xiaoyu/llm
MSIZE=396705472
MNAME=Qwen3-0.6B-Q4_K_M.gguf

[ "$(uname -m)" = aarch64 ] || { echo "⚠ 只支持 arm64 手机"; exit 1; }
if pgrep -f launch_astrbot.py >/dev/null 2>&1; then echo "⚠ 请先在 App 首页停止 AstrBot，再运行本脚本。"; exit 1; fi
[ -f "$DATA/cmd_config.json" ] || { echo "⚠ 找不到 AstrBot 配置：先启动一次 AstrBot 再停止，然后重跑。"; exit 1; }
FREE=$(df -Pk /persistent | awk 'NR==2{print $4}'); [ "$FREE" -gt 700000 ] || { echo "⚠ 空间不足，至少要 700MB"; exit 1; }

mkdir -p "$D"; cd "$D"
echo "1/4 下载程序包（约 14MB）…"
ok=0
for u in "$PAGES/xiaoyu-llm-pack.tar.gz" "https://raw.githubusercontent.com/yuihonoka/yuihonoka/main/xiaoyu/llm/xiaoyu-llm-pack.tar.gz"; do
  curl -fL --retry 3 -o pack.tar.gz "$u" && { ok=1; break; } || echo "  换一个地址…"
done
[ $ok = 1 ] || { echo "⚠ 程序包下载失败，检查网络后重跑"; exit 1; }
tar xzf pack.tar.gz -C /persistent && rm -f pack.tar.gz
chmod +x "$D/bin/llama-server" "$D/llm.sh"

echo "2/4 下载小模型（约 380MB，可断点续传）…"
if [ "$(stat -c %s "$D/model.gguf" 2>/dev/null || echo 0)" != "$MSIZE" ]; then
  for u in "https://hf-mirror.com/unsloth/Qwen3-0.6B-GGUF/resolve/main/$MNAME" "https://huggingface.co/unsloth/Qwen3-0.6B-GGUF/resolve/main/$MNAME"; do
    curl -fL --retry 5 -C - -o "$D/model.gguf" "$u" && break || echo "  换一个地址…"
  done
fi
[ "$(stat -c %s "$D/model.gguf" 2>/dev/null || echo 0)" = "$MSIZE" ] || { echo "⚠ 模型没下完整，重跑本脚本会接着下"; exit 1; }

echo "3/4 安装开机自启插件…"
mkdir -p "$DATA/plugins"; rm -rf "$DATA/plugins/astrbot_plugin_xiaoyu_local_llm"
cp -a "$D/plugin/astrbot_plugin_xiaoyu_local_llm" "$DATA/plugins/"

echo "4/4 把本地模型加进小鱼的后备列表（排最后）…"
cp -a "$DATA/cmd_config.json" "$DATA/cmd_config.json.bak-llm-$(date +%Y%m%d-%H%M%S)"
"$PY" - "$DATA/cmd_config.json" <<'PYEOF'
import json,sys
p=sys.argv[1]; c=json.load(open(p,encoding='utf-8-sig'))
src={"provider":"openai","type":"openai_chat_completion","provider_type":"chat_completion","key":["local"],
     "api_base":"http://127.0.0.1:7806/v1","timeout":600,"proxy":"","custom_headers":{},"id":"local","enable":True}
prov={"id":"local/qwen3-0.6b","enable":True,"provider_source_id":"local","model":"qwen3-0.6b",
      "modalities":["text"],"custom_extra_body":{},"max_context_tokens":2048}
c["provider_sources"]=[s for s in c.get("provider_sources",[]) if s.get("id")!="local"]+[src]
c["provider"]=[x for x in c.get("provider",[]) if x.get("id")!="local/qwen3-0.6b"]+[prov]
m=c.setdefault("agent_runner",{}).setdefault("config",{}).setdefault("model",{})
fb=[i for i in m.get("fallback_provider_ids",[]) if i!="local/qwen3-0.6b"]+["local/qwen3-0.6b"]
m["fallback_provider_ids"]=fb
json.dump(c,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=2)
print("  后备顺序：", " → ".join([m.get("provider_id","?")]+fb))
PYEOF
echo "✅ 装好了。回首页启动 AstrBot，本地模型会跟着自动待命。"
echo "   测试：bash $D/llm.sh test    状态：bash $D/llm.sh status"
