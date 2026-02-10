#!/system/bin/sh

# =========================================================
# 🥚 Up366 听力砸蛋器 (Shell 轻量版)
# 专为 MT管理器 设计 - 无需 Python - 无需 Root (通常)
# =========================================================

# 定义基础路径 (MT管理器通常能直接访问这个路径)
BASE_PATH="/storage/emulated/0/Android/data/com.up366.mobile/files/flipbook"

# 排除目录列表 (grep 正则格式)
EXCLUDE_PATTERN="bookres|images|resources|checkFile|config.json|index.html|valid.bin"

echo "========================================"
echo "   🥚 Up366 听力砸蛋器 (Shell版)   "
echo "========================================"

# ---------------------------------------------------------
# 阶段 1: 环境检测与创建
# ---------------------------------------------------------
if [ ! -d "$BASE_PATH" ]; then
    echo "[!] 检测到 flipbook 文件夹不存在"
    echo "[*] 正在尝试自动创建..."
    
    mkdir -p "$BASE_PATH"
    
    if [ -d "$BASE_PATH" ]; then
        echo "✅ 自动创建成功！"
        echo "----------------------------------------"
        echo "🛑 请执行以下步骤："
        echo "1. 打开天学网 App"
        echo "2. 下载/重新下载你要做的听力题"
        echo "3. 再次运行本脚本查看答案"
        echo "----------------------------------------"
    else
        echo "❌ 自动创建失败 (权限不足)"
        echo "请在 MT管理器 中手动进入 /Android/data/com.up366.mobile/files/"
        echo "并新建名为 flipbook 的文件夹。"
    fi
    exit 0
fi

# ---------------------------------------------------------
# 阶段 2: 自动定位最新题目 (User -> Book)
# ---------------------------------------------------------
echo "[*] 正在自动定位题目..."

# 1. 找最新的 User 目录 (按时间排序 ls -t，取第一个 head -1)
USER_DIR=$(ls -td "$BASE_PATH"/*/ 2>/dev/null | head -n 1)

if [ -z "$USER_DIR" ]; then
    echo "❌ flipbook 目录为空"
    echo "💡 请先去 App 下载题目 (确保 flipbook 文件夹存在)"
    exit 1
fi

# 2. 找最新的 Book 目录 (排除系统文件夹)
# grep -vE 排除掉匹配 EXCLUDE_PATTERN 的行
BOOK_DIR=$(ls -td "$USER_DIR"/*/ 2>/dev/null | grep -vE "$EXCLUDE_PATTERN" | head -n 1)

if [ -z "$BOOK_DIR" ]; then
    echo "❌ 未找到题目文件夹"
    echo "💡 可能只下载了资源包，没下载具体题目"
    exit 1
fi

BOOK_NAME=$(basename "$BOOK_DIR")
echo "✅ 锁定目标: $BOOK_NAME"
echo "📂 正在扫描路径: $BOOK_DIR"
echo "========================================"

# ---------------------------------------------------------
# 阶段 3: 提取与解析 (Grep + Sed 魔法)
# ---------------------------------------------------------

# 查找所有 .js 文件
JS_FILES=$(find "$BOOK_DIR" -name "*.js" 2>/dev/null)

if [ -z "$JS_FILES" ]; then
    echo "❌ 未找到 .js 题目文件"
    exit 1
fi

# 创建临时文件
TMP_FILE="/sdcard/up366_temp_sh.txt"
rm -f "$TMP_FILE"

# 合并文件内容
# 注意：有些文件名带空格，使用 while read 循环处理
echo "$JS_FILES" | while read -r f; do
    if [ -f "$f" ]; then
        cat "$f" >> "$TMP_FILE"
        echo "" >> "$TMP_FILE" # 补个换行防粘连
    fi
done

echo "[*] 文件合并完成，正在解析答案..."

# --- 核心解析逻辑 ---
# 1. sed: 将 \" 替换为 " (去转义)
# 2. sed: 将 "answer_text" 替换为特殊标记，强行分行
# 3. grep: 筛选出包含答案的行
# 4. while循环: 逐行提取 ID 和 Content

count=1
has_answer=0

# 预处理并读取
cat "$TMP_FILE" | sed 's/\\"/"/g' | sed 's/"answer_text"/\nANSWER_BLOCK_START/g' | grep "ANSWER_BLOCK_START" | while read -r line; do
    
    # 截取直到 "knowledge" 的部分 (模拟 lazy match)
    # 使用 sed 删除 knowledge 及其后面的所有内容
    block=$(echo "$line" | sed 's/"knowledge".*//')
    
    # 提取选项字母 (A, B, C, D)
    # grep -o 只输出匹配的部分
    opt=$(echo "$block" | grep -o "[A-D]" | head -n 1)
    
    if [ -n "$opt" ]; then
        # 提取 Content
        # 匹配结构: "id":"A"..."content":"The Answer"
        # 使用 sed 的捕获组 \1 提取内容
        content=$(echo "$block" | sed -n "s/.*\"id\":\"$opt\".*\"content\":\"\([^\"]*\)\".*/\1/p")
        
        if [ -n "$content" ]; then
            if [ $count -eq 1 ]; then
                echo ""
                echo "🎉 答案列表 🎉"
                echo "----------------------------------------"
            fi
            echo "[$count] $content"
            echo "----------------------------------------"
            count=$((count + 1))
            has_answer=1
        fi
    fi
done

# 清理
rm -f "$TMP_FILE"

if [ $count -eq 1 ]; then
    echo "⚠️  未提取到答案 (可能文件已加密或格式变更)"
else
    echo ""
    echo "✅ 提取结束 (共 $((count - 1)) 题)"
fi

# 暂停防止窗口秒关
# echo "按回车键退出..."
# read _
