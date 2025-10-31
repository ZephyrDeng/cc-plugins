#!/bin/bash
# 快速测试脚本 - 验证所有功能

set -e

echo "🧪 Running webhook-notifier tests..."
echo ""

# 测试 1: CLI 帮助
echo "1️⃣ Testing CLI help..."
node dist/index.js --help
echo "✅ Help command passed"
echo ""

# 测试 2: Config 显示
echo "2️⃣ Testing config show..."
node dist/index.js config --show
echo "✅ Config show passed"
echo ""

# 测试 3: Config 验证
echo "3️⃣ Testing config validation..."
node dist/index.js config --validate
echo "✅ Config validation passed"
echo ""

# 测试 4: Logs 查看
echo "4️⃣ Testing logs view..."
node dist/index.js logs --lines 5
echo "✅ Logs view passed"
echo ""

# 测试 5: CLI Test
echo "5️⃣ Testing notification test..."
node dist/index.js test
echo "✅ Test command passed"
echo ""

# 测试 6: Hook 模式
echo "6️⃣ Testing hook mode..."
HOOK_OUTPUT=$(echo '{"hook_event_name":"Notification","session_id":"test-script","transcript_path":"/tmp/test.jsonl","cwd":"/tmp","permission_mode":"enabled"}' | node dist/index.js)
if [ "$HOOK_OUTPUT" = '{"continue":true}' ]; then
  echo "✅ Hook mode passed"
else
  echo "❌ Hook mode failed: unexpected output"
  echo "   Expected: {\"continue\":true}"
  echo "   Got: $HOOK_OUTPUT"
  exit 1
fi
echo ""

echo "✨ All tests passed!"
