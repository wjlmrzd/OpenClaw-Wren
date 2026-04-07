#!/usr/bin/env python3
"""Batch update cron job models to achieve MiniMax:Dashscope = 5:2 ratio"""

import json
from pathlib import Path

JOBS_FILE = Path("D:/OpenClaw/.openclaw/cron/jobs.json")

# 方案：把高频任务从 Dashscope 迁移到 MiniMax
# 目标比例 MiniMax:Dashscope = 5:2 (71.4%:28.6%)

# 保留在 Dashscope 的低频任务（文本生成类）
KEEP_DASHSCOPE_GLM5 = [
    "afd8aec9-1a66-4bf7-a46a-bedf4490356e",  # 🌅 早晨摘要 (1次/日)
    "2428c991-f51e-47d7-8b6d-0035b8aba1e1",  # 📈 每周总结 (0.1次/日)
    "b8665efb-6e32-4a0b-b9ed-39ed69c69185",  # 📰 每日信息汇总 (1次/日)
    "58540a34-62ab-46a7-a713-cac112e5cd48",  # 🏃 运动提醒员 (1次/日)
    "0e63f087-5446-4033-b826-19dafe65673b",  # 📰 每日早报 (1次/日)
    "b41843c3-9956-4992-860d-df21cd03a766",  # 🌐 网站监控员 (1次/日)
]

# 保留在 Dashscope 的分析类低频任务
KEEP_DASHSCOPE_QWEN = [
    "22b950df-29d8-40a7-8d08-427cb032eabb",  # 🔍 系统自检员 (1次/日)
    "98d9b2a8-b925-470b-b0ea-4f74290f3e4b",  # 🛠️ 每日维护员 (1次/日)
    "b6bc413c-0228-48c8-b42c-0af833216d2c",  # 🧠 调度优化员 (8次/日)
]

# 迁移到 MiniMax（高频任务 - 降低 Dashscope 消耗）
TO_MINIMAX = [
    "ddd96cfb-f017-475e-8b2b-34c522b9ddae",  # 🧠 知识管理三元组 (180次/日 → 降至4次/日)
    "ccb233d7-0977-4d57-aba7-7564a67041d8",  # 🚑 故障自愈员 (12次/日)
    "e4248abd-0b9b-4540-9bc5-633547462443",  # 🧪 回归测试员 (24次/日)
    "7eb7f35e-fe72-4a90-bfc6-ed59392b10f6",  # 🔔 通知协调员 (8次/日)
    "2b564e59-8ed9-4cd8-8345-a9b41e4349bb",  # 📝 配置审计师 (6次/日)
    "791c995e-4758-469d-ac35-608da1627167",  # 📊 运营总监 (0.1次/日)
    "9f4f1914-3bbf-46e9-8ad4-30547e66998b",  # 🤖 伴侣检查员 (24次/日)
    "7677e68c-a6e7-4d92-8d31-09fb24bb5769",  # 🧠 知识整理员 (1次/日)
    "13f18a92-372a-4076-9b97-08f0efa2377f",  # 🧬 知识演化员 (1次/日)
    "fa18eb23-19af-4176-8e60-990050ba1fab",  # 📊 每周训练回顾 (0.1次/日)
    "3a1df011-613d-4528-a274-530cfd84f4fb",  # 📡 事件协调员 (24次/日)
    "2bb2b058-da87-486a-a400-b871cd5cf8a4",  # 💼 项目顾问 (1次/日)
]

def main():
    with open(JOBS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    changes = []
    
    for job in data["jobs"]:
        job_id = job["id"]
        name = job["name"]
        old_model = job["payload"].get("model", "")
        
        # Keep Dashscope (GLM-5)
        if job_id in KEEP_DASHSCOPE_GLM5:
            new_model = "dashscope-coding-plan/glm-5"
            if old_model != new_model:
                job["payload"]["model"] = new_model
                changes.append(f"✅ {name}: {old_model.split('/')[-1]} → glm-5 (Dashscope)")
        
        # Keep Dashscope (Qwen)
        elif job_id in KEEP_DASHSCOPE_QWEN:
            new_model = "dashscope-coding-plan/qwen3-coder-plus"
            if old_model != new_model:
                job["payload"]["model"] = new_model
                changes.append(f"✅ {name}: {old_model.split('/')[-1]} → qwen3-coder-plus (Dashscope)")
        
        # Migrate to MiniMax
        elif job_id in TO_MINIMAX:
            new_model = "minimax-coding-plan/minimax-2.7"
            if old_model != new_model:
                job["payload"]["model"] = new_model
                changes.append(f"✅ {name}: {old_model.split('/')[-1]} → minimax-2.7 (MiniMax)")
    
    # Special: Reduce knowledge-triple frequency from */8 to */6h
    for job in data["jobs"]:
        if job["id"] == "ddd96cfb-f017-475e-8b2b-34c522b9ddae":
            job["schedule"]["expr"] = "0 */6 * * *"  # Every 6 hours instead of every 8 minutes
            changes.append("🔧 🧠 知识管理三元组: */8 → */6h (频率降低)")
    
    # Write back
    with open(JOBS_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    # Report
    print("=" * 60)
    print("📋 模型迁移完成")
    print("=" * 60)
    for change in changes:
        print(change)
    
    print("\n" + "=" * 60)
    print("📊 最终分布预测")
    print("=" * 60)
    
    # Re-run prediction
    from predict_api_usage import parse_cron_expr
    
    minimax_calls = 0
    dashscope_calls = 0
    
    for job in data["jobs"]:
        if not job.get("enabled", True):
            continue
        model = job["payload"].get("model", "")
        expr = job["schedule"].get("expr", "0 0 * * *")
        daily = parse_cron_expr(expr)
        
        if "minimax" in model:
            minimax_calls += daily * 30
        elif "dashscope" in model:
            dashscope_calls += daily * 30
    
    total = minimax_calls + dashscope_calls
    print(f"\nMiniMax: {int(minimax_calls)} 次/月 ({minimax_calls/total*100:.1f}%)")
    print(f"Dashscope: {int(dashscope_calls)} 次/月 ({dashscope_calls/total*100:.1f}%)")
    
    if dashscope_calls > 0:
        ratio = minimax_calls / dashscope_calls
        print(f"\n比例: MiniMax:Dashscope = {ratio:.1f}:1 ≈ {ratio*2:.1f}:2")

if __name__ == "__main__":
    # Import prediction helper
    import sys
    sys.path.insert(0, str(Path(__file__).parent))
    main()