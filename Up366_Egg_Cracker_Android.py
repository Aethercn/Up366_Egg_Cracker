import os
import re
import sys

def main_process():
    print("="*50)
    print("🥚 Up366 Egg Cracker (Android 版)")
    print("Created by Aether")
    print("="*50)
    
    # 获取当前脚本所在目录作为搜索起点
    current_dir = os.getcwd()
    questions_dir = os.path.join(current_dir, "questions")

    # 验证 questions 目录是否存在
    if not os.path.exists(questions_dir):
        # 如果当前就在 questions 目录下，则直接使用
        if os.path.basename(current_dir).lower() == 'questions':
            questions_dir = current_dir
        else:
            print(f"\n❌ 错误：未找到 'questions' 目录！")
            print(f"当前路径: {current_dir}")
            print("提示：请确保你已按照 README 将脚本放入包含 'questions' 的文件夹（通常是文件夹 '2'）内运行。")
            return

    print(f"\n📂 正在扫描目录: {questions_dir}")

    js_files_list = []
    
    # 遍历 questions 目录下的子文件夹（如 1, 2, 3...）
    for folder_name in os.listdir(questions_dir):
        full_folder_path = os.path.join(questions_dir, folder_name)
        if os.path.isdir(full_folder_path):
            question_num = 999 
            found_by = "未识别"
            
            # 1. 优先通过媒体文件名匹配题号
            media_path = os.path.join(full_folder_path, "media")
            if os.path.exists(media_path):
                for f in os.listdir(media_path):
                    if f.lower().endswith(".mp3"):
                        mp3_match = re.search(r'T(\d+)', f, re.IGNORECASE)
                        if mp3_match:
                            question_num = int(mp3_match.group(1))
                            found_by = f"MP3"
                            break
            
            # 2. 备选方案：通过文件夹名匹配题号
            if question_num == 999:
                folder_match = re.search(r'(\d+)', folder_name)
                if folder_match:
                    question_num = int(folder_match.group(1))
                    found_by = f"文件夹"
            
            # 寻找加密的 JS 文件
            target_js_path = None
            net_path = os.path.join(full_folder_path, "net")
            potential_paths = [net_path, full_folder_path]
            
            for p in potential_paths:
                if os.path.exists(p):
                    for f in os.listdir(p):
                        if f.endswith(".js"):
                            target_js_path = os.path.join(p, f)
                            break
                    if target_js_path: break
            
            if target_js_path:
                js_files_list.append((question_num, target_js_path))
                print(f"  ✅ [题号 {question_num:02d}] 来源: {found_by}")

    if not js_files_list:
        print("\n❌ 错误：未找到任何有效的答案文件 (.js)！")
        return

    # 按题号升序排列
    js_files_list.sort(key=lambda x: x[0])
    print(f"\n📑 成功识别 {len(js_files_list)} 道题目，正在解析...")

    # 合并并解析答案内容
    combined_content = ""
    for _, js_path in js_files_list:
        try:
            with open(js_path, 'r', encoding='utf-8') as f:
                combined_content += f.read() + "\n"
        except:
            with open(js_path, 'r', encoding='gbk') as f:
                combined_content += f.read() + "\n"

    outputs = []
    try:
        # 匹配 answer_text 块
        pattern = r'"answer_text"(.*?)"knowledge"'
        matches = re.findall(pattern, combined_content, re.DOTALL)
        
        if not matches:
             pattern = r'answer_text(.*?)"knowledge"'
             matches = re.findall(pattern, combined_content, re.DOTALL)
             
        for answer_block in matches:
            opt_match = re.search(r'[A-D]', answer_block)
            if opt_match:
                option = opt_match.group()
                # 提取对应选项的文本内容
                content_pattern = r'"id"\s*:\s*"{}"(.*?)"content"\s*:\s*"(.*?)"'.format(option)
                res = re.search(content_pattern, answer_block, re.DOTALL)
                if res:
                    clean_text = res.group(2).replace('\\"', '"')
                    outputs.append(clean_text)
    except Exception as e:
        print(f"⚠️ 解析过程出错: {e}")

    # 输出结果
    if not outputs:
        print("\n📭 警告：未提取到答案。请确保文件是加密格式 (.u3enc)。")
    else:
        print("\n" + "✨ 提取结果 " + "="*30)
        for i, ans in enumerate(outputs):
            print(f" {i+1:02d}. {ans}")
            print("-" * 20)
        print("="*40)
        print(f"🎉 成功提取 {len(outputs)} 个答案！")
        print("GitHub: Aethercn/Fuck_Up366")

if __name__ == "__main__":
    try:
        main_process()
    except KeyboardInterrupt:
        print("\n程序已手动停止。")
    except Exception as e:
        print(f"\n❌ 运行时崩溃: {e}")