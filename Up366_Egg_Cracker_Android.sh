#!/system/bin/sh

# =========================================================
# 🥚 Up366 听力砸蛋器 (完美修复版)
# 1. 修复了标记词含干扰字母导致永远选A的Bug
# 2. 增加了文件排序，防止题目乱序
# =========================================================

echo "========================================"
echo "   🥚 Up366 听力砸蛋器 (Shell版)   "
echo "========================================"

CURRENT_DIR=$(dirname "$0")
cd "$CURRENT_DIR" || exit

# 1. 查找并排序 .js 文件 (解决乱序问题)
# 使用 sort 确保题目按 T01, T02... 顺序排列
JS_FILES=$(find . -name "*.js" 2>/dev/null | sort)

if [ -z "$JS_FILES" ]; then
    echo "❌ 未找到 .js 文件，请确认脚本在 '2' 文件夹内。"
    exit 1
fi

TMP_FILE="./up366_raw.txt"
PARSED_FILE="./up366_parsed.txt"
rm -f "$TMP_FILE" "$PARSED_FILE"

# 2. 合并文件
echo "$JS_FILES" | while read -r f; do
    if [ -f "$f" ] && grep -q "answer_text" "$f"; then
        cat "$f" >> "$TMP_FILE"
        echo "" >> "$TMP_FILE"
    fi
done

if [ ! -s "$TMP_FILE" ]; then
    echo "❌ 未找到题目文件。"
    rm -f "$TMP_FILE"
    exit 1
fi

echo "✅ 正在解析..."
echo ""

# 3. 预处理
# 关键修复：使用 _SEP_ 作为分隔符，它不包含 [A-D]，不会干扰选项识别
cat "$TMP_FILE" | sed 's/\\"/"/g' | sed 's/"answer_text"/\n_SEP_/g' | grep "_SEP_" > "$PARSED_FILE"

count=1
echo "🎉 答案列表 🎉"
echo "----------------------------------------"

while read -r line; do
    # 截取 block
    block=$(echo "$line" | sed 's/"knowledge".*//')
    
    # 提取正确选项 (A/B/C/D)
    # 因为 _SEP_ 不含字母，这里抓到的第一个 [A-D] 才是真正的答案
    opt=$(echo "$block" | grep -o "[A-D]" | head -n 1)
    
    if [ -n "$opt" ]; then
        # 提取内容 logic
        # 1. 标记目标ID位置
        temp_str=$(echo "$block" | sed "s/\"id\":\"$opt\"/MARKER/")
        
        # 2. 截取 MARKER 之后的内容
        after_id=${temp_str#*MARKER}
        
        # 3. 截取 "content":" 之后的内容
        after_content=${after_id#*\"content\":\"}
        
        # 4. 截取答案文本
        final_answer=${after_content%%\"*}
        
        if [ -n "$final_answer" ]; then
            echo "[$count] $final_answer"
            echo "----------------------------------------"
            count=$((count + 1))
        fi
    fi
done < "$PARSED_FILE"

rm -f "$TMP_FILE" "$PARSED_FILE"

if [ $count -eq 1 ]; then
    echo "⚠️  未提取到答案。"
else
    echo ""
    echo "✅ 提取结束 (共 $((count - 1)) 题)"
fi
